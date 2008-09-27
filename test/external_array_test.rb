require File.join(File.dirname(__FILE__), 'external_test_helper.rb') 
require 'external_array'
require 'fileutils'

class ExternalArrayTest < Test::Unit::TestCase
  acts_as_file_test

  def setup
    super
    # cls represents an array
    @cls = ExternalArray
  end
  
  #
  # initialize tests
  #
  
  def test_initialize
    ea = ExternalArray.new
    assert_equal "", ea.io.read
    assert_equal [], ea.io_index.to_a
  end
  
  #
  # test reindex
  #
  
  def reindex_test(arr, blksize=nil)
    str = ""
    arr.each {|i| str += i.to_yaml}
    StringIO.open(str) do |strio|
      ea = ExternalArray.new(strio)
      ea.io.default_blksize = blksize unless blksize == nil 
      ea.reindex
      assert_equal arr, ea.to_a, PP.singleline_pp(arr, "")
      
      yield(str, ea.io_index.to_a) if block_given?
    end
  end
  
  def test_reindex
    reindex_test [1, 2, 3.3, "cat", {:key => 'value'}] do |str, index|
      assert_equal "--- 1\n--- 2\n--- 3.3\n--- cat\n--- \n:key: value\n", str
      assert_equal [[0, 6], [6, 6], [12, 8], [20, 8], [28, 17]], index
    end
    
    reindex_test []
    reindex_test [nil, nil, nil]
    reindex_test [1, 2, 3.3, "cat", [:a, :b], {:key => 'value', :alt => 'value'}]
    reindex_test [[1,2,3].to_yaml]
    reindex_test [{:one => 'one', :two => 'two'}.to_yaml]
    
    arr = [[:a, [:b, {:c => [1,2,3].to_yaml}]],{:a => {:b => [:c, [1,2,3].to_yaml]}}]
    reindex_test arr
    
    half_length = arr.to_yaml.length/2
    reindex_test arr, half_length
    
    third_length = arr.to_yaml.length/3
    reindex_test arr, third_length
    
    # fails due to YAML deserialization
    #reindex_test ["\n", "\r\n", "", "--- \n"]
  end
  
  #
  # entry_to_str, str_to_entry test
  #

  def test_entry_to_str_and_str_to_entry_are_inverse_functions
    extarr = ExternalArray.new '', ''
    
    [ nil, true, false,
      :symbol,
      '', 'a', "abcde fghij", "1234", "with\nnewline", " \r \n \t  ", " ", "\t", 
      0, 1, -1, 18446744073709551615,
      1.1, -1.1,
      [], [1,2,3], 
      {}, {:key => 'value', 'another' => 1}, 
      Time.now,
      
      # yaml and nested yaml
      {:key => 'value', 'another' => 1}.to_yaml, 
      [1,2,3].to_yaml, 
      {{:key => 'value', 'another' => 1}.to_yaml => [1,2,3].to_yaml}.to_yaml
    ].each do |obj|
      str = extarr.entry_to_str(obj)
      assert_equal obj, extarr.str_to_entry(str)
    end
  
    # FLUNK cases
    [ "\r", 
      "\r\n", 
      "string with \r\n internal",
      "\n", "\n\n\n"
    ].each do |obj|
      str = extarr.entry_to_str(obj)
      assert_not_equal obj, extarr.str_to_entry(str)
    end
    
    # ERROR cases
    [ lambda {},
      Object # a class
    ].each do |obj|
      assert_raise(TypeError) do
        str = extarr.entry_to_str(obj)
        extarr.str_to_entry(str)
      end
    end
  end
  
  def test_datetimes_are_loaded_as_Times
    extarr = ExternalArray.new '', ''
    
    now = DateTime.now
    dumped_entry = extarr.entry_to_str(now)
    loaded_entry = extarr.str_to_entry(dumped_entry)
    
    assert_equal Time, loaded_entry.class
    assert_equal now.year, loaded_entry.year
    assert_equal now.month, loaded_entry.month
    assert_equal now.day, loaded_entry.day
    assert_equal now.hour, loaded_entry.hour
    assert_equal now.min, loaded_entry.min
    assert_equal now.sec, loaded_entry.sec
  end

  #############################
  # Documentation tests
  #############################

  def test_AGET_documentation
    a = ExternalArray[ "a", "b", "c", "d", "e" ]
    assert_equal "cab", a[2] +  a[0] + a[1]
    assert_equal nil, a[6]
    assert_equal [ "b", "c" ], a[1, 2]
    assert_equal [ "b", "c", "d" ], a[1..3]
    assert_equal [ "e" ], a[4..7]
    assert_equal nil, a[6..10]
    assert_equal [ "c", "d", "e" ], a[-3, 3]
    # special cases
    assert_equal nil, a[5]
    assert_equal [], a[5, 1]
    assert_equal [], a[5..10]
  end
  
  def test_ASET_documentation
    a = ExternalArray.new
    a[4] = "4"
    assert_equal [nil, nil, nil, nil, "4"], a
    a[0, 3] = [ 'a', 'b', 'c' ]
    assert_equal ["a", "b", "c", nil, "4"], a
    a[1..2] = [ 1, 2 ]
    assert_equal ["a", 1, 2, nil, "4"], a
    a[0, 2] = "?"
    assert_equal ["?", 2, nil, "4"], a
    a[0..2] = "A"
    assert_equal ["A", "4"], a
    a[-1]   = "Z"
    assert_equal ["A", "Z"], a
    a[1..-1] = nil
    assert_equal ["A"], a
  end
  
  ##########################################################
  # Modified Array methods tests
  #
  # taken from Ruby 1.9 trunk, revision 13450 (2007-16-2007)
  # test/ruby/test_array.rb
  ##########################################################

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
    # Changes: had to rewrite arrays as @cls
    
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
  
    x = @cls["foo", "bar", "baz", "baz", 1, 2, 3, 3, 4]
    assert_equal(@cls["baz","baz"], x.find_all{ |obj| obj == "baz" })
    assert_equal(@cls[3,3], x.find_all{ |obj| obj == 3 })
  end
  
  def test_LSHIFT # '<<'
    a = @cls[]
    a << 1
    assert_equal(@cls[1], a)
    a << 2 << 3
    assert_equal(@cls[1, 2, 3], a)
    a << nil << 'cat'
    assert_equal(@cls[1, 2, 3, nil, 'cat'], a)
    
    # Changes: when you add a to itself, the version at 
    # the << line is added, not the one that appears in the
    # comparison
    #a << a
    #assert_equal(@cls[1, 2, 3, nil, 'cat', a], a)
    
    b = @cls.new
    a << b
    assert_equal(@cls[1, 2, 3, nil, 'cat', b], a)
  end

  def test_ASET # '[]='
    a = @cls[*(0..99).to_a]
    assert_equal(0, a[0] = 0)
    assert_equal(@cls[0] + @cls[*(1..99).to_a], a)

    a = @cls[*(0..99).to_a]
    assert_equal(0, a[10,10] = 0)
    assert_equal(@cls[*(0..9).to_a] + @cls[0] + @cls[*(20..99).to_a], a)

    a = @cls[*(0..99).to_a]
    assert_equal(0, a[-1] = 0)
    assert_equal(@cls[*(0..98).to_a] + @cls[0], a)

    a = @cls[*(0..99).to_a]
    assert_equal(0, a[-10, 10] = 0)
    assert_equal(@cls[*(0..89).to_a] + @cls[0], a)

    a = @cls[*(0..99).to_a]
    assert_equal(0, a[0,1000] = 0)
    assert_equal(@cls[0] , a)

    a = @cls[*(0..99).to_a]
    assert_equal(0, a[10..19] = 0)
    assert_equal(@cls[*(0..9).to_a] + @cls[0] + @cls[*(20..99).to_a], a)

    b = @cls[*%w( a b c )]
    a = @cls[*(0..99).to_a]
    assert_equal(b, a[0,1] = b)
    assert_equal(b + @cls[*(1..99).to_a], a)

    a = @cls[*(0..99).to_a]
    assert_equal(b, a[10,10] = b)
    assert_equal(@cls[*(0..9).to_a] + b + @cls[*(20..99).to_a], a)

    a = @cls[*(0..99).to_a]
    assert_equal(b, a[-1, 1] = b)
    assert_equal(@cls[*(0..98).to_a] + b, a)

    a = @cls[*(0..99).to_a]
    assert_equal(b, a[-10, 10] = b)
    assert_equal(@cls[*(0..89).to_a] + b, a)

    a = @cls[*(0..99).to_a]
    assert_equal(b, a[0,1000] = b)
    assert_equal(b , a)

    a = @cls[*(0..99).to_a]
    assert_equal(b, a[10..19] = b)
    assert_equal(@cls[*(0..9).to_a] + b + @cls[*(20..99).to_a], a)

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
    assert_equal([1, 1, 2, 3, 2, 3], a)

    a = @cls[1, 2, 3]
    a[-1, 0] = a
    assert_equal([1, 2, 1, 2, 3, 3], a)
  end
  
  def test_collect
    # Changes: YAML cannot dump the class. Also had to rewrite
    # assertions with @cls due to comparison order.
    
    a = @cls[ 1, 'cat', 1..1 ]
    #assert_equal([ Fixnum, String, Range], a.collect {|e| e.class} )
    assert_equal(@cls[ 'Fixnum', 'String', 'Range'], a.collect {|e| e.class.to_s } )
    #assert_equal([ 99, 99, 99], a.collect { 99 } )
    assert_equal(@cls[ 99, 99, 99], a.collect { 99 } )

    #assert_equal([], @cls[].collect { 99 })
    assert_equal(@cls[], @cls[].collect { 99 })

    # Ruby 1.9 feature change:
    # Enumerable#collect without block returns an Enumerator.
    #assert_equal([1, 2, 3], @cls[1, 2, 3].collect)
    assert_kind_of Enumerable::Enumerator, @cls[1, 2, 3].collect
  end
  
  def test_concat
    assert_equal(@cls[1, 2, 3, 4],     @cls[1, 2].concat(@cls[3, 4]))
    assert_equal(@cls[1, 2, 3, 4],     @cls[].concat(@cls[1, 2, 3, 4]))
    assert_equal(@cls[1, 2, 3, 4],     @cls[1, 2, 3, 4].concat(@cls[]))
    assert_equal(@cls[],               @cls[].concat(@cls[]))
    assert_equal(@cls[@cls[1, 2], @cls[3, 4]], @cls[@cls[1, 2]].concat(@cls[@cls[3, 4]]))
    
    a = @cls[1, 2, 3]
    a.concat(a)
    assert_equal([1, 2, 3, 1, 2, 3], a)
  end
  
  def test_eql?
    assert(@cls[].eql?(@cls[]))
    assert(@cls[1].eql?(@cls[1]))
    assert(@cls[1, 1, 2, 2].eql?(@cls[1, 1, 2, 2]))
    
    # Changes: converting values to strings and back to 
    # numerics causes equal values to be equal, regardless
    # of whether they were entered as different types initially
    #assert(!@cls[1.0, 1.0, 2.0, 2.0].eql?(@cls[1, 1, 2, 2]))
    assert(@cls[1.0, 1.0, 2.0, 2.0].eql?(@cls[1, 1, 2, 2]))
  end
  
  def test_include?
    # Changes: had to remvove @cls from the above
    # list ... no way to keep state for @cls
    a = @cls[ 'cat', 99, /a/, [ 1, 2, 3] ]
    assert(a.include?('cat'))
    assert(a.include?(99))
    assert(a.include?(/a/))
    assert(a.include?([1,2,3]))
    assert(!a.include?('ca'))
    assert(!a.include?([1,2]))
  end
  
  def test_to_a
    a = @cls[ 1, 2, 3 ]
    a_id = a.__id__
    assert_equal(a, a.to_a)
    
    # Changes: can't do this comparison by object id
    #assert_equal(a_id, a.to_a.__id__)
  end
end