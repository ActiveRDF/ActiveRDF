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

		#TODO: waiting for an answer on how to enable --scan over ruby api
		#model = Redland::Model.new
		#parser = Redland::Parser.new('rdfxml')
		#parser.parse_into_model(model, url)
		#triples = Redland.librdf_model_to_string(model.model, nil, 'ntriples', '', nil)

		#TODO: using rapper cmdline in the meantime
		triples = `rapper --quiet --scan "#{url}"`

		lines = triples.split($/)
		$activerdflog.debug "found #{lines.size} triples"

		context = RDFS::Resource.new(url)
		add_ntriples(triples, context)
  end
end
