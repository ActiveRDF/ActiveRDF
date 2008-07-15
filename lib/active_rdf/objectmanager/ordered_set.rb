require 'active_rdf'
require 'queryengine/query'
require 'objectmanager/resource'

class OrderedSet
    
  # the uri of current resource
  attr_reader :uri
    
  # Initialize TaliaSeqContainer
  def initialize(uri)
    @uri = RDF::Seq.new uri
  end
  
  # get all elements of Resource that match with 'rdf:_'
  # return value is an Array object that start from 1
  def elements
    # execute query
    query.collect { |predicate, object| object }
  end
      
  # return size of elements
  def size
    result = query
    
    if result.empty?
      return 0
    else
      index = property_to_index result.last[0]
      return index.to_i
    end
  end
    
  # add a new object to OrderedSet
  def add(object)
    # get property for next item
    property =  index_to_property(size + 1)
      
    # add item
    FederationManager.add(self.uri, property , object)
  end
    
  # remove an existing object to OrderedSet
  def delete(index)
    # get property to delete
    property = index_to_property(index)
    
    # delete item
    FederationManager.delete(self.uri, property, nil)
  end
    
  # remove all copy of object to OrderedSet
  def delete_all()
    # call delete method
    (1..size).each do |index|
      self.delete(index)
    end
  end
    
  # replace item
  def replace(index, object)
    # delete item
    self.delete(index)
      
    # get property for index
    property =  index_to_property(index)
      
    # add item
    FederationManager.add(self.uri, property , object)
  end
    
  private
  # execute query and return the result
  def query
    # execute query
    result = Query.new.select(:p, :o).where(self.uri, :p, :o).filter('regex(str(?p), "^' + (RDF::_).uri + '")').execute
    
    # order result
    result = result.sort_by { |items| items[0] }
  end

  # return property from index
  def index_to_property(index)
    RDFS::Resource.new(RDF::_.uri + "#{index}")
  end
  
  def property_to_index(property)
    property.uri.sub(RDF::_.uri, '')
  end
end
