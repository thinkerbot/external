require 'external/base'
require 'ext_ind'
require 'strscan'

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

class ExtArc < External::Base
  class << self
    def [](*args)
      ab = self.new
      ab.concat(args)
      ab
    end
    
    def default_index_filepath(filepath)
      filepath.chomp(File.extname(filepath)) + '.index'
    end
  end
  
  attr_reader :_index

  def initialize(io=nil, options={})
    super(io)
    
    @_index = nil
    index_options = {
      :format => 'II', 
      :nil_value => [0,0], 
      :cached => options.has_key?(:cache_index) ? options[:cache_index] : true}
    initialize_index(options[:index], index_options)
  end
  
  def closed?
    super && (!_index.respond_to?(:close) || _index.closed?)
  end
  
  def close(path=nil, index_path=nil)
    if path != nil && index_path == nil
      index_path = self.class.default_index_filepath(path) 
    end
    
    _index.close(index_path)
    super(path)
  end
  
  def options
    { :index => (_index.cached? ? _index.cache : _index.io.path),
      :cache_index => _index.cached?}
  end
  
  # Returns another ExtArc, cached if self is cached.
  def another
    self.class.new(nil, :cache_index => _index.cached?)
  end

  protected
  
  # Set the index.  The index may be:
  # - An existing ExtInd (specified index options are ignored)
  # - An io, filepath, or nil
  #
  # In the latter cases the input is used to initialize an ExtInd
  # with the specified index options.  If nil is provided, and the
  # ExtArc io is a file, then the index will be initialized to the 
  # default_index_filepath for the file.
  #
  def initialize_index(index, index_options) 
    raise "index already initialized" unless @_index == nil
    
    @_index = case index
    when String, nil
      if io.kind_of?(File)
        index = self.class.default_index_filepath(io.path) if index == nil
        FileUtils.touch(index) unless File.exists?(index)
      end

      ExtInd.open(index, "r+", index_options)
    when Array 
      index << index_options
      ExtInd[*index]
    when ExtInd then index
    else
      # assume index is a kind of io and try to open it
      ExtInd.new(index, index_options)
    end
  end
  
  def reset_index
    _index.clear
    io.flush unless io.generic_mode == "r"
    io.rewind
    yield(_index) if block_given?
    self
  end
  
  def array_to_pl(array)
    array
  end
  
  def pl_to_array(pos, length, str=nil)
    [pos, length]
  end
  
  public
  
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
    
    reset_index do |index|
      span = options[:range_or_span] || io.default_span
      blksize = options[:blksize]
      carryover_limit = options[:carryover_limit]

      io.scan(span, blksize, carryover_limit) do |scan_pos, string|
        scanner = StringScanner.new(string)
        while advanced = scanner.search_full(pattern, true, false)
          break unless advanced > 0
            
          index.unframed_write pl_to_array(scan_pos, advanced)
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
    
    reset_index do |index|
      # calculate default span after reset_index in case any flush needs to happen
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
          arr = case mode
          when 0 then pl_to_array(scan_pos, advanced)
          when 2 then pl_to_array(scan_pos-sep_length, advanced)
          else
            pl_to_array(scan_pos, advanced-sep_length)
          end
          
          _index.unframed_write(arr)
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
        arr = if exclude_sep
          pl_to_array(io.length - remainder, remainder)
        else
          pl_to_array(io.length - remainder - sep_length, remainder + sep_length)
        end
        
        _index.unframed_write(arr)
      end   
    end
  end

  def str_to_entry(str)
    str
  end
  
  def entry_to_str(entry)
    entry.to_s
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
      if self._index == another._index
        
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

    when ExtArr
      # test simply based on length
      return false unless self.length == another.length
      
      # if indexes are equal, additional 
      # 'quick' comparisons are allowed 
      if self._index == another._index
           
        # equal in comparison if the ios are equal
        return true if (self.io.sort_compare(another.io, (self._index.buffer_size/2).ceil)) == 0
      end

      # compare arrays
      self.to_a == another.to_a
    else
      false
    end      
  end
  
  def [](input, length=nil)
    # two call types are required because while ExtInd can take 
    # a nil length, Array cannot and index can be either
    entries = (length == nil ? _index[input] : _index[input, length])
    
    # for conformance with array range retrieval
    return entries if entries.nil? || entries.empty?

    if length == nil && !input.kind_of?(Range)
      epos, elen = array_to_pl(entries)
      
      # single entry, just read it
      io.pos = epos
      str_to_entry( io.read(elen) )
    else
      pos = nil
      entries.collect do |array|
        epos, elen = array_to_pl(array)
        
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

      #value = self.to_a if value.kind_of?(ExtInd)
      
      # write entry to io first as a check
      # that io is open for writing.
      elen = io.write( entry_to_str(value) )
      io.length += elen

      self._index[index] = pl_to_array(epos, elen, value)
  
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
        indicies << pl_to_array(epos, elen, value)
        
        io.length += elen
        epos += elen
      end
      
      self._index[index, length] = indicies
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
    _index.clear
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
    _index.each do |array|
      epos, elen = array_to_pl(array)
      
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
  def each_index(&block) # :yield: index
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
    _index.length
  end
  
  # Returns the number of non-nil elements in self. May be zero.
  def nitems
    count = self.length
    _index.each do |array|
      epos, elen = array_to_pl(array)
      
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
    _index.reverse_each do |array|
      epos, elen = array_to_pl(array)
      
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