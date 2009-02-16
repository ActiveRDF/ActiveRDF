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

    # this maps downcased Jena database types into drivers
    DRIVER_MAP = {
      'oracle' => 'oracle.jdbc.Driver',
      'mysql' => 'com.mysql.jdbc.Driver',
      'derby' => 'org.apache.derby.jdbc.EmbeddedDriver',
      'postgresql' => 'org.postgresql.Driver',
      'hsql' => 'org.hsqldb.jdbcDriver',
      'mssql' => 'com.microsoft.sqlserver.jdbc.SQLServerDriver'
    }

    DRIVER_MAP.each do |name, driver|
      av = "#{name}_available"
      (class << self ; self ; end).send(:bool_accessor, av.to_sym)
      begin
        java.lang.Class.forName driver
        Jena::DB.send("#{av}=", true)
      rescue
        Jena::DB.send("#{av}=", false)
      end
    end
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

  module Graph
    include_package('com.hp.hpl.jena.graph')
  end

end
