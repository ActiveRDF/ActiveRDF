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
