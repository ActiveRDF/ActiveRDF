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

class RDFLite
	ConnectionPool.register_adapter(:rdflite,self)
	attr_reader :db

	# instantiate RDFLite database
	def initialize(params = {})
		# if no file-location given, we use in-memory store
		file = params[:location] || ':memory:'
		@db = SQLite3::Database.new(file) 

		# turn off filesystem synchronisation for speed
		# TODO: can we safely do that?
		@db.execute('pragma synchronous = off')

		# create triples table. since triples are unique, inserted duplicates are 
		# ignored
		@db.execute('create table if not exists triple(s,p,o, unique(s,p,o) on conflict ignore)')

		# creating lookup indices
		@db.execute('create index if not exists sidx on triple(s)')
		@db.execute('create index if not exists pidx on triple(p)')
		@db.execute('create index if not exists oidx on triple(o)')
		@db.execute('create index if not exists spidx on triple(s,p)')
		@db.execute('create index if not exists poidx on triple(p,o)')

		log("opened connection to #{file}")
		log("database contains #{size} triples")
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

	def load(file)
		time = Time.now

		ntriples = File.readlines(file)
		ntriples.each do |triple|
			nodes = triple.scan(Node)
			@db.execute('insert into triple values (?,?,?)',nodes[0], nodes[1], nodes[2])
		end
		
		log("read #{ntriples.size} triples from file in #{Time.now - time}s")
		ntriples.size
	end

	def query(query)
		# log received query
		log "received query: #{query}"

		# construct query clauses
		sql = construct_select(query) + construct_join(query) + construct_where(query)

		# log constructed query
		log "executing query: #{sql} with #{@right_hand_sides.join(',')}"

		# executing query, passing all where-clause values as parameters (so that 
		# sqlite will encode quotes correctly)
		results = @db.execute(sql, *@right_hand_sides)

		# convert results to ActiveRDF nodes and return them
		wrap(query, results)
	end

	private

	# construct select clause
	def construct_select(query)
		select = []
		where_clauses = query.where_clauses.flatten

		query.select_clauses.each do |term|
			# get string representation of resource/literal
			term = term.to_s

			# find the right select clause for this term: look up the first occurence 
			# of this term in the where clauses, and compute the level and s/p/o 
			# position of it
			index = where_clauses.index(term)
			termtable = "t#{index / 3}"
			termspo = SPO[index % 3]
			select << "#{termtable}.#{termspo}"
		end

		select_clause = ''
		select_clause << 'distinct ' if query.distinct?
		select_clause << select.join(', ')
		select_clause = "count(#{select_clause})" if query.count?

		"select " + select_clause
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
		considering = where_clauses.uniq

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
				# get string representation of resource/literal
				subclause = subclause.to_s

				# dont add where clause for variables
				unless subclause[0..0] == '?'
					where << "t#{level}.#{SPO[i]} = ?"
					@right_hand_sides << subclause
				end
			end
		end
		if where.empty?
			''
		else
			"where " + where.join(' and ')
		end
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
					result
				end
			end
		end
	end

	Resource = /<([^>]*)>/
	Literal = /"([^"]*)"/
	Node = Regexp.union(/<[^>]*>/,/"[^"]*"/)
	SPO = ['s','p','o']

	def log(s)
		puts "#{Time.now}: #{s}"
	end
end
