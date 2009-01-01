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
  #  email.store("eyal.oren@deri.com")                              # add new value to this property
  #  email += ("eyal.oren@deri.net")                                # alternative way to add new value
  #  email.clear                                                    # delete any existing values
  #  email.store(["eyal@cs.cu.nl","eyal.oren@deri.com"])            # add enumerable containing values
  #  email["eyal.oren@deri.com"] = "eyal.oren@deri.net"             # replace existing value
  #  email[p.index("eyal.oren@deri.net")] = "eyal.oren@deri.org"    # replace existing value by key
  #  email.include?("eyal@cs.cu.nl") => true                        # check for existing value
  #  email == ["eyal.oren@deri.net","eyal@cs.cu.nl"] => true        # compare value(s) to enumerable (order is ignored)
  #  email.delete("eyal@cs.cu.nl")                                  # delete specific value
  #  email == "eyal.oren@deri.net" => true                          # compare value(s) to single value
  #  email.collect!{|val| val.gsub(/@/,' at ').gsub(/\./,' dot ')}  # update value(s) with result of block
  class Property < RDFS::Resource
    include Enumerable
    attr_reader :subject

    def initialize(pred, subject = nil)
      super(pred)
      @subject = subject
    end
    self.class_uri = Namespace.lookup(:rdf, :Property)

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
      FederationManager.delete(@subject, self, value)
      store(new_value)
    end

    # Returns an array with the object appended 
    def +(obj)
      to_a + [*obj]
    end

    # Returns an array with the object removed 
    def -(obj)
      to_a - [*obj]
    end

    # Removes all values
    def clear
      raise ActiveRdfError, "#{self}: no associated subject" unless @subject
      FederationManager.delete(@subject, self)
      self
    end

    # Invokes the block once for each value, replacing the value with the value returned by block
    def collect!(&block)
      to_a.each do |item|
        new_item = yield(item)
        delete(item)
        store(new_item)
      end
      self
    end
    alias :map! :collect!

    # Deletes value given by key or value. If the item is not found, returns nil.
    # If the optional code block is given, returns the result of block if the item is not found
    def delete(md5_or_value) 
      value = self[md5_or_value]
      if value
        FederationManager.delete(@subject, self, value)
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

    # Calls block once for each value, passing the value as a parameter
    def each(&block)  # :yields: value
      to_a.each(&block)
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

    # Equality. Two properties are the same. If @subject is given, compare by values. If no match by value or no @subject was given, compare as Resource 
    def ==(other)
      # compare to property values if subject is set
      if @subject
        if other.is_a?(Enumerable)
          Set.new(other) == Set.new(to_a)
        else
          arr = to_a
          if arr.size == 1
            other == arr[0] || super
          else
            super
          end
        end
      else
        super
      end
    end
    alias :eql? :==

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
      @subject ? "[#{to_a.collect{|obj| obj.inspect}.join(", ")}]" : super
    end

    # Returns a new array populated with the keys to the values
    def keys
      collect{|value| get_key(value)}
    end

    # Returns the number of values assigned to this property for this @subject
    def length
      to_a.length
    end
    alias :size :length

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
      store(new)
      self
    end
    alias :size :length

    # Append. Adds the given object(s) to the values for this property belonging to @subject
    # This expression returns the property itself, so several appends may be chained together.
    def store(*args)
      raise ActiveRdfError, "#{self}: no associated subject" unless @subject 
      args.each do |arg|
        if arg.is_a?(Enumerable) && !arg.is_a?(String)
          arg.each {|item| FederationManager.add(@subject, self, item)}
        else
          FederationManager.add(@subject, self, arg)
        end
      end
      self
    end

    # Returns an array of copies of all values for this property of the given @subject
    # Changes to this array will not effect the underlying values. Use #store or #replace to persist changes.
    # Raises ActiveRdfError if @subject is not defined for this property.
    def to_a
      raise ActiveRdfError, "#{self}: no associated subject" unless @subject 
      Query.new.distinct(:o).where(@subject,self,:o).execute(:flatten => false)
    end
    alias :to_ary :to_a 

    # Returns a hash of copies of all values with indexes.
    # Changes to this hash will not effect the underlying values. Use #store or #replace to persist changes.
    # See also #each_pair
    def to_h
      hash = {}
      to_a.each do |value|
        hash[get_key(value)] = value
      end
      hash
    end

    # Returns the values of the property joined if @subject is set, otherwise calls Resource.to_s
    def to_s
      @subject ? to_a.join(", ") : super
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