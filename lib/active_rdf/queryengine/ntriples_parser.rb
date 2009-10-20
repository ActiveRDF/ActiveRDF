# Author:: Eyal Oren
# Copyright:: (c) 2005-2006 Eyal Oren
# License:: LGPL
require 'active_rdf'
require 'uuidtools'
require 'strscan'

module ActiveRDF
  # ntriples parser
  class NTriplesParser
    def self.parse_node input
      case input
      when MatchBNode
        RDFS::Resource.new("http://www.activerdf.org/bnode/#{UUID.random_create}/#$1")
      when MatchLiteral
        value = fix_unicode($1)
        if $2
          RDFS::Literal.typed(value, RDFS::Resource.new($2))
        elsif $3
          LocalizedString.new(value,$3)
        else
          value
        end
      when MatchResource
        RDFS::Resource.new($1)
      else
        nil
      end
    end

    # parses an input string of ntriples and returns a nested array of [s, p, o]
    # (which are in turn ActiveRDF objects)
    def self.parse(input)
      # need unique identifier for this batch of triples (to detect occurence of
      # same bnodes _:#1
      uuid = UUID.random_create.to_s

      input.split(/\r|\n/).collect do |triple|
        next if  triple =~ /^\s*#|^\s*$/
        nodes = []
        scanner = StringScanner.new(triple)
        scanner.skip(/\s+/)
        while not scanner.eos?
          nodes << scanner.scan(MatchNode)
          scanner.skip(/\s+/)
          scanner.terminate if nodes.size == 3
        end

        # handle bnodes if necessary (bnodes need to have uri generated)
        subject = case nodes[0]
                  when MatchBNode
                    RDFS::Resource.new("http://www.activerdf.org/bnode/#{uuid}/#$1")
                  when MatchResource
                    RDFS::Resource.new($1)
                  end

        predicate = case nodes[1]
                    when MatchResource
                      RDFS::Resource.new($1)
                    end

        # handle bnodes and literals if necessary (literals need unicode fixing)
        object = case nodes[2]
                 when MatchBNode
                   RDFS::Resource.new("http://www.activerdf.org/bnode/#{uuid}/#$1")
                 when MatchLiteral
                   value = fix_unicode($1)
                   if $2
                     RDFS::Literal.typed(value, RDFS::Resource.new($2))
                   elsif $3
                     LocalizedString.new(value, $3)
                   else
                     value
                   end
                 when MatchResource
                   RDFS::Resource.new($1)
                 end

        # collect s, p, o into array to be returned
        [subject, predicate, object]
      end.compact
    end

    private
    # constants for extracting resources/literals from sql results
    MatchBNode = /_:(\S*)/
    MatchResource = /<([^>]*)>/
    MatchLiteral = /"((?:\\"|[^"])*)"(?:\^\^<(\S+)>|@(\S+))?/
    MatchNode = Regexp.union(MatchBNode,MatchResource,MatchLiteral)

    # fixes unicode characters in literals (because we parse them wrongly somehow)
    def self.fix_unicode(str)
      tmp = str.gsub(/\\\u([0-9a-fA-F]{4,4})/u){ "U+#$1" }
      tmp.gsub(/U\+([0-9a-fA-F]{4,4})/u){["#$1".hex ].pack('U*')}
    end
  end
end