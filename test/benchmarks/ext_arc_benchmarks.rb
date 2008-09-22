require File.join(File.dirname(__FILE__), '../external_test_helper.rb') 
require 'ext_arc'
require 'fileutils'

class ExtArcBenchmarks < Test::Unit::TestCase
  include Benchmark
  
  def test_reindex_by_sep_speed
    puts "\n#{method_name}"
    bm(20) do |x|
      Tempfile.open("benchmark") do |file|
        str = (0..10).to_a.join("\n")
        file << str
        file.flush
        
        ea = ExtArc.new(file)
        assert_equal 0, ea.length
        x.report("\n#{10} entries") do
          ea.reindex_by_sep
        end
        assert_equal (10), ea.length
      end
      
      Tempfile.open("benchmark") do |file|
        # 20 bytes * 100 = 2kb * 1000 = 2Mb
        str = (0..10).to_a.join("\n") * 100 * 1000
        file << str
        file.flush
        
        ea = ExtArc.new(file)
        assert_equal 0, ea.length
        x.report("\n#{10 * 100 *1000} entries") do
          ea.reindex_by_sep
        end
        assert_equal (10 * 100 *1000), ea.length
      end 
    end
  end
  
  def test_reindex_by_regexp_speed
    puts "\n#{method_name}"
    bm(20) do |x|
      Tempfile.open("benchmark") do |file|
        str = (0..10).to_a.join("\n")
        file << str
        file.flush
        
        ea = ExtArc.new(file)
        assert_equal 0, ea.length
        x.report("\n#{10} entries") do
          ea.reindex_by_regexp
        end
        assert_equal (10), ea.length
      end
      
      Tempfile.open("benchmark") do |file|
        # 20 bytes * 100 = 2kb * 1000 = 2Mb
        str = (0..10).to_a.join("\n") * 100 * 1000
        file << str
        file.flush
        
        ea = ExtArc.new(file)
        assert_equal 0, ea.length
        x.report("\n#{10 * 100 *1000} entries") do
          ea.reindex_by_regexp
        end
        assert_equal (10 * 100 *1000), ea.length
      end 
    end
  end
end