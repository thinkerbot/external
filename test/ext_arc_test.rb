require File.join(File.dirname(__FILE__), 'external_test_helper.rb') 
require 'ext_arc'

class ExtArcTest < Test::Unit::TestCase
  attr_reader :ea

  def setup
    @ea = ExtArc.new
  end
  
  #
  # readme doc test
  #
  
  def test_readme_doc_for_ext_arc
    arc = ExtArc[">swift", ">brown", ">fox"]
    assert_equal ">fox", arc[2]
    assert_equal [">swift", ">brown", ">fox"], arc.to_a

    assert_equal Tempfile, arc.io.class
    arc.io.rewind
    assert_equal ">swift>brown>fox", arc.io.read

  	Tempfile.open('test_readme_doc_for_ext_arc') do |file|
  	  file << ">swift>brown>fox"
  	  file.flush

  	  arc = ExtArc.new(file)
  	  assert_equal [], arc.to_a
  	  arc.reindex_by_sep(">", :entry_follows_sep => true)
  	  assert_equal [">swift", ">brown", ">fox"], arc.to_a
  	  
  	  arc = ExtArc.new(file)
  	  assert_equal [], arc.to_a
  	  arc.reindex_by_regexp(/>\w*/)
  	  assert_equal [">swift", ">brown", ">fox"], arc.to_a
  	end
  end

  #
  # entry_to_str, str_to_entry test
  #

  def test_entry_to_str_simply_stringifies_entry
    obj = "abc"
    assert_equal obj.to_s, ea.entry_to_str(obj)
    
    obj = 1
    assert_equal obj.to_s, ea.entry_to_str(obj)
  end
  
  def test_entry_to_str_simply_return_input
    obj = "abc"
    assert_equal obj.object_id, ea.str_to_entry(obj).object_id
  end
  
  #####################################
  # indexing tests
  #####################################
  
  def reindex_by_regexp_test(arr, pattern, blksize=nil)
    str = arr.join('')
    StringIO.open(str) do |strio|
      ea = ExtArc.new(strio)
      ea.io.default_blksize = blksize unless blksize == nil 
      
      ea.reindex_by_regexp(pattern)
      yield(str, ea._index.to_a) if block_given?
      
      assert_equal arr, ea.to_a
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
  
  def reindex_by_sep_test(arr, sep, options={}, blksize=nil)
    str = arr.join('')
    StringIO.open(str) do |strio|
      ea = ExtArc.new(strio)
      ea.io.default_blksize = blksize unless blksize == nil 
      
      ea.reindex_by_sep(sep, options)
      yield(str, ea._index.to_a) if block_given?
      ea.to_a
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