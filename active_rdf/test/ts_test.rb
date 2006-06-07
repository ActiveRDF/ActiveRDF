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
				if $adapters.include?(:yars)
					p "running YARS tests"
					require path 
				end
      when /.*redland.*/
				if $adapters.include?(:redland)
					p "running Redland tests"
					require path 
				end
      when /(.*)/ # else
        if $run_tests.any? {|test| $1 =~ /.*#{test}.*/ }
          require path
          p "running #{path}"
        end
      end
		end
  end
end
