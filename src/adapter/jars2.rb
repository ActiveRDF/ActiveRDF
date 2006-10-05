# read-only adapter to jars2
# (experimental YARS branch for SWSE engine)
# TODO: add unit test
require 'active_rdf'
require 'queryengine/query2jars2'
require 'net/http'
require 'cgi'

class Jars2Adapter
	ConnectionPool.register_adapter(:jars2, self)

	def initialize(params = {})
		@host = params[:host] || 'm3pe.org'
		@port = params[:port] || 2020
		@yars = Net::HTTP.new(@host, @port)
	end

	def reads?; true; end
	def writes?; false; end

	def query(query)
		qs = Query2Jars2.translate(query)
		header = { 'Accept' => 'application/rdf+n3' }

		# querying Jars2, adding 'eyal' parameter to get all variable bindings in 
		# the result
		response = @yars.get("/?q=#{CGI.escape(qs)}&eyal", header)

		# return empty array if no content
		return [] if response.is_a?(Net::HTTPNoContent)

		# return false unless HTTP OK returned
		return false unless response.is_a?(Net::HTTPOK)

		# parse the result
		results = parse_result(response.body, query)

		# remove duplicates if asked for distinct results
		if query.distinct?
			results.uniq
		else
			results
		end
	end

	private
	Resource = /<[^>]*>/
	Literal = /"[^"]*"/
	Node = Regexp.union(Resource,Literal)

	# parses Jars2 results into array of ActiveRDF objects
	def parse_result(response, query)
		# Jars2 responses contain one result per line
		results = response.split("\n")

		# the first line of the response contains the variable bindings of the 
		# results: we look at that line to figure out which column contains the 
		# data we are looking for (which is the variables mentioned in the select 
		# clauses of the query
		bindings = results[0].split(' ')

		# array of found answers, will be filled by iterating over the results and 
		# only including the requested (i.e. selected) clauses
		answers = []

		# we iterate over the real results, and extract the clauses that we're 
		# looking for (i.e. the select clauses from the query)
		results[1..-1].each do |result|

			# scan row for occurence of nodes (either resources or literals)
			row = result.scan(Node)

			# for each select clause, we find its index, and add the value at that 
			# location in the result row to our answer
			row = query.select_clauses.collect do |clause|
				clause_index = bindings.index(clause)
				convert_into_activerdf(row[clause_index])
			end
			answers << row
		end

		answers
	end

	# converts ntriples serialisation of resource or literal into ActiveRDF object
	def convert_into_activerdf(string)
		case string
		when /<(.*)>/
			# <http://foaf/Person> is a resource
			RDFS::Resource.new($1)
		when /"(.*)"/
			# "30" is a literal
			# TODO: handle datatypes
			String.new($1)
		end
	end

end
