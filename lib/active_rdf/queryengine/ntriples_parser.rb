# Author:: Eyal Oren
# Copyright:: (c) 2005-2006 Eyal Oren
# License:: LGPL
require 'active_rdf'
require 'uuidtools'
require 'strscan'

# ntriples parser
class NTriplesParser
  # parses an input string of ntriples and returns a nested array of [s, p, o] 
  # (which are in turn ActiveRDF objects)
  def self.parse(input)
		# need unique identifier for this batch of triples (to detect occurence of 
		# same bnodes _:#1
		uuid = UUID.random_create.to_s

    input.collect do |triple|
      nodes = []
      scanner = StringScanner.new(triple)
      scanner.skip(/\s+/)
      while not scanner.eos?
        nodes << scanner.scan(Node)
        scanner.skip(/\s+/)
        scanner.terminate if nodes.size == 3 
      end

			# handle bnodes if necessary (bnodes need to have uri generated)
			subject = case nodes[0]
								when BNode
									RDFS::Resource.new("http://www.activerdf.org/bnode/#{uuid}/#$1")
                when Resource
									RDFS::Resource.new($1)
								end

      predicate = case nodes[1]
                  when Resource
                    RDFS::Resource.new($1)
                  end

			# handle bnodes and literals if necessary (literals need unicode fixing)
			object = case nodes[2]
							 when BNode
								 RDFS::Resource.new("http://www.activerdf.org/bnode/#{uuid}/#$1")
							 when Literal
								 fix_unicode($1)
               when Resource
								 RDFS::Resource.new($1)
							 end

      # collect s, p, o into array to be returned
      [subject, predicate, object]
    end
  end

	private
	# constants for extracting resources/literals from sql results
	Node = Regexp.union(/"(?:\\"|[^"])*"/,/_:\S*/,/<[^>]*>/)
	BNode = /_:(\S*)/
	Resource = /<([^>]*)>/
	Literal = /"((?:\\"|[^"])*)"/

	# fixes unicode characters in literals (because we parse them wrongly somehow)
	def self.fix_unicode(str)
		tmp = str.gsub(/\\\u([0-9a-fA-F]{4,4})/u){ "U+#$1" }
    tmp.gsub(/U\+([0-9a-fA-F]{4,4})/u){["#$1".hex ].pack('U*')}
	end
end
