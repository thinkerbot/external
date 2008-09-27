require 'external/chunkable'
require 'external/utils'

autoload(:StringIO, 'stringio')
autoload(:Tempfile, 'tempfile')
autoload(:FileUtils, 'fileutils')

module External
  
  # Adds functionality to an IO required by External. 
  #
  # IO adds/overrides the length accessor for getting the size of the IO contents.  
  # Note that length is not automatically adjusted by write, for performance
  # reasons.  length must be managed manually, or reset after writes using
  # reset_length.
  #
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
    
    # Resets length to the length returned by Utils.length
    def reset_length
      self.length = Utils.length(self)
    end

    # Modified truncate that adjusts length
    def truncate(n)
      super
      self.pos = n if self.pos > n
      self.length = n
    end
    
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
    
    # Quick comparision with another IO.  Returns true if
    # another == self, or if both are file-type IOs and 
    # their paths are equal.
    def quick_compare(another)
      self == another || (self.kind_of?(File) && another.kind_of?(File) && self.path == another.path)
    end

    # Sort compare (ie <=>) with another IO, behaving like 
    # a comparison between the full string contents of self 
    # and another.  This obviously can be a long operation
    # if it requires the full read of two large IO objects.
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
    
    # Alias for sort_compare.
    def <=>(another)
      sort_compare(another)
    end
  end
end