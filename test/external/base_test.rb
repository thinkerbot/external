require File.join(File.dirname(__FILE__), '../external_test_helper.rb') 
require 'external/base'
require 'tempfile'

class BaseTest < Test::Unit::TestCase
  include External

  attr_reader :array, :b, :tempfile

  def setup
    @array = ('a'..'z').to_a
    @tempfile = Tempfile.new("basetest")
    @tempfile << array.join('')
    @b = Base.new(@tempfile)
  end
  
  def teardown
    tempfile.close unless tempfile.closed?
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
  # close, closed? test
  #

  def test_close_closes_io
    assert !b.io.closed?
    assert b.close
    assert b.io.closed?
    assert !b.close
  end
  
  def test_closed_returns_closed_state_of_io
    b.io.close   
    assert b.closed?
  end
  
  def test_close_moves_file_to_path_if_specifed
    path = File.dirname(__FILE__) + "/target.txt"
    assert !File.exists?(path)
    assert File.exists?(b.io.path)
    
    begin
      b.io.write " content"
      b.close(path)

      assert File.exists?(path)
      assert !File.exists?(b.io.path)
      assert_equal "abcdefghijklmnopqrstuvwxyz content", File.read(path)
    ensure
      FileUtils.rm(path) if File.exists?(path)
    end
  end
  
  def test_close_does_not_move_file_if_file_doesnt_exist_or_not_path
    b = Base.new
    b.close(nil)
    assert File.exists?(b.io.path)
    
    b = Base.new
    b.close(false)
    assert File.exists?(b.io.path)
  end
end
