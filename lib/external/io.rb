require 'external/chunkable'
require 'stringio'
require 'tempfile'
require 'fileutils'

module External
  # Position gets IO objects to work properly for large files.  Additionally, 
  # IO adds a length accessor for getting the size of the IO contents.  Note
  # that length is not automatically adjusted by write, for performance
  # reasons.  length must be managed manually, or reset after writes using
  # reset_length.
  #
  # A variety of bugs needed to be addressed per-platform:
  #
  # == Mac OS X Tiger
  #
  # Using the default (broken) installation of Ruby, StringIO does not correctly
  # position itself when a pos= statement is issued.
  #
  #   s = StringIO.new "abc"
  #   s.read    # => "abc"
  #   s.pos = 0
  #   s.read    # => nil
  #
  # For regular IO objects, as expected, the second read statement returns
  # "abc".  Install the a fixed version of Ruby, perhaps with the one-click
  # installer: http://rubyosx.rubyforge.org/
  #
  # == Windows
  #
  # Ruby on Windows has problems with files larger than ~2 gigabytes.
  # Sizes return as negative, and positions cannot be set beyond the max
  # size of a long (2147483647 ~ 2GB = 2475636895).  IO corrects both of 
  # these issues thanks in large part to a bit of code taken from 
  # 'win32/file/stat' (http://rubyforge.org/projects/win32utils/).
  #
  # == Others
  #
  # I haven't found errors on Fedora and haven't tested on any other platforms.
  # If you find and solve some wierd positioning errors, please let me know. 
  module IO
    
    # Determines the generic mode of the input io using the _mode
    # method for the input io class.  By default IO provides _mode
    # methods for File, Tempfile, and StringIO.  The return string
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
    def self.mode(io) 
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
    # for the input io class.  Non-External::IO inputs are extended 
    # in this process.
    #
    # The _length method takes the input io, and should return the 
    # current length of the input io (ie a flush operation may be 
    # required). 
    # 
    # See try_handle for more details.
    def self.length(io)
      case io
      when External::IO
        try_handle(io, "length")
      else
        io.extend External::IO
        io.length
      end
    end
    
    # Returns an array of bools determining if the input File 
    # is readable and writable.
    def self.file_mode(io)
      begin
        dup = io.dup
        
        # determine readable/writable by sending close methods
        # to the duplicated IO.  If the io cannot  be closed for 
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
        # Be sure that the io is fully closed before proceeding!  
        # (Otherwise Tempfiles will not be properly disposed of
        # ... at least on Windows, perhaps on others)
        dup.close if dup && !dup.closed?
      end
    end
    
    # Returns the length of the input File
    def self.file_length(io)
      io.fsync unless io.generic_mode == 'r'
      File.size(io.path)
    end
    
    # Returns an array of bools determining if the input Tempfile 
    # is readable and writable.
    def self.tempfile_mode(io)
      file_mode(io.instance_variable_get("@tmpfile"))
    end
    
    # Returns the length of the input Tempfile
    def self.tempfile_length(io)
      file_length(io)
    end
    
    # Returns an array of bools determining if the input StringIO 
    # is readable and writable.
    #
    #   s = StringIO.new("abcde", "r+")
    #   External::IO.stringio_mode(s)  # => [true, true]
    #
    def self.stringio_mode(io)
      [!io.closed_read?, !io.closed_write?]
    end
    
    # Returns the length of the input StringIO
    #
    #   s = StringIO.new("abcde", "r+")
    #   External::IO.length(s)  # => 5
    #
    def self.stringio_length(io)
      io.string.length
    end
    
    def self.extended(base) # :nodoc:
      base.instance_variable_set("@generic_mode", mode(base))
      base.reset_length
      base.default_blksize = 1024
      base.binmode
    end
    
    protected
    
    # try_handle is a forwarding method allowing External::IO to handle
    # non-File, non-Tempfile IO objects.  try_handle infers a method
    # name based on the class of the input and trys to forward the 
    # input io to that method within External::IO. For instance:
    #
    # * the _mode method for StringIO is 'stringio_mode'
    # * the _length method for StringIO is 'stringio_length' 
    # 
    # Nested classes have '::' replaced by '_'.  Thus to add support
    # for Some::Unknown::IO, extend External::IO as below:
    #
    #   module External::IO
    #     def some_unknown_io_mode(io)
    #       ...
    #     end
    # 
    #     def some_unknown_io_length(io)
    #       ...
    #     end
    #   end
    #
    # See stringio_mode and stringio_length for more details.
    def self.try_handle(io, method)
      method_name = io.class.to_s.downcase.gsub(/::/, "_") + "_#{method}"
      if self.respond_to?(method_name)
        External::IO.send(method_name, io)
      else
        raise "cannot determine #{method} for '%s'" % io.class
      end
    end
    
    public
    
    include Chunkable
    
    attr_reader :generic_mode

    # True if self is a File or Tempfile
    def file?
      self.kind_of?(File) || self.kind_of?(Tempfile)
    end

    # Modified truncate that adjusts length
    def truncate(n)
      super
      self.pos = n if self.pos > n
      self.length = n
    end
    
    # Resets length to the length returned by External::IO.length
    def reset_length
      self.length = External::IO.length(self)
    end
    
    #
    # comparison
    #
    
    # Quick comparision with another IO.  Returns true if
    # another == self, or if both are file-type IOs and 
    # their paths are equal.
    def quick_compare(another)
      self == another || (self.file? && another.file? && self.path == another.path)
    end

    # Sort compare with another IO, behaving like a comparison between
    # the full string contents of self and another.  Can be a long 
    # operation if it requires the full read of two large IO objects.
    def sort_compare(another, blksize=default_blksize)
      # equal in comparison if the ios are equal
      return 0 if quick_compare(another)
      
      self.flush unless self.generic_mode == 'r'
      self.reset_length
      another.flush unless another.generic_mode == 'r'
      another.reset_length
      
      if another.length > self.length
        return -1
      elsif self.length < another.length
        return 1
      else
        self.pos = 0
        another.pos = 0

        sa = sb = nil
        while sa == sb
          sa = self.read(blksize)
          sb = another.read(blksize)
          break if sa.nil? || sb.nil?
        end

        sa.to_s <=> sb.to_s
      end
    end
    
    # Sort compare with another IO, behaving like a comparison between
    # the full string contents of self and another.  Can be a long 
    # operation if it requires the full read of two large IO objects.
    def <=>(another)
      sort_compare(another)
    end
    
    #
    # reading
    #
    
    def scan(range_or_span=default_span, blksize=default_blksize, carryover_limit=default_blksize)
      carryover = 0
      chunk(range_or_span, blksize) do |offset, length|
        raise "carryover exceeds limit: #{carryover} (#{carryover_limit})" if carryover > carryover_limit
        
        scan_begin = offset - carryover
        self.pos = scan_begin
        string = self.read(length + carryover)
        carryover = yield(scan_begin, string)
      end
      carryover
    end
    
    #
    # writing
    #
    
    # 
    def insert(src, range=0..src.length, pos=nil)
      self.pos = pos unless pos == nil
      
      start_pos = self.pos
      length_written = 0

      src.flush unless src.generic_mode == 'r'   
      src.pos = range.begin 
      src.chunk(range) do |offset, length|
        length_written += write(src.read(length))
      end

      end_pos = start_pos + length_written
      self.length = end_pos if end_pos > self.length
      length_written
    end
    
    # 
    def concat(src, range=0..src.length)
      insert(src, range, length)
    end
    
    #--
    # it appears that as long as the io opening t.path closes,
    # the tempfile will be deleted at the exit of the ruby 
    # instance... otherwise it WILL NOT BE DELETED
    # Make note of this in the documentation to be sure to close
    # files if you start inserting because it may make tempfiles
    #++
    def copy(mode="r", range=0..length)
      self.flush
      
      temp = Tempfile.new("copy")
      temp.extend IO
      temp.insert(self, range)
      temp.close

      cp = File.open(temp.path, mode)
      cp.extend IO

      if block_given?
        begin
          yield(cp)
        ensure
          cp.close unless cp.closed?
          FileUtils.rm(cp.path) if File.exists?(cp.path)
        end
      else
        cp
      end
    end
  
  end
end

# This code block modifies IO only if running on windows
unless RUBY_PLATFORM.index('mswin').nil?
require 'Win32API' 

module External
  module IO
  
    def self.extended(base) # :nodoc:
      base.instance_variable_set("@generic_mode", mode(base))
      base.reset_length
      base.default_blksize = 1024
      base.binmode
      base.instance_variable_set("@pos", nil)
    end
    
    # Modfied to properly determine file lengths on Windows. Uses code
    # from 'win32/file/stat' (http://rubyforge.org/projects/win32utils/)
    def self.file_length(io) # :nodoc:
      io.fsync unless io.generic_mode == 'r'

      # I would have liked to use win32/file/stat to do this... however, some issue
      # arose involving FileUtils.cp, File.stat, and File::Stat.mode.  cp raised an 
      # error because the mode would be nil for files.  I wasn't sure how to fix it, 
      # so I've lifted the relevant code for pulling the large file size.

      # Note this is a simplified version... if you base.path point to a chardev, 
      # this may need to be changed, because apparently the call to the Win32API 
      # may fail

      stat_buf = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0].pack('ISSssssIILILILIL')
      Win32API.new('msvcrt', '_stat64', 'PP', 'I').call(io.path, stat_buf)
      stat_buf[24, 4].unpack('L').first # Size of file in bytes
    end
    
    POSITION_MAX = 2147483647  # maximum size of long
    
    # Modified to handle positions past the 2Gb limit
    def pos # :nodoc:
      @pos || super
    end
    
    # Positions larger than the max value of a long cannot be directly given 
    # to the default +pos=+.  This version incrementally seeks to positions 
    # beyond the maximum, if necessary.
    #
    # Note: setting the position beyond the 2Gb limit requires the use of a 
    # sysseek statement.  As such, errors will arise if you try to position 
    # an IO object that does not support this method (for example StringIO... 
    # but then what are you doing with a 2Gb StringIO anyhow?)
    def pos=(pos)
      if pos < POSITION_MAX
        super(pos)
        @pos = nil
      elsif @pos != pos
        # note sysseek appears to be necessary here, rather than io.seek
        @pos = pos
        
        super(POSITION_MAX)
        pos -= POSITION_MAX
        
        while pos > POSITION_MAX
          pos -= POSITION_MAX
          self.sysseek(POSITION_MAX, Object::IO::SEEK_CUR)
        end
        
        self.sysseek(pos, Object::IO::SEEK_CUR)
      end
    end
    
  end
end

end # end the windows-specific code
