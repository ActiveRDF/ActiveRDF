# Author:: Eyal Oren
# Copyright:: (c) 2005-2006 Eyal Oren
# License:: LGPL

# FetchingAdapter is an extension to rdflite for fetching RDF from online sources.
module ActiveRDF
  class FetchingAdapter < RDFLite
    ConnectionPool.register_adapter(:fetching, self)

    # TODO: check that rapper is installed

    # fetches RDF/XML data from given url and adds it to the datastore, using the
    # source url as context identifier.
    def fetch(url, syntax = nil)
      # check if url starts with http://
      return unless url.match(/http:\/\/(.*)/)

      $activerdflog.debug "fetching from #{url}"

      #model = Redland::Model.new
      #parser = Redland::Parser.new('rdfxml')
      #scan = Redland::Uri.new('http://feature.librdf.org/raptor-scanForRDF')
      #enable = Redland::Literal.new('1')
      #Redland::librdf_parser_set_feature(parser, scan.uri, enable.node)
      #parser.parse_into_model(model, url)
      #triples = Redland::Serializer.ntriples.model_to_string(nil, model)

      opts = syntax ? "-i #{syntax}" : "--scan"
      triples = `rapper #{opts} --quiet "#{url}"`
      lines = triples.split($/)
      $activerdflog.debug "found #{lines.size} triples"

      context = RDFS::Resource.new(url)
      add_ntriples(triples, context)
    end
    alias :load :fetch
  end
end