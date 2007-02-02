
require 'java'

WrapperForSesame2 = org.activerdf.minced.sesame2.WrapperForSesame2

class SimpleLog
  def initialize(where)
    @db = WrapperForSesame2.new
    @logfile = File.new(where, "w+")
    ObjectSpace.define_finalizer     (self, SimpleLog.create_finalizer(@logfile,@db))
  end
  def write(msg)
    @logfile.puts msg
  end
  def SimpleLog.create_finalizer(logfile,db)
    proc {|id| puts "Finalizer on #{id}"
      logfile.puts "Closed properly"
      logfile.close
      db.getSesameConnection.close
    }
  end
end
a=SimpleLog.new("/tmp/aa")
a.write("HI")
a=nil
puts "Listing instances of SimpleLog:"
ObjectSpace.each_object(SimpleLog){|obj|
  p obj
}
puts "DONE"
puts "Running the garbage collector"
#GC.start
puts "Listing remaining instances of SimpleLog:"
ObjectSpace.each_object(SimpleLog){|obj|
  p obj
}
puts "DONE"
