require 'active_rdf/queryengine/query'
require 'active_rdf/objectmanager/resource'

class OrderedSet
    
  # the uri of current resource
  attr_reader :uri
    
  # Initialize SeqContainer
  def initialize(uri)
    @uri = RDF::Seq.new uri
  end
  
  # get all elements of Resource that match with 'rdf:_'
  # 
  # return value: Array
  def elements
    # execute query
    query.collect { |predicate, object| object }
  end
  
  # get element at position index
  # *index: int
  #
  # return value: RDFS::Resource
  def at(index)
    # get predicate for next item
    predicate =  index_to_predicate(index)
    
    # execute query
    result = Query.new.select(:o).where(self.uri, predicate, :o).execute
    
    if (!(result.nil?) and (result.size > 0))
      result.first
    else
      nil
    end
  end
      
  # return size of elements
  #
  # return value: int
  def size
    result = query
    
    if result.empty?
      return 0
    else
      index = predicate_to_index result.last[0]
      return index.to_i
    end
  end
    
  # add a new object
  # * object: RDFS::Resource
  def add(object)
    # get predicate for next item
    predicate =  index_to_predicate(size + 1)
      
    # add item
    FederationManager.add(self.uri, predicate , object)
  end
    
  # remove an existing object
  # * index: int
  def delete(index)
    # get predicate to delete
    predicate = index_to_predicate(index)
    
    # delete item
    FederationManager.delete(self.uri, predicate, nil)
  end
    
  # remove all copy of object to OrderedSet
  def delete_all()
    # call delete method
    (1..size).each do |index|
      self.delete(index)
    end
  end
    
  # replace item
  # * index: int
  # * object: RDFS::Resource
  def replace(index, object)
    # delete item
    self.delete(index)
      
    # get predicate for index
    predicate =  index_to_predicate(index)
      
    # add item
    FederationManager.add(self.uri, predicate , object)
  end
    
  private
  # execute query and return the result
  def query
    # execute query
    result = Query.new.select(:p, :o).where(self.uri, :p, :o).regex(:p, "^#{(RDF::_).uri}").execute
    
    # order result
    result = result.sort_by { |items| items[0] }
  end

  # return predicate from index
  def index_to_predicate(index)
    RDFS::Resource.new(RDF::_.uri + "#{index}")
  end
  
  # return index of the predicate
  def predicate_to_index(predicate)
    predicate.uri.sub(RDF::_.uri, '')
  end
end
