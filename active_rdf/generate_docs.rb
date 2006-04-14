#!/usr/bin/ruby

# = x_generate_doc.rb - Generate development documentation
#
# Project	: ActiveRDF
#
# Author 	: Renaud Delbru
#
# Mail 		: mailto:renaud.delbru@deri.org

rdoc_options = "-SN -c utf-8 -x test -x exceptions -x generate_docs"

result = `rdoc1.8 #{rdoc_options}`

if $? != 0
  exit($?)
else
  puts result.chomp
  puts "Development documentation generated"
  exit(0)
end
