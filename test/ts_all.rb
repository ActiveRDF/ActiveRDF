# = ts_all.rb
#
# Test Suite of all the Test Unit.
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
#

require 'active_rdf'
require 'node_factory'

require 'test/unit/testsuite'
require 'test/unit/ui/console/testrunner'

require 'test/node_factory/test_initialisation'
require 'test/node_factory/test_create_literal'
require 'test/node_factory/test_create_basic_resource'

require 'test/adapter/redland/test_redland_adapter'
require 'test/adapter/redland/test_redland_adapter_add'
require 'test/adapter/redland/test_redland_adapter_remove'
require 'test/adapter/redland/test_redland_basic_query'
require 'test/adapter/redland/test_redland_joint_query'

require 'test/adapter/yars/test_yars_adapter'
require 'test/adapter/yars/test_yars_adapter_add'
require 'test/adapter/yars/test_yars_adapter_remove'
require 'test/adapter/yars/test_yars_basic_query'
require 'test/adapter/yars/test_yars_joint_query'

require 'test/resource/test_resource'
require 'test/resource/test_redland_resource_get'
require 'test/resource/test_yars_resource_get'
require 'test/resource/test_redland_resource_find'
require 'test/resource/test_yars_resource_find'

require 'test/namespace_factory/test_namespace_factory'

class TestSuite_AllTests
    def self.suite
        suite = Test::Unit::TestSuite.new("ActiveRDF Tests")
        
        $stderr << 'Start NodeFactory Tests' << "\n"
        suite << TestNodeFactoryInitialisation.suite
        suite << TestNodeFactoryLiteral.suite
        suite << TestNodeFactoryBasicResource.suite
        
        $stderr << 'Start Redland Adapter Tests' << "\n"
        suite << TestRedlandAdapter.suite
        suite << TestRedlandAdapterAdd.suite
        suite << TestRedlandAdapterRemove.suite
        suite << TestRedlandAdapterBasicQuery.suite
        suite << TestRedlandAdapterJointQuery.suite
        
        $stderr << 'Start Yars Adapter Tests' << "\n"
        suite << TestYarsAdapter.suite
        suite << TestYarsAdapterAdd.suite
        suite << TestYarsAdapterRemove.suite
        suite << TestYarsAdapterBasicQuery.suite
        suite << TestYarsAdapterJointQuery.suite
        
        $stderr << 'Start Resource Tests' << "\n"
        suite << TestResource.suite
        suite << TestRedlandResourceGet.suite
        suite << TestYarsResourceGet.suite
        suite << TestRedlandResourceFind.suite
        suite << TestYarsResourceFind.suite
        
        $stderr << 'Start NamespaceFactory Tests' << "\n"
        suite << TestNamespaceFactory.suite    
               
        return suite
    end
end

Test::Unit::UI::Console::TestRunner.run(TestSuite_AllTests)

