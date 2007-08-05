#$: << "/Users/kph/unc/projects/activerdf_jena/lib" 
require 'rubygems'
require 'active_rdf'
#require 'activerdf_jena'
p Jena::Model
p Pellet.pellet_available?
p Pellet.reasoner_factory
p LuceneARQ.lucene_available?
adapter = ConnectionPool.add_data_source(:type => :jena, :ontology => :owl, :reasoner => :pellet, :lucene => true)
adapter.load('file:///Volumes/kph/skuld/organisms.owl')
adapter.load('file:///Volumes/kph/skuld/categories.owl')
puts adapter.dump
p ObjectManager.construct_classes
