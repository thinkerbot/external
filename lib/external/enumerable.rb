require 'enumerator'

module External
  
  # An externalized implementation of Enumerable.  External::Enumerable
  # requires several methods with the following functionality: 
  # 
  # each:: iterates over items in self
  # another::  provide a another instance of self
  # to_a:: converts self to an Array
  #
  module Enumerable
    # Flag indicating whether to enumerate (ie collect,
    # select, etc) into an array or into an instance
    # of self.  In most cases enumerating to an array
    # performs better, but enumerating to another
    # instance of self may be desired for especially
    # large collections.
    attr_accessor :enumerate_to_a
    
    def all? # :yield: obj
      # WARN -- no tests for this in test_array
      each do |obj|
        return false unless yield(obj)
      end
      true
    end
    
    def any? # :yield: obj
      # WARN -- no tests for this in test_array
      each do |obj|
        return true if yield(obj)
      end
      false
    end
    
    def collect # :yield: item
      if block_given?
        another = enumerate_to_a ? [] : self.another
        each do |item|
          another << yield(item)
        end
        another
      else
        # Not sure if Enumerator works right for large externals...
        Object::Enumerable::Enumerator.new(self)
      end
    end
    
    # def collect! # :yield: item
    #   not_implemented
    # end
    
    def detect(ifnone=nil) # :yield: obj
      # WARN -- no tests for this in test_array
      each do |obj|
        return obj if yield(obj)
      end
      nil
    end
    
    # def each_cons(n) # :yield:
    #   not_implemented
    # end
    
    # def each_slice(n) # :yield:
    #   not_implemented
    # end
    
    def each_with_index(&block)
      chunk do |offset, length|
        self[offset, length].each_with_index do |item, i|
          yield(item, i + offset)
        end
      end
    end
    
    def entries
      to_a
    end
    
    # def enum_cons(n)
    #   not_implemented
    # end
    
    # def enum_slice(n)
    #   not_implemented
    # end
    
    # def enum_with_index
    #   not_implemented
    # end
    
    def find(ifnone=nil, &block) # :yield: obj
      # WARN -- no tests for this in test_array
      detect(ifnone, &block)
    end
    
    def find_all # :yield: obj
      another = enumerate_to_a ? [] : self.another
      each do |item|
        another << item if yield(item)
      end
      another
    end
    
    # def grep(pattern) # :yield: obj
    #   not_implemented
    # end
    
    def include?(obj)
      each do |current|
        return true if current == obj
      end
      false
    end
    
    # def inject(init) # :yield: memo, obj
    #   not_implemented
    # end
    
    def map(&block) # :yield: item
      collect(&block)
    end
    
    # def map!(&block) # :yield: item
    #   collect!(&block)
    # end
    
    # def max # :yield: a,b
    #   not_implemented
    # end
    
    def member?(obj)
      include?(obj)
    end
    
    # def min # :yield: a,b
    #   not_implemented
    # end
    
    # def partition # :yield: obj
    #   not_implemented
    # end
    
    # def reject # :yield: item
    #   not_implemented
    # end
    
    # def reject! # :yield: item
    #   not_implemented
    # end
    
    def select(&block) # :yield: obj
      find_all(&block)
    end
    
    # def sort # :yield: a,b
    #   not_implemented
    # end
    
    # def sort! # :yield: a,b
    #   not_implemented
    # end
    
    # def sort_by # :yield: obj
    #   not_implemented
    # end
    
    # def to_a
    #   not_implemented
    # end
    
    # def to_set(klass=Set, *args, &block)
    #   not_implemented
    # end

    # def zip(*arg) # :yield: arr
    #   not_implemented
    # end
  end
end