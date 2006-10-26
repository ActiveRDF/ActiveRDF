def get_adapter
	types = ConnectionPool.adapter_types
	if types.include?(:rdflite)
		ConnectionPool.add :type => :rdflite
	elsif types.include?(:redland)
		ConnectionPool.add :type => :redland
	elsif types.include?(:sparql)
		ConnectionPool.add :type => :sparql
	elsif types.include?(:yars)
		ConnectionPool.add :type => :yars
	elsif types.include?(:jars2)
		ConnectionPool.add :type => :jars2
	else
		raise ActiveRdfError, "no suitable adapter found for test"
	end
end

def get_all_read_adapters
	types = ConnectionPool.adapter_types
	adapters = types.collect {|type| ConnectionPool.add :type => type }
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
