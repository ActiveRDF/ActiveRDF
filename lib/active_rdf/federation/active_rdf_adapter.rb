require 'active_rdf/queryengine/query2sparql'

# Generic superclass of all adapters
module ActiveRDF
  class ActiveRdfAdapter
    # indicate if adapter can read and write
    bool_accessor :enabled, :reads, :writes, :new, :contexts, :enabled

    # The following options are accepted
    #  :write => true | false       # adapter supports writing. default true
    #  :new => true | false         # create new dataset. default false
    #  :contexts =>  true | false   # adapter supports contexts. default false
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

    # Clear the adapter. Crude default implementation, which can be overwritten
    # in subclasses. TODO: This queries all adapters, this may lead to problems...
    def clear
      raise(ActiveRdfError, "Can only delete from writing adapters") unless(writes?)
      to_delete = Query.new.select(:s, :p, :o).where(:s, :p, :o).execute
      to_delete.each do |s, p, o|
        delete(s, p, o)
      end
    end
  end
end