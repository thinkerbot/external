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
  
  # Returns another instance of ExternalIndex, initialized with the 
  # input options merged to the current options of self.
  def another(overrides={})
    self.class.new(nil, options.merge(overrides))
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
  
  def dup(options=self.options)
    self.flush
    another(options).concat(self)
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
    #validate_length(array, 1)
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
  #   io = StringIO.new [1,2,3,4,5].pack("I*")
  #   i = ExternalIndex.new(io, :format => 'I')
  #   i[2]                   #=> [3]
  #   i[6]                   #=> nil
  #   i[1, 2]                #=> [ [2], [3] ]
  #   i[1..3]                #=> [ [2], [3], [4] ]
  #   i[4..7]                #=> [ [5] ]
  #   i[6..10]               #=> nil
  #   i[-3, 3]               #=> [ [3], [4], [5] ]
  #   # special cases
  #   i[5]                   #=> nil
  #   i[5, 1]                #=> []
  #   i[5..10]               #=> []
  #
  # Note that entries are returned in frame, as arrays.
  def [](index, length=nil)
    case index
    when Fixnum
      index += self.length if index < 0
      return nil if index < 0

      unless length == nil
        raise TypeError.new("no implicit conversion from nil to integer") if length.nil?
        return [] if length == 0 || index >= self.length
        return nil if length < 0
        
        # ensure you don't try to read more entries than are available
        max_length = self.length - index
        length = max_length if length > max_length
      end
      
      case 
      when length == nil then read(1, index)    # read one, as index[0]
      when length == 1 then [read(1, index)]    # read one framed, as index[0,1]
      else read(length, index)                  # read length, automatic framing
      end 
      
    when Range
      raise TypeError.new("can't convert Range into Integer") unless length == nil
  
      offset, length = split_range(index)
  
      # for conformance with array range retrieval
      return nil if offset < 0 || offset > self.length
      return [] if length < 0
      
      self[offset, length + 1]
    when nil
      raise TypeError.new("no implicit conversion from nil to integer")
    else
      raise TypeError.new("can't convert #{index.class} into Integer") 
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
  # Note that []= must take entries in frame, or (in the case of [offset, length] and 
  # range insertions) another ExternalIndex with the same frame, format, and nil_value.
  #--
  # TODO -- cleanup error messages so they are more meaningful 
  # and helpful, esp for frame errors
  #++
  def []=(*args)
    raise ArgumentError.new("wrong number of arguments (1 for 2)") if args.length < 2
    index, length, value = args
    if args.length == 2
      value = length 
      length = nil
    end

    case index
    when Fixnum
      if index < 0
        index += self.length
        raise IndexError.new("index #{index} out of range") if index  < 0
      end
      
      if length == nil
        # simple insertion 
        value = nil_value if value.object_id == 4 # nil
        unframed_write(value, index)
      else
        raise IndexError.new("negative length (#{length})") if length < 0
        
        # arrayify value if needed
        unless value.kind_of?(ExternalIndex)
          value = [value] unless value.kind_of?(Array)
        end
        
        case
        when self == value
          # special case when insertion is self (no validation needed)
          # A whole copy of self is required because the insertion 
          # can overwrite the tail of self.  As such this can be a
          # worst-case scenario-slow and expensive procedure.
          copy_beg = (index + length) * frame_size
          copy_end = io.length
          
          io.copy do |copy|
            # truncate io
            io.truncate(index * frame_size)
            io.pos = io.length
            
            # pad as needed
            pad_to(index) if index > self.length
            
            # write the copy of self
            io.insert(copy)
            
            # copy the tail of the insertion
            io.insert(copy, copy_beg..copy_end)
          end
        when value.length == length
          # optimized insertion, when insertion is the correct length
          write(value, index)
        else
          # range insertion: requires copy and rewrite of the tail 
          # of the ExternalIndex, after the insertion.
          # WARN - can be slow when the tail is large
          copy_beg = (index + length) * frame_size
          copy_end = io.length
          
          io.copy("r", copy_beg..copy_end) do |copy|
            # pad as needed
            pad_to(index) if index > self.length
            
            # write inserted value
            io.pos = index * frame_size
            write(value)
            
            # truncate io
            io.truncate(io.pos)

            # copy the tail of the insertion
            io.insert(copy)
          end
        end
      end
      
      value
    when Range
      raise TypeError.new("can't convert Range into Integer") if args.length == 3 
      
      # for conformance with setting a range with nil (truncates)
      value = [] if value.nil?
      offset, length = split_range(index)
      self[offset, length + 1] = value
    when nil
      raise TypeError.new("no implicit conversion from nil to integer")
    else
      raise TypeError.new("can't convert #{index.class} into Integer") 
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
      validate_index(another)
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
      if length == 1
        yield read(1)
      else
        read(length).each(&block)
      end
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
      if length == 1
        yield read(1)
      else
        read(length, offset).reverse_each(&block)
      end
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
    case
    when length == 0 then []
    when length == 1 then [read(length, 0)]
    else read(length, 0)
    end
  end

  # def to_ary
  #   not_implemented
  # end

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
  
  # Sets the current position of the index.  Negative positions
  # are counted from the end of the index (just as they are in
  # an array).  Positions can be set beyond the actual length
  # of the index (similar to an IO).
  #
  #   i = ExternalIndex[[1],[2],[3]]
  #   i.length                      # => 3
  #   i.pos = 2; i.pos              # => 2
  #   i.pos = -1; i.pos             # => 2
  #   i.pos = 10; i.pos             # => 40
  def pos=(pos)
    if pos < 0
      raise ArgumentError.new("position out of bounds: #{pos}") if pos < -length
      pos += length 
    end
    
    # do something fake for caching so that 
    # the position need not be set (this 
    # works either way)
    io.pos = (pos * frame_size)
  end
  
  # Returns the current position of the index
  def pos
    io.pos/frame_size
  end

  # Reads the packed byte string for n entries from the specified 
  # position. By default reads the string for all remaining entries
  # from the current position.
  # 
  #   i = ExternalIndex[[1],[2],[3]]
  #   i.pos                              # => 0
  #   i.readbytes.unpack("I*")           # => [1,2,3]
  #   i.readbytes(1,0).unpack("I*")      # => [1]
  #   i.readbytes(10,1).unpack("I*")     # => [2,3]
  #
  # Like an IO, when n is nil and no entries can be read, an empty
  # string is returned.  When n is specified, nil will be returned
  # when no entries can be read.
  #
  #   i.pos = 3
  #   i.readbytes                        # => ""
  #   i.readbytes(1)                     # => nil
  def readbytes(n=nil, pos=nil)
    # set the io position to the specified index
    self.pos = pos unless pos == nil

    # read until the end if no n is given
    n == nil ? io.read : io.read(n * frame_size)
  end
  
  # Unpacks the given string into an array of index values.
  # Single entries are returned in frame, multiple entries 
  # are returned in an array.
  #
  #   i.format                          # => 'I*'
  #   i.unpack( [1].pack('I*') )        # => [1] 
  #   i.unpack( [1,2,3].pack('I*') )    # => [[1],[2],[3]]
  #   i.unpack("")                      # => []
  #   
  def unpack(str)
    case
    when str.empty? then []
    when str.length == frame_size 
      str.unpack(format)
    when process_in_bulk
      results = []
      str.unpack(format).each_slice(frame) {|s| results << s}
      results
    else
      Array.new(str.length/frame_size) do |i|
        str[i*frame_size, frame_size].unpack(format)
      end
    end
  end

  # Reads n entries from the specified position. By default 
  # reads all remaining entries from the current position.
  # Single entries are returned in frame, multiple entries 
  # are returned in an array.
  #
  #   i = ExternalIndex[[1],[2],[3]]
  #   i.pos                       # => 0
  #   i.read                      # => [[1],[2],[3]]
  #   i.read(1,0)                 # => [1]
  #   i.read(10,1)                # => [[2],[3]]
  # 
  # When n is nil and no entries can be read, an empty array
  # is returned.  When n is specified, nil will be returned
  # when no entries can be read.
  #
  #   i.pos = 3
  #   i.read                      # => []
  #   i.read(1)                   # => nil       
  def read(n=nil, pos=nil)
    str = readbytes(n, pos)
    str == nil ? nil : unpack(str)
  end
  
  # Writes the framed entries into self starting at the 
  # specified position.  By default writing begins at the 
  # current position.  The array can have multiple entries
  # so long as each is in the correct frame.
  #
  #   i = ExternalIndex[]
  #   i.write([[2],[3]], 1)
  #   i.pos = 0; 
  #   i.write([[1]])
  #   i.read(3, 0)                # => [[1],[2],[3]]
  #
  # write may accept another ExternalIndex with corresponding
  # index_attrs.
  #
  # Note! -- for performance reasons write does 
  # NOT check to make sure entries are valid when cached?.
  # Naturally, you will, however, get errors if you try to
  # uncache or write a corrupted index.
  #
  #   i.cached = true    
  #   i.write([["cat"]])   # no error
  #   i.last                    # => ["cat"]
  #   i.cached = false          # => TypeError
  def write(array, pos=nil)
    case array
    when Array
      validate_framed_array(array)
      prepare_write_to_pos(pos)
      write_framed_array(array)
    when ExternalIndex
      validate_index(array)
      prepare_write_to_pos(pos)
      write_index(array)
    else  
      raise ArgumentError.new("could not convert #{array.class} to Array or ExternalIndex")
    end
  end
  
  # Same as write, except the input entries are unframed. 
  # Multiple entries can be provided in a single array, 
  # so long as the total number of elements is divisible 
  # into entries of the correct frame.
  #
  #   i = ExternalIndex[]
  #   i.unframed_write([2,3], 1)
  #   i.pos = 0; 
  #   i.unframed_write([1])
  #   i.read(3, 0)                # => [[1],[2],[3]]
  #
  def unframed_write(array, pos=nil)
    case array
    when Array
      validate_unframed_array(array)
      prepare_write_to_pos(pos)
      write_unframed_array(array)
    when ExternalIndex
      validate_index(array)
      prepare_write_to_pos(pos)
      write_index(array)
    else  
      raise ArgumentError.new("could not convert #{array.class} to Array or ExternalIndex")
    end
  end
  
  protected
  
  attr_accessor :cache_pos # :nodoc:
   
  def prepare_write_to_pos(pos) # :nodoc:
    unless pos == nil
      # pad to the starting position if necessary
      pad_to(pos) if pos > length
    
      # set the io position to the specified index
      self.pos = pos
    end
  end
  
  def pad_to(pos) # :nodoc:
    n = (pos-length)/frame
      
    io.pos = io.length
    io.length += io.write(nil_value(false) * n) 
      
    # in this case position doesn't 
    # need to be set.  set pos to nil
    # to skip the set statement below
    pos = nil
  end

  def validate_index(index) # :nodoc:
    unless index.index_attrs == index_attrs
      raise ArgumentError.new("incompatible index attributes [#{index.index_attrs.join(',')}]") 
    end
  end
  
  def validate_framed_array(array) # :nodoc:
    array.each do |item| 
      case item
      when Array
        unless item.length == frame
          raise ArgumentError.new("expected array in frame '#{frame}' but was '#{item.length}'") 
        end
      when nil 
        # framed arrays can contain nils
        next
      else
        raise ArgumentError.new("expected array in frame '#{frame}', was #{item.class}")
      end
    end
  end
  
  def validate_unframed_array(array) # :nodoc:
    unless array.length % frame == 0
      raise ArgumentError.new("expected array in frame '#{frame}' but was '#{array.length}'") 
    end
  end
  
  def validate_length(obj, n) # :nodoc:
    unless obj.respond_to?(:length)
      raise ArgumentError.new("could not determine length of #{obj}") 
    end
    
    unless obj.length == n * frame
      raise ArgumentError.new("expected #{n} entries, but was #{obj.length.to_f/frame}") 
    end
  end
  
  def write_index(index) # :nodoc:
    end_pos = io.pos + io.insert(index.io)
    io.length = end_pos if end_pos > io.length
  end
  
  def write_framed_array(array) # :nodoc:
    # framed arrays may contain nils, and must
    # be resolved before writing the data
    
    start_pos = io.pos
    length_written = 0
    
    if process_in_bulk
      arr = []
      array.each {|item| arr.concat(item == nil ? nil_value : item) }
      length_written += io.write(arr.pack(format))
    else
      array.each do |item|
        str = (item == nil ? nil_value(false) : item.pack(format))
        length_written += io.write(str)
      end
    end
  
    end_pos = start_pos + length_written
    io.length = end_pos if end_pos > io.length
  end
  
  def write_unframed_array(array) # :nodoc:
    # unframed arrays cannot contain nils
    
    start_pos = io.pos
    length_written = 0
    
    if process_in_bulk
      length_written += io.write(array.pack(format))
    else
      array.each_slice(frame) do |arr|
        length_written += io.write(arr.pack(format))
      end
    end
  
    end_pos = start_pos + length_written
    io.length = end_pos if end_pos > io.length
  end
end
