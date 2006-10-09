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

	def clear
		@db.execute('delete from triple')
	end

	def load(file)
		ntriples = File.readlines(file)
		ntriples.each do |triple|
			nodes = triple.scan(Node)
			@db.execute('insert into triple values (?,?,?)',nodes[0], nodes[1], nodes[2])
		end
		ntriples.size
	end

	def query(query)
		where_clauses = query.where_clauses.size
		sql = ""
		spo = ['s','p','o']
		where_clauses = query.where_clauses.flatten

		# construct select clause
		select = []
		query.select_clauses.each do |term|
			# get string representation of resource/literal
			term = term.to_s

			# find the right select clause for this term: look up the first occurence 
			# of this term in the where clauses, and compute the level and s/p/o 
			# position of it
			index = where_clauses.index(term)
			termtable = "t#{index / 3}"
			termspo = spo[index % 3]
			select << "#{termtable}.#{termspo}"
		end

		select_clause = ''
		select_clause << 'distinct ' if query.distinct?
		select_clause << select.join(', ')
		select_clause = "count(#{select_clause})" if query.count?
		sql << "select #{select_clause}\n"

		# construct join clause
		joins = []
		where_clauses.each_with_index do |term, index|
			# get string representation of resource/literal
			term = term.to_s

			# if term is a variable
			if term[0..0] == '?'
				# look for buddy: another occurence of same variable
				buddy = where_clauses[index+1..-1].index(term)

				# if buddy was found, add join clause, e.g.
				# from triples as t1 join triples at t3 on t1.s = t3.s
				# index / 3 gives the level of index (e.g. 1 or 3)
				# index % 3 indicates s/p/o: 0-2

				unless buddy.nil?
					# buddy's real position in the clauses array is found index plus 
					# (index+1) since we only search in the slice starting after the 
					# current term (which is index+1).
					buddy += index+1

					termtable = "t#{index / 3}"
					buddytable = "t#{buddy / 3}"
					termspo = spo[index % 3]
					buddyspo = spo[index % 3]

					joins << "triple as #{termtable} join triple as #{buddytable} on #{termtable}.#{termspo} = #{buddytable}.#{buddyspo}\n"
				end
			end
		end
		if joins.empty?
			sql << "from triple as t0\n"
		else
			sql << "from #{joins.join(' and ')}"
		end

		# collecting where clauses, these will be added to the sql string later
		where = []

		# collecting all the right-hand sides of where clauses (e.g. where name = 
		# 'abc'), to add to query string later using ?-notation, because then 
		# sqlite will automatically encode quoted literals correctly
		clauses = []

		# convert each where clause to SQL:
		# add where clause for each subclause, except if it's a variable
		query.where_clauses.each_with_index do |clause,level|
			clause.each_with_index do |subclause, i|
				# get string representation of resource/literal
				subclause = subclause.to_s

				# dont add where clause for variables
				unless subclause[0..0] == '?'
					where << "t#{level}.#{spo[i]} = ?"
					clauses << subclause
				end
			end
		end
		sql << "where #{where.join(' and ')}\n" unless where.empty?

		log "executing query \n#{sql}"
		# executing query, passing all where-clause values as parameters (so that 
		# sqlite will encode quotes correctly)
		results = @db.execute(sql, *clauses)
		wrap(query, results)
	end

	private
	def log(s)
		 #puts "#{Time.now}: #{s}"
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
	Node = Regexp.union(Resource,Literal)
end
