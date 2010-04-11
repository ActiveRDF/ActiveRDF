module SetupAdapter
  ActiveRDF::Namespace.register(:test, 'http://activerdf.org/test/')

  def setup(adapter_args = nil)
    @adapter_args = adapter_args || {}
    ActiveRDF::ConnectionPool.clear
    @adapter = adapter_args ? ActiveRDF::ConnectionPool.add(adapter_args) : get_default_primary_adapter
  end

  def teardown
    ActiveRDF::ConnectionPool.close(@adapter)
  end
end

def get_default_primary_adapter
#### Fetching default
#  ActiveRDF::ConnectionPool.add(:type => :fetching)
#### Suggesting default
#  ActiveRDF::ConnectionPool.add(:type => :suggesting)
#### Rdflite default
  ActiveRDF::ConnectionPool.add(:type => :rdflite, :contexts => 'yes')
# ActiveRDF::ConnectionPool.add(:type => :sparql)
#### Redland default
#  ActiveRDF::ConnectionPool.add(:type => :redland, :contexts => 'no')
#### Redland file
#  ActiveRDF::ConnectionPool.add(:type => :redland, :name => 'db1', :location => '/path/to/file')
#### Redland memory
#  ActiveRDF::ConnectionPool.add(:type => :redland, :name => 'db1', :location => 'memory')
#### Redland sqlite
#  ActiveRDF::onnectionPool.add(:type => :redland, :name => 'db1', :location => 'sqlite', :new => 'yes')
#### Redland MySql
#  ActiveRDF::ConnectionPool.add(:type => :redland, :name => 'db1', :location => 'mysql',
#                                :host => 'localhost', :database => 'redland_test',
#                                :user => '', :password => '', :new => 'yes', :contexts => 'no')
#### Redland Postgresql
#  ActiveRDF::ConnectionPool.add(:type => :redland, :name => 'db1', :location => 'postgresql',
#                                :host => 'localhost', :database => 'redland_test',
#                                :user => '', :password => '', :new => 'yes')
#### Redland Yars
#  ActiveRDF::ConnectionPool.add(:type => :yars)
#### Redland Jars2
#  ActiveRDF::ConnectionPool.add(:type => :jars2)
end

def get_default_secondary_adapter
#### Fetching default
#  ActiveRDF::ConnectionPool.add(:type => :fetching)
#### Suggesting default
#  ActiveRDF::ConnectionPool.add(:type => :suggesting)
#### Rdflite default
  ActiveRDF::ConnectionPool.add(:type => :rdflite)
#### Redland default
#  ActiveRDF::ConnectionPool.add(:type => :redland)
#### Redland file
#  ActiveRDF::ConnectionPool.add(:type => :redland, :name => 'db2', :location => '/path/to/file')
#### Redland memory
#  ActiveRDF::ConnectionPool.add(:type => :redland, :name => 'db2', :location => 'memory')
#### Redland sqlite
#  ActiveRDF::ConnectionPool.add(:type => :redland, :name => 'db2', :location => 'sqlite', :new => 'yes')
#### Redland MySql
#  ActiveRDF::ConnectionPool.add(:type => :redland, :name => 'db2', :location => 'mysql',
#                                :host => 'localhost', :database => 'redland_test',
#                                :user => '', :password => '', :new => 'yes')
#### Redland Postgresql
#  ActiveRDF::ConnectionPool.add(:type => :redland, :name => 'db2', :location => 'postgresql',
#                                :host => 'localhost', :database => 'redland_test',
#                                :user => '', :password => '', :new => 'yes')
#### Redland Yars
#  ActiveRDF::ConnectionPool.add(:type => :yars)
#### Redland Jars2
#  ActiveRDF::ConnectionPool.add(:type => :jars2)
end

def get_default_read_only_adapter
  if ActiveRDF::ConnectionPool.adapter_types.include?(:sparql)
    get_sparql
  else
    raise ActiveRDF::ActiveRdfError, "no suitable read-only adapter found for test"
  end
end

def get_default_primary_write_adapter
  adapter = get_default_primary_adapter
  raise "No writable adapter" unless adapter.writes?
  adapter
end

def get_default_secondary_write_adapter
  adapter = get_default_secondary_adapter
  raise "No writable adapter" unless adapter.writes?
  adapter
end

private
def get_sparql
  ActiveRDF::ConnectionPool.add(:type => :sparql, :url => "http://sparql.org/books",
                                :engine => :joseki, :results => :sparql_xml)
end

