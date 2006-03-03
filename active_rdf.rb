# = active_rdf.rb.rb
# Loader of ActiveRDF library
# ----
# Project	: SemperWiki
#
# See		: www.semperwiki.org
#
# Author	: Renaud Delbru, Eyal Oren
#
# Mail		: first dot last at deri dot org
#
# (c) 2005-2006

# We add the active_rdf subdirectory to the LOAD_PATH
if File.symlink?(__FILE__)
    $: << File.dirname(File.expand_path(File.readlink(__FILE__))) + '/src'
    $: << File.dirname(File.expand_path(File.readlink(__FILE__))) + '/src/lib'
else
    $: << File.dirname(File.expand_path(__FILE__)) + '/src'
    $: << File.dirname(File.expand_path(__FILE__)) + '/src/lib'
end

# Load Module Class modification for true abstract class
require 'misc/abstract_class'

# Start the logger
require 'logger'

$logger = Logger.new('/tmp/activerdf.log') if $logger.nil?
$logger.level = Logger::DEBUG