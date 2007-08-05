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

  

end
