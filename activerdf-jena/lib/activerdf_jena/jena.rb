#
# Author:  Karsten Huneycutt
# Copyright 2007 Valkeir Corporation
# License:  LGPL
#
require 'java'

module Jena

  module Ontology
    include_package('com.hp.hpl.jena.ontology')
  end

  module Model
    include_package('com.hp.hpl.jena.rdf.model')
  end

  module DB
    include_package('com.hp.hpl.jena.db')
  end

  module Query
    include_package('com.hp.hpl.jena.query')
  end

  module Reasoner
    include_package('com.hp.hpl.jena.reasoner')
  end

  module Datatypes
    include_package('com.hp.hpl.jena.datatypes')
  end

  include_class('com.hp.hpl.jena.graph.Node')

end
