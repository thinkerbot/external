require File.join(File.dirname(__FILE__), '../external_test_helper.rb') 
require 'external/io'

class  IOTest < Test::Unit::TestCase
  include External
  
  def std_class_test(data)
    Tempfile.open("file_test") do |tempfile|
      tempfile << data
      tempfile.flush
    
      File.open(tempfile.path, "r+") do |file|
        file.extend IO
        yield(file)
      end
    end
    
    Tempfile.open("tempfile_test") do |tempfile|
      tempfile << data
      tempfile.extend IO

      yield(tempfile)
    end
    
    Tempfile.open("strio_test") do |tempfile|
      tempfile << data
      tempfile.flush
    
      tempfile.pos = 0
      StringIO.open(tempfile.read, "r+") do |file|
        file.extend IO
        yield(file)
      end
    end
  end
  
  #
  # length test
  #
  
  def test_length_is_set_to_file_size_upon_extend_for_file
    # File
    t = Tempfile.new "position_test"
    t << "abcd"
    t.close
    
    File.open(t.path, "r+") do |file|
      file.extend IO
      assert_equal 4, file.length 
      assert_equal 4, File.size(file.path)
    end

    # Tempfile
    t = Tempfile.new "position_test"
    t << "abcd"
    t.fsync
    assert_equal 4, File.size(t.path)
    
    t.extend IO
    assert_equal 4, t.length

    t.close
  end
  
  def test_length_does_NOT_automatically_correspond_to_file_size
    t = Tempfile.new "position_test"
    t.close 
    
    assert_equal 0, File.size(t.path)
    File.open(t.path, "r+") do |file|
      file.extend IO
    
      assert_equal 0, file.length
      assert_equal 0, File.size(t.path)
      
      file << "abcd"
      file.fsync
      
      assert_equal 0, file.length
      assert_equal 4, File.size(t.path)
    end
    
    
    # Tempfile
    t = Tempfile.new "position_test"
    t.extend IO
    
    assert_equal 0, t.length
    assert_equal 0, File.size(t.path)
    
    t << "abcd"
    t.fsync
    
    assert_equal 0, t.length
    assert_equal 4, File.size(t.path)
    
    t.close
  end
  
  #
  # reset length test
  #
  
  def test_reset_length_resets_length_to_file_size
    # File
    t = Tempfile.new "position_test"
    t.close
    
    File.open(t.path, "r+") do |file|
      file.extend IO
    
      assert_equal 0, file.length
      assert_equal 0, File.size(file.path)
    
      file << "abcd"
      file.fsync
    
      assert_equal 0, file.length
      assert_equal 4, File.size(t.path)
    
      file.reset_length
    
      assert_equal 4, file.length
    end
    
    # Tempfile
    t = Tempfile.new "position_test"
    t.extend IO
    
    assert_equal 0, t.length
    assert_equal 0, File.size(t.path)
    
    t << "abcd"
    t.fsync
    
    assert_equal 0, t.length
    assert_equal 4, File.size(t.path)
    
    t.reset_length
    
    assert_equal 4, t.length
    
    t.close
  end

  #
  # position test
  #
  
  def two_gb_size
    2147483647
  end
  
  def test_position_mswin
    platform_test('mswin') do 
      prompt_test(:path_to_large_file) do |path|
        path = $1 if path =~ /^"([^"]*)"$/ 

        File.open(path) do |file|
          file.extend IO
          
          # stat.size < 0 due to windows bug
          assert file.stat.size < 0, "File size must be > 2GB (only #{file.length/two_gb_size})"
          assert file.length > two_gb_size + 5,  "File size must be > 2GB (only #{file.length/two_gb_size})"
          
          file.pos = two_gb_size
          assert_equal two_gb_size, file.pos
          ten_bytes = file.read(10)
          
          file.pos = two_gb_size + 5
          assert_equal two_gb_size + 5, file.pos
          five_bytes = file.read(5)
          
          assert_equal ten_bytes[5..-1], five_bytes
        end
      end 
    end
  end
  
  def test_position
    platform_test('non_mswin') do 
      prompt_test(:path_to_large_file) do |path|
        path = $1 if path =~ /^"([^"]*)"$/ 

        File.open(path) do |file|
          file.extend IO
        
          assert file.length > (two_gb_size + 5), "File size must be > 2GB (only #{file.length/two_gb_size})"
        
          file.pos = two_gb_size
          assert_equal two_gb_size, file.pos
          ten_bytes = file.read(10)
        
          file.pos = two_gb_size + 5
          assert_equal two_gb_size + 5, file.pos
          five_bytes = file.read(5)
        
          assert_equal ten_bytes[5..-1], five_bytes
        end
      end
    end
  end

  #
  # generic_mode test
  #
  
  def test_generic_modes_are_determined_correctly
    {
      "r" => "r",
      "r+" => "r+",
      "w" => "w",
      "w+" => "r+",
      "a" => "w",
      "a+" => "r+"
    }.each_pair do |mode, expected|
      Tempfile.open("position_test") do |t|
        File.open(t.path, mode) do |file|
          file.extend IO
          assert_equal expected, file.generic_mode, mode
          assert !file.closed?
        end
      end
      
      StringIO.open("", mode) do |file|
        file.extend IO
        assert_equal expected, file.generic_mode, mode
        assert !file.closed?
      end
    end
  end
  
  #
  # quick_compare test
  #
  
  def test_quick_compare_true_if_another_is_self
    std_class_test("") do |io|
      assert io.quick_compare(io)
    end
  end
  
  def test_quick_compare_true_if_paths_of_self_and_another_are_the_same
    Tempfile.open("a") do |a|
      a.extend IO
      
      File.open(a.path) do |b|
        b.extend IO
        
        assert a != b
        assert a.path == b.path
        assert a.quick_compare(b)
      end
    end
  end
  
  #
  # <=> test
  #

  def test_sort_compare_with_self
    std_class_test("") do |io|
      assert_equal 0, (io <=> io)
    end
  end

  def test_sort_compare_with_same_file
    Tempfile.open("a") do |a|
      a.extend IO
      
      File.open(a.path) do |b|
        b.extend IO
        
        assert a != b
        assert a.path == b.path
        assert_equal 0, (a <=> b)
      end
    end
  end
  
  def test_sort_compare_with_unequal_lengths
    Tempfile.open("a") do |a|
      a << "abcd"
      a.extend IO
      
      Tempfile.open("b") do |b|
        b << "abc"
        b.extend IO
        
        assert !a.quick_compare(b)
        assert_equal 1, ("abcd" <=> "abc")
        assert_equal 1, (a <=> b)
        
        assert_equal -1, ("abc" <=> "abcd")
        assert_equal -1, (b <=> a)
      end
    end
  end
  
  def test_sort_compare
    Tempfile.open("a") do |a|
      a << "abcd"
      a.extend IO
      
      Tempfile.open("b") do |b|
        b << "abcz"
        b.extend IO
        
        assert_equal -1, ("abcd" <=> "abcz")
        assert_equal -1, (a <=> b)
        
        assert_equal 1, ("abcz" <=> "abcd")
        assert_equal 1, (b <=> a)
      end
    end
  end
  
  def test_sort_compare_same_content
    Tempfile.open("a") do |a|
      a.extend IO
      a << "abcd"
      
      Tempfile.open("b") do |b|
        b.extend IO
        b << "abcd"
        
        assert a.path != b.path
        assert_equal 0, (a <=> b)
      end
    end
  end
  
  def test_sort_compare_no_content
    Tempfile.open("a") do |a|
      a.extend IO
      
      Tempfile.open("b") do |b|
        b.extend IO

        assert a.path != b.path
        assert_equal 0, (a <=> b)
      end
    end
  end
  
  def test_sort_compare_with_different_underlying_io_types
    Tempfile.open("a") do |a|
      a << "abcd"
      a.extend IO
      
      StringIO.open("abcz") do |b|
        b.extend IO
        
        assert_equal -1, ("abcd" <=> "abcz")
        assert_equal -1, (a <=> b)
        
        assert_equal 1, ("abcz" <=> "abcd")
        assert_equal 1, (b <=> a)
      end
    end
  end

  #
  # copy test
  #
  
  def test_std_class_test
    classes = []
    std_class_test("some data") do |io|
      assert io.kind_of?(IO)
      assert "r+", io.generic_mode
      
      io.pos = 0
      assert_equal "some data", io.read
      
      # the new data will throw the previous assertion
      # if the ios are not independent
      io << " new data"  
      io.pos = 0
      assert_equal "some data new data", io.read
      
      classes << io.class
    end
    
    if pre_ruby19?
      assert_equal [File, Tempfile, StringIO], classes
    else
      assert_equal [File, File, StringIO], classes
    end
  end
  
  def test_copy_opens_a_copy_in_read_mode
    data = "test data"
    
    std_class_test(data) do |io|
      copy_path = nil
      io.copy do |copy|
        assert_equal "r", copy.generic_mode
        assert_equal data, copy.read

        copy_path =  copy.path
        assert_not_equal io.path, copy_path
      end

      assert !copy_path.nil?
      assert !File.exists?(copy_path)
    end
  end
  
  def test_copy_opens_copy_in_mode_if_provided 
    std_class_test("") do |io|
      assert_equal "r+", io.generic_mode
      io.copy("w") do |copy|
        assert_equal "w", copy.generic_mode
      end
    end
  end
end