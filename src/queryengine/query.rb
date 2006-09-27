# represent a query on a datasource, abstract representation of SPARQL features
# is passed to federation/adapter for execution on data
require 'federation/federation_manager'
class Query	
	attr_reader :select_clauses, :where_clauses
	def initialize
		@select_clauses = []
		@where_clauses = []
	end
	
	def select *s
		s.each do |e|
			@select_clauses << parametrise(e)
		end
		self
	end
	
	def where s,p,o
		@where_clauses << [s,p,o].collect{|arg| parametrise(arg)}
		self
	end	
	
	# execute query on data sources
	# either returns result as array 
	# (flattened into single value unless specified otherwise) 
	# or executes a block (number of block variables should be 
	# same as number of select variables)
	# 
	# usage: results = query.execute
	# usage: query.execute do |s,p,o| ... end
	def execute(options={:flatten => true}, &block)
		if block_given?
			FederationManager.instance.query(self) do |*clauses|
				block.call(*clauses)
			end
		else
			FederationManager.instance.query(self, options)
		end
	end
	
	private
	def parametrise s		
		case s
		when Symbol
			'?' + s.to_s
		when RDFS::Resource
		  s
		else
			'"' + s.to_s + '"'
		end
	end
end