require File.join(File.dirname(__FILE__), '../external_test_helper.rb') 
require 'tempfile'
require 'enumerator'
require 'scanf'

class TestPosSpeed < Test::Unit::TestCase
  include Benchmark

  attr_reader :path
  
  def setup
    t = Tempfile.new('integers')
    ints = [*(1..100000).to_a]
    t << ints.pack("I*")
    t.close
    @path = t.path
  end
  
  def test_pos_speed
    file = File.open(path, "r")
    length = file.stat.size
    positions = Array.new(1000) do
      p = rand(length)
    end
    
    benchmark_test(20) do |x|
      x.report("100kx pos=") do
        (1000).times do
          positions.each do |p|
            file.pos = p
            file.pos = p
          end
        end
      end
      
      x.report("100kx pos= with check") do
        (1000).times do
          positions.each do |p|
            file.pos = p
            file.pos = p unless file.pos = p
          end
        end
      end
    end   
  end

end