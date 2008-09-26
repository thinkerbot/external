require 'external/base'
require 'strscan'

# Provides array-like access to index data kept on disk.  Index data is
# defined by a packing format (see Array#pack) like 'II', which would 
# represent two integers; in this case each member of the ExternalIndex
# would be a two-integer array.  
#
# All directives except '@' and 'X' are allowed, in any combination. 
#
#--
# not implemented --
# dclone, flatten, flatten!, frozen?, pack, quote, to_yaml, transpose, yaml_initialize
#
# be careful accession io directly.  for peformance reasons there is no check to make
# sure io is in register (ie pos is at a frame boundary, ie io.length % frame_size == 0)
# In addition, note that length must be adjusted manually in most io operations (truncate is
# the exception).  Thus if you change the file length by any means, the file length must be
# reset.
class ExternalIndex < External::Base
  
  class << self
    
    # Initializes a new ExternalIndex using an array-like [] syntax.
    # The last argument may be an options hash (this is ok since
    # ExternalIndex cannot store a Hash anyhow).
    def [](*argv)
      options = argv.last.kind_of?(Hash) ? argv.pop : {}
      index = new(nil, options)
      
      normalized_args = argv.collect do |item| 
        item.nil? ? index.nil_value : item
      end.flatten
      index.unframed_write(normalized_args)
      
      # reset the position of the IO under this initialize
      index.pos = 0
      index
    end
    
    # Opens and reads the file into an array.
    def read(fd, options={})
      return [] if fd.nil?
      open(fd, "r", options) do |index|
        index.read(nil, 0)
      end
    end
    
    # Returns the number of bytes required to pack an item in an array
    # using the directive (see Array.pack for more details).  All directives
    # return a size except the positioning directives '@' and 'X'; these
    # and all other unknown directives return nil.
    #
    #   Directives          N bytes
    #   ------------------------------
    #   AaBbCcHhUwxZ     |   1
    #   nSsv             |   2
    #   M                |   3
    #   eFfgIiLlNPpV     |   4
    #   m                |   5
    #   u                |   6
    #   DdEGQq           |   8
    #   @X               |   nil
    def directive_size(directive)
      case directive
      when /^[eFfgIiLlNPpV]$/ then 4
      when /^[DdEGQq]$/ then 8
      when /^[AaBbCcHhUwxZ]$/ then 1
      when /^[nSsv]$/ then 2
      when 'M' then 3
      when 'm' then 5
      when 'u' then 6
      else
        nil
      end
    end
    
    # Returns an array of zeros in the specified frame.
    def default_nil_value(format, frame)
      Array.new(frame, 0)
    end
  end
  
  # The format of the indexed data.  Format may be optimized from 
  # the original input format in cases like 'III' where bulk
  # processing is useful.
  attr_reader :format
  
  # The number of elements in each entry, ex: ('I' => 1, 'III' => 3).  
  # frame is calculated from format.
  attr_reader :frame
  
  # The number of bytes required for each entry; frame_size is
  # calculated from format.
  attr_reader :frame_size
  
  # A flag indicating whether or not the format was optimized
  # to pack/unpack entries in bulk; proccess_in_bulk is
  # automatically set according to format.
  attr_reader :process_in_bulk
  
  # The default buffer size (8Mb)
  DEFAULT_BUFFER_SIZE = 8 * 2**20     
  
  def initialize(io=nil, options={})
    super(io)
    
    options = {
      :format => "I",
      :nil_value => nil,
      :buffer_size => DEFAULT_BUFFER_SIZE
    }.merge(options)
  
    # set the format, frame, and frame size
    format = options[:format]
    @frame = 0
    @frame_size = 0
    @process_in_bulk = true
    
    scanner = StringScanner.new(format)
    if scanner.skip(/\d+/)
      # skip leading numbers ... they are normally ignored
      # by pack and unpack but you could raise an error.
    end

    bulk_directive = nil
    while directive = scanner.scan(/./)
      size = ExternalIndex.directive_size(directive)
      raise ArgumentError.new("cannot determine size of: '#{directive}'") if size == nil
      
      # scan for a multiplicity factor
      multiplicity = (scanner.scan(/\d+/) || 1).to_i
      @frame += multiplicity
      @frame_size += size * multiplicity
      
      # if the bulk directive changes, 
      # processing in bulk is impossible
      if bulk_directive == nil
        bulk_directive = directive
      elsif bulk_directive != directive
        @process_in_bulk = false
      end
    end
    
    # The "a" and "A" directives cannot be
    # processed in bulk.
    if ['a','A'].include?(bulk_directive)
      @process_in_bulk = false
    end
    
    # Repetitive formats like "I", "II", "I2I", 
    # etc can be packed and unpacked in bulk.
    @format = process_in_bulk ? "#{bulk_directive}*" : format
    
    # set the buffer size
    self.buffer_size = options[:buffer_size]
    
    # set the nil value to an array of zeros, or
    # to the specified nil value.  If a nil value
    # was specified, ensure it is of the correct
    # frame size and can be packed
    nil_value = if options[:nil_value] == nil 
      self.class.default_nil_value(format, frame)
    else
      options[:nil_value]
    end
    
    begin 
      @nil_value = nil_value.pack(format)
      unless nil_value.length == frame && @nil_value.unpack(format) == nil_value
        raise "" # just to invoke the rescue block
      end
    rescue
      raise ArgumentError, 
        "unacceptable nil value '#{nil_value}': the nil value must " +
        "be in frame and packable using the format '#{format}'"
    end
  end
  
  # Returns the buffer size of self (equal to io.default_blksize and 
  # default_blksize * frame_size).  Buffer size specifies the memory
  # available for io perform external operations.
  def buffer_size
    self.io.default_blksize
  end
  
  # Sets the buffer size of self (as well as io.default_blksize and 
  # self.default_blksize).  See buffer_size. 
  def buffer_size=(buffer_size)
    raise ArgumentError.new("buffer size must be > 0") if buffer_size <= 0
    
    @default_blksize = (buffer_size/frame_size).ceil
    self.io.default_blksize = buffer_size
  end
  
  # Returns the default_blksize of self.  See buffer_size.
  def default_blksize=(value)
    @default_blksize = value
    self.io.default_blksize = value * frame_size
  end
    
  # Returns the string value used for nils.  Specify unpacked to 
  # show the unpacked array value.
  #
  #   index = ExternalIndex.new 
  #   index.nil_value            # => [0]
  #   index.nil_value(false)     # => "\000\000\000\000"
  #
  def nil_value(unpacked=true)
    unpacked ? @nil_value.unpack(format) : @nil_value
  end
  
  # An array of the index attributes of self: [frame, format, nil_value]
  def index_attrs
    [frame, format, nil_value]
  end
  
  # Returns initialization options for the current settings of self.
  def options
    { :format => process_in_bulk ? format[0,1] * frame : format,
      :nil_value => nil_value,
      :buffer_size => buffer_size}
  end
  
  # Returns another instance of self.class,
  # initialized with the current options of self.
  def another
    self.class.new(nil, options)
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
  
  def dup
    self.flush
    another.concat(self)
  end

  def +(another)
    dup.concat(another)
  end

  # def -(another)
  #   not_implemented
  # end

  # Differs from the Array << in that multiple entries
  # can be shifted on at once.  
  def <<(array)
    unframed_write(array, length)
    self
  end
  
  def <=>(another)
    return 0 if self.object_id == another.object_id
    
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
    when ExternalIndex
      self.io.sort_compare(another.io, (buffer_size/2).ceil)
    else
      raise TypeError.new("can't convert from #{another.class} to ExternalIndex or Array")
    end
  end

  def ==(another)
    return true if super
    
    case another
    when Array
      return false if self.length != another.length
      self.to_a == another
      
    when ExternalIndex
      return false if self.length != another.length || self.index_attrs != another.index_attrs
      return true  if (self.io.sort_compare(another.io, (buffer_size/2).ceil)) == 0
 
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
  #   index = ExternalIndex[1,2,3,4,5]
  #   index[2]                   #=> [3]
  #   index[6]                   #=> nil
  #   index[1, 2]                #=> [[2],[3]]
  #   index[1..3]                #=> [[2],[3],[4]]
  #   index[4..7]                #=> [[5]]
  #   index[6..10]               #=> nil
  #   index[-3, 3]               #=> [[3],[4],[5]]
  #
  #   # special cases
  #   index[5]                   #=> nil
  #   index[5, 1]                #=> []
  #   index[5..10]               #=> []
  #
  # Note that entries are returned in frame.
  def [](one, two = nil)
    one = convert_to_int(one)
    
    case one
    when Fixnum
      
      # normalize the index
      if one < 0
        one += length 
        return nil if one < 0
      end

      if two == nil 
        at(one)            # read one, no frame
      else
        two = convert_to_int(two)
        return nil if two < 0 || one > length
        return []  if two == 0 || one == length
        
        read(two, one)     # read length, framed
      end
      
    when Range
      raise TypeError, "can't convert Range into Integer" unless two == nil
      
      # total is the length of self
      total = length
      
      # split the range
      start = convert_to_int(one.begin)
      start += total if start < 0
      
      finish = convert_to_int(one.end)
      finish += total if finish < 0
      
      length = finish - start
      length -= 1 if one.exclude_end?
  
      # (identical to those above...)
      return nil if start < 0 || start > total
      return []  if length < 0 || start == total
      
      read(length + 1, start)  # read length, framed
      
    when nil
      raise TypeError, "no implicit conversion from nil to integer"
    else
      raise TypeError, "can't convert #{one.class} into Integer"
    end
  end

  # Element Assignment — Sets the entry at index, or replaces a subset starting at start
  # and continuing for length entries, or replaces a subset specified by range.
  # A negative indices will count backward from the end of self. Inserts elements if 
  # length is zero. If nil is used in the second and third form, deletes elements from 
  # self. An IndexError is raised if a negative index points past the beginning of self. 
  # See also push, and unshift.
  #
  #   io = StringIO.new ""
  #   i = ExternalIndex.new(io, :format => 'I')
  #   i.nil_value                  # => [0]
  #   i[4] = [4]                   # => [[0], [0], [0], [0], [4]]
  #   i[0, 3] = [ [1], [2], [3] ]  # => [[1], [2], [3], [0], [4]]
  #   i[1..2] = [ [5], [6] ]       # => [[1], [5], [6], [0], [4]]
  #   i[0, 2] = [ [7] ]            # => [[7], [6], [0], [4]]
  #   i[0..2] = [ [8] ]            # => [[8], [4]]
  #   i[-1]   = [9]                # => [[8], [9]]
  #   i[1..-1] = nil               # => [[8]]
  #
  # Note that []= can only take entries in frame, or (in the case of [offset, length] and 
  # range insertions) another ExternalIndex with the same frame, format, and nil_value.
  #--
  # TODO -- cleanup error messages so they are more meaningful 
  # and helpful, esp for frame errors
  #++
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
      
      if two == nil
        # simple insertion 
        unframed_write(value == nil ? nil_value : value, one)
      else
        two = convert_to_int(two)
        raise IndexError, "negative length (#{two})" if two < 0
        
        value = [] if value == nil
        value = convert_to_ary(value)
        
        case
        when self == value
          # special case when insertion is self (no validation needed)
          # A whole copy of self is required because the insertion 
          # can overwrite the tail of self.  As such this can be a
          # worst-case scenario-slow and expensive procedure.
          copy_beg = (one + two) * frame_size
          copy_end = io.length
        
          io.copy do |copy|
            # truncate io
            io.truncate(one * frame_size)
            io.pos = io.length
        
            # pad as needed
            pad_to(one) if one > length
        
            # write the copy of self
            io.insert(copy)
        
            # copy the tail of the insertion
            io.insert(copy, copy_beg..copy_end)
          end
        
        when value.length == two
          # optimized insertion, when insertion is the correct length
          write(value, one)
        
        else
          # range insertion: requires copy and rewrite of the tail 
          # of the ExternalIndex, after the insertion.
          # WARN - can be slow when the tail is large
          copy_beg = (one + two) * frame_size
          copy_end = io.length
        
          io.copy("r", copy_beg..copy_end) do |copy|
            # pad as needed
            pad_to(one) if one > length
        
            # write inserted value
            io.pos = one * frame_size
            write(value)
        
            # truncate io
            io.truncate(io.pos)
        
            # copy the tail of the insertion
            io.insert(copy)
          end
        end
      end

    when Range
      raise TypeError, "can't convert Range into Integer" unless two == nil
      
      # total is the length of self
      total = length
      
      # split the range
      start = convert_to_int(one.begin)
      raise TypeError, "can't convert #{one.begin.class} into Integer" unless start.kind_of?(Integer)
      start += total if start < 0
      
      finish = convert_to_int(one.end)
      raise TypeError, "can't convert #{one.end.class} into Integer" unless finish.kind_of?(Integer)
      finish += total if finish < 0
      
      length = finish - start
      length -= 1 if one.exclude_end?
      
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
    if index >= length || (index < 0 && index < -length)
      nil
    else
      str = readbytes(1, index)
      str == nil ? nil : str.unpack(format)
    end
  end

  # Removes all elements from _self_.
  def clear
    io.truncate(0)
    self
  end

  # Returns a copy of self with all nil entries removed. Nil 
  # entries are those which equal nil_value.
  #
  # <em>potentially expensive</em>
  def compact
    another = self.another
    nil_array = self.nil_value
    each do |array|
      another << array unless array == nil_array
    end
    another
  end

  # def compact!
  #   not_implemented
  # end

  # Appends the entries in another to self.  Another may be an array
  # of entries (in frame), or another ExternalIndex with corresponding 
  # index_attrs.
  #
  # <em>potentially expensive</em> especially if another is very 
  # large, or if it must be loaded into memory to be concatenated, 
  # ie when cached? = true.
  def concat(another)
    case another
    when Array
      write(another, length)
    when ExternalIndex 
      check_index(another)
      io.concat(another.io)
    else 
      raise TypeError.new("can't convert #{another.class} into ExternalIndex or Array")
    end
    self
  end

  # def delete(obj)
  #   not_implemented
  # end

  # def delete_at(index)
  #   not_implemented
  # end

  # def delete_if # :yield: item
  #   not_implemented
  # end

  # Calls block once for each entry in self, passing that entry as a parameter.
  def each(&block) # :yield: entry
    self.pos = 0
    chunk do |offset, length|
      # special treatment for 1, because then read(1) => [...] rather
      # than [[...]].  when frame > 1, each will iterate over the 
      # element rather than pass it to the block directly
      read(length).each(&block)
    end
    self
  end

  # Same as each, but passes the index of the entry instead of the entry itself.
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

  # def fill(*args)
  #   not_implemented
  # end

  # Returns the first n entries (default 1)
  def first(n=nil)
    n.nil? ? self[0] : self[0,n]
  end

  # def hash
  #   not_implemented
  # end

  # def include?(obj)
  #   not_implemented
  # end

  # def index(obj)
  #   not_implemented
  # end

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
    io.length/frame_size
  end

  # Returns the number of non-nil entries in self. Nil entries  
  # are those which equal nil_value. May be zero.
  def nitems
    # TODO - seems like this could be optimized 
    # to run without unpacking each item...
    count = self.length
    nil_array = self.nil_value
    each do |array|
      count -= 1 if array == nil_array
    end
    count
  end

  # def pop
  #   not_implemented
  # end

  # def pretty_print(q)
  #   not_implemented
  # end

  # def pretty_print_cycle(q)
  #   not_implemented
  # end

  # Append — Pushes the given entry(s) on to the end of self. 
  # This expression returns self, so several appends may be 
  # chained together. Pushed entries must be in frame.
  def push(*array)
    write(array, length)
    self
  end

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

  # Same as each, but traverses self in reverse order.
  def reverse_each(&block)
    reverse_chunk do |offset, length|
      # special treatment for 1, because then read(1) => [...] rather
      # than [[...]].  when frame > 1, each will iterate over the 
      # element rather than pass it to the block directly
      read(length, offset).reverse_each(&block)
    end
    self
  end

  # def rindex(obj)
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

  # Converts self to an array, or returns the cache if cached?.
  def to_a
    length == 0 ? [] : read(length, 0)
  end
  
  # Returns self.
  def to_ary
    self
  end

  # Returns _self_.join.
  # def to_s
  #   self.join
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

  # Returns a copy of self containing the entries corresponding to the 
  # given selector(s). The selectors may be either integer indices or 
  # ranges.
  #
  # <em>potentially expensive</em>
  def values_at(*selectors)
    another = self.another
    selectors.each do |s| 
      entries = self[s]
      another << (entries == nil ? nil_value : entries.flatten)
    end
    another
  end

  # def |(another)
  #   not_implemented
  # end
  
  #################
  # IO-like methods
  ##################
  
  # Returns the current position of self (ie io.pos/frame_size).
  # pos is often used as the default location for IO-like
  # operations like read or write.
  def pos
    io.pos/frame_size
  end
  
  # Sets the current position of the index.  Positions can be set beyond
  # the actual length of the index, similar to an IO. Negative positions
  # are counted back from the end of the index (just as they are in
  # an array), but naturally raise an error if they count back to a
  # position less than zero.
  #
  #   index = ExternalIndex[[1],[2],[3]]
  #   index.length                          # => 3
  #
  #   index.pos = 2; index.pos              # => 2
  #   index.pos = 10; index.pos             # => 10
  #
  #   index.pos = -1; index.pos             # => 2
  #   index.pos = -10; index.pos            # !> ArgumentError
  #
  def pos=(pos)
    if pos < 0
      raise ArgumentError.new("position out of bounds: #{pos}") if pos < -length
      pos += length 
    end
    
    io.pos = (pos * frame_size)
  end

  # Reads the packed byte string for n entries from the specified 
  # position. By default all remaining entries will be read.
  # 
  #   index = ExternalIndex[[1],[2],[3]]
  #   index.pos                              # => 0
  #   index.readbytes.unpack("I*")           # => [1,2,3]
  #   index.readbytes(1,0).unpack("I*")      # => [1]
  #   index.readbytes(10,1).unpack("I*")     # => [2,3]
  #
  # The behavior of readbytes when no entries can be read echos
  # that of IO; when n is nil, an empty string is returned;
  # when n is specified, nil will be returned.
  #
  #   index.pos = 3
  #   index.readbytes                        # => ""
  #   index.readbytes(1)                     # => nil
  #
  def readbytes(n=nil, pos=nil)
    # set the io position to the specified index
    self.pos = pos unless pos == nil

    # read until the end if no n is given
    n == nil ? io.read : io.read(n * frame_size)
  end
  
  # Unpacks the given string into an array of index values.
  # Entries are returned in frame.
  #
  #   index = ExternalIndex[[1],[2],[3]]
  #   index.format                          # => 'I*'
  #   index.unpack( [1].pack('I*') )        # => [[1]] 
  #   index.unpack( [1,2,3].pack('I*') )    # => [[1],[2],[3]]
  #   index.unpack("")                      # => []
  #   
  def unpack(str)
    case
    when process_in_bulk
      # multiple entries, bulk processing (faster)
      results = []
      str.unpack(format).each_slice(frame) {|s| results << s}
      results
    else
      # multiple entries, individual unpacking (slower)
      Array.new(str.length/frame_size) do |i|
        str[i*frame_size, frame_size].unpack(format)
      end
    end
  end

  # Reads n entries from the specified position (ie, read
  # is basically readbytes, then unpack). By default all 
  # remaining entries will be read; single entries are 
  # returned in frame, multiple entries are returned in 
  # an array.
  #
  #   index = ExternalIndex[[1],[2],[3]]
  #   index.pos                       # => 0
  #   index.read                      # => [[1],[2],[3]]
  #   index.read(1,0)                 # => [[1]]
  #   index.read(10,1)                # => [[2],[3]]
  # 
  # The behavior of read when no entries can be read echos
  # that of IO; when n is nil, an empty array is returned;
  # when n is specified, nil will be returned.
  #
  #   index.pos = 3
  #   index.read                      # => []
  #   index.read(1)                   # => nil
  #    
  def read(n=nil, pos=nil)
    str = readbytes(n, pos)
    str == nil ? nil : unpack(str)
  end
  
  # Writes the framed entries into self starting at the 
  # specified position.  By default writing begins at the 
  # current position.  The array can have multiple entries
  # so long as each is in the correct frame.
  #
  #   index = ExternalIndex[]
  #   index.write([[2],[3]], 1)
  #   index.pos = 0; 
  #   index.write([[1]])
  #   index.read(3, 0)                # => [[1],[2],[3]]
  #
  # write may accept an ExternalIndex if it has the same
  # index_attrs as self.
  def write(array, pos=nil)
    case array
    when Array
      check_framed_array(array)
      prepare_write_to_pos(pos)
      write_framed_array(array)
    when ExternalIndex
      check_index(array)
      prepare_write_to_pos(pos)
      write_index(array)
    else  
      raise ArgumentError, "could not convert #{array.class} to Array or ExternalIndex"
    end
  end
  
  # Same as write, except the input entries are unframed. 
  # Multiple entries can be provided in a single array, 
  # so long as the total number of elements is divisible 
  # into entries of the correct frame.
  #
  #   index = ExternalIndex[]
  #   index.unframed_write([2,3], 1)
  #   index.pos = 0; 
  #   index.unframed_write([1])
  #   index.read(3, 0)                # => [[1],[2],[3]]
  #
  def unframed_write(array, pos=nil)
    case array
    when Array
      check_unframed_array(array)
      prepare_write_to_pos(pos)
      write_unframed_array(array)
    when ExternalIndex
      check_index(array)
      prepare_write_to_pos(pos)
      write_index(array)
    else  
      raise ArgumentError.new("could not convert #{array.class} to Array or ExternalIndex")
    end
  end
  
  private
  
  # converts obj to an int using the <tt>to_int</tt>
  # method, if the object responds to <tt>to_int</tt>
  def convert_to_int(obj)  # :nodoc:
    obj.respond_to?(:to_int) ? obj.to_int : obj
  end
  
  # converts obj to an array using the <tt>to_ary</tt>
  # method, if the object responds to <tt>to_ary</tt>
  def convert_to_ary(obj)  # :nodoc:
    obj.respond_to?(:to_ary) ? obj.to_ary : obj
  end
  
  # prepares a write at the specified position by
  # padding to the position and setting pos to
  # the position
  def prepare_write_to_pos(pos) # :nodoc:
    unless pos == nil
      # pad to the starting position if necessary
      pad_to(pos) if pos > length
    
      # set the io position to the specified index
      self.pos = pos
    end
  end
  
  # pads io with nil_value up to pos.
  def pad_to(pos) # :nodoc:
    n = (pos-length)/frame
      
    io.pos = io.length
    io.length += io.write(nil_value(false) * n) 
      
    # in this case position doesn't 
    # need to be set.  set pos to nil
    # to skip the set statement below
    pos = nil
  end
  
  # checks that the input has the same index_attrs as self.
  def check_index(index) # :nodoc:
    unless index.index_attrs == index_attrs
      raise ArgumentError.new("incompatible index attributes [#{index.index_attrs.join(',')}]") 
    end
  end
  
  # checks that the array consists only of 
  # arrays of the correct frame, or nils.
  def check_framed_array(array) # :nodoc:
    array.each do |item| 
      case item
      when Array
        
        # validate the frame of the array
        unless item.length == frame
          raise ArgumentError, "not in frame #{frame}: #{ellipse_inspect(item)}"
        end
        
      when nil # framed arrays can contain nils
      else raise ArgumentError, "not an Array or nil value: #{item.class} "
      end
    end
  end
  
  # checks that the unframed array is of a 
  # frameable length
  def check_unframed_array(array) # :nodoc:
    unless array.length % frame == 0
      raise ArgumentError, "not in frame #{frame}: #{ellipse_inspect(array)}"
    end
  end
  
  # writes the ExternalIndex to io.
  def write_index(index) # :nodoc:
    end_pos = io.pos + io.insert(index.io)
    io.length = end_pos if end_pos > io.length
  end
  
  # writes the framed array to io.  nil values
  # in the array are converted to nil_value.
  def write_framed_array(array) # :nodoc:
    start_pos = io.pos
    length_written = 0
    
    if process_in_bulk
      arr = []
      array.each {|item| arr.concat(item == nil ? nil_value : item) }
      length_written += io.write(arr.pack(format))
    else
      array.each do |item|
        length_written += io.write(item == nil ? nil_value(false) : item.pack(format))
      end
    end
    
    # update io.length as necessary
    end_pos = start_pos + length_written
    io.length = end_pos if end_pos > io.length
  end
  
  # writes the unframed array to io.  unframed
  # arrays cannot contain nils.
  def write_unframed_array(array) # :nodoc:
    start_pos = io.pos
    length_written = 0
    
    if process_in_bulk
      length_written += io.write(array.pack(format))
    else
      array.each_slice(frame) do |arr|
        length_written += io.write(arr.pack(format))
      end
    end
    
    # update io.length as necessary
    end_pos = start_pos + length_written
    io.length = end_pos if end_pos > io.length
  end
end
