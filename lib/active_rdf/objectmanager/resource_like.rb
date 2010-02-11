module ActiveRDF
  
  # Helper Module that contains same additional methods that
  # are expected from classes that want to behave like
  # RDFS::Resource.
  #
  # The module expects that the including class has an uri
  # method or property.
  module ResourceLike
    
    # returns uri of resource, can be overridden in subclasses
    def to_s
      "<#{uri}>"
    end
    
    # overriding sort based on uri
    def <=>(other) 
      uri <=> other.uri
    end
    
    # NTriple representation of element
    def to_literal_s
      "<#{uri}>"
    end
    
  end
  
end