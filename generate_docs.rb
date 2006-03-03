#!/usr/bin/ruby

# = x_generate_doc.rb - Generate development documentation
#
# Project	: ActiveRDF
#
# Author 	: Renaud Delbru
#
# Mail 		: mailto:renaud.delbru@deri.org

result = `find . -name "*.rb" | rdoc1.8 -SN -c utf-8`

if $? != 0
  exit($?)
else
  puts result.chomp
  puts "Development documentation generated"
  exit(0)
end
