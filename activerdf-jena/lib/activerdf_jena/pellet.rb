#
# Author:  Karsten Huneycutt
# Copyright 2007 Valkeir Corporation
# License:  LGPL
#
module Pellet

  class << self
    bool_accessor :pellet_available
    attr_accessor :reasoner_factory
  end

  begin
    include_class('org.mindswap.pellet.jena.PelletReasonerFactory')
    self.pellet_available = true
    self.reasoner_factory = PelletReasonerFactory.theInstance
  rescue
    self.pellet_available = false
  end

  module Query
    include_package('org.mindswap.pellet.query.jena')
  end

end
