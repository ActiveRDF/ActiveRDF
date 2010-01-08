module RDFS
  class BNode < Resource
    def to_s
      "<_:#{uri}>"
    end
  end
end