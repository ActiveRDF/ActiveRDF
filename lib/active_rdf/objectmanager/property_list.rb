# Simple class which will contain all values of a specified property related to a subject.
# It provides some useful shortcut methods to work with properties and related values.

class PropertyList < Array
  
  # Add reader accessor
  attr_reader :s, :p
  
  # Initialize a new list of properties' values
  # * p           the original property
  # * pv_list     the list of properties' values
  # * s           the sobject which property is related to
  def initialize(p, pv_list, s)
    super pv_list
    @s, @p = s, p
  end

  # add a new property value realated to @p property and @s subject
  alias :add :<<
  def <<(pv)
    # update the array list
    add pv
    
    # insert the new statment into the store
    FederationManager.add(@s, @p, pv)
  end
  
  # delete a statment which contains old_p_value
  # and insert a new statment (@s, @p, new_p_value)
  def replace(old_p_value, new_p_value)
    # delete the old statment
    self.delete(old_p_value)
    FederationManager.delete(@s, @p, old_p_value)
    
    # insert the new statment
    self << new_p_value
  end

  # if no papameters will be specified, delete every
  # triple related to :s and p: otherwise delete the
  # triples whose values are specified by params
  def remove(*params)
    if params.length >= 1
      # delete only triples whose values is specified by parameters
      params.each{|param|
        if self.delete(param)
          return FederationManager.delete(@s, @p, param)
        end
      }
    else
      # delete every triple related to :s and :p whose values is contained by self...
      self.each{|value|
        if FederationManager.delete(@s, @p, value) == false
          return false
        end
      }
      # ...and clear the array Poperty_list array
      self.clear
      return true
    end
  end

end