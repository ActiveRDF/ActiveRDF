#
# Author:  Karsten Huneycutt
# Copyright 2007 Valkeir Corporation
# License:  LGPL
#
module LuceneARQ

  class << self
    bool_accessor :lucene_available
  end

  begin 
    include_class('com.hp.hpl.jena.query.larq.LARQ')
    include_package('com.hp.hpl.jena.query.larq')
    self.lucene_available = true
  rescue
    self.lucene_available = false
  end

end
