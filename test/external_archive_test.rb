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
    @extarc = ExternalArchive.new StringIO.new(data)
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
  # readme doc test
  #
  
  # def test_readme_doc_for_ext_arc
  #   arc = ExternalArchive[">swift", ">brown", ">fox"]
  #   assert_equal ">fox", arc[2]
  #   assert_equal [">swift", ">brown", ">fox"], arc.to_a
  # 
  #   assert_equal Tempfile, arc.io.class
  #   arc.io.rewind
  #   assert_equal ">swift>brown>fox", arc.io.read
  # 
  #   Tempfile.open('test_readme_doc_for_ext_arc') do |file|
  #     file << ">swift>brown>fox"
  #     file.flush
  # 
  #     arc = ExternalArchive.new(file)
  #     assert_equal [], arc.to_a
  #     arc.reindex_by_sep(">", :entry_follows_sep => true)
  #     assert_equal [">swift", ">brown", ">fox"], arc.to_a
  #     
  #     arc = ExternalArchive.new(file)
  #     assert_equal [], arc.to_a
  #     arc.reindex_by_regexp(/>\w*/)
  #     assert_equal [">swift", ">brown", ">fox"], arc.to_a
  #   end
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

end