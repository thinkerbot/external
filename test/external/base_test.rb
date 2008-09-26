require File.join(File.dirname(__FILE__), '../external_test_helper.rb') 
require 'external/base'
require 'tempfile'

class BaseTest < Test::Unit::TestCase
  include External
  
  acts_as_file_test
  
  attr_reader :base

  def setup
    super
    @base = Base.new
  end

  #
  # initialize test
  #
  
  def test_base_initializes_io_to_StringIO_when_nil
    base = Base.new(nil)
    assert_equal StringIO, base.io.class
  end
  
  def test_base_initializes_io_to_a_strio_when_string
    base = Base.new("abcde")
    assert_equal StringIO, base.io.class
    assert_equal "abcde", base.io.string
  end
  
  def test_base_initializes_enumerate_to_a_as_true
    base = Base.new(nil)
    assert base.enumerate_to_a
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
  
  #
  # flush test
  #
  
  def test_flush_flushes_io_and_resets_io_length
    assert_equal 0, base.io.length
    base.io << "abcde"
    assert_equal 0, base.io.length
    
    base.flush
    
    base.io.rewind
    assert_equal "abcde", base.io.read
    assert_equal 5, base.io.length
  end
  
  def test_flush_returns_self
    assert_equal base, base.flush
  end
  
end
