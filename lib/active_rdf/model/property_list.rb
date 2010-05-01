# Simple class which will contain all values of a specified property related to a subject.
# It provides some useful shortcut methods to work with properties and related values.

class PropertyList < Array
  
  # Add reader accessor
  attr_reader :s, :p
  attr_accessor :writeable
  
  # Initialize a new list of properties' values
  # * p           the original property
  # * pv_list     the list of properties' values
  # * s           the sobject which property is related to
  # * writeable   if set to false, the list will be write-protected
  def initialize(p, pv_list, s, writeable = true)
    super pv_list
    @s, @p = s, p
    @writeable = writeable
  end

  # add a new property value realated to @p property and @s subject
  alias :add :<<
  def <<(pv)
    check_writeable!
    # update the array list
    add pv
    
    # insert the new statment into the store
    ActiveRDF::FederationManager.add(@s, @p, pv)
  end
  
  # delete a statment which contains old_p_value
  # and insert a new statment (@s, @p, new_p_value)
  def replace(old_p_value, new_p_value)
    check_writeable!
    # delete the old statment
    self.delete(old_p_value)
    ActiveRDF::FederationManager.delete(@s, @p, old_p_value)
    
    # insert the new statment
    self << new_p_value
  end

  # if no papameters will be specified, delete every
  # triple related to :s and p: otherwise delete the
  # triples whose values are specified by params
  def remove(*params)
    check_writeable!
    if params.length >= 1
      # delete only triples whose values is specified by parameters
      params.each{|param|
        if self.delete(param)
          return ActiveRDF::FederationManager.delete(@s, @p, param)
        end
      }
    else
      # delete every triple related to :s and :p whose values is contained by self...
      self.each{|value|
        if ActiveRDF::FederationManager.delete(@s, @p, value) == false
          return false
        end
      }
      # ...and clear the array Poperty_list array
      self.clear
      return true
    end
  end
    
  private
  
  # Checks if the list is writeable, raise an error otherwise
  def check_writeable!
    raise(RuntimeError, "List is not writeable!") unless(@writeable)
  end

end