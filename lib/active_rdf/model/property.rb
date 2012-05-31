require 'digest'
require 'set'

module RDF
  # Represents an RDF property.
  # If an optional subject is provided on instatiation, provides access to values of this property belonging to the
  # associated subject. Property objects are +Enumerable+. Values are returned as copies with no order garunteed
  # and may be accessed individually by key.
  #
  # == Usage
  #  age = RDF::Property.new('http://activerdf.org/test/age')
  #  age.domain => [#<RDFS::Resource @uri="http://activerdf.org/test/Person">]
  #  age.range => [#<RDFS::Resource @uri="http://www.w3.org/1999/02/22-rdf-syntax-ns#Literal">]
  #  age.type => [#<RDFS::Resource @uri="http://www.w3.org/1999/02/22-rdf-syntax-ns#Property">]
  #  age.to_a => ActiveRdfError: http://activerdf.org/test/age: no associated subject
  #
  #  email = RDF::Property.new('http://activerdf.org/test/email', 'http://activerdf.org/test/eyal')
  #  email.replace("eyal@cs.cu.nl")                                 # replace any existing values
  #  email.add("eyal.oren@deri.com")                                # add new value to this property
  #  email += ("eyal.oren@deri.net")                                # alternative way to add new value
  #  email.clear                                                    # delete any existing values
  #  email.add(["eyal@cs.cu.nl","eyal.oren@deri.com"])              # add array containing values
  #  email["eyal.oren@deri.com"] = "eyal.oren@deri.net"             # replace existing value
  #  email[p.index("eyal.oren@deri.net")] = "eyal.oren@deri.org"    # replace existing value by key
  #  email.include?("eyal.oren@deri.org") => true                   # check for existing value
  #  email == ["eyal.oren@deri.org","eyal@cs.cu.nl"] => true        # compare value(s) to array (order is ignored)
  #  email.delete("eyal@cs.cu.nl")                                  # delete specific value
  #  email == "eyal.oren@deri.org" => true                          # compare value(s) to single value
  #  email.collect!{|val| val.gsub(/@/,' at ').gsub(/\./,' dot ')}  # update value(s) with result of block
  class Property < RDFS::Resource
    attr_reader :subject

    def initialize(property, subject = nil)
      super(property)
      @subject = subject
      @lang = nil
      @exact_lang = true
      @datatype = nil
      @context = nil

      if @subject
        class<<self
          include AssociatedProperty
        end
      end
    end

    self.class_uri = ActiveRDF::Namespace.lookup(:rdf, :Property)

    def initialize_copy(property)
      if @subject
        class<<self
          include AssociatedProperty
        end
      end
    end

    # Returns the property object for this property without @subject set
    def property
      RDF::Property.new(self)
    end
  end

  # Provides methods for accessing property values when @subject is set
  module AssociatedProperty
    include Enumerable
    # Value reference. Retrieves a copy of the value by the key or value. Returns nil if not found.
    def [](md5_or_value)
      unless md5_or_value.nil?
        arr = to_a
        arr.find{|value| value == md5_or_value} || arr.find{|value| get_key(value) == md5_or_value}
      end
    end
    alias :at :[]

    # Selective value replacement. Replaces the value given by key or value. Raises IndexError if value not found.
    def []=(md5_or_value,new_value)
      value = self[md5_or_value]
      raise IndexError, "Couldn't find existing value to replace: #{md5_or_value}" unless value
      ActiveRDF::FederationManager.delete(@subject, self.property, value)
      add(new_value)
    end

    # Returns a new array with the object appended, or the objects values if obj.respond_to? :to_ary
    def +(obj)
      to_a + [*obj]
    end

    # Returns a new array with the object removed
    def -(obj)
      to_a - [*obj]
    end

    def ==(other)
      if other.respond_to?(:to_ary)
        Set.new(other) == Set.new(to_a)
      else
        arr = to_a
        if arr.size == 1
          other == arr[0] || super
        else
          super
        end
      end
    end
    alias :eql? :==

    # Append. Adds the given object(s) to the values for this property belonging to @subject
    # This expression returns the property itself, so several appends may be chained together.
    def add(*args)
      args.each do |arg|
        if arg.respond_to?(:to_ary)
          arg.to_ary.each {|item| ActiveRDF::FederationManager.add(@subject, self.property, item)}
        else
          ActiveRDF::FederationManager.add(@subject, self.property, arg)
        end
      end
      self
    end

    # Removes all values
    def clear
      ActiveRDF::FederationManager.delete(@subject, self.property)
      self
    end

    # Invokes the block once for each value, replacing the value with the value returned by block
    def collect!(&block)
      to_a.each do |item|
        new_item = yield(item)
        delete(item)
        add(new_item)
      end
      self
    end
    alias :map! :collect!

    # Returns the context for the property if context is nil.
    # Returns a new RDF::Property object with the @context value set if context is provided
    # see also #lang, #datatype
    def context(context = nil)
      if context.nil?
        @context
      else
        property_with_context = self.dup
        property_with_context.context = context
        property_with_context
      end
    end

    # Sets context for this property
    def context=(context)
      @context = context
    end

    # Returns the datatype if type is nil.
    # Returns a new RDF::Property object with the @datatype set if type is provided
    # see also #context, #lang
    def datatype(type = nil)
      if type.nil?
        @datatype
      else
        property_with_datatype = dup
        property_with_datatype.datatype = type
        property_with_datatype
      end
    end

    # Sets datatype for this property
    def datatype=(type)
      @datatype = type
    end

    # Deletes value given by key or value. If the item is not found, returns nil.
    # If the optional code block is given, returns the result of block if the item is not found
    def delete(md5_or_value)
      value = self[md5_or_value]
      if value
        ActiveRDF::FederationManager.delete(@subject, self.property, value)
        value
      elsif block_given?
        yield
      end
    end

    # Deletes every value for which block evaluates to true
    def delete_if(&block)  # :yields: key, value
      reject!(&block)
      self
    end

    # Calls block once for each value, passing a copy of the value as a parameter
    def each(&block)  # :yields: value
      q = ActiveRDF::Query.new.distinct(:o).where(@subject,self,:o,@context)
      if @lang and !@datatype
        q.lang(:o,@lang,@exact_lang)
      elsif @datatype and !@lang
        q.datatype(:o, @datatype)
      elsif @lang and @datatype
        raise ActiveRdfError, "@datatype and @lang may not both be set"
      end
      q.execute(&block)
      self
    end
    alias :each_value :each

    # Calls block once for each value, passing the key as a parameter
    def each_key(&block)  # :yields: key
      keys.each(&block)
      self
    end

    # Calls block once for each value, passing the key and value as a parameters
    # See also #to_h
    def each_pair(&block)  # :yields: key, value
      each{|value| yield get_key(value), value}
      self
    end

    # Returns true if the property contains no values
    def empty?
      to_a.empty?
    end
    alias :blank? :empty?

    # Returns a value from the property for the given key. If the key can't be found, there are several options:
    # With no other arguments, it will raise an IndexError exception; if default is given, then that will be returned;
    # if the optional code block is specified, then that will be run and its result returned.
    def fetch(md5, default = nil, &block)
      val = self[md5]
      if val
        val
      else
        if block_given?
          yield md5
        elsif default
          default
        else
          raise IndexError, "could not find #{md5}"
        end
      end
    end

    # Returns true if the given key or value is present
    def include?(obj)
      !!self[obj]
    end
    alias :value? :include?
    alias :has_value? :include?

    # Returns the key for a given value. If not found, returns nil.
    def index(obj)
      value = to_a.find{|val| obj == val}
      get_key(value) if value
    end

    # Return the value(s) of this property as a string.
    def inspect
      "#<RDF::Property #{abbr} [#{to_a.collect{|obj| obj.inspect}.join(", ")}]>"
    end

    # Returns a new array populated with the keys to the values
    def keys
      collect{|value| get_key(value)}
    end

    # Returns the language tag and the match settings for the property if tag is nil.
    # Returns a new RDF::Property object with the @lang value set if tag is provided
    # see also #context, #datatype
    def lang(tag = nil, exact = true)
      if tag.nil?
        [@lang,@exact_lang]
      else
        property_with_lang = RDF::Property.new(self, @subject)
        property_with_lang.lang = tag, exact
        property_with_lang
      end
    end

    # Sets lang and match settings
    def lang=(*args)
      args.flatten!
      @lang = args[0].sub(/^@/,'')
      @exact_lang = truefalse(args[1],true)
    end

    # Returns the number of values assigned to this property for this @subject
    def length
      to_a.length
    end
    alias :size :length

    # Ensure the return of only one value assigned to this property for this @subject.
    # If more than 1 value is found, ActiveRdfError is thrown.
    def only
      entries = self.entries
      raise ActiveRDF::ActiveRdfError if entries.size > 1
      entries[0]
    end

    # Equivalent to Property#delete_if, but returns nil if no changes were made
    def reject!(&block)  # :yields: key, value
      change = false
      each_pair do |key, value|
        if yield(key, value)
          delete(value)
          change = true
        end
      end
      self if change
    end

    # Value replacement. Replaces all current value(s) with the new value
    def replace(new)
      clear
      add(new)
      self
    end
    alias :size :length

    # Allow this Property to be automatically converted to array
    alias :to_ary :to_a

    # Returns a hash of copies of all values with indexes.
    # Changes to this hash will not effect the underlying values. Use #add or #replace to persist changes.
    # See also #each_pair
    def to_h
      hash = {}
      to_a.each do |value|
        hash[get_key(value)] = value
      end
      hash
    end

    def to_s
      to_a.join(",")
    end

    # Return an array containing the values for the given keys.
    def values_at(*args)
      args.collect{|md5| self[md5]}
    end

    private
    def get_key(value)
      Digest::MD5.hexdigest(value.to_s)
    end
  end
end