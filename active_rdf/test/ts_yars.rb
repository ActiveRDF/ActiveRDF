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
$:.unshift File.join(File.dirname(__FILE__),'..')

require 'active_rdf'
require 'node_factory'

require 'test/unit/testsuite'
require 'test/unit/ui/console/testrunner'

DB = :yars
DB_HOST = 'browserdf.org'
DB_CONTEXT = 'test-context'

# NodeFactory Tests
require 'test/node_factory/test_connection'
require 'test/node_factory/test_initialisation_connection'
require 'test/node_factory/test_create_literal'
require 'test/node_factory/test_create_basic_resource'
require 'test/node_factory/test_create_identified_resource_with_unknown_type'
require 'test/node_factory/test_create_identified_resource_on_person_type'
require 'test/node_factory/test_person_methods'
require 'test/node_factory/test_equals'

# Yars adapter Tests
require 'test/adapter/yars/test_yars_adapter'
require 'test/adapter/yars/test_yars_adapter_add'
require 'test/adapter/yars/test_yars_adapter_remove'
require 'test/adapter/yars/test_yars_basic_query'
require 'test/adapter/yars/test_yars_joint_query'

# Core Tests
require 'test/core/resource/test_resource'
require 'test/core/resource/test_resource_get'
require 'test/core/resource/test_resource_find'
require 'test/core/resource/test_identified_resource'
require 'test/core/resource/test_identifiedresource_get'
require 'test/core/resource/test_identifiedresource_find'
require 'test/core/resource/test_identifiedresource_create'
require 'test/core/resource/test_identifiedresource_attributescontainer'

# NamespaceFactory Test
require 'test/namespace_factory/test_namespace_factory'