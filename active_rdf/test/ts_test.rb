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
      when /(.*)/ # else
        require path #if $run_tests.any? {|test| $1 =~ /.*#{test}.*/ }
      end
		end
  end
end
