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


require 'active_rdf'
require 'node_factory'

DB = :redland

require 'test/unit/testsuite'
require 'test/unit/ui/console/testrunner'

# NodeFactory Tests
require 'active_rdf/test/node_factory/test_initialisation_connection'
require 'active_rdf/test/node_factory/test_create_literal'
require 'active_rdf/test/node_factory/test_create_basic_resource'
require 'active_rdf/test/node_factory/test_create_identified_resource_with_unknown_type'
require 'active_rdf/test/node_factory/test_create_identified_resource_on_person_type'
require 'active_rdf/test/node_factory/test_person_methods'

# Redland adapter Tests
require 'active_rdf/test/adapter/redland/test_redland_adapter'
require 'active_rdf/test/adapter/redland/test_redland_adapter_add'
require 'active_rdf/test/adapter/redland/test_redland_adapter_remove'
require 'active_rdf/test/adapter/redland/test_redland_basic_query'
require 'active_rdf/test/adapter/redland/test_redland_joint_query'

# Core Tests
require 'active_rdf/test/core/resource/test_resource'
require 'active_rdf/test/core/resource/test_resource_get'
require 'active_rdf/test/core/resource/test_resource_find'
require 'active_rdf/test/core/resource/test_identified_resource'
require 'active_rdf/test/core/resource/test_identifiedresource_get'
require 'active_rdf/test/core/resource/test_identifiedresource_find'
require 'active_rdf/test/core/resource/test_identifiedresource_create'
require 'active_rdf/test/core/resource/test_identifiedresource_attributescontainer'

# NamespaceFactory Test
require 'active_rdf/test/namespace_factory/test_namespace_factory'

# QueryEngine Test
require 'active_rdf/test/query_generator/test_query_engine'

