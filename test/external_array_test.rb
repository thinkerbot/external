require File.join(File.dirname(__FILE__), 'external_test_helper.rb') 
require 'external_array'
require 'fileutils'

class ExternalArrayTest < Test::Unit::TestCase
  acts_as_file_test

  attr_reader :ea, :tempfile

  def setup
    super
    # cls represents an array
    @cls = ExternalArray
    
    @tempfile = Tempfile.new("eatest")
    @tempfile << string
    @tempfile.pos = 0

    @ea = ExternalArray.new(@tempfile)
    @ea.io_index.concat(index)
  end
  
  def teardown
    @tempfile.close unless @tempfile.closed?
    super
  end
  
  def string
    "abcdefgh"
  end
  
  def array
    ["abc", "de", "fgh"]
  end
  
  def index
    [[0,3],[3,2],[5,3]]
  end
  
  #
  # doc tests
  #
  
  # def test_readme_doc_for_ext_arr
  #   ea = ExternalArray[1, 2.2, "cat", {:key => 'value'}]
  #   assert_equal "cat", ea[2]  
  #   assert_equal({:key => 'value'}, ea.last)
  #   ea << [:a, :b]
  #   assert_equal [1, 2.2, "cat", {:key => 'value'}, [:a, :b]], ea.to_a 
  #   
  #   assert_equal Tempfile, ea.io.class 
  #   ea.io.rewind
  #   assert_equal "--- 1\n--- 2.2\n--- cat\n--- \n:key: value\n--- \n- :a\n- :b\n", ea.io.read
  # 
  #   assert_equal ExternalIndex, ea.io_index.class 
  #   assert_equal [[0, 6], [6, 8], [14, 8], [22, 17], [39, 15]], ea.io_index.to_a  
  #   
  #   Tempfile.open("test_readme_doc_for_ext_arr") do |file|
  #     file << "--- 1\n--- 2.2\n--- cat\n--- \n:key: value\n--- \n- :a\n- :b\n"
  #     file.flush
  # 
  #     index_filepath = ExternalArray.default_index_filepath(file.path)
  #     assert !File.exists?(index_filepath)
  # 
  #     ea = ExternalArray.new(file)
  #     assert_equal [], ea.to_a 
  #     ea.reindex 
  #     assert_equal [1, 2.2, "cat", {:key => 'value'}, [:a, :b]], ea.to_a
  #   end
  # end
  
  #
  # test setup
  #
  
  def test_setup
    assert_equal ExternalArray, @cls
    
    assert_equal string, tempfile.read
    assert_equal tempfile.path, ea.io.path
    assert_equal index, ea.io_index.to_a
  end
  
  #
  # initialize tests
  #
  
  def test_initialize
    ea = ExternalArray.new
      
    assert_equal Tempfile, ea.io.class
    assert_equal "", ea.io.read
    assert_equal [], ea.io_index.to_a
  end
  
  def test_initialize_with_existing_file_and_index
    File.open(ctr.filepath("input.txt")) do |file|
      ea = ExternalArray.new(file)
      
      assert_equal 'input.txt', File.basename(ea.io.path)
      assert_equal string, ea.io.read
      assert_equal index, ea.io_index.to_a
      
      ea.close
    end
  end
  
  def test_initialize_load_specified_index_file
    File.open(ctr.filepath('without_index.txt')) do |file|
      alt_index = ctr.filepath('input.index')
      
      assert File.exists?(alt_index)
      
      ea = ExternalArray.new(file, :index => alt_index)
      assert_equal File.read(alt_index).unpack("I*"), ea.io_index.to_a.flatten
      ea.close
    end
  end
  
  # def test_initialize_with_existing_file_and_non_existant_index_file_creates_index_file_in_cached_mode
  #   File.open(ctr.filepath('without_index.txt')) do |file|
  #     index_file = ctr.filepath('without_index.index')
  #     begin
  #       assert !File.exists?(index_file)
  #       ea = ExternalArray.new(file, :index => index_file)
  #     
  #       assert_equal ExternalIndex, ea.io_index.class
  #       assert File.exists?(ea.io_index.io.path)
  #       assert ea.io_index.cached?
  #     
  #       ea.close
  #     ensure
  #       FileUtils.rm(index_file) if File.exists?(index_file)
  #     end  
  #   end
  # end
  
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
  
  
  # def test_length_speed
  #   arr = [[1,2,3].to_yaml]
  #   str = arr.to_yaml * 100000
  #   
  #   io = StringIO.new(str)
  #   
  #   bm do |x|
  #     x.report("10k") do
  #       YAML.parse_documents(io) do |doc|
  #         doc
  #       end
  #     end
  #     
  #     io.rewind
  #     x.report("10k length") do
  #       YAML.parse_documents(io) do |doc|
  #         doc.length 
  #       end
  #     end
  #   end
  # end
  
  #
  # entry_to_str, str_to_entry test
  #

  def test_entry_to_str_and_str_to_entry_are_inverse_functions_for_objects_responding_to_to_yaml
    [
      nil, true, false,
      :a, :symbol,
      '', 'a', "abcde fghij", "1234", "with\nnewline", " \r \n \t  ", " ", "\t", [1,2,3].to_yaml, 
      0, 1, -1, 1.1, 18446744073709551615,
      [], [1,2,3], 
      {}, {:key => 'value', 'another' => 1}, 
      Time.now
    ].each do |obj|
      str = ea.entry_to_str(obj)
      assert_equal obj, ea.str_to_entry(str)
    end
    
    # FLUNK CASES! 
    ["\r", "\n", "\r\n", "string_with_\r\n_internal"].each do |obj|
      str = ea.entry_to_str(obj)
      assert_not_equal obj, ea.str_to_entry(str)
    end
  end
  
  def test_strings_and_numerics_can_be_converted_from_their_to_s
    ['a', "abcde fghij"].each  do |obj|
      assert obj.kind_of?(String)
      assert_equal obj, ea.str_to_entry(obj.to_s)
    end
    
    [1, -1, 1.1, 18446744073709551615].each  do |obj|
      assert obj.kind_of?(Numeric)
      assert_equal obj, ea.str_to_entry(obj.to_s)
    end
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
    #assert_equal([1, 1, 2, 3, 2, 3], a)
    assert_equal(@cls[1, 1, 2, 3, 2, 3], a)

    a = @cls[1, 2, 3]
    a[-1, 0] = a
    #assert_equal([1, 2, 1, 2, 3, 3], a)
    assert_equal(@cls[1, 2, 1, 2, 3, 3], a)
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
    # Currently there are issues with this...
    
    # assert_equal(@cls[1, 2, 3, 4],     @cls[1, 2].concat(@cls[3, 4]))
    # assert_equal(@cls[1, 2, 3, 4],     @cls[].concat(@cls[1, 2, 3, 4]))
    # assert_equal(@cls[1, 2, 3, 4],     @cls[1, 2, 3, 4].concat(@cls[]))
    # assert_equal(@cls[],               @cls[].concat(@cls[]))
    # assert_equal(@cls[@cls[1, 2], @cls[3, 4]], @cls[@cls[1, 2]].concat(@cls[@cls[3, 4]]))
    # 
    # a = @cls[1, 2, 3]
    # a.concat(a)
    # assert_equal([1, 2, 3, 1, 2, 3], a)
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