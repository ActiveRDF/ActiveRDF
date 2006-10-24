# RDFLite is our own lightweight RDF database on top of sqlite3.  It satisfies 
# the ActiveRDF adapter interface, so it is also an adapter to this datastore 
# from ActiveRDF.
#
# Author:: Eyal Oren
# Copyright:: (c) 2005-2006 Eyal Oren
# License:: LGPL

require 'sqlite3'
require 'active_rdf'
require 'federation/connection_pool'

begin 
	require 'ferret'
	@@have_ferret = true
rescue LoadError
	$log.warn "We could not load ferret, therefore keyword search is not available. If you want keyword search, please install ferret: gem install ferret"
	@@have_ferret = false
end

class RDFLite < GemPlugin::Plugin "/adapter"
	$log.info "loading RDFLite adapter"
	ConnectionPool.register_adapter(:rdflite,self)
	attr_reader :db

	# instantiate RDFLite database
	def initialize(params = {})
		$log.info "initialised rdflite with params #{params.to_s}"
	
		# if no file-location given, we use in-memory store
		file = params[:location] || ':memory:'
		@db = SQLite3::Database.new(file) 

		# we enable keyword unless the user specifies otherwise
		@keyword_search = if params[:keyword].nil?
												true
											else
											  params[:keyword]
											end

		# we can only do keyword search if ferret is found
		@keyword_search &= @@have_ferret
		$log.debug "we #{@keyword_search ? "do" : "don't"} have keyword search"

		if @keyword_search
			# we initialise the ferret index, either as a file or in memory

			# we setup the fields not to store object's contents
			infos = Ferret::Index::FieldInfos.new
			infos.add_field(:subject, :store => :yes, :index => :no, :term_vector => :no)
			infos.add_field(:object, :store => :no, :index => :omit_norms)
			
			@ferret = if params[:location]
									Ferret::I.new(:path => params[:location] + '.ferret', :field_infos => infos)
								else
									Ferret::I.new(:field_infos => infos)
								end
		end

		# turn off filesystem synchronisation for speed
		@db.synchronous = 'off'
		#execute('pragma synchronous = off')

		# create triples table. since triples are unique, inserted duplicates are 
		@db.execute('create table if not exists triple(s,p,o, unique(s,p,o) on conflict ignore)')

		sidx = params[:sidx] || false
		pidx = params[:pidx] || false
		oidx = params[:oidx] || false
		spidx = params[:spidx] || true
		soidx = params[:soidx] || false
		poidx = params[:poidx] || true
		opidx = params[:opidx] || false

		# creating lookup indices
		@db.execute('create index if not exists sidx on triple(s)') if sidx
		@db.execute('create index if not exists pidx on triple(p)') if pidx
		@db.execute('create index if not exists oidx on triple(o)') if oidx
		@db.execute('create index if not exists spidx on triple(s,p)') if spidx
		@db.execute('create index if not exists soidx on triple(s,p)') if soidx
		@db.execute('create index if not exists poidx on triple(p,o)') if poidx
		@db.execute('create index if not exists opidx on triple(o,p)') if opidx

		$log.debug("opened connection to #{file}")
		$log.debug("database contains #{size} triples")
	end

	# returns all triples in the datastore
	def dump
		@db.execute('select s,p,o from triple') do |s,p,o|
			[s,p,o].join(' ')
		end
	end

	# we can read and write to this adapter
	def writes?; true; end
	def reads?; true; end

	# returns the number of triples in the datastore (incl. possible duplicates)
	def size
		@db.execute('select count(*) from triple')[0]
	end

	#def clear
	#	@db.execute('delete from triple')
	#end
	
	def add(s,p,o)
		raise(ActiveRdfError, "adding non-resource #{s}") unless s.respond_to?(:uri)
		raise(ActiveRdfError, "adding non-resource #{p}") unless p.respond_to?(:uri)

		s = "<#{s.uri}>"
		p = "<#{p.uri}>"
		o = case o
				when RDFS::Resource
					"<#{o.uri}>"
				else
					"\"#{o.to_s}\""
				end

		add_internal(s,p,o)
	end
	
	def add_internal(s,p,o)
		# insert the triple into the datastore
		@db.execute('insert into triple values (?,?,?)', s,p,o)

		# if keyword-search available, insert the object into keyword search
		@ferret << {:subject => s, :object => o} if @keyword_search
	end

	def load(file)
		time = Time.now

		@db.transaction do 
			ntriples = File.readlines(file)
			ntriples.each do |triple|
				nodes = triple.scan(Node)
				add_internal(nodes[0], nodes[1], nodes[2])
			end
			$log.debug("read #{ntriples.size} triples from file in #{Time.now - time}s")
		end
	end

	def query(query)
		# log received query
		$log.debug "received query: #{query.to_sp}"

		# construct query clauses
		sql = translate(query)

		# executing query, passing all where-clause values as parameters (so that 
		# sqlite will encode quotes correctly)
		constraints = @right_hand_sides.collect { |value| value.to_s }

		$log.debug format("executing: #{sql.gsub('?','"%s"')}", *constraints)

		# executing query
		results = @db.execute(sql, *constraints)

		return [results[0][0].to_i > 0] if query.ask?

		# convert results to ActiveRDF nodes and return them
		wrap(query, results)
	end

	def translate(query)
		construct_select(query) + construct_join(query) + construct_where(query) + 
			construct_limit(query)
	end

	private
	# construct select clause
	def construct_select(query)
		# ask queries just count the results, and return true if results > 0
		return "select count(*)" if query.ask?

		# find the right select clause for this term
		select = query.select_clauses.collect do |term|
			variable_name(query, term)
		end

		select_clause = ''
		select_clause << 'distinct ' if query.distinct?
		select_clause << select.join(', ')
		select_clause = "count(#{select_clause})" if query.count?

		"select " + select_clause
	end

	# construct (optional) limit and offset clauses
	def construct_limit(query)
		clause = ""

		# if no limit given, use limit -1 (no limit)
		limit = query.limits.nil? ? -1 : query.limits

		# if no offset given, use offset 0
		offset = query.offsets.nil? ? 0 : query.offsets

		clause << " limit #{limit} offset #{offset}"
		clause
	end

	# construct join clause
	# TODO: joins don't work this way, they have to be linear (in one direction 
	# only, and we should only alias tables we didnt alias yet)
	# we should only look for one join clause in each where-clause: when we find 
	# one, we skip the rest of the variables in this clause.
	def construct_join(query)
		join_stmt = ''

		# no join necessary if only one where clause given
		return ' from triple as t0 ' if query.where_clauses.size == 1

		where_clauses = query.where_clauses.flatten
		considering = where_clauses.uniq.select{|w| w.is_a?(Symbol)}

		# constructing hash with indices for all terms
		# e.g. {?s => [1,3,5], ?p => [2], ... }
		term_occurrences = Hash.new()
		where_clauses.each_with_index do |term, index|
			ary = (term_occurrences[term] ||= [])
			ary << index 
		end

		aliases = {}

		where_clauses.each_with_index do |term, index|
			# if the term has been joined with his buddy already, we can skip it
			next unless considering.include?(term)

			# we find all (other) occurrences of this term
			indices = term_occurrences[term]

			# if the term doesnt have a join-buddy, we can skip it
			next if indices.size == 1

			# construct t0,t1,... as aliases for term
			# and construct join condition, e.g. t0.s
			termalias = "t#{index / 3}"
			termjoin = "#{termalias}.#{SPO[index % 3]}"

			join = if join_stmt.include?(termalias)
							 ""
						 else
							 "triple as #{termalias}"
						 end

			indices.each do |i|
				# skip the current term itself
				next if i==index

				# construct t0,t1, etc. as aliases for buddy,
				# and construct join condition, e.g. t0.s = t1.p
				buddyalias = "t#{i/3}"
				buddyjoin = "#{buddyalias}.#{SPO[i%3]}"

				# TODO: fix reuse of same table names as aliases, e.g.
				# "from triple as t1 join triple as t2 on ... join t1 on ..."
				# is not allowed as such by sqlite
				# but on the other hand, restating the aliases gives ambiguity:
				# "from triple as t1 join triple as t2 on ... join triple as t1 ..."
				# is ambiguous
				join << " join triple as #{buddyalias} on #{termjoin} = #{buddyjoin} "
			end
			join_stmt << join
			
			# remove term from 'todo' list of still-considered terms
			considering.delete(term)
		end

		if join_stmt == ''
			return " from triple as t0 "
		else
			return " from #{join_stmt} "
		end
	end

	# construct where clause
	def construct_where(query)
		# collecting where clauses, these will be added to the sql string later
		where = []

		# collecting all the right-hand sides of where clauses (e.g. where name = 
		# 'abc'), to add to query string later using ?-notation, because then 
		# sqlite will automatically encode quoted literals correctly
		@right_hand_sides = []

		# convert each where clause to SQL:
		# add where clause for each subclause, except if it's a variable
		query.where_clauses.each_with_index do |clause,level|
			clause.each_with_index do |subclause, i|
				# dont add where clause for variables
				unless subclause.is_a?(Symbol)
					where << "t#{level}.#{SPO[i]} = ?"
					@right_hand_sides << case subclause
				 	when RDFS::Resource
						"<#{subclause.uri}>"
					else
						subclause.to_s
					end
				end
			end
		end

		# if keyword clause given, convert it using keyword index
		if query.keyword?
			subjects = []
			query.keywords.each do |subject, key|
				@ferret.search_each("object:\"#{key}\"") do |idx,score|
					subjects << @ferret[idx][:subject]
				end
				subjects.uniq! if query.distinct?
				where << "#{variable_name(query,subject)} in (#{subjects.collect {'?'}.join(',')})"
				@right_hand_sides += subjects
			end
		end

		if where.empty?
			''
		else
			"where " + where.join(' and ')
		end
	end

	# returns sql variable name for a queryterm
	def variable_name(query,term)
		# look up the first occurence of this term in the where clauses, and compute 
		# the level and s/p/o position of it
		index = query.where_clauses.flatten.index(term)
		raise ActiveRdfError,'unbound variable in select clause' if index.nil?
		termtable = "t#{index / 3}"
		termspo = SPO[index % 3]
		return "#{termtable}.#{termspo}"
	end

	# wrap resources into ActiveRDF resources, literals into Strings
	def wrap(query, results)
		results.collect do |row|
			row.collect do |result|
				case result
				when Resource
					RDFS::Resource.new($1)
				when Literal
					String.new($1)
				else
					# when we do a count(*) query we get a number, not a resource/literal
					results
				end
			end
		end
	end

	Resource = /<([^>]*)>/
	Literal = /"([^"]*)"/
	Node = Regexp.union(/<[^>]*>/,/"[^"]*"/)
	SPO = ['s','p','o']

end
