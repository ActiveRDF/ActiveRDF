class BNode < RDFS::Resource
  def to_s
    "_:#{uri}"
  end
end
