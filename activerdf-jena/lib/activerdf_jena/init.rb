#
# Author:  Karsten Huneycutt
# Copyright 2007 Valkeir Corporation
# License:  LGPL
#
# add the directory in which this file is located to the ruby loadpath
file =
if File.symlink?(__FILE__)
  File.readlink(__FILE__)
else
  __FILE__
end
$: << File.dirname(File.expand_path(file))

java_dir = File.expand_path(File.join(File.dirname(File.expand_path(file)), "..", "..", "ext"))

Dir.foreach(java_dir) do |jar|
  $CLASSPATH << File.join(java_dir, jar) if jar =~ /.jar$/
end

require 'jena'
require 'ng4j'
require 'pellet'
require 'lucene'
require 'jena_adapter'
require 'ng4j_adapter'
