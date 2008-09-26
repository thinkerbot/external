# For some inexplicable reason yaml MUST be required before
# tempfile in order for ExtArrTest::test_LSHIFT to pass.
# Otherwise it fails with 'TypeError: allocator undefined for Proc'
 
require 'yaml'
require 'tempfile'

require 'external/enumerable'
require 'external/io'

module External
  
  # Base provides a basic IO interface used by ExternalArchive, ExternalArray, 
  # and ExternalIndex.
  class Base
    class << self
      
      # Initializes an instance of self with File.open(fd, mode) as an io.
      # As with File.open, the instance will be passed to the block and
      # closed when the block returns.  If no block is given, open returns
      # the new instance.  
      #
      # Nil may be provided as an fd, in which case a Tempfile will be
      # used (and mode gets ignored).
      def open(fd=nil, mode="rb", *argv)
        fd = File.open(fd, mode) unless fd == nil
        base = self.new(fd, *argv)
        
        if block_given?
          begin
            yield(base)
          ensure
            base.close
          end
        else
          base
        end
      end
    end
    
    include External::Enumerable  
    include External::Chunkable
    
    # The underlying io for self.
    attr_reader :io
    
    # The default tempfile basename for Base instances
    # initialized without an io.
    TEMPFILE_BASENAME = "external_base"
    
    # Creates a new instance of self with the specified io.  If io==nil,
    # a Tempfile initialized to TEMPFILE_BASENAME is used.
    def initialize(io=nil)
      self.io = case io
      when nil then Tempfile.new(TEMPFILE_BASENAME)
      when String then StringIO.new(io)
      else io
      end
      
      @enumerate_to_a = true
    end
 
    # True if io is closed.
    def closed?
      io.closed?
    end
  
    # Closes io.  If a path is specified, io will be dumped to it.  If
    # io is a File or Tempfile, the existing file is moved (not dumped)
    # to path.  Raises an error if path already exists and overwrite is 
    # not specified.
    def close(path=nil, overwrite=false)
      result = !io.closed?
      
      if path 
        if File.exists?(path) && !overwrite
          raise ArgumentError, "already exists: #{path}"
        end
      
        case io
        when File, Tempfile
          io.close unless io.closed?
          FileUtils.move(io.path, path)
        else
          io.flush
          io.rewind
          File.open(path, "w") do |file|
             file << io.read(io.default_blksize) while !io.eof?
          end
        end
      end
      
      io.close unless io.closed?
      result
    end
    
    # Flushes the io and resets the io length.  Returns self
    def flush
      io.flush
      io.reset_length
      self
    end
    
    # Returns another instance of self.  Must be
    # implemented in a subclass.
    def another
      raise NotImplementedError
    end
    
    def inspect
      "#<#{self.class}:#{object_id} #{ellipse_inspect(self)}>"
    end
    
    protected
    
    # Sets io and extends the input io with Io.
    def io=(io)
      io.extend Io unless io.kind_of?(Io)
      @io = io
    end
    
    # helper to inspect large arrays
    def ellipse_inspect(array) # :nodoc:
      if array.length > 10
        "[#{collect_join(array[0,5])} ... #{collect_join(array[-5,5])}] (length = #{array.length})"
      else
        "[#{collect_join(array.to_a)}]"
      end
    end
    
    def collect_join(array) # :nodoc:
      array.collect do |obj|
        obj.inspect
      end.join(', ')
    end
    
  end
end