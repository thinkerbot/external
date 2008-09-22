require File.join(File.dirname(__FILE__), 'external_test_helper.rb') 
require 'ext_ind'
require 'fileutils'

require 'ext_arr'

class ExtIndBenchmarks < Test::Unit::TestCase
  include Benchmark
  
  #######################
  # Benchmark tests
  #######################

  #
  # benchmarks
  #
  
  def index_bm_test(mode, length=20, array=nil, &block)
    benchmark(length) do |x|
      ['I', 'IIIIIIIIII'].each do |format|
        unless array
          array = []
          1.upto(10000) {|i| array << i }
        end
        
        Tempfile.open('benchmark') do |file|
          file << array.pack('I*')
          
          begin
            index = @cls.new(file, :format => format)  
            yield(x, format, index)
          ensure
            index.close if index
          end
        end
      end
      
      yield(x, "array reference", array)
    end
     
    array
  end
  
  def test_element_reference_speed_for_index
    n = 100
    index_bm_test('r') do |x, type, index|
      puts type
      
      x.report("#{n}kx [index]") { (n*1000).times { index[1000] } }
      x.report("#{n}kx [range]") { (n*1000).times { index[1000..1000] } }
      x.report("#{n}kx [s,1]") { (n*1000).times { index[1000, 1] } }
      x.report("#{n}kx [s,10]") { (n*1000).times { index[1000, 10] } }
      x.report("#{n}kx [s,100]") { (n*1000).times { index[1000, 100] } }   
      
      puts
    end
  end

  def test_element_assignment_speed_for_index
    index_bm_test('r+') do |x, type, index|
      puts type
      
      n = 10
      obj = Array.new(index.respond_to?(:frame) ? index.frame : 1, 0)
      
      x.report("#{n}kx [index]=") do 
        (n*1000).times { index[1000] = obj} 
      end      
      x.report("#{n}kx [range]=") do 
        (n*1000).times { index[1000..1000] = [obj] } 
      end  
      x.report("#{n}kx [s,1]=") do 
        (n*1000).times { index[1000,1] = [obj] } 
      end
      
      puts
    end
  end
end



class Hold
  def btest_each_speed
    indexbm_test('r') do |x, type, index|
      x.report("10x #{type} - cs100k") { 10.times { index.each {|e|} } }
      #x.report("10x #{type} - cs100") { 10.times { index.each(0,index.length, 100) {|e|} } }      
    end
  end
  
  
  def btest_push_speed
    indexbm_test('r+') do |x, type, index|
      obj = Array.new(index.frame, 0)
      x.report("10kx #{type} index=") do 
        10000.times { index << obj} 
      end    
    end
  end
  
  def btest_sort_speed
    benchmark_test(20) do |x|
      n = 1
      unsorted, sorted = sort_arrays(n*10**6)
      
      x.report("#{n}M array sort") do 
        unsorted.sort
      end
      
      index = setup_index({:default_blksize => 100000}, unsorted)
      x.report("#{n}M index sort") do 
        index.sort.close
      end
      index.close
      
      index = setup_index({:frame => 2, :default_blksize => 100000}, unsorted)
      x.report("#{n}M frame with block") do 
        index.sort {|a, b| b <=> a }.close
      end
      index.close
      
      sindex = setup_sindex({:default_blksize => 100000}, unsorted)
      x.report("#{n}M sindex sort") do 
        sindex.sort.close
      end
      sindex.close
      
      # cannot finish... not sure why
    #  sindex = setup_sindex({:frame => 2, :default_blksize => 100000}, unsorted)
    #  x.report("#{n}M frame with block") do 
    #    sindex.sort {|a, b| b <=> a }.close
    #  end
    #  sindex.close
    end
  end
end