module ActiveRDF
  Namespace.register(:bnode, "http://www.activerdf.org/bnode#")

  class BNode < RDFS::Resource
    def to_s
      "<_:#{uri}>"
    end

    self.class_uri = RDFS::Resource.new("http://www.activerdf.org/bnode")
  end
end