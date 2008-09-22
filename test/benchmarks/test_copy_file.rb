require File.join(File.dirname(__FILE__), '../external_test_helper.rb') 
require 'tempfile'
require 'fileutils'

ENV['ALL'] = 'true'

class TestCopyFile < Test::Unit::TestCase
  include Benchmark
  include Tap::Test::SubsetMethods
  
  
  # The lesson from this test is that chunky copy can be 
  # faster than FileUtils.cp  It's interesting to note
  # that if you look up the code, you can see that a
  # chunky copy is exactly what cp is... with chunks of
  # 1024 bytes.
  def test_copy_vs_chunky_rewrite
    t = Tempfile.new "large_file"
    t.close
    puts t.path

    prompt_test(:path_to_large_file) do |config|
      path = config[:path_to_large_file]
      
      benchmark_test do |x|
        x.report("copy") { FileUtils.cp(path, t.path) }
        assert FileUtils.cmp(path, t.path)
        
        # tenmb = 1 * 2097152
        # x.report("chunk 2MB") do 
        #   File.open(path, "r") do |src|
        #     File.open(t.path, "w") do |target|
        #       str = ""
        #       while src.read(tenmb, str)
        #         target << str
        #       end
        #     end
        #   end
        # end
        
        tenmb = 4 * 2097152
        x.report("chunk 8MB") do 
          File.open(path, "r") do |src|
            File.open(t.path, "w") do |target|
              str = ""
              while src.read(tenmb, str)
                target << str
              end
            end
          end
        end
        assert FileUtils.cmp(path, t.path)
        
        # tenmb = 4 * 2097152
        # x.report("chunk 8MB - no buf") do 
        #   File.open(path, "r") do |src|
        #     File.open(t.path, "w") do |target|
        #       while str = src.read(tenmb)
        #         target << str
        #       end
        #     end
        #   end
        # end
        
        # tenmb = 10 * 2097152
        # x.report("chunk 20MB") do 
        #   File.open(path, "r") do |src|
        #     File.open(t.path, "w") do |target|
        #       str = ""
        #       while src.read(tenmb, str)
        #         target << str
        #       end
        #     end
        #   end
        # end

      end
    end
  end
end