require 'test/unit'
require 'benchmark'
require 'tap/test/subset_methods'

ENV['benchmark'] = 'true'

class BenchmarkCheck < Test::Unit::TestCase
  include Tap::Test::SubsetMethods
  include Benchmark
  
  if match_platform?('darwin')
    require 'inline'
    
    inline do |builder|
      builder.c %Q{
      int read_in_chunk(VALUE str, int n, int times) {
        char *filepath = RSTRING(str)->ptr;
        FILE *fp = fopen(filepath, "r");
        char input[(n*times)];
        int len = (n*times)+1;  // ADD ONE to the read length because a null is appended as well

        if (fp != NULL)
        {
          fgets(input, len, fp);
          //printf(input);
          fclose(fp);
          return 1;
        }
        else
          return 0;
      }}
    end
    
    inline do |builder|
      builder.c %Q{
      int read_in_pieces(VALUE str, int n, int times) {
        char *filepath = RSTRING(str)->ptr;
        FILE *fp = fopen(filepath, "r");
        char input[n];
        int len = n+1;  // ADD ONE to the read length because a null is appended as well
        int i = 0;

        if (fp != NULL)
        {
          while(i < times)
          {
            fgets(input, len, fp);
            //printf(input);
            ++i;
          }
          fclose(fp);
          return 1;
        }
        else
          return 0;
      }}
    end
      
    inline do |builder|
      builder.c %Q{
      int read_in_one_block(VALUE str, int len, int times) {
        char *filepath = RSTRING(str)->ptr;
        FILE *fp = fopen(filepath, "r");
        char input[len*times];
        int n_read;
        
        if (fp != NULL)
        {
          n_read = fread(input, len, times, fp);
          input[n_read*len] = NULL;
          //printf(input);
          fclose(fp);
          return 1;
        }
        else
          return 0;
      }}
    end
    
    inline do |builder|
      builder.c %Q{
      int read_in_blocks(VALUE str, int len, int times) {
        char *filepath = RSTRING(str)->ptr;
        FILE *fp = fopen(filepath, "r");
        char input[len];
        int n_read;
        int i = 0;
        
        if (fp != NULL)
        {
          while(i < times)
          {
            fread(input, len, 1, fp);
            input[len] = NULL;
            //printf(input);
            ++i;
          }
          
          fclose(fp);
          return 1;
        }
        else
          return 0;
      }}
    end
  end
  
  def test_read_in_chunk_vs_read_in_pieces
    platform_test("darwin") do
      begin 
        filepath = File.expand_path("background_test.txt")
        File.open(filepath, "w") do |file|
           10000.times do
             file << "0123456789"
           end
        end
        assert_equal 10000*10, File.size(filepath)
        
        benchmark_test(20) do |x|
          x.report("1kx read in chunk") { 1000.times { assert read_in_chunk(filepath, 10, 10000) }}
          x.report("1kx read in pieces") { 1000.times { assert read_in_pieces(filepath, 10, 10000) }}
          x.report("1kx read in one block") { 1000.times { assert read_in_one_block(filepath, 10, 10000) }}
          x.report("1kx read in blocks") { 1000.times { assert read_in_blocks(filepath, 10, 10000) }}
          x.report("1kx File.read") { 1000.times { File.read(filepath) }}
        end
        
      ensure
        FileUtils.rm(filepath) if File.exists?(filepath)
      end
    end
  end
  
  if match_platform?('darwin')
    require 'inline'
 
    inline do |builder|
      builder.c %Q{

      VALUE unpack_to_array(VALUE str, int frame, int size, int times) {
        char *filepath = RSTRING(str)->ptr;
        FILE *fp = fopen(filepath, "r");
        char input[frame*size*times];
        char *p = input;
        int i, j;
        VALUE results, arr;

        if (fp == NULL)
          rb_raise(rb_eArgError, "couldn't open file");

        times = fread(input, frame*size, times, fp);
        results = rb_ary_new();

        // convert to Fixnums
        i = 0;
        while(i < times)
        {
          j = 0;
          arr = rb_ary_new();
          while(j < frame)
          {
            // no need to copy the data at *p,
            // apparently the conversion can 
            // happen directly from the pointer
      		  rb_ary_push(arr, UINT2NUM(*p));
      		  p += size;
            ++j;
    		  }

    		  rb_ary_push(results, arr);
    		  ++i;
        }

        fclose(fp);
        return results;
      }}
    end
  end
  
  require 'enumerator'
  
  def test_read_into_arrays
    platform_test("darwin") do
      begin 
        filepath = File.expand_path("background_test.txt")
        
        times = 5000
        frame = 5
        size = 4
        format = "I*"
        
        array = Array.new(times) { (1..frame).to_a }
        File.open(filepath, "w") do |file|
          file << array.flatten.pack(format)
        end
        assert_equal 10000*10, File.size(filepath)
        assert_equal array, unpack_to_array(filepath, frame, size, times)
        
        benchmark_test(20) do |x|
          x.report("100x unpack to array") { 100.times { unpack_to_array(filepath, frame, size, times) }}
          
          results = []
          File.read(filepath).unpack(format).each_slice(frame) do |arr|
            results << arr
          end
          assert_equal array, results
          x.report("100x File.read.unpack") do 
            100.times do
              results = []
              File.read(filepath).unpack(format).each_slice(frame) do |arr|
                results << arr
              end
            end
          end
        end

      ensure
        FileUtils.rm(filepath) if File.exists?(filepath)
      end  
    end
  end
  
  if match_platform?('darwin')
    require 'inline'
 
    inline do |builder|
      builder.c %Q{

      VALUE unpack_str(VALUE str, int frame, int size, int times) {
        char *p = RSTRING(str)->ptr;
        int i, j;
        VALUE results, arr;
        char directive = 'I';
        results = rb_ary_new();

        i = 0;
        while(i < times)
        {
          j = 0;
          arr = rb_ary_new();
          while(j < frame)
          {
            switch(directive)
            {
              case 'I':
                {// no need to copy the data at *p,
                // apparently the conversion can 
                // happen directly from the pointer
          		  rb_ary_push(arr, UINT2NUM(*p));
          		  p += size;
                ++j;}
                break;
            }
    		  }

    		  rb_ary_push(results, arr);
    		  ++i;
        }

        return results;
      }}
    end
  end
  
  require 'enumerator'
  
  def test_unpack_speed
    platform_test("darwin") do
      begin 
        filepath = File.expand_path("background_test.txt")
        
        times = 5000
        frame = 5
        size = 4
        format = "I*"
        
        array = Array.new(times) { (1..frame).to_a }
        File.open(filepath, "w") do |file|
          file << array.flatten.pack(format)
        end
        assert_equal 10000*10, File.size(filepath)
        
        str = File.read(filepath)
        assert_equal array, unpack_str(str, frame, size, times)
        
        benchmark_test(20) do |x|
          x.report("100x unpack") { 100.times { unpack_str(str, frame, size, times) }}
          
          results = []
          File.read(filepath).unpack(format).each_slice(frame) do |arr|
            results << arr
          end
          assert_equal array, results
          x.report("100x str.unpack") do 
            100.times do
              results = []
              str.unpack(format).each_slice(frame) do |arr|
                results << arr
              end
            end
          end
        end

      ensure
        FileUtils.rm(filepath) if File.exists?(filepath)
      end  
    end
  end
  
  if match_platform?('darwin')
    require 'inline'
 
    inline do |builder|
      builder.c %Q{

      int work_with_values() {
      	int a = NUM2INT(rb_iv_get(self, "@a"));
      	int b = NUM2INT(rb_iv_get(self, "@b"));
      	
        return a + b;
      }}
    end
  end
  
  attr_accessor :a, :b
  
  def test_work_with_values
    platform_test("darwin") do
      @a = 10
      @b = 2
        
      assert_equal 12, work_with_values
    end
  end
  
  if match_platform?('darwin')
    require 'inline'
    
    module FileExt
      inline do |builder|
        builder.include "<rubyio.h>"
        builder.c %Q{

        int read_from_file(int n) {
        	FILE *fp = RFILE(self)->fptr->f;
        	
          char input[n];
          int len = n+1;  // ADD ONE to the read length because a null is appended as well

          if (fp != NULL)
          {
            fgets(input, len, fp);
            //printf(input);
            fclose(fp);
            return 1;
          }
          else
            return 0;
        }}
      end
    end
  end
  
  def test_get_file_pointer
    platform_test("darwin") do
      begin 
        filepath = File.expand_path("background_test.txt")
        File.open(filepath, 'w+') do |file|
          file.extend FileExt
          file << "hello world"
          file.pos = 0
          assert file.read_from_file(5)
        end
      ensure
        FileUtils.rm(filepath) if File.exists?(filepath)
      end
    end
  end
  
  if match_platform?('darwin')
    require 'inline'
    
    inline do |builder|
      builder.include "<rubyio.h>"
      builder.c %Q{
      int read_from_file(int len, int times) {
        FILE *fp = RFILE(rb_iv_get(self, "@file"))->fptr->f;  
        char input[len*times];
        
        if (fp == NULL)
          return 0;
          
        fread(input, len, times, fp);
        input[len*times] = NULL;
        // printf(input);
 
        return 1;
      }}
    end
  end
  
  attr_reader :file
  
  def test_read_from_open_file
    platform_test("darwin") do
      begin 
        filepath = File.expand_path("background_test.txt")
        File.open(filepath, "w") do |file|
           10000.times do
             file << "0123456789"
           end
        end
        assert_equal 10000*10, File.size(filepath)
        
        
        File.open(filepath) do |file|
          @file = file
          
          file.pos = 0
          assert read_from_file(10, 2)
          
          benchmark_test(20) do |x|
            x.report("1kx read from file") { 1000.times { file.pos = 0; read_from_file(10, 10000) }}
            x.report("1kx file.read") { 1000.times { file.pos = 0; file.read }}
          end
        
        end
      ensure
        FileUtils.rm(filepath) if File.exists?(filepath)
      end
    end
  end
  
  def test_array_methods
    benchmark_test(20) do |x|
      a = []
      x.report("1M <<") { (1*1000000).times { a << 1 } }
      a.clear
      x.report("1M []") { (1*1000000).times { a[1] = 1 } }
    end
  end
end
