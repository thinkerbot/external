require File.join(File.dirname(__FILE__), 'external_test_helper.rb') 
require 'external_index'
require 'fileutils'
#require 'ext_arr'

class ExternalIndexTest < Test::Unit::TestCase
  acts_as_subset_test

  attr_reader :index, :tempfile

  def setup
    # cls represents an array
    @cls = ExternalIndex

    @tempfile = Tempfile.new("indextest")
    @tempfile << array.pack(format)
    @tempfile.pos = 0
    
    @index = ExternalIndex.new(@tempfile)
  end
  
  def array
    [1,2,3,4,5]
  end
  
  def framed_array
    [[1],[2],[3],[4],[5]]
  end
  
  def format
    "I*"
  end
  
  def teardown
    @tempfile.close unless @tempfile.closed?
  end

  #
  #  readme doc test
  #
  
  # def test_readme_doc_for_ext_ind
  #   ea = ExtArr.new
  #   assert_equal ExternalIndex, ea._index.class
  #   index = ea._index
  #   assert_equal 'I*', index.format
  #   assert_equal 2, index.frame
  #   index << [1,2]
  #   index << [3,4]
  #   assert_equal [[1,2],[3,4]], index.to_a
  #   
  #   Tempfile.open('test_readme_doc_for_ext_ind') do |file|
  #     file << [1,2,3].pack("IQS")
  #     file << [4,5,6].pack("IQS")
  #     file << [7,8,9].pack("IQS")
  #     file.flush
  # 
  #     index = ExternalIndex.new(file, :format => "IQS")
  #     assert_equal [4,5,6], index[1]
  #     assert_equal [[1,2,3],[4,5,6],[7,8,9]], index.to_a
  #   end
  # end
  
  #
  # setup tests
  #
  
  def test_setup
    assert_equal ExternalIndex, @cls
    
    assert_equal 0, index.pos
    assert_equal 5, index.length
    assert_equal 4, index.frame_size
    assert_equal 8 * 2**20, index.buffer_size
    assert_equal [0], index.nil_value
    assert_equal({:format => "I", :buffer_size => 8 * 2**20, :nil_value => [0]}, index.options)
    
    tempfile.pos = 0
    assert_equal array.pack(format), tempfile.read
    assert_equal tempfile.path, index.io.path
  end
  
  

  #
  # ExternalIndex.read test
  #
  
  def test_read_returns_the_index_file_in_frame
    assert_equal framed_array, ExternalIndex.read(tempfile.path)
    
    tempfile.pos = tempfile.length
    tempfile << [6].pack("I")
    tempfile.flush
    tempfile.pos = 0
    assert_equal [1,2,3,4,5,6].pack("I*"), tempfile.read
    
    assert_equal [[1,2],[3,4],[5,6]], ExternalIndex.read(tempfile.path, :format => 'II')
  end
  
  #
  # ExternalIndex.directive_size test
  #
  
  def test_directive_size_returns_the_number_of_bytes_to_pack_a_directive
    # @     |  Moves to absolute position
    # not implemented
    assert_nil ExternalIndex.directive_size('@')
    # A     |  ASCII string (space padded, count is width)
    assert_equal 1, ["a"].pack("A").length
    assert_equal 1, ExternalIndex.directive_size('A')
    # a     |  ASCII string (null padded, count is width)
    assert_equal 1, ["a"].pack("a").length
    assert_equal 1, ExternalIndex.directive_size('a')
    # B     |  Bit string (descending bit order)
    assert_equal 1, ['a'].pack("B").length
    assert_equal 1, ExternalIndex.directive_size('B')
    # b     |  Bit string (ascending bit order)
    assert_equal 1, ['a'].pack("b").length
    assert_equal 1, ExternalIndex.directive_size('b')
    # C     |  Unsigned char
    assert_equal 1, [1].pack("C").length
    assert_equal 1, ExternalIndex.directive_size('C')
    # c     |  Char
    assert_equal 1, [1].pack("c").length
    assert_equal 1, ExternalIndex.directive_size('c')
    # D, d  |  Double-precision float, native format
    assert_equal 8, [1].pack("D").length
    assert_equal 8, ExternalIndex.directive_size('D')
    assert_equal 8, [1].pack("d").length
    assert_equal 8, ExternalIndex.directive_size('d')
    # E     |  Double-precision float, little-endian byte order
    assert_equal 8, [1].pack("E").length
    assert_equal 8, ExternalIndex.directive_size('E')
    # e     |  Single-precision float, little-endian byte order
    assert_equal 4, [1].pack("e").length
    assert_equal 4, ExternalIndex.directive_size('e')
    # F, f  |  Single-precision float, native format
    assert_equal 4, [1].pack("F").length
    assert_equal 4, ExternalIndex.directive_size('F')
    assert_equal 4, [1].pack("f").length
    assert_equal 4, ExternalIndex.directive_size('f')
    # G     |  Double-precision float, network (big-endian) byte order
    assert_equal 8, [1].pack("G").length
    assert_equal 8, ExternalIndex.directive_size('G')
    # g     |  Single-precision float, network (big-endian) byte order
    assert_equal 4, [1].pack("g").length
    assert_equal 4, ExternalIndex.directive_size('g')
    # H     |  Hex string (high nibble first)
    assert_equal 1, ['a'].pack("H").length
    assert_equal 1, ExternalIndex.directive_size('H')
    # h     |  Hex string (low nibble first)
    assert_equal 1, ['a'].pack("h").length
    assert_equal 1, ExternalIndex.directive_size('h')
    # I     |  Unsigned integer
    assert_equal 4, [1].pack("I").length
    assert_equal 4, ExternalIndex.directive_size('I')
    # i     |  Integer
    assert_equal 4, [1].pack("i").length
    assert_equal 4, ExternalIndex.directive_size('i')
    # L     |  Unsigned long
    assert_equal 4, [1].pack("L").length
    assert_equal 4, ExternalIndex.directive_size('L')
    # l     |  Long
    assert_equal 4, [1].pack("l").length
    assert_equal 4, ExternalIndex.directive_size('l')
    # M     |  Quoted printable, MIME encoding (see RFC2045)
    assert_equal 3, ['a'].pack("M").length
    assert_equal 3, ExternalIndex.directive_size('M')
    # m     |  Base64 encoded string
    assert_equal 5, ['a'].pack("m").length
    assert_equal 5, ExternalIndex.directive_size('m')
    # N     |  Long, network (big-endian) byte order
    assert_equal 4, [1].pack("N").length
    assert_equal 4, ExternalIndex.directive_size('N')
    # n     |  Short, network (big-endian) byte-order
    assert_equal 2, [1].pack("n").length
    assert_equal 2, ExternalIndex.directive_size('n')
    # P     |  Pointer to a structure (fixed-length string)
    assert_equal 4, ['a'].pack("P").length
    assert_equal 4, ExternalIndex.directive_size('P')
    # p     |  Pointer to a null-terminated string
    assert_equal 4, ['a'].pack("p").length
    assert_equal 4, ExternalIndex.directive_size('p')
    # Q, q  |  64-bit number
    assert_equal 8, [1].pack("Q").length
    assert_equal 8, ExternalIndex.directive_size('Q')
    assert_equal 8, [1].pack("q").length
    assert_equal 8, ExternalIndex.directive_size('q')
    # S     |  Unsigned short
    assert_equal 2, [1].pack("S").length
    assert_equal 2, ExternalIndex.directive_size('S')
    # s     |  Short
    assert_equal 2, [1].pack("s").length
    assert_equal 2, ExternalIndex.directive_size('s')
    # U     |  UTF-8
    assert_equal 1, [1].pack("U").length
    assert_equal 1, ExternalIndex.directive_size('U')
    # u     |  UU-encoded string
    assert_equal 6, ['a'].pack("u").length
    assert_equal 6, ExternalIndex.directive_size('u')
    # V     |  Long, little-endian byte order
    assert_equal 4, [1].pack("V").length
    assert_equal 4, ExternalIndex.directive_size('V')
    # v     |  Short, little-endian byte order
    assert_equal 2, [1].pack("v").length
    assert_equal 2, ExternalIndex.directive_size('v')
    # w     |  BER-compressed integer\fnm
    # not implemented
    assert_equal 1, [1].pack("w").length
    assert_equal 1, ExternalIndex.directive_size('w')
    # X     |  Back up a byte
    # not implemented
    assert_nil ExternalIndex.directive_size('X')
    # x     |  Null byte
    assert_equal 1, [nil].pack("x").length
    assert_equal 1, ExternalIndex.directive_size('x')
    # Z     |  Same as ``a'', except that null is added with *
    assert_equal 1, ['a'].pack("Z").length
    assert_equal 1, ExternalIndex.directive_size('Z')
  end
 
  #
  # initialize tests
  #

  def test_default_initialize
    index = ExternalIndex.new
    
    assert_equal 0, index.pos
    assert_equal 0, index.length
    assert_equal 4, index.frame_size
    assert_equal 8 * 2**20, index.buffer_size
    assert_equal [0], index.nil_value
    assert_equal({:format => "I", :buffer_size => 8 * 2**20, :nil_value => [0]}, index.options)
  end
  
  def test_initialize_calculates_frame_from_format
    index = @cls.new nil, :format => 'III'
    assert_equal 3, index.frame
    
    index = @cls.new nil, :format => 'ID'
    assert_equal 2, index.frame
    
    index = @cls.new nil, :format => 'I8I'
    assert_equal 9, index.frame
  end
  
  def test_initialize_calculates_frame_size_from_format
    index = @cls.new nil, :format => 'III'
    assert_equal 12, index.frame_size
    
    index = @cls.new nil, :format => 'ID'
    assert_equal 12, index.frame_size
    
    index = @cls.new nil, :format => 'I8I'
    assert_equal 36, index.frame_size
  end
  
  def test_initialize_condenses_bulk_formats
    index = @cls.new nil, :format => 'III'
    assert_equal 'I*', index.format
    assert index.process_in_bulk
    
    index = @cls.new nil, :format => 'I8I'
    assert_equal 'I*', index.format
    assert index.process_in_bulk
  end
  
  def test_initialize_with_format_containing_an_unsupported_directive_raises_error
    assert_raise(ArgumentError) { @cls.new(nil, :format => 'x') }
    assert_raise(ArgumentError) { @cls.new(nil, :format => 'I_I') }
    assert_raise(ArgumentError) { @cls.new(nil, :format => 'I*') }
  end
  
  def test_initialize_sets_buffer_size
    index = @cls.new nil, :buffer_size => 1000
    assert_equal 1000, index.buffer_size
  end
  
  def test_initialize_sets_nil_value_to_an_frame_sized_array_of_zeros
    index = @cls.new nil, :format => 'I'
    assert_equal [0], index.nil_value
    
    index = @cls.new nil, :format => 'III'
    assert_equal [0,0,0], index.nil_value
  end
  
  def test_initialize_raises_error_if_specified_nil_value_is_incompatible_with_format
    assert_raise(ArgumentError) { @cls.new nil, :format => 'I', :nil_value => [0,1] }
    assert_raise(ArgumentError) { @cls.new nil, :format => 'II', :nil_value => [0] }
    assert_raise(ArgumentError) { @cls.new nil, :format => 'I', :nil_value => [1.2] }
    assert_raise(ArgumentError) { @cls.new nil, :format => 'I', :nil_value => ['a'] }
  end
  
  #
  # buffer_size test
  #
  
  def test_buffer_size_is_io_default_blksize
    index.io.default_blksize = 1000
    assert_equal 1000, index.io.default_blksize
    assert_equal 1000, index.buffer_size
  end
  
  def test_set_buffer_size_sets_default_blksize_for_io_and_self
    assert_equal 4, index.frame_size
    
    index.buffer_size = 40
    assert_equal 10, index.default_blksize
    assert_equal 40, index.io.default_blksize
  end
  
  #
  # default_blksize test
  #
  
  def test_set_default_blksize_sets_default_blksize_for_io_and_self
    assert_equal 4, index.frame_size
    
    index.default_blksize = 10
    assert_equal 10, index.default_blksize
    assert_equal 40, index.io.default_blksize
  end
  
  #
  # nil_value tests
  # 
  
  def test_nil_value_documentation
    index = ExternalIndex.new 
    assert_equal [0], index.nil_value         
    assert_equal "\000\000\000\000",  index.nil_value(false)  
  end
  
  #
  # index_attrs test
  #
  
  def test_index_attrs_returns_frame_format_nil_value_array
    assert_equal [index.frame, index.format, index.nil_value], index.index_attrs
  end
  
  #
  # options test
  #
  
  def test_options_returns_options_hash_for_current_settings
    assert_equal({
      :format => 'I', 
      :buffer_size => ExternalIndex::DEFAULT_BUFFER_SIZE, 
      :nil_value => [0]
    }, index.options)
    
    index.buffer_size = 40
    assert_equal({
      :format => 'I', 
      :buffer_size => 40, 
      :nil_value => [0]
    }, index.options)
  end
  
  def test_options_expands_packed_formats
    index = @cls.new nil, :format => 'III'
    assert_equal 'I*', index.format
    
    assert_equal({
      :format => 'III', 
      :buffer_size => ExternalIndex::DEFAULT_BUFFER_SIZE, 
      :nil_value => [0,0,0]
    }, index.options)
  end
  
  #
  # another tests
  #
  
  def test_another_returns_new_instance
    a = @cls[1,2,3]
    b = a.another
    
    assert_not_equal(a.object_id, b.object_id)
    assert_equal(@cls[], b)
  end
  
  def test_another_has_same_options_as_self
    a = @cls.new nil, :format => 'ID', :nil_value => [1,2], :buffer_size => 40
    b = a.another
    
    assert_equal 'ID', b.format
    assert_equal [1,2], b.nil_value
    assert_equal 40, b.buffer_size
  end
  
  def test_another_uses_override_options
    a = @cls[1,2,3]
    a.buffer_size = 10
    b = a.another :buffer_size => 20
    
    assert_equal(10, a.buffer_size)
    assert_equal(20, b.buffer_size)
  end
 
  ########################
  # ...
  ########################
  
  #
  # length test
  #
  
  def test_length_returns_io_length_divided_by_frame_size
    assert_equal 20, tempfile.length
    assert_equal 5, index.length
    
    tempfile.length = 4
    assert_equal 1, index.length
    
    tempfile.length = 0
    assert_equal 0, index.length
  end
  
  ########################
  # ...
  ########################
  
  #
  # pos test
  #
  
  def test_pos_returns_io_pos_divided_by_frame_size
    assert_equal 0, index.io.pos
    assert_equal 0, index.pos
    
    index.io.pos = 4
    assert_equal 1, index.pos
    
    index.io.pos = 20
    assert_equal 5, index.pos
  end
  
  #
  # pos= test
  #
  
  def test_pos_set_documentation
    i = @cls[[1],[2],[3]]
    assert_equal 3, i.length  
    i.pos = 2
    assert_equal 2, i.pos             
    i.pos = -1
    assert_equal 2, i.pos           
  end
  
  def test_pos_set_sets_io_pos_to_index_value_of_input_times_frame_size
    index.pos = 1
    assert_equal 1, index.pos
    assert_equal 4, index.io.pos
    
    index.pos = -1
    assert_equal 4, index.pos
    assert_equal 16, index.io.pos
  end
  
  def test_positions_can_be_set_beyond_the_index_length
    index.pos = 10
    assert_equal 10, index.pos
  end
    
  def test_pos_set_raises_error_if_out_of_bounds
    assert_raise(ArgumentError) { index.pos = -6 }
  end
  
  #
  # readbytes test
  #
  
  def test_readbytes_documentation
    i = @cls[[1],[2],[3]]
    assert_equal [1,2,3], i.readbytes.unpack("I*")       
    assert_equal [1], i.readbytes(1,0).unpack("I*")      
    assert_equal [2,3], i.readbytes(10,1).unpack("I*")    
    i.pos = 3
    assert_equal "", i.readbytes                    
    assert_equal nil, i.readbytes(1)                 
  end
  
  def test_readbytes_returns_bytestring_for_n_and_pos
    assert_equal array.pack(format), index.readbytes(5,0) 
    assert_equal array.pack(format), index.readbytes(5,-5) 
    assert_equal [2,3].pack(format), index.readbytes(2,1) 
    
    assert_equal array.pack(format), index.readbytes(10,0)
    assert_equal array.pack(format), index.readbytes(10,-5)
  
    index.pos = 0
    assert_equal array.pack(format), index.readbytes
    
    index.pos = 3
    assert_equal [4,5].pack(format), index.readbytes
  
    index.pos = 3
    assert_equal [4].pack(format), index.readbytes(1)
  end
  
  def test_readbytes_returns_nil_if_n_is_specified_and_no_entries_can_be_read
    assert_nil index.readbytes(1,5)
  end
  
  def test_readbytes_returns_empty_string_if_n_is_nil_and_no_entries_can_be_read
    assert_equal "", index.readbytes(nil, 5)
  end
  
  def test_readbytes_raises_error_if_position_is_out_of_bounds
    assert_raise(ArgumentError) { index.readbytes(1,-6) }
  end
  
  def test_readbytes_behavior_is_like_io_behavior
    tempfile.pos = 20
    assert_equal "", tempfile.read(nil)
    assert_nil tempfile.read(1)
  end
  
  #
  # unpack tests
  #
  
  def test_unpack_documentation
    assert_equal "I*", index.format  
    assert_equal [1], index.unpack( [1].pack('I*') )      
    assert_equal [[1], [2], [3]], index.unpack( [1,2,3].pack('I*') ) 
    assert_equal [], index.unpack("") 
  end
  
  def test_unpack_unpacks_string_into_frames_using_format
    assert_equal [[1],[2],[3],[4],[5]], index.unpack(array.pack(format))
    assert_equal [1], index.unpack([1].pack(format))
    assert_equal [], index.unpack("")
  end
  
  #
  # read tests
  #
  
  def test_read_documentation
    i = @cls[[1],[2],[3]]
    assert_equal 0, i.pos                      
    assert_equal [[1],[2],[3]], i.read                   
    assert_equal [1], i.read(1,0)                 
    assert_equal [[2],[3]], i.read(10,1)               
    
    i.pos = 3
    assert_equal [], i.read                   
    assert_equal nil, i.read(1)            
  end
  
  def test_read_returns_unpacked_array_for_n_and_pos
    assert_equal framed_array, index.read(5,0) 
    assert_equal framed_array, index.read(5,-5) 
    assert_equal [[2],[3]], index.read(2,1) 
    
    assert_equal framed_array, index.read(10,0)
    assert_equal framed_array, index.read(10,-5)
    
    index.pos = 0
    assert_equal framed_array, index.read
    
    index.pos = 3
    assert_equal [[4],[5]], index.read
  
    index.pos = 3
    assert_equal [4], index.read(1)
  end
  
  def test_read_returns_nil_if_n_is_specified_and_no_entries_can_be_read
    assert_nil index.read(1,5)
  end
  
  def test_read_returns_empty_array_if_n_is_nil_and_no_entries_can_be_read
    assert_equal [], index.read(nil, 5)
  end
  
  def test_read_raises_error_if_position_is_out_of_bounds
    assert_raise(ArgumentError) { index.read(1,-6) }
  end
  
  def test_read_handles_mixed_formats
    index = @cls.new tempfile, :format => "IQS"
    tempfile.pos = 0
    a = [1,2,3].pack("IQS")
    b = [4,5,6].pack("IQS")
    c = [7,8,9].pack("IQS")
    tempfile << a + b + c
    
    index.pos=0
    assert_equal [[1,2,3],[4,5,6],[7,8,9]], index.read
    
    index.pos=1
    assert_equal [4,5,6], index.read(1)
  end
  
  #
  # write test
  #
  
  def test_write_documentation
    i = @cls[]
    i.write([[2],[3]], 1) 
    i.pos = 0
    i.write([[1]])
    assert_equal [[1],[2],[3]], i.read(3, 0)
  end
  
  
  #
  # unframed_write test
  #
  
  def test_unframed_write_documentation
    i = @cls[]
    i.unframed_write([2,3], 1) 
    i.pos = 0
    i.unframed_write([1])
    assert_equal [[1],[2],[3]], i.read(3, 0)
  end
  
  def test_unframed_write_unframed_writes_packed_array_to_io_at_pos_and_adjusts_io_length
    index = @cls.new
    index.unframed_write([1,2,3])
    assert_equal 12, index.io.length
    assert_equal 12, index.io.pos
     
    index.io.pos = 0
    assert_equal [1,2,3].pack("I*"), index.io.read
    
    index.unframed_write([-2], 1)
    assert_equal 12, index.io.length
    assert_equal 8, index.io.pos
     
    index.io.pos = 0
    assert_equal [1,-2,3].pack("I*"), index.io.read
  end
  
  def test_unframed_write_pads_with_nil_value_if_position_is_past_length
    index = @cls.new nil, :nil_value => [8]
    assert_equal 0, index.length
    
    index.unframed_write([1,2,3], 2)
    
    index.io.pos = 0
    assert_equal [8,8,1,2,3], index.io.read.unpack("I*")
  end
  
  def test_unframed_write_unframed_writes_nothing_with_empty_array
    assert_equal 20, index.io.length
    
    index.unframed_write([])
    index.pos = 0
    assert_equal 20, index.io.length
    
    index.unframed_write([], 0)
    index.pos = 0
    assert_equal 20, index.io.length
  end
  
  def test_unframed_write_raises_error_if_array_is_not_in_frame
    index = @cls.new(nil, :format => "II")
    assert_raise(ArgumentError) { index.unframed_write([1]) }
    assert_raise(ArgumentError) { index.unframed_write([1,2,3]) }
  end
  
  def test_unframed_write_handles_mixed_formats
    index = @cls.new tempfile, :format => "IQS"
    a = [1,2,3].pack("IQS")
    b = [4,5,6].pack("IQS")
    c = [7,8,9].pack("IQS")
    d = [-4,-5,-6].pack("IQS")
    
    index.unframed_write([1,2,3,4,5,6,7,8,9])
    tempfile.pos=0
    assert_equal a+b+c, tempfile.read
    
    index.pos=1
    index.unframed_write([-4,-5,-6])
    tempfile.pos=0
    assert_equal a+d+c, tempfile.read
  end
  
  #
  # numeric format range tests
  #
  
  unless defined?(SHRT_MIN)
    SHRT_MIN = -32768
    SHRT_MAX = 32767
  
    USHRT_MIN = 0
    USHRT_MAX = 65535
  
    LONG_MIN = -2147483648
    LONG_MAX = 2147483647 
  
    ULONG_MIN = 0
    ULONG_MAX = 4294967295
  
    LLONG_MIN = -9223372036854775808
    LLONG_MAX = 9223372036854775807
  
    ULLONG_MIN = 0
    ULLONG_MAX = 18446744073709551615
  end
  
  def test_read_and_unframed_write_handles_full_numeric_range_for_numeric_formats
    # S handles an unsigned short
    i = @cls.new tempfile, :format => 'S'
    
    i.unframed_write([USHRT_MIN], 0)
    assert_equal [USHRT_MIN], i.read(1,0)
    i.unframed_write([USHRT_MAX], 0)
    assert_equal [USHRT_MAX], i.read(1,0)
  
    i.unframed_write([USHRT_MIN-1], 0)
    assert_equal [USHRT_MAX], i.read(1,0)
  
    # s handles an signed short
    i = @cls.new tempfile, :format => 's'
    
    i.unframed_write([SHRT_MIN], 0)
    assert_equal [SHRT_MIN], i.read(1,0)
    i.unframed_write([SHRT_MAX], 0)
    assert_equal [SHRT_MAX], i.read(1,0)
  
    i.unframed_write([SHRT_MIN], 0)
    assert_equal [SHRT_MIN], i.read(1,0)
    i.unframed_write([SHRT_MIN-1], 0)
    assert_equal [SHRT_MAX], i.read(1,0)
    
    # I,L handle an unsigned long
    ['I', 'L'].each do |format|
      i = @cls.new tempfile, :format => format
      
      i.unframed_write([ULONG_MIN], 0)
      assert_equal [ULONG_MIN], i.read(1,0)
      i.unframed_write([ULONG_MAX], 0)
      assert_equal [ULONG_MAX], i.read(1,0)
  
      i.unframed_write([ULONG_MIN-1], 0)
      assert_equal [ULONG_MAX], i.read(1,0)
    end
    
    # i,l handle an signed long
    ['i', 'l'].each do |format|
      i = @cls.new tempfile, :format => format
      
      i.unframed_write([LONG_MIN], 0)
      assert_equal [LONG_MIN], i.read(1,0)
      i.unframed_write([LONG_MAX], 0)
      assert_equal [LONG_MAX], i.read(1,0)
  
      i.unframed_write([LONG_MIN], 0)
      assert_equal [LONG_MIN], i.read(1,0)
      i.unframed_write([LONG_MIN-1], 0)
      assert_equal [LONG_MAX], i.read(1,0)
    end
  
    # Q handles an unsigned long long
    i = @cls.new tempfile, :format => 'Q'
    
    i.unframed_write([ULLONG_MIN], 0)
    assert_equal [ULLONG_MIN], i.read(1,0)
    i.unframed_write([ULLONG_MAX], 0)
    assert_equal [ULLONG_MAX], i.read(1,0)
  
    i.unframed_write([ULLONG_MIN-1], 0)
    assert_equal [ULLONG_MAX], i.read(1,0)
    
    # q handles an signed long long
    i = @cls.new tempfile, :format => 'q'
    
    i.unframed_write([LLONG_MIN], 0)
    assert_equal [LLONG_MIN], i.read(1,0)
    i.unframed_write([LLONG_MAX], 0)
    assert_equal [LLONG_MAX], i.read(1,0)
  
    i.unframed_write([LLONG_MIN], 0)
    assert_equal [LLONG_MIN], i.read(1,0)
    i.unframed_write([LLONG_MIN-1], 0)
    assert_equal [LLONG_MAX], i.read(1,0)
  end
  
  def test_read_and_unframed_write_cycle_numerics_beyond_natural_range
    # S handles an unsigned short
    i = @cls.new tempfile, :format => 'S'
    
    i.unframed_write([-USHRT_MAX], 0)
    assert_equal [1], i.read(1,0)
    i.unframed_write([USHRT_MIN-1], 0)
    assert_equal [USHRT_MAX], i.read(1,0)
  
    # s handles an signed short
    i = @cls.new tempfile, :format => 's'
  
    i.unframed_write([SHRT_MIN], 0)
    assert_equal [SHRT_MIN], i.read(1,0)
    i.unframed_write([SHRT_MIN-1], 0)
    assert_equal [SHRT_MAX], i.read(1,0)
    
    # I,L handle an unsigned long
    ['I', 'L'].each do |format|
      i = @cls.new tempfile, :format => format
      
      i.unframed_write([-ULONG_MAX], 0)
      assert_equal [1], i.read(1,0)
      i.unframed_write([ULONG_MIN-1], 0)
      assert_equal [ULONG_MAX], i.read(1,0)
    end
    
    # i,l handle an signed long
    ['i', 'l'].each do |format|
      i = @cls.new tempfile, :format => format
      
      i.unframed_write([LONG_MIN], 0)
      assert_equal [LONG_MIN], i.read(1,0)
      i.unframed_write([LONG_MIN-1], 0)
      assert_equal [LONG_MAX], i.read(1,0)
    end
  
    # Q handles an unsigned long long
    i = @cls.new tempfile, :format => 'Q'
    
    i.unframed_write([-ULLONG_MAX], 0)
    assert_equal [1], i.read(1,0)
    i.unframed_write([ULLONG_MIN-1], 0)
    assert_equal [ULLONG_MAX], i.read(1,0)
    
    # q handles an signed long long
    i = @cls.new tempfile, :format => 'q'
    
    i.unframed_write([LLONG_MIN], 0)
    assert_equal [LLONG_MIN], i.read(1,0)
    i.unframed_write([LLONG_MIN-1], 0)
    assert_equal [LLONG_MAX], i.read(1,0)
  end
  
  def test_numerics_cycle_up_to_the_unsigned_max_in_either_sign
    # S,s,I,i,L,l all can cycle up to the size of an ULONG 
    ['S','s','I','i','L','l'].each do |format|
      i = @cls.new tempfile, :format => format
      
      assert_raise(RangeError) { i.unframed_write([-(ULONG_MAX+1)]) }
      assert_raise(RangeError) { i.unframed_write([(ULONG_MAX+1)]) }
    end
    
    # Q,q can cycle up to the size of an ULLONG 
    ['Q', 'q'].each do |format|
      i = @cls.new tempfile, :format => format
      
      assert_raise(RangeError) { i.unframed_write([-(ULLONG_MAX+1)]) }
      assert_raise(RangeError) { i.unframed_write([(ULLONG_MAX+1)]) }
    end
  end
  
  #############################
  # Array method documentation
  #############################
  
  def test_AREF_doc
    io = StringIO.new [1,2,3,4,5].pack("I*")
    i = ExternalIndex.new(io, :format => 'I')
    assert_equal [3], i[2]
    assert_equal nil, i[6]
    assert_equal [[2],[3]], i[1,2]
    assert_equal [[2],[3],[4]], i[1..3]
    assert_equal [[5]], i[4..7]
    assert_equal nil, i[6..10]
    assert_equal [[3],[4],[5]], i[-3,3]
    assert_equal nil, i[5]
    assert_equal [], i[5,1]
    assert_equal [], i[5..10]
  end
  
  def test_ASET_doc
    io = StringIO.new ""
    i = ExternalIndex.new(io, :format => 'I')
    assert_equal [0], i.nil_value   
                   
    i[4] = [4]                   
    assert_equal [[0], [0], [0], [0], [4]], i.to_a
    
    i[0, 3] = [ [1], [2], [3] ]  
    assert_equal [[1], [2], [3], [0], [4]], i.to_a

    i[1..2] = [ [5], [6] ]       
    assert_equal [[1], [5], [6], [0], [4]], i.to_a

    i[0, 2] = [[7]]               
    assert_equal [[7], [6], [0], [4]], i.to_a

    i[0..2] = [[8]]                
    assert_equal [[8], [4]], i.to_a

    i[-1]   = [9]            
    assert_equal [[8], [9]], i.to_a

    i[1..-1] = nil        
    assert_equal [[8]], i.to_a
  end
  
  #############################
  # Modified Array methods tests
  #############################

  def test_empty_0
    # Changes: had to rewrite arrays as @cls
    # assert_equal true, [].empty?
    # assert_equal false, [1].empty?
    # assert_equal false, [1, 1, 4, 2, 5, 4, 5, 1, 2].empty?
    assert_equal true, @cls[].empty?
    assert_equal false, @cls[1].empty?
    assert_equal false, @cls[1, 1, 4, 2, 5, 4, 5, 1, 2].empty?
  end
  
  def test_find_all_0
    # Changes: had to rewrite arrays as @cls and
    # with index entries.
    
    # assert_respond_to([], :find_all)
    # assert_respond_to([], :select)       # Alias
    # assert_equal([], [].find_all{ |obj| obj == "foo"})
    #   
    # x = ["foo", "bar", "baz", "baz", 1, 2, 3, 3, 4]
    # assert_equal(["baz","baz"], x.find_all{ |obj| obj == "baz" })
    # assert_equal([3,3], x.find_all{ |obj| obj == 3 })
    
    assert_respond_to(@cls[], :find_all)
    assert_respond_to(@cls[], :select)       # Alias
    assert_equal(@cls[], @cls[].find_all{ |obj| obj == "foo"})
  
    x = @cls[8, 9, 10, 10, 1, 2, 3, 3, 4]
    assert_equal(@cls[10, 10], x.find_all{ |obj| obj == [10] })
    assert_equal(@cls[3,3], x.find_all{ |obj| obj == [3] })
  end
  
  def test_01_square_brackets
    # Changes: results returned in frame 
    
    a = @cls[ 5, 4, 3, 2, 1 ]
    assert_instance_of(@cls, a)
    assert_equal(5, a.length)
    #5.times { |i| assert_equal(5-i, a[i]) }
    5.times { |i| assert_equal([5-i], a[i]) }
    assert_nil(a[6])
  end

  def test_PLUS # '+'
    # Changes: strings not allowed in ExternalIndex
    # replace 'cat' with 4, 'dog' with 5
    
    assert_equal(@cls[],     @cls[]  + @cls[])
    assert_equal(@cls[1],    @cls[1] + @cls[])
    assert_equal(@cls[1],    @cls[]  + @cls[1])
    assert_equal(@cls[1, 1], @cls[1] + @cls[1])
    #assert_equal(@cls['cat', 'dog', 1, 2, 3], %w(cat dog) + (1..3).to_a)
    assert_equal(@cls[4, 5, 1, 2, 3], @cls[4,5] + @cls[*(1..3).to_a])

    # Additional:
    # check addition of Array to ExternalIndex (can't add ExternalIndex to Array)
    assert_equal(@cls[4, 5, 1, 2, 3], @cls[4,5] + [[1],[2],[3]])
    assert_raise(TypeError) { [4,5] + @cls[*(1..3).to_a] }
    
    # check result is distinct from factors
    a = @cls[1]
    b = @cls[2]
    c = a + b
    assert_equal [[1],[2]], c.to_a
    
    a.concat [[1]]
    b.concat [[2]]
    c.concat [[3]]
    assert_equal [[1],[1]], a.to_a
    assert_equal [[2],[2]], b.to_a
    assert_equal [[1],[2],[3]], c.to_a
  end
  
  def test_LSHIFT # '<<'
    # Changes: inputs must be in frame and can't take
    # strings.  And ExternalIndex can't accept itself as an entry
    
    a = @cls[]
    #a << 1
    a << [1]
    assert_equal(@cls[1], a)
    #a << 2 << 3
    a << [2] << [3]
    assert_equal(@cls[1, 2,3], a)
    #a << nil << 'cat'
    #assert_equal(@cls[1, 2, 3, nil, 'cat'], a)
    #a << a
    #assert_equal(@cls[1, 2, 3, nil, 'cat', a], a)
    
    # Additional: check multiple entries can be
    # lshifted at once
    a << [4,5,6]
    assert_equal(@cls[1, 2,3,4,5,6], a)
  end

  def test_CMP # '<=>'
    # Changes: strings not allowed in ExternalIndex
    # replace 'cat' with 4, 'dog' with 5
    assert_equal(-1, 4 <=> 5)
    
    assert_equal(0,  @cls[] <=> @cls[])
    assert_equal(0,  @cls[1] <=> @cls[1])
    #assert_equal(0,  @cls[1, 2, 3, 'cat'] <=> @cls[1, 2, 3, 'cat'])
    assert_equal(0,  @cls[1, 2, 3] <=> @cls[1, 2, 3])
    assert_equal(-1, @cls[] <=> @cls[1])
    assert_equal(1,  @cls[1] <=> @cls[])
    #assert_equal(-1, @cls[1, 2, 3] <=> @cls[1, 2, 3, 'cat'])
    assert_equal(-1, @cls[1, 2, 3] <=> @cls[1, 2, 3, 4])
    #assert_equal(1,  @cls[1, 2, 3, 'cat'] <=> @cls[1, 2, 3])
    assert_equal(1,  @cls[1, 2, 3, 4] <=> @cls[1, 2, 3])
    #assert_equal(-1, @cls[1, 2, 3, 'cat'] <=> @cls[1, 2, 3, 'dog'])
    assert_equal(-1, @cls[1, 2, 3, 4] <=> @cls[1, 2, 3, 5])
    #assert_equal(1,  @cls[1, 2, 3, 'dog'] <=> @cls[1, 2, 3, 'cat'])
    assert_equal(1,  @cls[1, 2, 3, 5] <=> @cls[1, 2, 3, 4])
  end

  def test_AREF # '[]'
    # Changes: results returned in frame 
    
    a = @cls[*(1..100).to_a]

    #assert_equal(1, a[0])
    assert_equal([1], a[0])
    #assert_equal(100, a[99])
    assert_equal([100], a[99])
    assert_nil(a[100])
    #assert_equal(100, a[-1])
    assert_equal([100], a[-1])
    #assert_equal(99,  a[-2])
    assert_equal([99],  a[-2])
    #assert_equal(1,   a[-100])
    assert_equal([1],   a[-100])
    assert_nil(a[-101])
    assert_nil(a[-101,0])
    assert_nil(a[-101,1])
    assert_nil(a[-101,-1])
    assert_nil(a[10,-1])

    # assert_equal(@cls[1],   a[0,1])
    assert_equal([[1]],   a[0,1])
    #assert_equal(@cls[100], a[99,1])
    assert_equal([[100]], a[99,1])
    #assert_equal(@cls[],    a[100,1])
    assert_equal([],    a[100,1])
    #assert_equal(@cls[100], a[99,100])
    assert_equal([[100]], a[99,100])
    #assert_equal(@cls[100], a[-1,1])
    assert_equal([[100]], a[-1,1])
    #assert_equal(@cls[99],  a[-2,1])
    assert_equal([[99]],  a[-2,1])
    #assert_equal(@cls[],    a[-100,0])
    assert_equal([],    a[-100,0])
    #assert_equal(@cls[1],   a[-100,1])
    assert_equal([[1]],   a[-100,1])

    assert_equal(@cls[10, 11, 12], a[9, 3])
    assert_equal(@cls[10, 11, 12], a[-91, 3])

    # assert_equal(@cls[1],   a[0..0])
    assert_equal([[1]],   a[0..0])
    # assert_equal(@cls[100], a[99..99])
    assert_equal([[100]], a[99..99])
    # assert_equal(@cls[],    a[100..100])
    assert_equal([],    a[100..100])
    # assert_equal(@cls[100], a[99..200])
    assert_equal([[100]], a[99..200])
    # assert_equal(@cls[100], a[-1..-1])
    assert_equal([[100]], a[-1..-1])
    # assert_equal(@cls[99],  a[-2..-2])
    assert_equal([[99]],  a[-2..-2])

    assert_equal(@cls[10, 11, 12], a[9..11])
    assert_equal(@cls[10, 11, 12], a[-91..-89])

    assert_nil(a[10, -3])
    # Ruby 1.8 feature change:
    # Array#[size..x] returns [] instead of nil.
    #assert_nil(a[10..7])
    assert_equal [], a[10..7]

    assert_raise(TypeError) {a['cat']}
  end

  def test_ASET # '[]='
    # Changes: values and results specified in frame 
    # added mirror tests to ensure testing using array
    # and index inputs
    
    # -- pair -- 
    a = @cls[*(0..99).to_a]
    #assert_equal(0, a[0] = 0)
    assert_equal([0], a[0] = [0])  
    assert_equal(@cls[0] + @cls[*(1..99).to_a], a)
    
    a = @cls[*(0..99).to_a]
    b = @cls[0]
    assert_equal(b, a[0] = b)  
    assert_equal(@cls[0] + @cls[*(1..99).to_a], a)
    
    # -- pair -- 
    a = @cls[*(0..99).to_a]
    #assert_equal(0, a[10,10] = 0)
    assert_equal([[0]], a[10,10] = [[0]])
    assert_equal(@cls[*(0..9).to_a] + @cls[0] + @cls[*(20..99).to_a], a)
    
    a = @cls[*(0..99).to_a]
    b = @cls[0]
    assert_equal(b, a[10,10] = b)
    assert_equal(@cls[*(0..9).to_a] + @cls[0] + @cls[*(20..99).to_a], a)
    
    # -- pair -- 
    a = @cls[*(0..99).to_a]
    #assert_equal(0, a[-1] = 0) 
    assert_equal([0], a[-1] = [0])
    assert_equal(@cls[*(0..98).to_a] + @cls[0], a)
    
    a = @cls[*(0..99).to_a]
    b = @cls[0]
    assert_equal(b, a[-1] = b)
    assert_equal(@cls[*(0..98).to_a] + @cls[0], a)    

    # -- pair -- 
    a = @cls[*(0..99).to_a]
    #assert_equal(0, a[-10, 10] = 0)
    assert_equal([[0]], a[-10, 10] = [[0]]) 
    assert_equal(@cls[*(0..89).to_a] + @cls[0], a)
    
    a = @cls[*(0..99).to_a]
    b = @cls[0]
    assert_equal(b, a[-10, 10] = b) 
    assert_equal(@cls[*(0..89).to_a] + @cls[0], a)
    
    # -- pair -- 
    a = @cls[*(0..99).to_a]
    #assert_equal(0, a[0,1000] = 0)
    assert_equal([[0]], a[0,1000] = [[0]])
    assert_equal(@cls[0] , a)
    
    a = @cls[*(0..99).to_a]
    b = @cls[0]
    assert_equal(b, a[0,1000] = b) 
    assert_equal(@cls[0] , a)

    # -- pair -- 
    a = @cls[*(0..99).to_a]
    #assert_equal(0, a[10..19] = 0)
    assert_equal([[0]], a[10..19] = [[0]])
    assert_equal(@cls[*(0..9).to_a] + @cls[0] + @cls[*(20..99).to_a], a)
    
    a = @cls[*(0..99).to_a]
    b = @cls[0]
    assert_equal(b, a[10..19] = b) 
    assert_equal(@cls[*(0..9).to_a] + @cls[0] + @cls[*(20..99).to_a], a)

    # -- pair -- 
    # Changes: cannot take strings, 
    # replace a,b,c with 1001, 1002, 10003
    #b = @cls[*%w( a b c )]
    b = @cls[1001, 1002, 10003]
    c = [[1001],[1002],[10003]]
    a = @cls[*(0..99).to_a]
    assert_equal(b, a[0,1] = b)
    assert_equal(b + @cls[*(1..99).to_a], a)
    
    a = @cls[*(0..99).to_a] 
    assert_equal(c, a[0,1] = c)
    assert_equal(b + @cls[*(1..99).to_a], a)
    
    # -- pair -- 
    a = @cls[*(0..99).to_a]
    assert_equal(b, a[10,10] = b)
    assert_equal(@cls[*(0..9).to_a] + b + @cls[*(20..99).to_a], a)

    a = @cls[*(0..99).to_a] 
    assert_equal(c, a[10,10] = c)
    assert_equal(@cls[*(0..9).to_a] + c + @cls[*(20..99).to_a], a)
    
    # -- pair -- 
    a = @cls[*(0..99).to_a]
    assert_equal(b, a[-1, 1] = b)
    assert_equal(@cls[*(0..98).to_a] + b, a)

    a = @cls[*(0..99).to_a]
    assert_equal(c, a[-1, 1] = c)
    assert_equal(@cls[*(0..98).to_a] + c, a)
    
    # -- pair -- 
    a = @cls[*(0..99).to_a]
    assert_equal(b, a[-10, 10] = b)
    assert_equal(@cls[*(0..89).to_a] + b, a)

    a = @cls[*(0..99).to_a]
    assert_equal(c, a[-10, 10] = c)
    assert_equal(@cls[*(0..89).to_a] + c, a)
  
    # -- pair --     
    a = @cls[*(0..99).to_a]
    assert_equal(b, a[0,1000] = b)
    assert_equal(b , a)

    a = @cls[*(0..99).to_a]
    assert_equal(c, a[0,1000] = c)
    assert_equal(c , a.to_a)
    
    # -- pair -- 
    a = @cls[*(0..99).to_a]
    assert_equal(b, a[10..19] = b)
    assert_equal(@cls[*(0..9).to_a] + b + @cls[*(20..99).to_a], a)

    a = @cls[*(0..99).to_a]
    assert_equal(c, a[10..19] = c)
    assert_equal(@cls[*(0..9).to_a] + c + @cls[*(20..99).to_a], a)
    
    # Ruby 1.8 feature change:
    # assigning nil does not remove elements.
=begin
    a = @cls[*(0..99).to_a]
    assert_equal(nil, a[0,1] = nil)
    assert_equal(@cls[*(1..99).to_a], a)

    a = @cls[*(0..99).to_a]
    assert_equal(nil, a[10,10] = nil)
    assert_equal(@cls[*(0..9).to_a] + @cls[*(20..99).to_a], a)

    a = @cls[*(0..99).to_a]
    assert_equal(nil, a[-1, 1] = nil)
    assert_equal(@cls[*(0..98).to_a], a)

    a = @cls[*(0..99).to_a]
    assert_equal(nil, a[-10, 10] = nil)
    assert_equal(@cls[*(0..89).to_a], a)

    a = @cls[*(0..99).to_a]
    assert_equal(nil, a[0,1000] = nil)
    assert_equal(@cls[] , a)

    a = @cls[*(0..99).to_a]
    assert_equal(nil, a[10..19] = nil)
    assert_equal(@cls[*(0..9).to_a] + @cls[*(20..99).to_a], a)
=end

    # Changes: should have @cls in definition

    a = @cls[1, 2, 3]
    a[1, 0] = a
    #assert_equal([1, 1, 2, 3, 2, 3], a)
    assert_equal(@cls[1, 1, 2, 3, 2, 3], a)
    
    a = @cls[1, 2, 3]
    a[-1, 0] = a
    #assert_equal([1, 2, 1, 2, 3, 3], a)
    assert_equal(@cls[1, 2, 1, 2, 3, 3], a)
    
    # Additional:
    
    # -- test self insertions --
    a = @cls[1, 2, 3]
    a[1, 3] = a
    assert_equal(@cls[1,1,2,3], a)
    
    a = @cls[1, 2, 3]
    a[3, 3] = a
    assert_equal(@cls[1,2,3,1,2,3], a)
    
    a = @cls[1, 2, 3]
    a[4, 3] = a
    assert_equal(@cls[1,2,3,0,1,2,3], a)
    
    # -- test insertions where padding is necessary --
    # -- pair -- 
    a = @cls[1,2,3, {:nil_value => [8]}]
    b = @cls[1001, 1002, 10003, {:nil_value => [8]}]
    assert_equal(b, a[4, 3] = b)
    assert_equal(@cls[1,2,3,8,1001,1002,10003, {:nil_value => [8]}], a.to_a)

    a = @cls[1,2,3, {:nil_value => [8]}]
    c = [[1001], [1002], [10003]]
    assert_equal(c, a[4, 3] = c)
    assert_equal(@cls[1,2,3,8,1001,1002,10003, {:nil_value => [8]}], a)
    
    # -- pair -- 
    a = @cls[1,2,3, {:nil_value => [8]}]
    b = @cls[1001, 1002, 10003, {:nil_value => [8]}]
    assert_equal(b, a[4, 1] = b)
    assert_equal(@cls[1,2,3,8,1001,1002,10003, {:nil_value => [8]}], a)

    a = @cls[1,2,3, {:nil_value => [8]}]
    c = [[1001], [1002], [10003]]
    assert_equal(c, a[4, 1] = c)
    assert_equal(@cls[1,2,3,8,1001,1002,10003, {:nil_value => [8]}], a)
    
    # -- test insertions with nils -- 
    # -- pair -- 
    a = @cls[1,2,3]
    b = @cls[1001, nil, nil, 10003]
    assert_equal(b, a[1, 3] = b)
    assert_equal(@cls[1,1001,0,0,10003], a)
    
    a = @cls[1,2,3]
    c = [[1001], nil, nil, [10003]]
    assert_equal(c, a[1, 3] = c)
    assert_equal(@cls[1,1001,0,0,10003], a)
    
    # -- insert beyond end of index, with inconsistent range --
    # first check the array behavior, then assert the same with ExternalIndex
    a = (0..5).to_a
    assert_equal([11,12,13], a[11..12] = [11,12,13])
    assert_equal((0..5).to_a + [nil,nil,nil,nil,nil] + (11..13).to_a, a)
    
    # -- pair -- 
    a = @cls[*(0..5).to_a]
    b = @cls[11,12,13]
    assert_equal(b, a[11..12] = b)
    assert_equal(@cls[*(0..5).to_a] + @cls[0,0,0,0,0] + b, a)
    
    a = @cls[*(0..5).to_a]
    c = [[11],[12],[13]]
    assert_equal(c, a[11..12] = c)
    assert_equal(@cls[*(0..5).to_a] + @cls[0,0,0,0,0] + c, a)
  end

  def test_at
    # Chagnes: values must be in frame
    
    a = @cls[*(0..99).to_a]
    # assert_equal(0,   a.at(0))
    assert_equal([0],   a.at(0))
    # assert_equal(10,  a.at(10))
    assert_equal([10],  a.at(10))
    # assert_equal(99,  a.at(99))
    assert_equal([99],  a.at(99))
    assert_equal(nil, a.at(100))
    # assert_equal(99,  a.at(-1))
    assert_equal([99],  a.at(-1))
    # assert_equal(0,  a.at(-100))
    assert_equal([0],  a.at(-100))
    assert_equal(nil, a.at(-101))

    assert_raise(TypeError) { a.at('cat') }
  end
  
  def test_collect
    # Changes: ExternalIndex doesn't support the types used, 
    # collection must be in frame, and assertions must
    # be rewritten with @cls
    
    #a = @cls[ 1, 'cat', 1..1 ]
    #assert_equal([ Fixnum, String, Range], a.collect {|e| e.class} )
    #assert_equal([ 99, 99, 99], a.collect { 99 } )
    a = @cls[ 1, 2, 3 ]
    assert_equal(@cls[ 4, 5, 6], a.collect {|e| [e[0] + 3] } )
    assert_equal(@cls[ 99, 99, 99], a.collect { [99] } )

    #assert_equal([], @cls[].collect { 99 })
    assert_equal(@cls[], @cls[].collect { [99] })

    # Ruby 1.9 feature change:
    # Enumerable#collect without block returns an Enumerator.
    #assert_equal([1, 2, 3], @cls[1, 2, 3].collect)
    assert_kind_of Enumerable::Enumerator, @cls[1, 2, 3].collect
  end
  
  def test_concat
    # Changes: ExternalIndex does not support Array/ExternalIndex nesting
    
    assert_equal(@cls[1, 2, 3, 4],     @cls[1, 2].concat(@cls[3, 4]))
    assert_equal(@cls[1, 2, 3, 4],     @cls[].concat(@cls[1, 2, 3, 4]))
    assert_equal(@cls[1, 2, 3, 4],     @cls[1, 2, 3, 4].concat(@cls[]))
    assert_equal(@cls[],               @cls[].concat(@cls[]))
    #assert_equal(@cls[@cls[1, 2], @cls[3, 4]], @cls[@cls[1, 2]].concat(@cls[@cls[3, 4]]))
    
    # Changes: should have @cls in definition
    
    a = @cls[1, 2, 3]
    a.concat(a)
    #assert_equal([1, 2, 3, 1, 2, 3], a)
    assert_equal(@cls[1, 2, 3, 1, 2, 3], a)
  end

  def test_each
    # Changes: cannot take strings, 
    # replace (ant bat cat dog) with [1,2,3,4]
    
    #a = @cls[*%w( ant bat cat dog )]
    a = @cls[*(1..4).to_a]
    i = 0
    a.each { |e|
      assert_equal(a[i], e)
      i += 1
    }
    assert_equal(4, i)

    a = @cls[]
    i = 0
    a.each { |e|
      assert_equal(a[i], e)
      i += 1
    }
    assert_equal(0, i)

    assert_equal(a, a.each {})
  end
  
  def test_each_index
    # Changes: cannot take strings, 
    # replace (ant bat cat dog) with [1,2,3,4]
    
    #a = @cls[*%w( ant bat cat dog )]
    a = @cls[*(1..4).to_a]
    i = 0
    a.each_index { |ind|
      assert_equal(i, ind)
      i += 1
    }
    assert_equal(4, i)

    a = @cls[]
    i = 0
    a.each_index { |ind|
      assert_equal(i, ind)
      i += 1
    }
    assert_equal(0, i)

    assert_equal(a, a.each_index {})
  end
  
  def test_eql?
    assert(@cls[].eql?(@cls[]))
    assert(@cls[1].eql?(@cls[1]))
    assert(@cls[1, 1, 2, 2].eql?(@cls[1, 1, 2, 2]))

    # Changes: all values are treated according to the format
    # so these floats are converted to ints and the ExternalIndexs 
    # are equal
    #assert(!@cls[1.0, 1.0, 2.0, 2.0].eql?(@cls[1, 1, 2, 2]))
    assert(@cls[1.0, 1.0, 2.0, 2.0].eql?(@cls[1, 1, 2, 2]))
  end

  def test_first
    # Changes: must be in frame
    #assert_equal(3,   @cls[3, 4, 5].first)
    assert_equal([3],   @cls[3, 4, 5].first)
    assert_equal(nil, @cls[].first)
  end
  
  def test_include?
    # Changes: must have index inputs and be in frame
    # a = @cls[ 'cat', 99, /a/, @cls[ 1, 2, 3] ]
    # assert(a.include?('cat'))
    # assert(a.include?(99))
    # assert(a.include?(/a/))
    # assert(a.include?([1,2,3]))
    # assert(!a.include?('ca'))
    # assert(!a.include?([1,2]))
    
    a = @cls[ 1, 99, 2, 3 ]
    assert(a.include?([1]))
    assert(a.include?([99]))
    assert(a.include?([2]))
    assert(a.include?([3]))
    assert(!a.include?([4]))
    assert(!a.include?([5]))
  end

  def test_last
    # Changes: must be in frame
    
    assert_equal(nil, @cls[].last)
    # assert_equal(1, @cls[1].last)
    assert_equal([1], @cls[1].last)
    # assert_equal(99, @cls[*(3..99).to_a].last)
    assert_equal([99], @cls[*(3..99).to_a].last)
  end
  
  def test_push
    # Changes: pushed values need to be framed
    
    a = @cls[1, 2, 3]
    assert_equal(@cls[1, 2, 3, 4, 5], a.push([4], [5]))
    assert_equal(@cls[1, 2, 3, 4, 5, nil], a.push(nil))
    # Ruby 1.8 feature:
    # Array#push accepts any number of arguments.
    #assert_raise(ArgumentError, "a.push()") { a.push() }
    a.push
    assert_equal @cls[1, 2, 3, 4, 5, nil], a
    a.push [6], [7]
    assert_equal @cls[1, 2, 3, 4, 5, nil, 6, 7], a
  end
  
  def test_reverse_each
    # Changes: gotta have index entries.
    #a = @cls[*%w( dog cat bee ant )]
    a = @cls[1,2,3]
    i = a.length
    a.reverse_each { |e|
      i -= 1
      assert_equal(a[i], e)
    }
    assert_equal(0, i)

    a = @cls[]
    i = 0
    a.reverse_each { |e|
      assert(false, "Never get here")
    }
    assert_equal(0, i)
  end
  
  def test_to_a
    a = @cls[ 1, 2, 3 ]
    # Changes: can't do this comparison by object id
    #a_id = a.__id__
    #assert_equal(a, a.to_a)
    assert_equal [[1],[2],[3]], a.to_a
    #assert_equal(a_id, a.to_a.__id__)
  end
  
  def test_values_at
    # Changes: gotta have index entries
    # a = @cls[*('a'..'j').to_a]
    # assert_equal(@cls['a', 'c', 'e'], a.values_at(0, 2, 4))
    # assert_equal(@cls['j', 'h', 'f'], a.values_at(-1, -3, -5))
    # assert_equal(@cls['h', nil, 'a'], a.values_at(-3, 99, 0))
    
    a = @cls[*(1..10).to_a]
    assert_equal(@cls[1, 3, 5], a.values_at(0, 2, 4))
    assert_equal(@cls[10, 8, 6], a.values_at(-1, -3, -5))
    assert_equal(@cls[8, a.nil_value , 1], a.values_at(-3, 99, 0))
  end

  
  #############################
  # Additional Array methods tests
  #############################
  
  #
  # ASET tests
  #
  
  def test_ASET_raises_error_if_input_is_not_in_frame
    a = @cls.new
    assert_raise(ArgumentError) { a[0] = 1 }
    assert_raise(ArgumentError) { a[0,1] = [1] }
    assert_raise(ArgumentError) { a[0,1] = [[1,2]] }
  end
  
  def test_ASET_raises_error_if_input_is_index_with_different_attributes
    a = @cls.new(nil, :format => "I")
    b = @cls.new(nil, :format => "II")
    assert_raise(ArgumentError) { a[0,1] = b }
  end
  
end
