require File.join(File.dirname(__FILE__), '../external_test_helper.rb') 
require 'external/base'
require 'tempfile'

class BaseTest < Test::Unit::TestCase
  include External
  
  acts_as_file_test
  
  attr_reader :array, :base, :tempfile

  def setup
    super
    @array = ('a'..'z').to_a
    @tempfile = Tempfile.new("basetest")
    @tempfile << array.join('')
    @base = Base.new(@tempfile)
  end
  
  def teardown
    tempfile.close unless tempfile.closed?
    super
  end

  #
  # setup tests
  #

  def test_setup
    assert_equal ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"], array
    assert_equal "abcdefghijklmnopqrstuvwxyz", array.join('')
    
    tempfile.pos = 0
    assert_equal "abcdefghijklmnopqrstuvwxyz", tempfile.read
  end

  #
  # initialize test
  #
  
  def test_io_points_to_tempfile_when_io_is_nil
    condition_test(:ruby_1_8) do
      begin
        b = Base.new(nil)
        assert b.io != nil
        assert_equal Tempfile, b.io.class
        assert_equal 0, b.io.path.index(Dir.tmpdir)
      ensure
        b.close if b
      end
    end
  end
  
  #
  # closed? test
  #
  
  def test_closed_is_true_if_io_is_closed
    assert !base.closed?
    base.io.close
    assert base.closed?  
  end
  
  #
  # close test
  #

  def test_close_closes_io
    assert !base.io.closed?
    assert base.close
    
    assert base.io.closed?
    assert !base.close
  end
  
  def test_close_returns_true_if_it_closed_io
    base = Base.new
    assert !base.io.closed?
    assert base.close
    
    base = Base.new
    base.io.close
    assert !base.close
  end
  
  def test_close_moves_File_io_to_path_if_specified
    source = method_tempfile("source.txt")
    target = method_tempfile("target.txt")
    assert !File.exists?(target)
    
    base = Base.new File.open(source, 'w')
    base.io.write "abcde"
    base.close(target)

    assert !File.exists?(source)
    assert File.exists?(target)
    assert_equal "abcde", File.read(target)
  end
  
  def test_close_moves_Tempfile_to_path_if_specifed
    source = Tempfile.new("base")
    target = method_tempfile("target.txt")
    assert !File.exists?(target)
    
    base = Base.new source
    base.io.write "abcde"
    base.close(target)

    assert !File.exists?(source.path)
    assert File.exists?(target)
    assert_equal "abcde", File.read(target)
  end

  def test_close_dumps_non_File_non_Tempfile_io_to_path_if_specifed
    target = method_tempfile("target.txt")
    assert !File.exists?(target)
    
    base = Base.new StringIO.new("")
    base.io.write "abcde"
    base.close(target)

    assert File.exists?(target)
    assert_equal "abcde", File.read(target)
  end
  
  def test_close_raises_error_if_target_exists
    target = method_tempfile("target.txt") {|file| file << "existing content"}
    assert File.exists?(target)
    
    assert_raise(ArgumentError) { base.close(target) }
    
    assert_equal "existing content", File.read(target)
  end
  
  def test_close_overwrites_existing_target_if_specified
    target = method_tempfile("target.txt") {|file| file << "existing content"}
    assert File.exists?(target)
    
    base = Base.new
    base.io.write "new content"
    assert_nothing_raised { base.close(target, true) }
    
    assert_equal "new content", File.read(target)
  end
end
