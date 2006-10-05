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
		response = @yars.get("/?q=#{CGI.escape(qs)}", header)

		# return empty array if no content
		return [] if response.is_a?(Net::HTTPNoContent)

		# return false unless HTTP OK returned
		return false unless response.is_a?(Net::HTTPOK)

		response.body.split("\n")

		#results = parse_result(respons.body)
		#results = extract_selected_clauses(results)
		#return results.uniq if query.distinct?
	end
end
