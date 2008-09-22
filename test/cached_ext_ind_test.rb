require File.expand_path("#{File.dirname(__FILE__)}/ext_ind_test.rb") 

class CachedExtIndTest < ExtIndTest
  class CachedExtInd < ExtInd
    def initialize(io=nil, options={})
      options = {
        :cached => true
      }.merge(options)
      
      super(io, options)
    end
  end
  
  def setup
    # cls represents an array
    @cls = CachedExtInd

    @index = CachedExtInd.new
    @index.cache.concat(framed_array)
  end
  
  def teardown
  end
  
  #
  # setup tests
  #
  
  def test_setup
    assert_equal CachedExtInd, @cls
    
    assert_equal 0, index.pos
    assert_equal 5, index.length
    assert_equal 4, index.frame_size
    assert index.cached?
    assert_equal framed_array, index.cache
  end
  
  
  #
  # initialize tests
  #
  
  undef_method :test_index_initialized_to_single_int_format_by_default
  
  def test_cache_initialized_to_empty_array_in_cached_mode
    index = @cls.new
  
    assert_equal 'I*', index.format
    assert_equal 1, index.frame
    assert_equal 4, index.frame_size
    assert_equal [0], index.nil_value
    assert index.cached?
    assert_equal [], index.cache
  end
  
  def test_cache_initialized_to_empty_array_in_cached_mode_regardless_of_format
    index = @cls.new nil, :format => "IQS"

    assert index.cached?
    assert_equal [], index.cache
  end
  
  #
  # close tests
  #
  
  def test_close_flushes_cache
    assert_equal 0, index.io.length
    index.close
    assert_equal(framed_array.length * 4, index.io.length)
  end
  
  def test_close_does_not_flush_cache_if_flush_false
    assert_equal 0, index.io.length
    index.close(nil, false)
    assert_equal 0, index.io.length
  end
  
  
  #
  # class read tests
  #
  
  undef_method :test_read_returns_the_index_file_in_frame
  
  #
  # class directive size tests
  #
  
  undef_method :test_directive_size_returns_the_number_of_bytes_to_pack_a_directive
 
  #
  # length test
  #
  
  undef_method :test_length_returns_io_length_divided_by_frame_size
  
  def test_length_returns_cache_length
    assert_equal index.cache.length, index.length
    
    index.cache.clear
    assert_equal 0, index.length
    
    index.cache.concat([[1],[2],[3]])
    assert_equal 3, index.length
  end
  
  def test_length_is_separate_from_io_length
    index.cache.clear
    assert_equal 0, index.length
    
    index.io.length = 10
    assert_equal 0, index.length
  end
  
  #
  # pos test
  #
  
  undef_method :test_pos_returns_io_pos_divided_by_frame_size
  
  def test_pos_is_kept_separate_from_io_pos_in_cached_mode
    assert_equal 0, index.io.pos
    assert_equal 0, index.pos
    
    index.io.pos = 4
    assert_equal 4, index.io.pos
    assert_equal 0, index.pos
  end
  
  #
  # pos= test
  #
  
  undef_method :test_pos_set_sets_io_pos_to_index_value_of_input_times_frame_size
  
  def test_pos_set_sets_pos_to_index_value_of_input
    index.pos = 1
    assert_equal 1, index.pos
    
    index.pos = -1
    assert_equal 4, index.pos
  end
  
  #
  # readbytes test
  #
  
  undef_method :test_readbytes_behavior_is_like_io_behavior
  
  #
  # write tests
  #
  
  def test_cached_write_documentation
    i = @cls.new
    i.write([["cat"]])
    assert_equal ["cat"], i.last
    assert_raise(TypeError) { i.cached = false }
  end
  
  def test_cached_write_does_not_check_that_entries_are_valid
    i = @cls.new
    i.write([["cat"]])
    assert_equal ["cat"], i.last
  end
  
  #
  # unframed_write tests
  #
  
  undef_method :test_unframed_write_unframed_writes_packed_array_to_io_at_pos_and_adjusts_io_length
  
  def test_cached_unframed_write_does_not_check_that_entries_are_valid
    i = @cls.new
    i.unframed_write(["cat"])
    assert_equal ["cat"], i.last
  end
  
  def test_unframed_write_unframed_writes_packed_array_to_cache_in_frame_and_does_not_affect_io
    index = @cls.new
    index.unframed_write([1,2,3])
    assert_equal 0, index.io.length
    assert_equal 0, index.io.pos
    
    assert_equal [[1],[2],[3]], index.cache
     
    index.unframed_write([-2], 1)
    assert_equal 0, index.io.length
    assert_equal 0, index.io.pos

    assert_equal [[1],[-2],[3]], index.cache
  end
  
  def test_unframed_write_pads_with_nil_value_if_position_is_past_length
    index = @cls.new nil, :nil_value => [8]
    assert_equal 0, index.length
    
    index.unframed_write([1,2,3], 2)
    assert_equal [[8],[8],[1],[2],[3]], index.cache
  end
  
  def test_unframed_write_unframed_writes_nothing_with_empty_array
    assert_equal framed_array, index.cache
    
    index.unframed_write([])
    assert_equal framed_array, index.cache
    
    index.unframed_write([], 0)
    assert_equal framed_array, index.cache
  end
  

  #
  # mixed formats test
  #
  
  def test_read_handles_mixed_formats
    index = @cls.new nil, :format => "IQS"
    
    index.cache << [1,2,3]
    index.cache << [4,5,6]
    index.cache << [7,8,9]
    
    assert_equal [[1,2,3],[4,5,6],[7,8,9]], index.read
    
    index.pos = 1
    assert_equal [4,5,6], index.read(1)
  end
  
  def test_unframed_write_handles_mixed_formats
    index = @cls.new nil, :format => "IQS"
    a = [1,2,3]
    b = [4,5,6]
    c = [7,8,9]
    d = [-4,-5,-6]
    
    index.unframed_write([1,2,3,4,5,6,7,8,9])
    assert_equal [a,b,c], index.cache

    index.pos = 1
    index.unframed_write([-4,-5,-6])
    assert_equal [a,d,c], index.cache
  end
  
  #
  # numeric format range tests
  #
  
  undef_method :test_read_and_unframed_write_handles_full_numeric_range_for_numeric_formats
  undef_method :test_read_and_unframed_write_cycle_numerics_beyond_natural_range
  undef_method :test_numerics_cycle_up_to_the_unsigned_max_in_either_sign

  def test_unframed_write_does_NOT_check_formatting_of_input_in_cached_mode
    index = @cls.new nil, :format => "S"
    assert_raise(RangeError) { [ExtIndTest::ULLONG_MAX].pack("S") }
    assert_nothing_raised { index.unframed_write([ExtIndTest::ULLONG_MAX]) }
  end
end
