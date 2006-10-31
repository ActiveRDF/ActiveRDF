def get_adapter
	types = ConnectionPool.adapter_types
	if types.include?(:rdflite)
		ConnectionPool.add :type => :rdflite
	elsif types.include?(:redland)
		ConnectionPool.add :type => :redland
	elsif types.include?(:sparql)
		ConnectionPool.add(:type => :sparql, :url => "http://m3pe.org:8080/repositories/test-people", :results => :sparql_xml)
	elsif types.include?(:yars)
		ConnectionPool.add :type => :yars
	elsif types.include?(:jars2)
		ConnectionPool.add :type => :jars2
	else
		raise ActiveRdfError, "no suitable adapter found for test"
	end
end

def get_read_only_adapter
	types = ConnectionPool.adapter_types
  if types.include?(:sparql)
		ConnectionPool.add(:type => :sparql, :url => "http://m3pe.org:8080/repositories/test-people", :results => :sparql_xml)
	else
		raise ActiveRdfError, "no suitable read only adapter found for test"
	end
	
end

# TODO make this work with a list of existing adapters, not only one
def get_different_adapter(existing_adapter)
	types = ConnectionPool.adapter_types
	if types.include?(:rdflite) and existing_adapter.class != RDFLite
		ConnectionPool.add :type => :rdflite
	elsif types.include?(:redland) and existing_adapter.class != RedlandAdapter
		ConnectionPool.add :type => :redland
	elsif types.include?(:sparql) and existing_adapter.class != SparqlAdapter
		ConnectionPool.add(:type => :sparql, :url => "http://m3pe.org:8080/repositories/test-people", :results => :sparql_xml)
	elsif types.include?(:yars) and existing_adapter.class != YarsAdapter
		ConnectionPool.add :type => :yars
	elsif types.include?(:jars2) and existing_adapter.class != Jars2Adapter
		ConnectionPool.add :type => :jars2
	else
		raise ActiveRdfError, "only one adapter on this system, or no suitable adapter found for test"
	end
end

def get_all_read_adapters
	types = ConnectionPool.adapter_types
	adapters = types.collect {|type| 
		if type == :sparql
			ConnectionPool.add(:type => :sparql, :url => "http://m3pe.org:8080/repositories/test-people", :results => :sparql_xml)
		else
			ConnectionPool.add :type => type 
		end
	}
	adapters.select {|adapter| adapter.reads?}
end

def get_all_write_adapters
	types = ConnectionPool.adapter_types
	adapters = types.collect {|type| ConnectionPool.add :type => type }
	adapters.select {|adapter| adapter.writes?}
end

def get_write_adapter
	types = ConnectionPool.adapter_types
	if types.include?(:rdflite)
		ConnectionPool.add :type => :rdflite
	elsif types.include?(:redland)
		ConnectionPool.add :type => :redland
	elsif types.include?(:yars)
		ConnectionPool.add :type => :yars
	elsif types.include?(:jars2)
		ConnectionPool.add :type => :jars2
	else
		raise ActiveRdfError, "no suitable adapter found for test"
	end
end

# TODO use a list of exisiting adapters not only one
def get_different_write_adapter(existing_adapter)
	types = ConnectionPool.adapter_types
	if types.include?(:rdflite) and existing_adapter.class != RDFLite
		ConnectionPool.add :type => :rdflite
	elsif types.include?(:redland) and existing_adapter.class != RedlandAdapter
		ConnectionPool.add :type => :redland
	elsif types.include?(:yars) and existing_adapter.class != YarsAdapter
		ConnectionPool.add :type => :yars
	else
		raise ActiveRdfError, "only one write adapter on this system, or no suitable write adapter found for test"
	end
end
