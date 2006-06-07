require 'active_rdf'
DB = :redland

def setup_connection
	case DB
	when :redland
		NodeFactory.connection :adapter => :redland, :location => :memory, :cache_server => :memory, :construct_class_model => false
	end
end

#DB = :yars
#DB_HOST = 'browserdf.org'
#TestContext = 'test'
