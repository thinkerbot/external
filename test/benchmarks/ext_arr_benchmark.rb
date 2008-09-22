require File.join(File.dirname(__FILE__), '../external_test_helper.rb') 
require 'ext_arr'
require 'fileutils'

class ExtArrBenchmarks < Test::Unit::TestCase
  include Benchmark

  #######################
  # Benchmark tests
  #######################

  #
  # benchmarks
  #
  
  def ea_bm_test(mode, length=20, array=nil, &block)
    benchmark(length) do |x|
      unless array
        array = []
        1.upto(10000) {|i| array << i.to_s }
      end
       
      begin
        ea = ExtArr[*array]
        yield(x, "", ea)
      ensure
        ea.close if index
      end

      yield(x, "array reference", array)
    end
     
    array
  end
  
  def test_element_reference_speed_for_ext_arr
    n = 10
    ea_bm_test('r') do |x, type, ea|
      puts type
      
      x.report("#{n}kx [index]") { (n*1000).times { ea[1000] } }
      x.report("#{n}kx [range]") { (n*1000).times { ea[1000..1000] } }
      x.report("#{n}kx [s,1]") { (n*1000).times { ea[1000, 1] } }
      x.report("#{n}kx [s,10]") { (n*1000).times { ea[1000, 10] } }
      #x.report("#{n}kx [s,100]") { (n*1000).times { ea[1000, 100] } }   
      
      puts
    end
  end

  def test_element_assignment_speed_for_ext_arr
    ea_bm_test('r+') do |x, type, index|
      puts type
      
      n = 1
      obj = "abcde"
      
      x.report("#{n}kx [index]=") do 
        (n*1000).times { ea[1000] = obj  } 
      end      
      x.report("#{n}kx [range]=") do 
        (n*1000).times { ea[1000..1000] = [obj] } 
      end  
      x.report("#{n}kx [s,1]=") do 
        (n*1000).times { ea[1000,1] = [obj] } 
      end
      
      puts
    end
  end
  
end
