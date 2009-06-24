require File.join(File.dirname(__FILE__), '../external_test_helper.rb') 
require 'external/io'

class  IOTest < Test::Unit::TestCase
  include External
  
  acts_as_file_test
  
  def io_test(data="")
    path = method_root.prepare(:tmp, "file_test") {|tempfile| tempfile << data }
    File.open(path, "r+") do |file|
      file.extend Io
      yield(:file, file)
    end
    
    io_path = method_root.prepare(:tmp, "io_test") {|tempfile| tempfile << data }
    File.open(io_path, "r+") do |file|
      IO.open(file.fileno, "r+") do |io|
        io.extend Io
        yield(:io, io)
      end
    end

    Tempfile.open("tempfile_test", method_root[:tmp]) do |tempfile|
      tempfile << data
      tempfile.fsync
      tempfile.extend Io

      yield(:tempfile, tempfile)
    end
    
    StringIO.open(data, "r+") do |strio|
      strio.extend Io
      yield(:strio, strio)
    end
  end
  
  #
  # length test
  #
  
  def test_length_is_set_to_io_size_upon_extend 
    io_test "abcde" do |type, io|
      assert_equal 5, io.length, type
    end
  end
  
  def test_length_does_not_automatically_correspond_to_io_size
    io_test do |type, io|
      assert_equal 0, io.length, type
      
      io << "abcde"
      io.fsync
      
      case io
      when StringIO 
        assert_equal 5, io.string.size, type
      else 
        assert_equal 5, io.stat.size, type
      end
      
      assert_equal 0, io.length, type
    end
  end
  
  #
  # reset length test
  #
  
  def test_reset_length_resets_length_to_file_size
    io_test do |type, io|
      io << "abcde"
      io.fsync
      
      assert_equal 0, io.length, type
    
      io.reset_length
      assert_equal 5, io.length
    end
  end

  #
  # position test
  #
  
  def two_gb_size
    2147483647
  end
  
  def test_position_mswin
    condition_test(:windows) do 
      prompt_test(:path_to_large_file) do |path|
        path = $1 if path =~ /^"([^"]*)"$/ 
  
        File.open(path) do |file|
          file.extend Io
          
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
    condition_test(:non_windows) do 
      prompt_test(:path_to_large_file) do |path|
        path = $1 if path =~ /^"([^"]*)"$/ 
  
        File.open(path) do |file|
          file.extend Io
        
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
  
  # def test_generic_modes_are_determined_correctly
  #   {
  #     "r" => "r",
  #     "r+" => "r+",
  #     "w" => "w",
  #     "w+" => "r+",
  #     "a" => "w",
  #     "a+" => "r+"
  #   }.each_pair do |mode, expected|
  #     path = method_root.prepare(:tmp, "file_test") {|tempfile| tempfile << '' }
  #     
  #     File.open(path, mode) do |file|
  #       file.extend Io
  #       assert_equal expected, file.generic_mode, "file #{mode}"
  #       assert !file.closed?, "file #{mode}"
  #     end
  #     
  #     StringIO.open("", mode) do |file|
  #       file.extend Io
  #       assert_equal expected, file.generic_mode, "strio #{mode}"
  #       assert !file.closed?, "strio #{mode}"
  #     end
  #   end
  # end
  
  #
  # quick_compare test
  #
  
  def test_quick_compare_true_if_another_is_self
    io_test do |type, io|
      assert io.quick_compare(io), type
    end
  end
  
  def test_quick_compare_true_if_paths_of_self_and_another_are_the_same
    Tempfile.open("a") do |a|
      a.extend Io
      
      File.open(a.path) do |b|
        b.extend Io
        
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
    io_test do |type, io|
      assert_equal 0, (io <=> io), type
    end
  end
  
  def test_sort_compare_with_same_file
    Tempfile.open("a") do |a|
      a.extend Io
      
      File.open(a.path) do |b|
        b.extend Io
        
        assert a != b
        assert a.path == b.path
        assert_equal 0, (a <=> b)
      end
    end
  end
  
  def test_sort_compare_with_unequal_lengths
    Tempfile.open("a") do |a|
      a << "abcd"
      a.extend Io
      
      Tempfile.open("b") do |b|
        b << "abc"
        b.extend Io
        
        assert !a.quick_compare(b)
        assert_equal 1, ("abcd" <=> "abc")
        assert_equal 1, (a <=> b)
        
        assert_equal(-1, ("abc" <=> "abcd"))
        assert_equal(-1, (b <=> a))
      end
    end
  end
  
  def test_sort_compare
    Tempfile.open("a") do |a|
      a << "abcd"
      a.extend Io
      
      Tempfile.open("b") do |b|
        b << "abcz"
        b.extend Io
        
        assert_equal(-1, ("abcd" <=> "abcz"))
        assert_equal(-1, (a <=> b))
        
        assert_equal 1, ("abcz" <=> "abcd")
        assert_equal 1, (b <=> a)
      end
    end
  end
  
  def test_sort_compare_same_content
    Tempfile.open("a") do |a|
      a.extend Io
      a << "abcd"
      
      Tempfile.open("b") do |b|
        b.extend Io
        b << "abcd"
        
        assert a.path != b.path
        assert_equal 0, (a <=> b)
      end
    end
  end
  
  def test_sort_compare_no_content
    Tempfile.open("a") do |a|
      a.extend Io
      
      Tempfile.open("b") do |b|
        b.extend Io
  
        assert a.path != b.path
        assert_equal 0, (a <=> b)
      end
    end
  end
  
  def test_sort_compare_with_different_underlying_io_types
    Tempfile.open("a") do |a|
      a << "abcd"
      a.extend Io
      
      StringIO.new("abcz") do |b|
        b.extend Io
        
        assert_equal(-1, ("abcd" <=> "abcz"))
        assert_equal(-1, (a <=> b))
        
        assert_equal 1, ("abcz" <=> "abcd")
        assert_equal 1, (b <=> a)
      end
    end
  end
  
  #
  # copy test
  #
  
  def test_io_test
    classes = []
    io_test("some data") do |type, io|
      assert io.kind_of?(Io)
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
    
    condition_test(:ruby_1_8) do
      assert_equal [File, IO, Tempfile, StringIO], classes
    end
    
    condition_test(:ruby_1_9) do
      assert_equal [File, IO, File, StringIO], classes
    end
  end
  
  def test_copy_opens_a_copy_in_read_mode
    data = "test data"
    
    io_test(data) do |type, io|
      copy_path = nil
      io.copy do |copy|
        assert_equal "r", copy.generic_mode
        assert_equal data, copy.read
  
        copy_path = copy.path
        
        if io.respond_to?(:path)
          assert io.path != copy_path
        end
      end
  
      assert !copy_path.nil?
      assert !File.exists?(copy_path)
    end
  end
  
  # def test_copy_opens_copy_in_mode_if_provided 
  #   io_test do |type, io|
  #     assert_equal "r+", io.generic_mode
  #     io.copy("w") do |copy|
  #       assert_equal "w", copy.generic_mode
  #     end
  #   end
  # end
end