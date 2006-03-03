# = abstract_class.rb
#
# Modify Module Class to create True Abstract class:
# * non-instatiable classes.
# * with methods that are to be implemented in subclasses.
#
# module Stack
#   abstract :push, :pop
# end
#
# class ConcreteStack; implements Stack
#   def initialize
#     @stack = []
#   end
#
#   def push e
#     @stack.push(e)
#   end
#
#   def pop
#     @stack.pop
#   end
# end
#
# class FooStack; implements Stack
# end
#
# s = ConcreteStack.new
# s.push("cs")
# p s.pop                                 # -> "cs"
#
# s = FooStack.new
# s.push("fs")                            # -> push not implemented
#
# == Project
#
# * ActiveRDF
# <http://m3pe.org/activerdf/>
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

class Module

  def abstract(*ids)
    for id in ids
      name = id.id2name # 1.4.x specific
      class_eval %Q{
        def #{name}(*a)  
          raise(NotImplementedError, "#{name} not implemented")
        end
      }
    end
  end

  alias implements include
end