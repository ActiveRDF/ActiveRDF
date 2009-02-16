# Author:: Benjamin Heitmann
# Copyright:: (c) 2007 DERI
# License:: LGPL

require 'java'

module NG4J

  module Internal
    include_package('de.fuberlin.wiwiss.ng4j')
    # This contains: NamedGraphSet, Quad
  end

  module DB

    include_package('de.fuberlin.wiwiss.ng4j.db')

    include_class('java.sql.DriverManager')

    # this maps downcased Jena database types into drivers
    DRIVER_MAP = {
      'mysql' => 'com.mysql.jdbc.Driver',
      'postgresql' => 'org.postgresql.Driver',
      'hsql' => 'org.hsqldb.jdbcDriver',
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

  module Sparql
    include_package('de.fuberlin.wiwiss.ng4j.sparql')
    # This contains: NamedGraphDataset
  end

  module Impl
    include_package('de.fuberlin.wiwiss.ng4j.impl')
    # This contains: NamedGraphSetImpl
  end

end
