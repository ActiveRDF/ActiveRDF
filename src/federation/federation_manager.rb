# manages the federation of datasources
# distributes queries to right datasources and merges their results
require 'set'
require 'federation/connection_pool'
class FederationManager
	include Singleton
	
	def initialize
		@@pool = ConnectionPool.instance
	end
		
	# executes read-only queries
	# by distributing query over complete read-pool
	# and aggregating the results
	def query(q, options={:flatten => true})
		# TODO: manage update queries
		
		# ask each adapter for query results
		# and yield them consequtively
		if block_given? 
			@@pool.read_adapters.each do |source| 
				source.query(q) do |*clauses|
					yield(*clauses)
				end
			end
		else
			# build Array of results from all sources
			results = @@pool.read_adapters.collect { |source| source.query(q) }

			# filter the empty results
			results.reject {|ary| ary.empty? }
			
			# give the union of results
			union = []
			results.each { |res| union |= res }
			
			# flatten results array if only one select clause
			# to prevent unnecessarily nested array [[eyal],[renaud],...]
			union.flatten! if q.select_clauses.size == 1
			
			# and remove array (return single value) unless asked not to 
			if options[:flatten]
  			case union.size
  			when 0
  			 nil
  			when 1
  			 union.first
  			else
  			 union			
  			end
  		else
  		  union
  		end
  		
		end
	end
end