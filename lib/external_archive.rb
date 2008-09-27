require 'external/base'
require 'external_index'

#--
#  later separate out individual objects logically
#  If writing, create new files:
#    - base/object_id.aio     (new file for recieving appends)
#    - base/object_id._index  (copy of existing index -- made on first insertion)
#    - in index, -index indicates object_id.aio file whereas +index indicates original file
#    - .consolidate(rename) resolves changes in index into the object_id file, renaming as needed
#      requires index rewrite as well, to remove negatives
#
#  If appending, ONLY allow << and all changes get committed to the original file.
#
#  This should allow returning of new arrayio objects under read/write conditions
#  By default read-only.  No insertions.  New ExternalArchive objects inherit parent mode.
#
#  Independent modes:
#  -  r
#  -  r+
#  -  For safety, w/w+ will by default act as r/r+, simply creating new .aio and .index files
#     changes to the originals will NOT be made unless .consolidate(rename) is used.  Allow option io_w => true 
#  -  b ALWAYS on with Windows
#++

# ExternalArchive provides array-like access to archival data stored on disk.
# ExternalArchives consist of an IO object and an index of [start, length]
# pairs which indicate the start position and length of entries in the IO.
# 
class ExternalArchive < External::Base
  class << self
    
    # Array-like constructor for an ExternalArchive.
    def [](*args)
      extarc = new
      extarc.concat(args)
      extarc
    end
    
    # Returns the default io index filepath for path:
    #
    #   ExternalArchive.index_path("/path/to/file.txt")   # => "/path/to/file.index"
    #
    def index_path(path)
      path ? path.chomp(File.extname(path)) + '.index' : nil
    end
    
    # Initializes an instance of self with File.open(path, mode) as an io.
    # As with File.open, the instance will be passed to the block and
    # closed when the block returns.  If no block is given, open returns
    # the new instance.
    #
    # By default the instance will be initialized with an ExternalIndex 
    # io_index, linked to index_path(path). The instance will be 
    # automatically reindexed if it is empty but it's io is not.
    #
    # Options (specify using symbols):
    # io_index:: Specifies the io_index manually.  A filepath may be
    #            provided and it will be used instead of index_path(path).
    #            Array and ExternalIndex values are used directly.
    # reindex:: Forces a call to reindex; using auto reindexing, reindex
    #           is normally only called when the instance is empty
    #           and the instance io is not. (default false)
    # auto_reindex:: Turns on or off auto reindexing (default true)
    #
    def open(path, mode="rb", options={})
      options = {
        :io_index => nil,
        :reindex => false,
        :auto_reindex => true
      }.merge(options)
      
      index = options[:io_index]
      if index == nil
        index = index_path(path)
        FileUtils.touch(index) unless File.exists?(index)
      end
      
      io_index = case index
      when Array, ExternalIndex then index
      else ExternalIndex.open(index, 'r+', :format => 'II')
      end
      
      io = path == nil ? nil : File.open(path, mode)
      extarc = new(io, io_index)
      
      # reindex if necessary
      if options[:reindex] || (options[:auto_reindex] && extarc.empty? && extarc.io.length > 0)
        extarc.reindex
      end
      
      if block_given?
        begin
          yield(extarc)
        ensure
          extarc.close
        end
      else
        extarc
      end
    end
  end
  
  # The underlying index of [position, length] arrays
  # indicating where entries in the io are located.
  attr_reader :io_index

  def initialize(io=nil, io_index=nil)
    super(io)
    @io_index = io_index || []
  end
  
  # Returns true if io_index is an Array.
  def cached?
    io_index.kind_of?(Array)
  end
  
  # Turns on or off caching by converting io_index
  # to an Array (cache=true) or to an ExternalIndex
  # (cache=false).
  def cache=(input)
    case
    when input && !cached?
      cache = io_index.to_a
      io_index.close
      @io_index = cache
      
    when !input && cached?
      io_index << {:format => 'II'}
      @io_index = ExternalIndex[*io_index]
      
    end
  end
  
  # Closes self as in External::Base#close.  An io_path may be
  # be specified to close io_index as well; when io_index is
  # not an ExternalIndex, one is temporarily created with the
  # current io_index content to 'close' and save the index.
  def close(path=nil, index_path=self.class.index_path(path), overwrite=false)
    case 
    when io_index.kind_of?(ExternalIndex)
      io_index.close(index_path, overwrite)
    when index_path != nil
      ExternalIndex[*io_index].close(index_path, overwrite)
    end
    
    super(path, overwrite)
  end
  
  # Returns another instance of self.class; the new instance will 
  # be cached if self is cached.
  def another
    self.class.new(nil, cached? ? [] : io_index.another)
  end

  public
  
  # Converts an string read from io into an entry.  By default
  # the string is simply returned.
  def str_to_entry(str)
    str
  end
  
  # Converts an entry into a string.  By default this method
  # returns entry.to_s.
  def entry_to_str(entry)
    entry.to_s
  end
  
  # Clears the io_index, and yields io and the io_index to the
  # block for reindexing.  The io is flushed and rewound before
  # being yielded to the block.  Returns self
  def reset_index
    io_index.clear
    io.flush
    io.rewind
    yield(io, io_index) if block_given?
    self
  end
  
  alias reindex reset_index
  
  # The speed of reindex_by_regexp is dictated by how fast the underlying
  # code can match the pattern.  Under ideal conditions (ie a very simple 
  # regexp), it will be as fast as reindex_by_sep.
  def reindex_by_regexp(pattern=/\r?\n/, options={})
    options = {
      :range_or_span => nil,
      :blksize => 8388608,
      :carryover_limit => 8388608
    }.merge(options)
    
    reset_index do |io, index|
      span = options[:range_or_span] || io.default_span
      blksize = options[:blksize]
      carryover_limit = options[:carryover_limit]

      io.scan(span, blksize, carryover_limit) do |scan_pos, string|
        scanner = StringScanner.new(string)
        while advanced = scanner.search_full(pattern, true, false)
          break unless advanced > 0
            
          index << [scan_pos, advanced]
          scan_pos += advanced 
        end
        
        # allow a blockfor monitoring
        yield if block_given?
        scanner.rest_size
      end
    end
  end
  
  def reindex_by_sep(sep_str=$/, options={}) 
    sep_str = sep_str.to_s
    options = {
      :sep_regexp => Regexp.new(sep_str),
      :sep_length => sep_str.length,
      :entry_follows_sep => false,
      :exclude_sep => false,
      :range_or_span => nil,
      :blksize => 8388608,
      :carryover_limit => 8388608
    }.merge(options)
    
    regexp = options[:sep_regexp]
    sep_length = options[:sep_length]
    entry_follows_sep = options[:entry_follows_sep]
    exclude_sep = options[:exclude_sep]
    
    mode = case
    when !entry_follows_sep && !exclude_sep then 0
    when entry_follows_sep && exclude_sep then 1
    when entry_follows_sep && !exclude_sep then 2
    when !entry_follows_sep && exclude_sep then 3
    end
    
    reset_index do |io, index|
      # calculate default span after resetio_index in case any flush needs to happen
      span = options[:range_or_span] || io.default_span
      blksize = options[:blksize]
      carryover_limit = options[:carryover_limit]
      
      remainder = io.scan(span, blksize, carryover_limit) do |scan_pos, string|
        scanner = StringScanner.new(string)
        
        # When the entry follows the separator, the scanner must
        # be set right after the separator for the first entry, so
        # that the search will find the beginning of the next entry.
        if scan_pos == 0 && entry_follows_sep
          scanner.pos = sep_length
          scan_pos = sep_length
        end

        # Scan for entries documents by looking for the beginning
        # of the next entry,  signaling the end of the current entry.
        while advanced = scanner.skip_until(regexp)
        
          # adjust indicies as needed...
          io_index << case mode
          when 0 then [scan_pos, advanced]
          when 2 then [scan_pos-sep_length, advanced]
          else [scan_pos, advanced-sep_length]
          end
          
          scan_pos += advanced
        end
        
        # allow a blockfor monitoring
        yield if block_given?
        scanner.rest_size
      end
      
      # Unless the io is empty, there will be a remaining entry that 
      # doesn't get scanned when the entry follows the separator.  
      # Add the entry here.
      if entry_follows_sep && io.length != 0
        io_index << if exclude_sep
          [io.length - remainder, remainder]
        else
          [io.length - remainder - sep_length, remainder + sep_length]
        end
      end   
    end
  end
  
  ###########################
  # Array methods
  ###########################
  
  # def &(another)
  #   not_implemented
  # end
  
  # def *(arg)
  #   not_implemented
  # end
  
  def +(another)
    self.concat(another)
  end
  
  # def -(another)
  #   not_implemented
  # end
  
  def <<(obj)
    self[length] = obj
    self
  end
  
  def <=>(another)
    case another
    when Array
      if another.length < self.length
        # if another is equal to the matching subset of self,
        # then self is obviously the longer array and wins.
        result = (self.to_a(another.length) <=> another)
        result == 0 ? 1 : result
      else
        self.to_a <=> another
      end
    when ExternalArray
      # if indexes are equal, additional 
      # 'quick' comparisons are allowed 
      if self.io_index == another.io_index
        
        # equal in comparison if the ios are equal
        return 0 if self.io.quick_compare(another.io)
      end
      
      self.io.flush
      another.io.flush
      
      # should chunk compare
      if another.length > self.length
        result = (self.to_a <=> another.to_a(self.length))
        result == 0 ? -1 : result
      elsif another.length < self.length
        result = (self.to_a(another.length) <=> another.to_a)
        result == 0 ? 1 : result
      else
        self.to_a <=> another.to_a
      end
    else
      raise TypeError.new("can't convert from #{another.class} to ExternalArchive or Array")
    end
  end

  def ==(another)
    case another
    when Array
      # test simply based on length
      return false unless self.length == another.length

      # compare arrays
      self.to_a == another

    when ExternalArchive
      # test simply based on length
      return false unless self.length == another.length
      
      # if indexes are equal, additional 
      # 'quick' comparisons are allowed 
      if self.io_index == another.io_index
           
        # equal in comparison if the ios are equal
        #, (self.io_index.buffer_size/2).ceil) ??
        return true if self.io.sort_compare(another.io) == 0
      end

      # compare arrays
      self.to_a == another.to_a
    else
      false
    end      
  end
  
  # Element Reference — Returns the entry at index, or returns an array starting 
  # at start and continuing for length entries, or returns an array specified 
  # by range. Negative indices count backward from the end of self (-1 is the last 
  # element). Returns nil if the index (or starting index) is out of range.
  #
  #    a = ExternalArchive[ "a", "b", "c", "d", "e" ]
  #    a[2] +  a[0] + a[1]    #=> "cab"
  #    a[6]                   #=> nil
  #    a[1, 2]                #=> [ "b", "c" ]
  #    a[1..3]                #=> [ "b", "c", "d" ]
  #    a[4..7]                #=> [ "e" ]
  #    a[6..10]               #=> nil
  #    a[-3, 3]               #=> [ "c", "d", "e" ]
  #    # special cases
  #    a[5]                   #=> nil
  #    a[5, 1]                #=> []
  #    a[5..10]               #=> []
  # 
  def [](input, length=nil)
    # two call types are required because while ExternalIndex can take 
    # a nil length, Array cannot and index can be either
    entry_indicies = (length == nil ? io_index[input] : io_index[input, length])
    
    case
    when entry_indicies == nil || entry_indicies.empty?
      # for conformance with array range retrieval,
      # simply return nil and [] indicies
      entry_indicies
      
    when length == nil && !input.kind_of?(Range)
      # a single entry was specified, read it
      entry_start, entry_length = entry_indicies
      io.pos = entry_start
      str_to_entry( io.read(entry_length) )
      
    else
      # multiple entries were specified, collect each
      pos = nil
      entry_indicies.collect do |(entry_start, entry_length)|
        next if entry_start == nil
 
        # only set io position if necessary
        unless pos == entry_start
          pos = entry_start
          io.pos = pos
        end
        
        pos += entry_length
        
        # read entry
        str_to_entry( io.read(entry_length) )
      end 
    end
  end
  
  # Element Assignment — Sets the entry at index, or replaces a subset starting at start
  # and continuing for length entries, or replaces a subset specified by range.
  # A negative indices will count backward from the end of self. Inserts elements if 
  # length is zero. If nil is used in the second and third form, deletes elements from 
  # self. An IndexError is raised if a negative index points past the beginning of self. 
  # See also push, and unshift.
  #
  #   a = ExternalArchive.new
  #   a[4] = "4"; a                  #=> [nil, nil, nil, nil, "4"]
  #   a[0, 3] = [ 'a', 'b', 'c' ]; a #=> ["a", "b", "c", nil, "4"]
  #   a[1..2] = [ '1', '2' ]; a      #=> ["a", '1', '2', nil, "4"]
  #   a[0, 2] = "?"; a               #=> ["?", '2', nil, "4"]
  #   a[0..2] = "A"; a               #=> ["A", "4"]
  #   a[-1]   = "Z"; a               #=> ["A", "Z"]
  #   a[1..-1] = nil; a              #=> ["A"]
  # 
  def []=(*args)
    raise ArgumentError, "wrong number of arguments (1 for 2)" if args.length < 2
    
    one, two, value = args
    if args.length == 2
      value = two 
      two = nil
    end

    one = convert_to_int(one)
    case one
    when Fixnum
      if one < 0
        one += length
        raise IndexError, "index #{one} out of range" if one  < 0
      end
      
      entry_start = io.length
      io.pos = entry_start
      
      if two == nil
        # simple insertion 
        # (note it is important to write the entry to io 
        # first as a check that io is open for writing)

        entry_length = io.write( entry_to_str(value) )
        io.length += entry_length
        io_index[one] = [entry_start, entry_length]
        
      else
        values = case value
        when Array then value
        when ExternalArchive
          # special case, self will be reading and
          # writing from the same io, producing 
          # incorrect results
          
          # potential to load a huge amount of data
          value == self ? value.to_a : value
        else convert_to_ary(value)
        end
        
        # write each value to self, collecting the indicies
        indicies = []
        values.each do |value|
          entry_length = io.write( entry_to_str(value) )
          indicies << [entry_start, entry_length]
          
          io.length += entry_length
          entry_start += entry_length
        end
        
        # register the indicies
        io_index[one, two] = indicies
      end

    when Range
      raise TypeError, "can't convert Range into Integer" unless two == nil
      start, length, total = split_range(one)
      
      raise RangeError, "#{one} out of range" if start < 0
      self[start, length < 0 ? 0 : length + 1] = value

    when nil
      raise TypeError, "no implicit conversion from nil to integer"
    else
      raise TypeError, "can't convert #{one.class} into Integer"
    end
  end

  # def abbrev(pattern=nil)
  #   not_implemented
  # end
  
  # def assoc(obj)
  #   not_implemented
  # end
  
  # Returns entry at index
  def at(index)
    self[index]
  end

  # Removes all elements from _self_.
  def clear
    io.truncate(0)
    io_index.clear
    self
  end

  def compact
    # TODO - optimize?
    another = self.another
    each do |item|
      another << item unless item == nil
    end
    another
  end

  # def compact!
  #   not_implemented
  # end

  def concat(another)
    case another
    when Array, ExternalArchive
      self[length, another.length] = another
    else 
      raise TypeError.new("can't convert #{another.class} into ExternalArchive or Array")
    end
    self
  end
  
  # def dclone
  #   not_implemented
  # end
  
  # def delete(obj)
  #   not_implemented
  # end
  
  # def delete_at(index)
  #   not_implemented
  # end
  
  # def delete_if # :yield: item
  #   not_implemented
  # end
  
  # Calls block once for each element string in self, passing that string as a parameter.
  def each_str(&block) # :yield: string
    # tracking the position using a local variable 
    # is faster than calling io.pos.  
    pos = nil
    io_index.each do |(start, length)|
      if start == nil
        yield("")
        next  
      end
      
      # only set io position if necessary
      unless pos == start
        pos = start
        io.pos = pos
      end
      
      # advance position
      pos += length
      
      # yield entry string
      yield io.read(length)
    end
    self
  end
  
  # Calls block once for each element in self, passing that element as a parameter.
  def each(&block) # :yield: item
    each_str do |str|
      # yield entry
      yield str_to_entry(str)
    end
  end
  
  # Same as each, but passes the index of the element instead of the element itself.
  def eachio_index(&block) # :yield: index
    0.upto(length-1, &block)
    self
  end
  
  # def fetch(index, default=nil, &block)
  #   index += index_length if index < 0 
  #   val = (index >= length ? default : self[index])
  #   block_given? ? yield(val) : val
  # end
  # 
  # def fill(*args)
  #   not_implemented
  # end
  
  # def flatten
  #   not_implemented
  # end
  
  # def flatten!
  #   not_implemented
  # end
  
  # def frozen?
  #   not_implemented
  # end
  
  # def hash
  #   not_implemented
  # end
  
  # def include?(obj)
  #   not_implemented
  # end
  
  # def index(obj)
  #   not_implemented
  # end
  # 
  # def indexes(*args)
  #   values_at(*args)
  # end
  # 
  # def indicies(*args)
  #   values_at(*args)
  # end
  
  # def replace(other)
  #   not_implemented
  # end
  
  # def insert(index, *obj)
  #   self[index] = obj
  # end
  
  # def inspect
  #   not_implemented
  # end

  # def join(sep=$,)
  #   not_implemented
  # end
  
  # Returns the last n entries (default 1)
  def last(n=nil)
    return self[-1] if n.nil?
  
    start = length-n
    start = 0 if start < 0
    self[start, n]
  end
  
  # Returns the number of entries in self
  def length 
    io_index.length
  end
  
  # Returns the number of non-nil elements in self. May be zero.
  # def nitems
  #   count = self.length
  #   io_index.each do |(start, length)|
  #     # the logic of this search is that nil,
  #     # (and only nil ?) can have an entry 
  #     # length of 5:  nil.to_yaml == "--- \n"
  #     count -= 1 if length == nil || length == 5
  #   end
  #   count
  # end
  
  # def pack(aTemplateString)
  #   not_implemented
  # end
  
  # def pop
  #   not_implemented
  # end
  
  # def pretty_print(q)
  #   not_implemented
  # end
  
  # def pretty_print_cycle(q)
  #   not_implemented
  # end
  
  def push(*obj)
    obj.each {|obj| self << obj }
    self
  end
  
  # def quote
  #   not_implemented
  # end
  
  # def rassoc(key)
  #   not_implemented
  # end
  
  # def replace(another)
  #   not_implemented
  # end
  
  # def reverse
  #   not_implemented
  # end
  
  # def reverse!
  #   not_implemented
  # end
  
  def reverse_each_str(&block) # :yield: string
    io_index.reverse_each do |(start,length)|
      next if start == nil

      # A more optimized approach would
      # read in a chunk of entries and
      # iterate over them?
      io.pos = start
      
      # yield entry string
      yield io.read(length)
    end
    self
  end
  
  def reverse_each # :yield: item
    reverse_each_str do |str|
      yield( str_to_entry(str) )
    end
  end
  
  # def rindex(obj)
  #   not_implemented
  # end
  
  # def select # :yield: item
  #   not_implemented
  # end
  
  # def shift
  #   not_implemented
  # end
  
  # Alias for length
  def size
    length
  end
   
  # def slice(*args)
  #   self.call(:[], *args)
  # end
  
  # def slice!(*args)
  #   not_implemented
  # end

  def to_a(length=self.length)
    length == 0 ? [] : self[0, length]
  end
  
  # def to_ary
  #   not_implemented
  # end

  # Returns _self_.join.
  # def to_s
  #   self.join
  # end
  
  # def to_yaml(opts={})
  #   self[0, self.length].to_yaml(opts)
  # end
  
  # def transpose
  #   not_implemented
  # end
  
  # def uniq
  #   not_implemented
  # end
  
  # def uniq!
  #   not_implemented
  # end
  
  # def unshift(*obj)
  #   not_implemented
  # end
  
  # Returns an array containing the chars in io corresponding to the given
  # selector(s). The selectors may be either integer indices or ranges
  def values_at(*selectors)
    another = self.another
    selectors.each do |s| 
      another << self[s]
    end
    another
  end
  
  # def yaml_initialize(tag, val)
  #   not_implemented
  # end
  
  # def |(another)
  #   not_implemented
  # end
end