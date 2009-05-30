module External
  module Utils
    module_function
    
    # try_handle is a forwarding method allowing External::IO to handle
    # non-File, non-Tempfile IO objects. try_handle infers a method
    # name based on the class of the input and trys to forward the
    # input io to that method within External::IO. For instance:
    #
    # * the _mode method for StringIO is 'stringio_mode'
    # * the _length method for StringIO is 'stringio_length'
    #
    # Nested classes have '::' replaced by '_'. Thus to add support
    # for Some::Unknown::IO, extend External::IO as below:
    #
    #   module External::IO
    #     def some_unknown_io_mode(io)
    #     ...
    #     end
    #
    #     def some_unknown_io_length(io)
    #     ...
    #     end
    #   end
    #
    # See stringio_mode and stringio_length for more details.
    def try_handle(io, method)
      method_name = io.class.to_s.downcase.gsub(/::/, "_") + "_#{method}"
      if Utils.respond_to?(method_name)
        Utils.send(method_name, io)
      else
        raise "cannot determine #{method} for '%s'" % io.class
      end
    end
    
    # Determines the generic mode of the input io using the _mode
    # method for the input io class.  By default Io provides _mode
    # methods for File, Tempfile, and StringIo.  The return string
    # is determined as follows:
    #
    # readable & writable:: r+
    # readable:: r
    # writable:: w
    #
    # The _mode method takes the input io and should return an array 
    # specifying whether or not io is readable and writable 
    # (ie [readable, writable]). 
    #
    # See try_handle for more details.
    def mode(io) 
      readable, writable = try_handle(io, "mode")

      case
      when readable && writable then "r+"
      when readable then "r"
      when writable then "w"
      else
        # occurs for r+ mode, for some reason
        "r+"
      end
    end
    
    # Determines the length of the input io using the _length method
    # for the input io class.  Non-External::Io inputs are extended 
    # in this process.
    #
    # The _length method takes the input io, and should return the 
    # current length of the input io (ie a flush operation may be 
    # required). 
    # 
    # See try_handle for more details.
    def length(io)
      case io
      when Io then try_handle(io, "length")
      else
        io.extend Io
        io.length
      end
    end
    
    # Returns an array of bools determining if the input Io 
    # is readable and writable.
    def io_mode(io)
      begin
        dup = io.dup
        
        # determine readable/writable by sending close methods
        # to the duplicated Io.  If the io cannot  be closed for 
        # read/write then it will raise an error, indicating that 
        # it was not open in the given mode.   
        [:close_read, :close_write].collect do |method|
          begin
            dup.send(method)
            true
          rescue(IOError)
            false
          end
        end
      ensure
        # Be sure that the dup is fully closed before proceeding!  
        # (Otherwise Tempfiles will not be properly disposed of
        # ... at least on Windows, perhaps on others)
        dup.close if dup && !dup.closed?
      end
    end
    
    # Returns the length of the input IO
    def io_length(io)
      io.fsync
      io.stat.size
    end
    
    def file_mode(io)
      io_mode(io)
    end
    
    def file_length(io)
      io_length(io)
    end
    
    # Returns an array of bools determining if the input Tempfile 
    # is readable and writable.
    def tempfile_mode(io)
      file_mode(io.instance_variable_get(:@tmpfile))
    end
    
    # Returns the length of the input Tempfile
    def tempfile_length(io)
      file_length(io)
    end
    
    # Returns an array of bools determining if the input StringIo 
    # is readable and writable.
    #
    #   s = StringIo.new("abcde", "r+")
    #   External::Io.stringio_mode(s)  # => [true, true]
    #
    def stringio_mode(io)
      [!io.closed_read?, !io.closed_write?]
    end
    
    # Returns the length of the input StringIo
    #
    #   s = StringIo.new("abcde", "r+")
    #   External::Io.length(s)  # => 5
    #
    def stringio_length(io)
      io.string.length
    end
  end
end

# Apply platform-specific patches
# case RUBY_PLATFORM
# when 'java' 
# end