require 'active_rdf'
include ActiveRDF

module SetupAdapter
  Namespace.register(:test, 'http://activerdf.org/test/')

  def setup(adapter_args = nil)
    @adapter_args = adapter_args || {}
    ConnectionPool.clear
    @adapter = adapter_args ? ConnectionPool.add(adapter_args) : get_primary_adapter
  end

  def teardown
    ConnectionPool.close(@adapter)
  end
end

def get_primary_adapter
#### Fetching default
#  ConnectionPool.add(:type => :fetching)
#### Suggesting default
#  ConnectionPool.add(:type => :suggesting)
#### Rdflite default
  ConnectionPool.add(:type => :rdflite, :contexts => 'yes')
#### Redland default
#  ConnectionPool.add(:type => :redland, :contexts => 'no')
#### Redland file
#  ConnectionPool.add(:type => :redland, :name => 'db1', :location => '/path/to/file')
#### Redland memory
#  ConnectionPool.add(:type => :redland, :name => 'db1', :location => 'memory')
#### Redland sqlite
#  ConnectionPool.add(:type => :redland, :name => 'db1', :location => 'sqlite', :new => 'yes')
#### Redland MySql
#  ConnectionPool.add(:type => :redland, :name => 'db1', :location => 'mysql',
#                                :host => 'localhost', :database => 'redland_test',
#                                :user => '', :password => '', :new => 'yes', :contexts => 'no')
#### Redland Postgresql
#  ConnectionPool.add(:type => :redland, :name => 'db1', :location => 'postgresql',
#                                :host => 'localhost', :database => 'redland_test',
#                                :user => '', :password => '', :new => 'yes')
#### Redland Yars
#  ConnectionPool.add(:type => :yars)
#### Redland Jars2
#  ConnectionPool.add(:type => :jars2)
end

def get_secondary_adapter
#### Fetching default
#  ConnectionPool.add(:type => :fetching)
#### Suggesting default
#  ConnectionPool.add(:type => :suggesting)
#### Rdflite default
#  ConnectionPool.add(:type => :rdflite)
#### Redland default
#  ConnectionPool.add(:type => :redland)
#### Redland file
#  ConnectionPool.add(:type => :redland, :name => 'db2', :location => '/path/to/file')
#### Redland memory
#  ConnectionPool.add(:type => :redland, :name => 'db2', :location => 'memory')
#### Redland sqlite
  ConnectionPool.add(:type => :redland, :name => 'db2', :location => 'sqlite', :new => 'yes')
#### Redland MySql
#  ConnectionPool.add(:type => :redland, :name => 'db2', :location => 'mysql',
#                                :host => 'localhost', :database => 'redland_test',
#                                :user => '', :password => '', :new => 'yes')
#### Redland Postgresql
#  ConnectionPool.add(:type => :redland, :name => 'db2', :location => 'postgresql',
#                                :host => 'localhost', :database => 'redland_test',
#                                :user => '', :password => '', :new => 'yes')
#### Redland Yars
#  ConnectionPool.add(:type => :yars)
#### Redland Jars2
#  ConnectionPool.add(:type => :jars2)
end

def get_read_only_adapter
  if ConnectionPool.adapter_types.include?(:sparql)
    get_sparql
  else
    raise ActiveRdfError, "no suitable read-only adapter found for test"
  end
end

def get_primary_write_adapter
  adapter = get_primary_adapter
  raise "No writable adapter" unless adapter.writes?
  adapter
end

def get_secondary_write_adapter
  adapter = get_secondary_adapter
  raise "No writable adapter" unless adapter.writes?
  adapter
end

private
def get_sparql
  ConnectionPool.add(:type => :sparql, :url => "http://sparql.org/books",
                                :engine => :joseki, :results => :sparql_xml)
end

