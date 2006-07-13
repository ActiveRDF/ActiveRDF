require 'rubygems' # bug in interplay between redland/yars/rubygems: we thus load rubygems here, before redland is loaded
require 'active_rdf'
require 'active_rdf/test/common'

require 'find'
Find.find(File.dirname(File.expand_path(__FILE__))) do |path|
  if FileTest.directory?(path)
    if File.basename(path)[0] == ?.
      # found '.' hidden directory, stop directory traversal
      Find.prune       
    else
      next
    end
  else
    if path =~ /test_(.*).rb$/
      case $1
      when /.*yars.*/
        require path if $adapters.include?(:yars)
      when /.*redland.*/
        require path if $adapters.include?(:redland)
      when /.*sparql.*/
				require path if $adapters.include?(:sparql)
      when /.*sesame.*/
				require path if $adapters.include?(:sesame)
      else
        require path
      end
    end
  end
end
