# require 'active_rdf'
require 'queryengine/query2sparql'

# Generic superclass of all adapters

class ActiveRdfAdapter
	# indicate if adapter can read and write
	bool_accessor :reads, :writes, :contexts, :enabled

  def initialize
    @enabled = true
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
