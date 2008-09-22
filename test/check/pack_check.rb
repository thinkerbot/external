require 'test/unit'

# a variety of tests that establish some basic facts/assumptions
# that get leveraged in somewhere in the library
class PackCheck < Test::Unit::TestCase
  
  # NOTE: upon pack:
  # unsigned values throw an error if > MAX or < -MAX
  # negative values are the same as positive values counting back from MAX
  
  LONG_MIN = -2147483648
  LONG_MAX = 2147483647 
  
  ULONG_MIN = 0
  ULONG_MAX = 4294967295
  
  LLONG_MIN = -9223372036854775808
  LLONG_MAX = 9223372036854775807

  ULLONG_MIN = 0
  ULLONG_MAX = 18446744073709551615
  
  def test_negative_unsigned_values_count_back_from_max_in_pack_and_unpack
    assert_equal [ULONG_MAX], [-1].pack('I').unpack('I')
    assert_equal [ULONG_MAX], [-1].pack('L').unpack('L')
    assert_equal [ULLONG_MAX], [-1].pack('Q').unpack('Q')
  end

  def test_signed_values_beyond_min_count_back_from_max_in_pack_and_unpack
    assert_equal [LONG_MAX], [LONG_MIN-1].pack('i').unpack('i')
    assert_equal [LONG_MAX], [LONG_MIN-1].pack('l').unpack('l')
    assert_equal [LLONG_MAX], [LLONG_MIN-1].pack('q').unpack('q')
  end
  
  def test_signed_values_beyond_max_count_up_from_min_in_pack_and_unpack
    assert_equal [LONG_MIN], [LONG_MAX+1].pack('i').unpack('i')
    assert_equal [LONG_MIN], [LONG_MAX+1].pack('l').unpack('l')
    assert_equal [LLONG_MIN], [LLONG_MAX+1].pack('q').unpack('q')
  end
  
  def test_numeric_ranges_for_pack_and_unpack
    # I,L handle an unsigned long
    ['I', 'L'].each do |format|
      assert_equal [ULONG_MIN], [ULONG_MIN].pack(format).unpack(format)
      assert_equal [ULONG_MAX], [ULONG_MAX].pack(format).unpack(format)
      
      #assert_equal [ULONG_MIN], [ULONG_MAX+1].pack(format).unpack(format)
      assert_equal [ULONG_MAX], [ULONG_MIN-1].pack(format).unpack(format)
      
      assert_raise(RangeError) { [-(ULONG_MAX+1)].pack(format) }
      assert_raise(RangeError) { [(ULONG_MAX+1)].pack(format) }
    end
    
    # i,l handle an signed long
    ['i', 'l'].each do |format|
      assert_equal [LONG_MIN], [LONG_MIN].pack(format).unpack(format)
      assert_equal [LONG_MAX], [LONG_MAX].pack(format).unpack(format)
      
      assert_equal [LONG_MIN], [LONG_MAX+1].pack(format).unpack(format)
      assert_equal [LONG_MAX], [LONG_MIN-1].pack(format).unpack(format)
      
      assert_raise(RangeError) { [-2*(LONG_MAX+1)].pack(format) }
      assert_raise(RangeError) { [2*(LONG_MAX+1)].pack(format) }
    end
    
    # Q handles an unsigned long long
    ['Q'].each do |format|
      assert_equal [ULLONG_MIN], [ULLONG_MIN].pack(format).unpack(format)
      assert_equal [ULLONG_MAX], [ULLONG_MAX].pack(format).unpack(format)
      
      #assert_equal [ULLONG_MIN], [ULLONG_MAX+1].pack(format).unpack(format)
      assert_equal [ULLONG_MAX], [ULLONG_MIN-1].pack(format).unpack(format)
      
      assert_raise(RangeError) { [-(ULLONG_MAX+1)].pack(format) }
      assert_raise(RangeError) { [(ULLONG_MAX+1)].pack(format) }
    end
    
    # q handles an signed long long
    ['q'].each do |format|
      assert_equal [LLONG_MIN], [LLONG_MIN].pack(format).unpack(format)
      assert_equal [LLONG_MAX], [LLONG_MAX].pack(format).unpack(format)
      
      assert_equal [LLONG_MIN], [LLONG_MAX+1].pack(format).unpack(format)
      assert_equal [LLONG_MAX], [LLONG_MIN-1].pack(format).unpack(format)
      
      assert_raise(RangeError) { [-2*(LLONG_MAX+1)].pack(format) }
      assert_raise(RangeError) { [2*(LLONG_MAX+1)].pack(format) }
    end
  end
  
  def test_leading_numbers_in_pack_unpack_are_ignored
    assert_equal [1,2,3], [1,2,3].pack("10I3").unpack("I3")
    assert_equal [1,2,3], [1,2,3].pack("I3").unpack("10I3")
    
    assert_equal [1,2,3], [1,2,3].pack("10IQS").unpack("IQS")
    assert_equal [1,2,3], [1,2,3].pack("IQS").unpack("10IQS")
  end
end
