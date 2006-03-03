# = ntriples_generator.rb
#
# Manage the generation of N-Triples query.
#
# == Project
#
# * ActiveRDF
# <http://m3pe.org/activerdf//>
#
# == Authors
# 
# * Eyal Oren <first dot last at deri dot org>
# * Renaud Delbru <first dot last at deri dot org>
#
# == Copyright
#
# (c) 2005-2006 by Eyal Oren and Renaud Delbru - All Rights Reserved
#
# == To-do
#
# * To-do 1
#

require 'query_generator/abstract_generator'

class NTriplesQueryGenerator < AbstractQueryGenerator
	@variables = {}

  
  
#----------------------------------------------#
#               PRIVATE METHODS                #
#----------------------------------------------#

  private
  
  # Create the select clause for the n3 query
  #
  # *Arguments* :
  # * *bindings* : 	Array of binding variables in the select clause.
  #					Binding variables is an array containing the triples which must
  #					be returned.
  #
  # *Return* :
  # * _String_ Select part of the n3 query
  def self.select(binding_triple)
  	select_template = String.new
  	
  	raise(BindingVariableError, "No binding variables received.") if binding_triple.empty? || binding_triple.nil?
  	
		s = convert_subject(binding_triple[0])
		p = convert_predicate(binding_triple[1])
		o = convert_object(binding_triple[2])
		select_template << "#{s} #{p} #{o} . \n"

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
  def self.where(conditions, keyword_match)
  	# Init where template
  	where_template = String.new
  	# Init counter
  	
  	conditions.each do |s, p, o|

			subject = convert_subject(s)
			predicate = convert_predicate(p)
			object = convert_object(o)
			  		
  		where_template << "\t #{subject} #{predicate} #{add_keyword(o) if keyword_match} #{object} . \n"
  	end
		# remove last \n
  	return where_template.chomp
  end


	def self.add_keyword obj
		if obj.is_a? Resource
			""
		else
			# creating unique placeholder variable for the keyword search, using a 
			# random number and checking if we have already generated this exact 
			# placeholder before
			#
			# resulting query will be something like
			# select {?s ?p ?o .}
			# where {?s :title ?keyword12345 . ?keyword12345 yars:keyword "test" .}
			raise(ActiveRdfError, 'too many conditions for keyword search') if @variables.size > 100
			while @variables[variable = '?keyword' + rand(100).to_s]
				;
			end
			@variables[variable] = true
			" #{variable} . #{variable} <http://sw.deri.org/2004/06/yars#keyword> "
		end
	end


  
  def self.order_by(order_opt)
  
  end
	
#----------------------------------------------#
#               PUBLIC METHODS                 #
#----------------------------------------------#

  public
  
  def self.generate(binding_triple, conditions, order_opt = nil, keyword_match = false)

	template_query = <<END_OF_QUERY
@prefix ql: <http://www.w3.org/2004/12/ql#> . 
<> ql:select {
#{select(binding_triple)}
}; 
ql:where {
#{where(conditions, keyword_match)}
} .
#{order_by(order_opt)}
END_OF_QUERY
		
	return template_query

  end
  
end

