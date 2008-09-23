require File.join(File.dirname(__FILE__), '../external_test_helper.rb') 
require 'external/chunkable'
require 'pp'

class ChunkableTest < Test::Unit::TestCase
  include External::Chunkable
  
  def setup
    @default_blksize = 100
    @length = 10
  end
  
  def pps(obj)
    PP.singleline_pp(obj, "")
  end
  
  def test_setup
    assert_equal 100, default_blksize
    assert_equal 10, length
  end

  #
  # default_span
  #
  
  def test_default_span_is_zero_to_length
    assert_equal [0,length], default_span
  end
  
  #
  # chunk tests
  #
  
  def test_chunk_documentation
    assert_equal 100, default_blksize 
    assert_equal [[0,100],[100,100],[200,50]], chunk(0..250) 
    
    results = []
    chunk([10,190]) {|offset, length| results << [offset, length]}
    assert_equal [[10,100],[110,90]], results
  end

  def test_chunk_returns_offset_and_length_of_each_chunk
    assert_equal [[0,99]], chunk([0,99])
    assert_equal [[0,100]], chunk([0,100])
    assert_equal [[0,100],[100,1]], chunk([0,101])
    assert_equal [[0,100],[100,100],[200,100]], chunk([0,300])
    assert_equal [[50,100],[150,100],[250,50]], chunk([50,250])
    
    # zero or neg length
    assert_equal [], chunk([0,0])
    assert_equal [], chunk([0,-1])
    
    # neg index
    assert_equal [[9,100]], chunk([-1,100])
    assert_equal [[0,100]], chunk([-10,100])
    assert_raise(ArgumentError) { chunk([-11,100]) }
    assert_raise(ArgumentError) { chunk([-11,0]) }
  end
  
  def test_chunk_uses_default_span_without_inputs
    assert_equal [0,10], default_span
    assert_equal [[0,10]], chunk
    
    self.length = 300
    assert_equal [0, 300], default_span
    assert_equal [[0,100],[100,100],[200,100]], chunk
  end
  
  def test_chunk_passes_results_to_block_if_given
    results = []
    chunk([0,300]) do |offset, length|
      results << [offset, length]
    end
      
    assert_equal [[0,100],[100, 100],[200, 100]], results
  end

  #
  # reverse chunk tests
  #
  
  def test_reverse_chunk_documentation
    assert_equal 100, default_blksize 
    assert_equal [[150,100],[50,100],[0,50]], reverse_chunk(0..250) 
    
    results = []
    reverse_chunk([10,190]) {|offset, length| results << [offset, length]}
    assert_equal [[100,100],[10,90]], results
  end
  
  def test_reverse_chunk_returns_offset_and_length_of_each_chunk
    assert_equal [[0,99]], reverse_chunk([0,99])
    assert_equal [[0,100]], reverse_chunk([0,100])
    assert_equal [[1,100],[0,1]], reverse_chunk([0,101])
    assert_equal [[200,100],[100,100],[0,100]], reverse_chunk([0,300])
    assert_equal [[200,100],[100,100],[50,50]], reverse_chunk([50,250])
    
    # zero or neg length
    assert_equal [], reverse_chunk([0,0])
    assert_equal [], reverse_chunk([0,-1])

    # neg index
    assert_equal [[9,100]], reverse_chunk([-1,100])
    assert_equal [[0,100]], reverse_chunk([-10,100])
    assert_raise(ArgumentError) { reverse_chunk([-11,100]) }
    assert_raise(ArgumentError) { reverse_chunk([-11,0]) }
  end

  def test_reverse_chunk_uses_default_span_without_inputs
    assert_equal [0,10], default_span
    assert_equal [[0,10]], reverse_chunk
    
    self.length = 300
    assert_equal [0,300], default_span
    assert_equal [[200,100],[100,100],[0,100]], reverse_chunk
  end
  
  def test_reverse_chunk_passes_results_to_block_if_given
    results = []
    reverse_chunk([0,300]) do |offset, length|
      results << [offset, length]
    end
      
    assert_equal [[200,100],[100,100],[0,100]], results
  end
  
  #
  # split_range 
  #
  
  def test_split_range_doc
    assert_equal 10, length
    assert_equal [0,10], split_range(0..10) 
    assert_equal [0,9], split_range(0...10) 
    assert_equal [9,1], split_range(-1..10) 
    assert_equal [0,9], split_range(0..-1)
  end
  
  def test_split_range
    {
      0..100 => [0,100],
      0...100 => [0, 99],
      1..100 => [1,99],
      1...100 => [1,98]
    }.each_pair do |range, expected|
      assert_equal expected, split_range(range), range
    end
  end
  
  def test_split_range_for_negative_indicies_counts_back_from_length
    assert_equal 10, length
    {
      # for begin index
      -1..100 => [9,91],  # equivalent to 9..100
      -1...100 => [9,90],
      -2..100 => [8,92],
      -2...100 => [8,91],
      -11..100 => [-1,101],
      -11...100 => [-1,100],
      
      # for end index
      0..-1 => [0,9],  # equivalent to 0..9
      0...-1 => [0,8],
      0..-10 => [0,0]
    }.each_pair do |range, expected|
      assert_equal expected, split_range(range), range
    end
  end
  
  def test_split_range_for_zero_cases
    {
      0..0 => [0,0],
      0...0 => [0,-1],
      -0..-0 => [0,0],
      -0...-0 => [0,-1]
    }.each_pair do |range, expected|
      assert_equal expected, split_range(range), range
    end
  end
  
  #
  # split_span test
  #
  
  def test_split_span_documentation
    assert_equal 10, length
    assert_equal [0,10], split_span([0, 10])
    assert_equal [9,1], split_span([-1, 1])
  end
  
  #
  # range_begin_and_end test
  #
  
  def test_range_begin_and_end_documentation
    assert_equal [0, 10], range_begin_and_end(0..10)
    assert_equal [0, 9], range_begin_and_end(0...10)
    assert_equal [0, 10], range_begin_and_end([0, 10])
  end
  
end