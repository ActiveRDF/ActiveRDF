require 'active_rdf'
require 'queryengine/query2sparql'

# Generic superclass of all adapters

class ActiveRdfAdapter
  # indicate if adapter can read and write
  bool_accessor :reads, :writes
  
  # Indicate if the adapter supports contexts
  def supports_context?
    self.class.supports_context?
  end

  # translate a query to its string representation
  def translate(query)
    Query2SPARQL.translate(query)
  end

  # Indicates if this adapter class supports contexts  
  def self.supports_context?
    @context_supported = false if(@context_supported == nil)
    @context_supported
  end
  
  private
  
  # Method to set the "context_supported" flag
  def self.supports_context
    @context_supported = true
  end
  
end
