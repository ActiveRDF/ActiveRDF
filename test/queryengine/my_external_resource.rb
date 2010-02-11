module RDFS
  # External resource class
  class MyExternalResource
    
    include ActiveRDF::ResourceLike
    
    # uri of the resource
    attr_reader :uri
    # adding accessor to the class uri:
    # the uri of the rdf resource being represented by this class
    class << self
      attr_accessor :class_uri
    end
    
    # creates new resource representing an RDF resource
    def initialize uri
      @uri = uri
    end
    
    def to_literal_s
      @uri
    end
    
    def to_s
      "<#{uri}>"
    end
  end
end
