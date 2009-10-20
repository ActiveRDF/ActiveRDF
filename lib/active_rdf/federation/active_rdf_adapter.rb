require 'active_rdf'
require 'queryengine/query2sparql'

# Generic superclass of all adapters
module ActiveRDF
  class ActiveRdfAdapter
    # indicate if adapter can read and write
    bool_accessor :reads, :writes, :contexts, :enabled

    def initialize(params = {})
                                             # defaults
      @enabled =                               true
      @reads =                                 true
      @writes =      truefalse(params[:write], true)
      @new =           truefalse(params[:new], false)
      @contexts = truefalse(params[:contexts], false)
    end

    # translate a query to its string representation
    def translate(query)
       Query2SPARQL.translate(query)
    end
  end
end