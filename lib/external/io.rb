require 'external/chunkable'
require 'external/utils'

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
  module Io
    include Chunkable
    
    PATCHES = []
    
    # Add version-specific patches
    case RUBY_VERSION
    when /^1.8/ then require "external/patches/ruby_1_8_io"
    end

    # Add platform-specific patches
    # case RUBY_PLATFORM
    # when 'java' 
    # end

    def self.extended(base)
      PATCHES.each {|patch| base.extend patch }
      base.reset_length
      base.default_blksize = 1024
      base.binmode
    end
    
    # True if self is a File
    def file?
      self.kind_of?(File)
    end

    # Modified truncate that adjusts length
    def truncate(n)
      super
      self.pos = n if self.pos > n
      self.length = n
    end
    
    # Resets length to the length returned by External::IO.length

    # Determines the length of the input io using the _length method
    # for the input io class.  Non-External::IO inputs are extended 
    # in this process.
    #
    # The _length method takes the input io, and should return the 
    # current length of the input io (ie a flush operation may be 
    # required). 
    # 
    # See try_handle for more details.
    def reset_length
      self.length = Utils.length(self)
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
      
      self.flush
      self.reset_length
      
      another.flush
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

      src.flush
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
      temp.extend Io
      temp.insert(self, range)
      temp.close

      cp = File.open(temp.path, mode)
      cp.extend Io

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