class FetchingAdapter < RDFLite
  ConnectionPool.register_adapter(:fetching,self)

  def fetch url
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

