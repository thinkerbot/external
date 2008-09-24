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
#  By default read-only.  No insertions.  New ExtArr objects inherit parent mode.
#
#  Independent modes:
#  -  r
#  -  r+
#  -  For safety, w/w+ will by default act as r/r+, simply creating new .aio and .index files
#     changes to the originals will NOT be made unless .consolidate(rename) is used.  Allow option io_w => true 
#  -  b ALWAYS on with Windows
#++

# ExternalArchive provides array-like access to archival data stored on disk.
# ExternalArchives consist of an IO object and an index of [position, length]
# pairs which indicate the start position and length of entries in the IO.
# 
class ExternalArchive < External::Base
  class << self
    def [](*args)
      ab = self.new
      ab.concat(args)
      ab
    end
    
    def default_index_filepath(path)
      path.chomp(File.extname(path)) + '.index'
    end
  end
  
  # The underlying index of [position, length] arrays
  # indicating where entries in the io are located.
  attr_reader :io_index

  def initialize(io=nil, io_index=[])
    super(io)
    @io_index = io_index
  end
  
  # Returns another instance of self.class; the new 
  # instance will have an io_index of the same class
  # as the current io_index.
  def another
    self.class.new(nil, io_index.class.new)
  end

  protected
  
  # Converts an io_index entry to a position and length; provided as 
  # a hook to interface with an io_index that does not directly keep 
  # an array of [position, length] values.
  def io_entry_to_pos_length(array)
    array
  end
  
  # Converts a position and length to and io_index entry; provided as 
  # a hook to interface with an io_index that does not directly keep 
  # an array of [position, length] values.
  def pos_length_to_io_entry(pos, length)
    [pos, length]
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
  def reindex
    io_index.clear
    io.flush
    io.rewind
    yield(io, io_index)
    self
  end

  # The speed of reindex_by_regexp is dictated by how fast the underlying
  # code can match the pattern.  Under ideal conditions (ie a very simple 
  # regexp), it will be as fast as reindex_by_sep.
  def reindex_by_regexp(pattern=/\r?\n/, options={})
    options = {
      :range_or_span => nil,
      :blksize => 8388608,
      :carryover_limit => 8388608
    }.merge(options)
    
    reindex do |io, index|
      span = options[:range_or_span] || io.default_span
      blksize = options[:blksize]
      carryover_limit = options[:carryover_limit]

      io.scan(span, blksize, carryover_limit) do |scan_pos, string|
        scanner = StringScanner.new(string)
        while advanced = scanner.search_full(pattern, true, false)
          break unless advanced > 0
            
          index << pos_length_to_io_entry(scan_pos, advanced)
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
    
    reindex do |io, index|
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
          when 0 then pos_length_to_io_entry(scan_pos, advanced)
          when 2 then pos_length_to_io_entry(scan_pos-sep_length, advanced)
          else pos_length_to_io_entry(scan_pos, advanced-sep_length)
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
          pos_length_to_io_entry(io.length - remainder, remainder)
        else
          pos_length_to_io_entry(io.length - remainder - sep_length, remainder + sep_length)
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
    when ExtArr
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
      raise TypeError.new("can't convert from #{another.class} to ExtArr or Array")
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
  
  def [](input, length=nil)
    # two call types are required because while ExternalIndex can take 
    # a nil length, Array cannot and index can be either
    entries = (length == nil ? io_index[input] : io_index[input, length])
    
    # for conformance with array range retrieval
    return entries if entries.nil? || entries.empty?

    if length == nil && !input.kind_of?(Range)
      epos, elen = io_entry_to_pos_length(entries)
      
      # single entry, just read it
      io.pos = epos
      str_to_entry( io.read(elen) )
    else
      pos = nil
      entries.collect do |array|
        epos, elen = io_entry_to_pos_length(array)
        
        # only set io position if necessary
        unless pos == epos
          pos = epos
          io.pos = pos
        end
        
        pos += elen
        
        # read entry
        str_to_entry( io.read(elen) )
      end 
    end
  end
  
  def []=(*args)
    raise ArgumentError.new("wrong number of arguments (1 for 2)") if args.length < 2
    index, length, value = args
    value = length if args.length == 2
  
    if index.kind_of?(Range)
      raise TypeError.new("can't convert Range into Integer") if args.length == 3 
      # for conformance with setting a range with nil (truncates)
      value = [] if value.nil?
      offset, length = External::Chunkable.split_range(index)
      return (self[offset, length + 1] = value)
    end
  
    index += self.length if index < 0
    raise IndexError.new("index #{index} out of range") if index  < 0
  
    epos = self.io.length
    io.pos = epos
    
    if args.length == 2

      #value = self.to_a if value.kind_of?(ExternalIndex)
      
      # write entry to io first as a check
      # that io is open for writing.
      elen = io.write( entry_to_str(value) )
      io.length += elen

      self.io_index[index] = pos_length_to_io_entry(epos, elen, value)
  
    else
      indicies = []
      
      values = case value
      when Array then value
      when ExtArr
        if value.object_id == self.object_id
          # special case, self will be reading and
          # writing from the same io, producing 
          # incorrect results
          
          # potential to load a huge amount of data
          self.to_a
        else
          value
        end
      else 
        [value]
      end

      values.each do |value|
        elen = io.write( entry_to_str(value) )
        indicies << pos_length_to_io_entry(epos, elen, value)
        
        io.length += elen
        epos += elen
      end
      
      self.io_index[index, length] = indicies
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
    when Array, ExtArr
      another.each {|item| self[length] = item }
    else 
      raise TypeError.new("can't convert #{another.class} into ExtArr or Array")
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
    io_index.each do |array|
      epos, elen = io_entry_to_pos_length(array)
      
      # only set io position if necessary
      unless pos == epos
        pos = epos
        io.pos = pos
      end
      
      # advance position
      pos += elen
      
      # yield entry string
      yield io.read(elen)
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

  # Returns true if _self_ contains no elements
  def empty?
    length == 0
  end
  
  def eql?(another)
    self == another
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
  
  # Returns the first n entries (default 1)
  def first(n=nil)
    n.nil? ? self[0] : self[0,n]
  end
  
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
  def nitems
    count = self.length
    io_index.each do |array|
      epos, elen = io_entry_to_pos_length(array)
      
      # the logic of this search is that nil,
      # (and only nil ?) can have an entry 
      # length of 5:  nil.to_yaml == "--- \n"
      count -= 1 if elen == 5
    end
    count
  end
  
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
    io_index.reverse_each do |array|
      epos, elen = io_entry_to_pos_length(array)
      
      # A more optimized approach would
      # read in a chunk of entries and
      # iterate over them?
      io.pos = epos
      
      # yield entry string
      yield io.read(elen)
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