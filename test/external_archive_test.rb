require File.join(File.dirname(__FILE__), 'external_test_helper.rb') 
require 'external_archive'

class ExternalArchiveTest < Test::Unit::TestCase
  attr_reader :extarc, :data
  
  acts_as_file_test
  
  def setup
    super
    
    # cls represents Array in many of the tests taken from MRI
    @cls = ExternalArchive
    @data = ""
    @extarc = ExternalArchive.new data
  end
  
  STRING = "abcdefgh"
  ARRAY = ["abc", "de", "fgh"]
  INDEX = [[0,3],[3,2],[5,3]]

  #
  # ExternalArchive.open test
  #
  
  def test_open_initializes_with_specified_file
    input = method_tempfile("input.txt") {|file| file << STRING }
    ExternalArchive.open(input) do |extarc|
      assert_equal File, extarc.io.class
      assert_equal input, extarc.io.path
      assert_equal STRING, extarc.io.read
    end
  end
  
  def test_open_initializes_with_specified_index
    input = method_tempfile("input.txt") {|file| file << STRING }
    index = method_tempfile("input.index") {|file| file << INDEX.flatten.pack('I*') }
    
    assert_not_equal index, ExternalArchive.index_path(input) 
    ExternalArchive.open(input, 'r', :io_index => index) do |extarr|
      assert_equal ExternalIndex, extarr.io_index.class
      assert_equal index, extarr.io_index.io.path
    end
    
    extind = ExternalIndex.open(index)
    ExternalArchive.open(input, 'r', :io_index => extind) do |extarr|
      assert_equal extind, extarr.io_index
    end
    
    ExternalArchive.open(input, 'r', :io_index => INDEX) do |extarr|
      assert_equal INDEX, extarr.io_index
    end
  end
  
  def test_open_without_index_initializes_with_default_index_file_if_none_is_specified
    input = method_tempfile("input.txt") {|file| file << STRING }
    index = ExternalArchive.index_path(input) 
    
    # first when the default index file doesn't exist
    assert !File.exists?(index)
    ExternalArchive.open(input) do |extarr|
      assert_equal ExternalIndex, extarr.io_index.class
      assert_equal index, extarr.io_index.io.path
    end
    
    # now when the default index file does exist
    assert File.exists?(index)
    ExternalArchive.open(input) do |extarr|
      assert_equal ExternalIndex, extarr.io_index.class
      assert_equal index, extarr.io_index.io.path
    end
  end
  
  class ReindexArchive < ExternalArchive
    attr_reader :reindex_called
    
    def initialize(*args)
      @reindex_called = false
      super
    end
    
    def reindex(*args)
      @reindex_called = true
      super
    end
  end
  
  def test_open_does_not_call_reindex_extarr_is_not_empty
    input = method_tempfile("input.txt") {|file| file << STRING }
    index = method_tempfile("input.index") {|file| file << INDEX.flatten.pack('I*') }
    
    ReindexArchive.open(input, 'r', :io_index => index) do |extarr|
      assert !extarr.reindex_called
    end
  end
  
  def test_open_calls_reindex_if_reindex_is_specified
    input = method_tempfile("input.txt") {|file| file << STRING }
    index = method_tempfile("input.index") {|file| file << INDEX.flatten.pack('I*') }
    
    ReindexArchive.open(input, 'r', :io_index => index, :reindex => true) do |extarr|
      assert extarr.reindex_called
    end
  end
  
  def test_open_calls_reindex_if_extarr_is_empty_and_io_is_not
    input = method_tempfile("input.txt") {|file| file << STRING }
    assert_equal STRING.length, File.size(input)
    
    ReindexArchive.open(input, 'r') do |extarr|
      assert extarr.reindex_called
    end
  end
  
  def test_open_does_not_call_reindex_if_extarr_io_is_empty
    input = method_tempfile("input.txt") {}
    assert_equal 0, File.size(input)
    
    ReindexArchive.open(input, 'r') do |extarr|
      assert !extarr.reindex_called
    end
  end
  
  def test_open_does_not_call_reindex_if_auto_reindex_is_false
    input = method_tempfile("input.txt") {|file| file << STRING }
    ReindexArchive.open(input, 'r', :auto_reindex => false) do |extarr|
      assert !extarr.reindex_called
    end
  end
  
  def test_open_raises_error_if_path_doesnt_exists
    input = method_tempfile("input.txt")
    
    assert !File.exists?(input)
    assert_raise(Errno::ENOENT) { ExternalArchive.open(input) }
  end
  
  def test_open_raises_error_if_specified_index_doesnt_exists
    input = method_tempfile("input.txt") {}
    index = method_tempfile("input.index")
    
    assert File.exists?(input)
    assert !File.exists?(index)
    assert_raise(Errno::ENOENT) { ExternalArchive.open(input, 'r', :io_index => index) }
  end
  
  #
  # ExternalArchive.index_path test
  #
  
  def test_index_path_documentation
    assert_equal "/path/to/file.index", ExternalArchive.index_path("/path/to/file.txt")
  end
  
  def test_index_path_returns_nil_for_nil
    assert_equal nil, ExternalArchive.index_path(nil)
  end
  
  #
  # cached? test
  #
  
  def test_cached_is_true_if_io_index_is_an_Array
    assert_equal Array, extarc.io_index.class
    assert extarc.cached?
    
    extarc = ExternalArchive.new nil, ExternalIndex.new
    assert_equal ExternalIndex, extarc.io_index.class
    assert !extarc.cached?
  end
  
  #
  # cache test
  #
  
  def test_set_cache_to_true_converts_ExternalIndex_io_index_to_array
    extarc = ExternalArchive.new nil, ExternalIndex.new([1,2,3,4].pack("I*"), :format => 'II')
    assert !extarc.cached?
    
    extarc.cache = true
    assert_equal [[1,2],[3,4]], extarc.io_index
    assert extarc.cached?
  end
  
  def test_set_cache_to_false_converts_Array_io_index_to_ExternalIndex
    extarc = ExternalArchive.new nil, [[1,2],[3,4]]
    assert extarc.cached?
    extarc.cache = false
    
    assert_equal ExternalIndex, extarc.io_index.class
    assert_equal 'II', extarc.io_index.options[:format]
    assert_equal [[1,2],[3,4]], extarc.io_index.to_a
    assert !extarc.cached?
  end
  
  #
  # close test
  #
  
  def test_close_closes_io_and_io_index
    index = ExternalIndex.new
    strio = StringIO.new(data)
    archive = ExternalArchive.new strio, index
    
    assert !index.closed?
    assert !strio.closed?
    assert !archive.closed?
    
    archive.close
    
    assert index.closed?
    assert strio.closed?
    assert archive.closed?
  end
  
  def test_close_closes_io_and_io_index_with_paths_if_specified
    archive = ExternalArchive.new StringIO.new(data), ExternalIndex.new
    archive[0] = "abcde"
    
    path = method_tempfile('path')
    index_path = method_tempfile('index_path')
    
    assert !File.exists?(path)
    assert !File.exists?(index_path)
    
    archive.close(path, index_path)
    
    assert File.exists?(path)
    assert_equal "abcde", File.read(path)
    
    assert File.exists?(index_path)
    assert_equal [0,5].pack("II"), File.read(index_path)
  end
  
  def test_close_dumps_non_ExternalIndex_data_to_index_path
    archive = ExternalArchive.new StringIO.new(data), []
    archive[0] = "abcde"
    
    path = method_tempfile('path')
    index_path = method_tempfile('index_path')
    
    assert !File.exists?(path)
    assert !File.exists?(index_path)
    
    archive.close(path, index_path)
    
    assert File.exists?(path)
    assert_equal "abcde", File.read(path)
    
    assert File.exists?(index_path)
    assert_equal [0,5].pack("II"), File.read(index_path)
  end
  
  #
  # another test
  #
  
  def test_another_returns_a_new_instance_with_a_new_io_index
    a = @cls.new nil, []
    b = a.another

    assert_not_equal(a.object_id, b.object_id)
    assert_equal(@cls[], b)
    assert_equal Array, b.io_index.class
    
    # now with an ExternalIndex
    a = @cls.new nil, ExternalIndex.new
    b = a.another

    assert_not_equal(a.object_id, b.object_id)
    assert_equal(@cls[], b)
    assert_equal ExternalIndex, b.io_index.class
  end
  
  #
  # str_to_entry test
  #
  
  def test_str_to_entry_return_str
    assert_equal "str", extarc.str_to_entry("str")
    assert_equal "1", extarc.str_to_entry("1")
  end
  
  #
  # entry_to_str test
  #
  
  def test_entry_to_str_returns_entry_to_s
    assert_equal "str", extarc.entry_to_str("str")
    assert_equal "1", extarc.entry_to_str(1)
  end
  
  #
  # reindex test
  #
  
  def test_reindex_yields_io_and_io_index_to_the_block
    was_in_block = false
    extarc.reindex do |io, io_index|
      assert_equal extarc.io, io
      assert_equal extarc.io_index, io_index
      was_in_block = true
    end
    
    assert was_in_block
  end
  
  def test_reindex_clears_io_index
    extarc.io_index << [1,0]
    assert !extarc.io_index.empty?
    
    was_in_block = false
    extarc.reindex do |io, io_index|
      assert io_index.empty?
      was_in_block = true
    end
    
    assert was_in_block
  end
  
  def test_reindex_rewinds_io
    extarc.io << "str"
    assert_not_equal 0, extarc.io.pos
    
    was_in_block = false
    extarc.reindex do |io, io_index|
      assert_equal 0, extarc.io.pos
      was_in_block = true
    end
    
    assert was_in_block
  end
  
  # def test_reindex_flushes_io
  # end
  
  #
  # reindex_by_regexp tests
  #
  
  def reindex_by_regexp_test(arr, pattern, blksize=nil)
    str = arr.join('')
    StringIO.open(str) do |strio|
      extarc = ExternalArchive.new(strio)
      extarc.io.default_blksize = blksize unless blksize == nil 
      
      extarc.reindex_by_regexp(pattern)
      yield(str, extarc.io_index.to_a) if block_given?
      
      assert_equal arr, extarc.to_a
    end
  end
  
  def test_reindex_by_regexp
    reindex_by_regexp_test [], /\r?\n/ do |str, index|
      assert_equal "", str
      assert_equal [], index
    end
    
    reindex_by_regexp_test ["\n","\n","\n"], /\r?\n/ do |str, index|
      assert_equal "\n\n\n", str
      assert_equal [[0,1],[1,1],[2,1]], index
    end
    
    reindex_by_regexp_test ["a\n","b\n","c\n"], /\r?\n/ do |str, index|
      assert_equal "a\nb\nc\n", str
      assert_equal [[0,2],[2,2],[4,2]], index
    end 
    
    reindex_by_regexp_test [">a\n",">b>c\n",">d\n"], />.*?\n/ do |str, index|
      assert_equal ">a\n>b>c\n>d\n", str
      assert_equal [[0,3],[3,5],[8,3]], index
    end 
  end
  
  #
  # reindex_by_sep tests
  #
  
  def reindex_by_sep_test(arr, sep, options={}, blksize=nil)
    str = arr.join('')
    StringIO.open(str) do |strio|
      extarc = ExternalArchive.new(strio)
      extarc.io.default_blksize = blksize unless blksize == nil 
      
      extarc.reindex_by_sep(sep, options)
      yield(str, extarc.io_index.to_a) if block_given?
      extarc.to_a
    end
  end
  
  def test_reindex_by_sep
    arr = reindex_by_sep_test [], ">" do |str, index|
      assert_equal "", str
      assert_equal [], index
    end
    assert_equal [], arr
    
    #reindex_by_sep_test ["a" + $\, "b" + $\, "c" + $\]
    #reindex_by_sep_test [$\, $\, $\] 
    
    arr = reindex_by_sep_test [">",">",">"], ">" do |str, index|
      assert_equal ">>>", str
      assert_equal [[0,1],[1,1],[2,1]], index
    end
    assert_equal [">",">",">"], arr
    
    arr = reindex_by_sep_test ["a>","b>","c>"], ">" do |str, index|
      assert_equal "a>b>c>", str
      assert_equal [[0,2],[2,2],[4,2]], index
    end
    assert_equal ["a>","b>","c>"], arr
  
    arr = reindex_by_sep_test([">",">",">"], ">", :exclude_sep => true) do |str, index|
      assert_equal ">>>", str
      assert_equal [[0,0],[1,0],[2,0]], index
    end
    assert_equal ["","",""], arr
    
    arr = reindex_by_sep_test(["a>","b>","c>"], ">", :exclude_sep => true) do |str, index|
      assert_equal "a>b>c>", str
      assert_equal [[0,1],[2,1],[4,1]], index
    end
    assert_equal ["a","b","c"], arr
    
    arr = reindex_by_sep_test([">a",">b",">c"], ">", :entry_follows_sep => true) do |str, index|
      assert_equal ">a>b>c", str
      assert_equal [[0,2],[2,2],[4,2]], index
    end
    assert_equal [">a",">b",">c"], arr
    
    arr = reindex_by_sep_test([">",">",">"], ">", :entry_follows_sep => true) do |str, index|
      assert_equal ">>>", str
      assert_equal [[0,1],[1,1],[2,1]], index
    end
    assert_equal [">",">",">"], arr
    
    arr = reindex_by_sep_test([">",">",">"], ">", :entry_follows_sep => true, :exclude_sep => true) do |str, index|
      assert_equal ">>>", str
      assert_equal [[1,0],[2,0],[3,0]], index
    end
    assert_equal ["","",""], arr
    
    arr = reindex_by_sep_test([">a",">b",">c"], ">", :entry_follows_sep => true, :exclude_sep => true) do |str, index|
      assert_equal ">a>b>c", str
      assert_equal [[1,1],[3,1],[5,1]], index
    end
    assert_equal ["a","b","c"], arr
    
    # now requiring multiple scan steps...
    arr = reindex_by_sep_test(["a>","b>","c>"], ">", {}, 3) do |str, index|
      assert_equal "a>b>c>", str
      assert_equal [[0,2],[2,2],[4,2]], index
    end
    assert_equal ["a>","b>","c>"], arr
  end
  
  #
  # AGET test
  #
  
  def test_AGET_documentation
    a = ExternalArchive[ "a", "b", "c", "d", "e" ]
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

  #
  # ASET test
  #
  
  def test_ASET_documentation
    a = ExternalArchive.new
    a[4] = "4"
    assert_equal [nil, nil, nil, nil, "4"], a
    a[0, 3] = [ 'a', 'b', 'c' ]
    assert_equal ["a", "b", "c", nil, "4"], a
    a[1..2] = [ '1', '2' ]
    assert_equal ["a", '1', '2', nil, "4"], a
    a[0, 2] = "?"
    assert_equal ["?", '2', nil, "4"], a
    a[0..2] = "A"
    assert_equal ["A", "4"], a
    a[-1]   = "Z"
    assert_equal ["A", "Z"], a
    a[1..-1] = nil
    assert_equal ["A"], a
  end
end