#class String
#  alias _match match
#  def match(*args)
#    m = _match(args.first)
#    if m && m.length > 1
#      args[1..-1].each_with_index do |name, index|
#        m.instance_eval "def #{name}; self[#{index+1}] end"
#      end
#    end
#    m
#  end
#end

class FetchingAdapter < RDFLite
  ConnectionPool.register_adapter(:fetching,self)

	# fetches RDF/XML data from given url and adds it to the datastore, using the 
	# source url as context identifier.
  def fetch url
		return unless url.match(/http:\/\/(.*)/)

		# remove fragment identifier from url
		hashidx = url.rindex('#')
		url = url[0..url.rindex('#')-1] unless hashidx.nil?

		$activerdflog.debug "fetching from #{url}"

		#model = Redland::Model.new
		#parser = Redland::Parser.new('rdfxml')
		#scan = Redland::Uri.new('http://feature.librdf.org/raptor-scanForRDF')
		#enable = Redland::Literal.new('1')
		#Redland::librdf_parser_set_feature(parser, scan.uri, enable.node)
		#parser.parse_into_model(model, url)
		#triples = Redland::Serializer.ntriples.model_to_string(nil, model)

		triples = `rapper --scan "#{url}"`
		lines = triples.split($/)
		$activerdflog.debug "found #{lines.size} triples"

		context = RDFS::Resource.new(url)
		add_ntriples(triples, context)
  end
end
