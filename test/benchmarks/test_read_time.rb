require File.join(File.dirname(__FILE__), '../external_test_helper.rb') 
require 'tempfile'
require 'enumerator'
require 'scanf'

class TestReadTime < Test::Unit::TestCase
  include Benchmark

  attr_reader :path, :ints
  
  def setup
    t = Tempfile.new('integers')
    ints = [*(1..100000).to_a]
    t << ints.pack("I*")
    t.close
    @path = t.path
    
    @ints = []
    ints.each_slice(1) do |s|
      @ints << s
    end
  end
  
  def test_read_time
    file = File.open(path, "r")
    results = nil

    benchmark_test(20) do |x|
      x.report("10x full (1)") do 
        (10).times do 
          file.pos = 0
          str = file.read
          results = []
          str.unpack("I*").each_slice(1) do |s|
            results << s
          end
        end 
      end
      assert_equal ints, results
      
      x.report("10x singles (1)") do 
        (10).times do 
          file.pos = 0
          
          results = []
          ints.length.times do
            results << file.read(4).unpack("I")
          end
        end 
      end
      assert_equal ints, results
    end   
  end

end