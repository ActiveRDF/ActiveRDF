DB = :yars
DB_HOST = 'browserdf.org'

require 'find'
Find.find(File.dirname(__FILE__)) do |path|
  if FileTest.directory?(path)
    if File.basename(path)[0] == ?.
      # found '.' directory: stop looking into this directory
      Find.prune       
    else
      next
    end
  else
    require path if path =~ /test_.*\.rb$/
  end
end