require 'active_rdf'
nf = NodeFactory.connection(:adapter => :jena, :location => "data.n3")

class Person < IdentifiedResource
  set_class_uri 'http://xmlns.com/foaf/0.1/Person' # BUG? Should be foaf namespace only
end

eyal = Person.create 'http://eyaloren.org/#me'
eyal.firstName = 'eyal'
eyal.lastName = 'oren'

eyal.save # BUG? Does nothing

armin = Person.create 'http://armin-haller.com/#me'
armin.firstName = 'armin'
armin.age = 30

p eyal.firstName

foo = Person.create 'http://example.com/#me'
foo.firstName = 'eyal'
foo.lastName = 'foo'

p Person.find

p Person.find_by_firstName('eyal')

eyal.delete

p Person.find_by_firstName('eyal')
