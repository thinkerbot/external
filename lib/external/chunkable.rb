module External
  
  # The Chunkable mixin provides methods for organizing a span or range
  # into chunks no larger than a specified block size. For reference:
  #
  #   span    an array like: [start, length]
  #   range   a Range like: start..end or start...(end - 1)
  #
  module Chunkable
    
    # The length of the chunkable object; 
    # length must be set by the object.
    attr_accessor :length
    
    # The default block size for chunking a chunkable
    # object; default_blksize must be set by the object.
    attr_accessor :default_blksize
    
    # Returns the default span: [0, length]
    def default_span
      [0, length]
    end

    # Breaks the input range or span into chunks of blksize or less.  
    # The offset and length of each chunk will be provided to the 
    # block, if given.
    #
    #   blksize           # => 100
    #   chunk(0..250)     # => [[0,100],[100,100],[200,50]]
    #
    #   results = []
    #   chunk([10,190]) {|offset, length| results << [offset, length]}
    #   results           # => [[10,100],[110,90]]
    #
    def chunk(range_or_span=default_span, blksize=default_blksize)
      return collect_results(:chunk, range_or_span) unless block_given?
      
      rbegin, rend = range_begin_and_end(range_or_span)
      
      # chunk the final range to make sure that no chunks  
      # greater than blksize are returned
      while rend - rbegin > blksize 
        yield(rbegin, blksize)
        rbegin += blksize
      end
      yield(rbegin, rend - rbegin) if rend - rbegin > 0
    end
    
    # Breaks the input range or span into chunks of blksize or less,
    # beginning from the end of the interval.  The offset and length 
    # of each chunk will be provided to the block, if given.
    #
    #   blksize                   # => 100
    #   reverse_chunk(0..250)     # => [[150,100],[50,100],[0,50]]
    #
    #   results = []
    #   reverse_chunk([10,190]) {|offset, length| results << [offset, length]}
    #   results                   # => [[100,100],[10,90]]
    #
    def reverse_chunk(range_or_span=default_span, blksize=default_blksize)
      return collect_results(:reverse_chunk, range_or_span) unless block_given?
    
      rbegin, rend = range_begin_and_end(range_or_span)

      # chunk the final range to make sure that no chunks  
      # greater than blksize are returned
      while rend - rbegin > blksize 
        rend -= blksize
        yield(rend, blksize)
      end
      yield(rbegin, rend - rbegin) if rend - rbegin > 0
    end

    module_function
    
    # Converts a range into an offset and length.  Negative values are
    # counted back from self.length
    #
    #   length                # => 10
    #   split_range(0..9)     # => [0,10]
    #   split_range(0...9)    # => [0,9]
    #
    #   split_range(-1..9)    # => [9,1]
    #   split_range(0..-1)    # => [0,10]
    def split_range(range)
      start, finish = range.begin, range.end
      start += length if start < 0
      finish += length if finish < 0
      
      [start, finish - start - (range.exclude_end? ? 1 : 0)]
    end
    
    # The compliment to split_range; returns the span with a negative
    # start index counted back from self.length.
    #
    #   length                # => 10
    #   split_span([0, 10])   # => [0,10]
    #   split_span([-1, 1])   # => [9,1]
    #
    def split_span(span)
      span[0] += self.length if span[0] < 0
      span
    end
    
    # Returns the begining and end of a range or span.
    # 
    #   range_begin_and_end(0..10)    # => [0, 10]
    #   range_begin_and_end(0...10)   # => [0, 9]
    #   range_begin_and_end([0, 10])  # => [0, 10]
    #
    def range_begin_and_end(range_or_span)
      rbegin, rend = range_or_span.kind_of?(Range) ? split_range(range_or_span) : split_span(range_or_span)
      raise ArgumentError.new("negative offset specified: #{PP.singleline_pp(range_or_span,'')}") if rbegin < 0
      rend += rbegin
      
      [rbegin, rend]
    end

    private
    
    # a utility method to collect the results of a method
    # that requires a block.
    def collect_results(method, args) # :nodoc:
      results = []
      send(method, args) do |*result|
        results << result
      end
      results
    end
  end
end
