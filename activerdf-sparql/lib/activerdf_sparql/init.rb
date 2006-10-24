# add the directory in which this file is located to the ruby loadpath
file =
if File.symlink?(__FILE__)
  File.readlink(__FILE__)
else
  __FILE__
end
$: << File.dirname(File.expand_path(file))

require 'sparql'
