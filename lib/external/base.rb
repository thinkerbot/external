# For some inexplicable reason yaml MUST be required before
# tempfile in order for ExtArrTest::test_LSHIFT to pass.
# Otherwise it fails with 'TypeError: allocator undefined for Proc'

require 'yaml'
require 'tempfile'
require 'fileutils'

require 'external/chunkable'
require 'external/enumerable'
require 'external/io'

module External
  
  # Base provides a basic IO interface used by ExtArc, ExtArr, and ExtInd.
  class Base
    class << self
      
      # Initializes an instance of self with File.open(fd, mode) and the
      # specified options.  As with File.open, the instance will be passed to
      # the block and closed when the block returns.  If no block is given,
      # open returns the new instance.  
      #
      # Nil may be provided as an fd, in which case it is passed directly
      # to new as the io.
      def open(fd=nil, mode="rb", options={})
        fd = File.open(fd, mode) unless fd == nil
        base = self.new(fd, options)
        
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
    
    # The underlying io for self.
    attr_reader :io
    
    TEMPFILE_BASENAME = "external_base"
    
    # Creates a new instance of self with the specified io.  If io==nil,
    # a Tempfile initialized to TEMPFILE_BASENAME is used.
    def initialize(io=nil)
      self.io = (io.nil? ? Tempfile.new(TEMPFILE_BASENAME) : io)
    end
 
    # True if io is closed.
    def closed?
      io.closed?
    end
  
    # Closes io.  If path is specified and io.path is an existing file, then 
    # the file is moved to path.
    def close(path=nil)
      result = !io.closed?
      
      io.close unless io.closed?
      if path && io.respond_to?(:path) && File.exists?(io.path)
        FileUtils.move(io.path, path)
      end
      
      result
    end
    
    protected
    
    include External::Chunkable
    
    # Sets io and extends the input io with External::Position.
    def io=(io)
      io.extend External::IO unless io.kind_of?(External::IO)
      @io = io
    end

  end
end