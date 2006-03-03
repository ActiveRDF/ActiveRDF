# = generate_query.rb
# Class managing the generation of Sparql query.
# ----
# Project	: ActiveRDF
#
# See		: http://m3pe.org/activerdf/
#
# Author	: Renaud Delbru, Eyal Oren
#
# Mail		: first dot last at deri dot org
#
# (c) 2005-2006

require 'query_generator/abstract_generator'

class SparqlQueryGenerator < AbstractQueryGenerator

  
#----------------------------------------------#
#               PRIVATE METHODS                #
#----------------------------------------------#

private

  # Create the select clause for the query
  #
  # *Arguments* :
  # * *bindings* : Array of binding variable in the select clause. Binding variable is a Symbol.
  #
  # *Return* :
  # * _String_ Select part of the Sparql query
  def self.select(bindings)
  	select_template = String.new
  	
  	if bindings.empty?
  		select_template << '*'
  	else
	  	bindings.each { |binding|
	  		raise(WrongTypeQueryError, "Symbol expected, #{binding.class} received") if (binding.class != Symbol)
	  		
	  		select_template << "?#{binding.to_s} "
	  	}
	  	select_template << "\n"
	  end
	  return select_template
  end

  # Create the where clause for the query
  #
  # *Arguments* :
  # * *conditions* : Array of ActiveRDF::Resource, Symbol and Standard types.
  #					 ActiveRDF::Resource for resource and predicate,
  #					 Symbol for binding variable
  #					 Standard types for Literal.
  #
  # *Return* :
  # * _String_ Where clause of the Sparql query
  def self.where(conditions)
  	# Init where template
  	where_template = String.new
  	# Init counter
  	nb_conditions = conditions.size
  	i = 0
  	
  	conditions.each do |s, p, o|
  		# Counter incrementation
			i += 1
  		
			subject = convert_subject(s)
			predicate = convert_predicate(p)
			object = convert_object(o)
  		
  		where_template << "\t #{subject} #{predicate} #{object} . \n" if (i != nb_conditions)
  		where_template << "\t #{subject} #{predicate} #{object}" if (i == nb_conditions)
  	end
  	return where_template
  end
  
  def self.order_by(order_opt)
  	return if order_opt.nil?
  	
  	order_template = "ORDER BY"
  	
  	order_opt.each do |binding, order|
  		raise(WrongTypeQueryError, "In #{__FILE__}:#{__LINE__}, unexpected order option received") if (binding.class != Symbol)
  		if order == 1
  			order_template << " DESC(?" << binding.to_s << ")"
  		else
  			order_template << " ?" << binding.to_s
  		end
  	end

  	order_template << "\n"
  	return order_template  	
  end
  
#----------------------------------------------#
#               PUBLIC METHODS                 #
#----------------------------------------------#

public
  
  def self.generate(bindings, conditions, order_opt = nil, keyword_search = nil)

	template_query = <<END_OF_QUERY
SELECT #{select(bindings)}
WHERE {
#{where(conditions)}
}
#{order_by(order_opt)}
END_OF_QUERY
		
	return template_query
		
  end
  
end
