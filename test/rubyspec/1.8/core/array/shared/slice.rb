# 84464649a5350c6fd93029e7980e9d72
# Generated: 2008-09-22 16:25:10
################################################################################
# describe :array_slice, :shared => true do
#   it "returns the element at index with [index]" do
#     [ "a", "b", "c", "d", "e" ].send(@method, 1).should == "b"
# 
#     a = [1, 2, 3, 4]
# 
#     a.send(@method, 0).should == 1
#     a.send(@method, 1).should == 2
#     a.send(@method, 2).should == 3
#     a.send(@method, 3).should == 4
#     a.send(@method, 4).should == nil
#     a.send(@method, 10).should == nil
# 
#     a.should == [1, 2, 3, 4]
#   end
# 
#   it "returns the element at index from the end of the array with [-index]" do
#     [ "a", "b", "c", "d", "e" ].send(@method, -2).should == "d"
# 
#     a = [1, 2, 3, 4]
# 
#     a.send(@method, -1).should == 4
#     a.send(@method, -2).should == 3
#     a.send(@method, -3).should == 2
#     a.send(@method, -4).should == 1
#     a.send(@method, -5).should == nil
#     a.send(@method, -10).should == nil
# 
#     a.should == [1, 2, 3, 4]
#   end
# 
#   it "return count elements starting from index with [index, count]" do
#     [ "a", "b", "c", "d", "e" ].send(@method, 2, 3).should == ["c", "d", "e"]
# 
#     a = [1, 2, 3, 4]
# 
#     a.send(@method, 0, 0).should == []
#     a.send(@method, 0, 1).should == [1]
#     a.send(@method, 0, 2).should == [1, 2]
#     a.send(@method, 0, 4).should == [1, 2, 3, 4]
#     a.send(@method, 0, 6).should == [1, 2, 3, 4]
#     a.send(@method, 0, -1).should == nil
#     a.send(@method, 0, -2).should == nil
#     a.send(@method, 0, -4).should == nil
# 
#     a.send(@method, 2, 0).should == []
#     a.send(@method, 2, 1).should == [3]
#     a.send(@method, 2, 2).should == [3, 4]
#     a.send(@method, 2, 4).should == [3, 4]
#     a.send(@method, 2, -1).should == nil
# 
#     a.send(@method, 4, 0).should == []
#     a.send(@method, 4, 2).should == []
#     a.send(@method, 4, -1).should == nil
# 
#     a.send(@method, 5, 0).should == nil
#     a.send(@method, 5, 2).should == nil
#     a.send(@method, 5, -1).should == nil
# 
#     a.send(@method, 6, 0).should == nil
#     a.send(@method, 6, 2).should == nil
#     a.send(@method, 6, -1).should == nil
# 
#     a.should == [1, 2, 3, 4]
#   end
# 
#   it "returns count elements starting at index from the end of array with [-index, count]" do
#     [ "a", "b", "c", "d", "e" ].send(@method, -2, 2).should == ["d", "e"]
# 
#     a = [1, 2, 3, 4]
# 
#     a.send(@method, -1, 0).should == []
#     a.send(@method, -1, 1).should == [4]
#     a.send(@method, -1, 2).should == [4]
#     a.send(@method, -1, -1).should == nil
# 
#     a.send(@method, -2, 0).should == []
#     a.send(@method, -2, 1).should == [3]
#     a.send(@method, -2, 2).should == [3, 4]
#     a.send(@method, -2, 4).should == [3, 4]
#     a.send(@method, -2, -1).should == nil
# 
#     a.send(@method, -4, 0).should == []
#     a.send(@method, -4, 1).should == [1]
#     a.send(@method, -4, 2).should == [1, 2]
#     a.send(@method, -4, 4).should == [1, 2, 3, 4]
#     a.send(@method, -4, 6).should == [1, 2, 3, 4]
#     a.send(@method, -4, -1).should == nil
# 
#     a.send(@method, -5, 0).should == nil
#     a.send(@method, -5, 1).should == nil
#     a.send(@method, -5, 10).should == nil
#     a.send(@method, -5, -1).should == nil
# 
#     a.should == [1, 2, 3, 4]
#   end
# 
#   it "returns the first count elements with [0, count]" do
#     [ "a", "b", "c", "d", "e" ].send(@method, 0, 3).should == ["a", "b", "c"]
#   end
# 
#   it "tries to convert the passed argument to an Integer using #to_int" do
#     obj = mock('to_int')
#     obj.stub!(:to_int).and_return(2)
# 
#     a = [1, 2, 3, 4]
#     a.send(@method, obj).should == 3
#     a.send(@method, obj, 1).should == [3]
#     a.send(@method, obj, obj).should == [3, 4]
#     a.send(@method, 0, obj).should == [1, 2]
#   end
# 
#   it "checks whether index and count respond to #to_int with [index, count]" do
#     obj = mock('method_missing to_int')
#     obj.should_receive(:respond_to?).with(:to_int).any_number_of_times.and_return(true)
#     obj.should_receive(:method_missing).with(:to_int).and_return(2, 2)
#     [1, 2, 3, 4].send(@method, obj, obj).should == [3, 4]
#   end
# 
#   it "returns the elements specified by Range indexes with [m..n]" do
#     [ "a", "b", "c", "d", "e" ].send(@method, 1..3).should == ["b", "c", "d"]
#     [ "a", "b", "c", "d", "e" ].send(@method, 4..-1).should == ['e']
#     [ "a", "b", "c", "d", "e" ].send(@method, 3..3).should == ['d']
#     [ "a", "b", "c", "d", "e" ].send(@method, 3..-2).should == ['d']
#     ['a'].send(@method, 0..-1).should == ['a']
# 
#     a = [1, 2, 3, 4]
# 
#     a.send(@method, 0..-10).should == []
#     a.send(@method, 0..0).should == [1]
#     a.send(@method, 0..1).should == [1, 2]
#     a.send(@method, 0..2).should == [1, 2, 3]
#     a.send(@method, 0..3).should == [1, 2, 3, 4]
#     a.send(@method, 0..4).should == [1, 2, 3, 4]
#     a.send(@method, 0..10).should == [1, 2, 3, 4]
# 
#     a.send(@method, 2..-10).should == []
#     a.send(@method, 2..0).should == []
#     a.send(@method, 2..2).should == [3]
#     a.send(@method, 2..3).should == [3, 4]
#     a.send(@method, 2..4).should == [3, 4]
# 
#     a.send(@method, 3..0).should == []
#     a.send(@method, 3..3).should == [4]
#     a.send(@method, 3..4).should == [4]
# 
#     a.send(@method, 4..0).should == []
#     a.send(@method, 4..4).should == []
#     a.send(@method, 4..5).should == []
# 
#     a.send(@method, 5..0).should == nil
#     a.send(@method, 5..5).should == nil
#     a.send(@method, 5..6).should == nil
# 
#     a.should == [1, 2, 3, 4]
#   end
# 
#   it "returns elements specified by Range indexes except the element at index n with [m...n]" do
#     [ "a", "b", "c", "d", "e" ].send(@method, 1...3).should == ["b", "c"]
# 
#     a = [1, 2, 3, 4]
# 
#     a.send(@method, 0...-10).should == []
#     a.send(@method, 0...0).should == []
#     a.send(@method, 0...1).should == [1]
#     a.send(@method, 0...2).should == [1, 2]
#     a.send(@method, 0...3).should == [1, 2, 3]
#     a.send(@method, 0...4).should == [1, 2, 3, 4]
#     a.send(@method, 0...10).should == [1, 2, 3, 4]
# 
#     a.send(@method, 2...-10).should == []
#     a.send(@method, 2...0).should == []
#     a.send(@method, 2...2).should == []
#     a.send(@method, 2...3).should == [3]
#     a.send(@method, 2...4).should == [3, 4]
# 
#     a.send(@method, 3...0).should == []
#     a.send(@method, 3...3).should == []
#     a.send(@method, 3...4).should == [4]
# 
#     a.send(@method, 4...0).should == []
#     a.send(@method, 4...4).should == []
#     a.send(@method, 4...5).should == []
# 
#     a.send(@method, 5...0).should == nil
#     a.send(@method, 5...5).should == nil
#     a.send(@method, 5...6).should == nil
# 
#     a.should == [1, 2, 3, 4]
#   end
# 
#   it "returns elements that exist if range start is in the array but range end is not with [m..n]" do
#     [ "a", "b", "c", "d", "e" ].send(@method, 4..7).should == ["e"]
#   end
# 
#   it "accepts Range instances having a negative m and both signs for n with [m..n] and [m...n]" do
#     a = [1, 2, 3, 4]
# 
#     a.send(@method, -1..-1).should == [4]
#     a.send(@method, -1...-1).should == []
#     a.send(@method, -1..3).should == [4]
#     a.send(@method, -1...3).should == []
#     a.send(@method, -1..4).should == [4]
#     a.send(@method, -1...4).should == [4]
#     a.send(@method, -1..10).should == [4]
#     a.send(@method, -1...10).should == [4]
#     a.send(@method, -1..0).should == []
#     a.send(@method, -1..-4).should == []
#     a.send(@method, -1...-4).should == []
#     a.send(@method, -1..-6).should == []
#     a.send(@method, -1...-6).should == []
# 
#     a.send(@method, -2..-2).should == [3]
#     a.send(@method, -2...-2).should == []
#     a.send(@method, -2..-1).should == [3, 4]
#     a.send(@method, -2...-1).should == [3]
#     a.send(@method, -2..10).should == [3, 4]
#     a.send(@method, -2...10).should == [3, 4]
# 
#     a.send(@method, -4..-4).should == [1]
#     a.send(@method, -4..-2).should == [1, 2, 3]
#     a.send(@method, -4...-2).should == [1, 2]
#     a.send(@method, -4..-1).should == [1, 2, 3, 4]
#     a.send(@method, -4...-1).should == [1, 2, 3]
#     a.send(@method, -4..3).should == [1, 2, 3, 4]
#     a.send(@method, -4...3).should == [1, 2, 3]
#     a.send(@method, -4..4).should == [1, 2, 3, 4]
#     a.send(@method, -4...4).should == [1, 2, 3, 4]
#     a.send(@method, -4...4).should == [1, 2, 3, 4]
#     a.send(@method, -4..0).should == [1]
#     a.send(@method, -4...0).should == []
#     a.send(@method, -4..1).should == [1, 2]
#     a.send(@method, -4...1).should == [1]
# 
#     a.send(@method, -5..-5).should == nil
#     a.send(@method, -5...-5).should == nil
#     a.send(@method, -5..-4).should == nil
#     a.send(@method, -5..-1).should == nil
#     a.send(@method, -5..10).should == nil
# 
#     a.should == [1, 2, 3, 4]
#   end
# 
#   it "tries to convert Range elements to Integers using #to_int with [m..n] and [m...n]" do
#     from = mock('from')
#     to = mock('to')
# 
#     # So we can construct a range out of them...
#     def from.<=>(o) 0 end
#     def to.<=>(o) 0 end
# 
#     def from.to_int() 1 end
#     def to.to_int() -2 end
# 
#     a = [1, 2, 3, 4]
# 
#     a.send(@method, from..to).should == [2, 3]
#     a.send(@method, from...to).should == [2]
#     a.send(@method, 1..0).should == []
#     a.send(@method, 1...0).should == []
# 
#     lambda { a.slice("a" .. "b") }.should raise_error(TypeError)
#     lambda { a.slice("a" ... "b") }.should raise_error(TypeError)
#     lambda { a.slice(from .. "b") }.should raise_error(TypeError)
#     lambda { a.slice(from ... "b") }.should raise_error(TypeError)
#   end
# 
#   it "checks whether the Range elements respond to #to_int with [m..n] and [m...n]" do
#     from = mock('from')
#     to = mock('to')
# 
#     def from.<=>(o) 0 end
#     def to.<=>(o) 0 end
# 
#     from.should_receive(:respond_to?).with(:to_int).any_number_of_times.and_return(true)
#     from.should_receive(:method_missing).with(:to_int).and_return(1)
#     
#     to.should_receive(:respond_to?).with(:to_int).any_number_of_times.and_return(true)
#     to.should_receive(:method_missing).with(:to_int).and_return(-2)
#     
#     [1, 2, 3, 4].send(@method, from..to).should == [2, 3]
#   end
# 
#   it "returns the same elements as [m..n] and [m...n] with Range subclasses" do
#     a = [1, 2, 3, 4]
#     range_incl = ArraySpecs::MyRange.new(1, 2)
#     range_excl = ArraySpecs::MyRange.new(-3, -1, true)
# 
#     a[range_incl].should == [2, 3]
#     a[range_excl].should == [2, 3]
#   end
# 
#   it "returns nil for a requested index not in the array with [index]" do
#     [ "a", "b", "c", "d", "e" ].send(@method, 5).should == nil
#   end
# 
#   it "returns [] if the index is valid but length is zero with [index, length]" do
#     [ "a", "b", "c", "d", "e" ].send(@method, 0, 0).should == []
#     [ "a", "b", "c", "d", "e" ].send(@method, 2, 0).should == []
#   end
# 
#   it "returns nil if length is zero but index is invalid with [index, length]" do
#     [ "a", "b", "c", "d", "e" ].send(@method, 100, 0).should == nil
#     [ "a", "b", "c", "d", "e" ].send(@method, -50, 0).should == nil
#   end
# 
#   # This is by design. It is in the official documentation.
#   it "returns [] if index == array.size with [index, length]" do
#     %w|a b c d e|.send(@method, 5, 2).should == []
#   end
# 
#   it "returns nil if index > array.size with [index, length]" do
#     %w|a b c d e|.send(@method, 6, 2).should == nil
#   end
# 
#   it "returns nil if length is negative with [index, length]" do
#     %w|a b c d e|.send(@method, 3, -1).should == nil
#     %w|a b c d e|.send(@method, 2, -2).should == nil
#     %w|a b c d e|.send(@method, 1, -100).should == nil
#   end
# 
#   it "returns nil if no requested index is in the array with [m..n]" do
#     [ "a", "b", "c", "d", "e" ].send(@method, 6..10).should == nil
#   end
# 
#   it "returns nil if range start is not in the array with [m..n]" do
#     [ "a", "b", "c", "d", "e" ].send(@method, -10..2).should == nil
#     [ "a", "b", "c", "d", "e" ].send(@method, 10..12).should == nil
#   end
# 
#   it "returns an empty array when m == n with [m...n]" do
#     [1, 2, 3, 4, 5].send(@method, 1...1).should == []
#   end
# 
#   it "returns an empty array with [0...0]" do
#     [1, 2, 3, 4, 5].send(@method, 0...0).should == []
#   end
# 
#   it "returns a subarray where m, n negatives and m < n with [m..n]" do
#     [ "a", "b", "c", "d", "e" ].send(@method, -3..-2).should == ["c", "d"]
#   end
# 
#   it "returns an array containing the first element with [0..0]" do
#     [1, 2, 3, 4, 5].send(@method, 0..0).should == [1]
#   end
# 
#   it "returns the entire array with [0..-1]" do
#     [1, 2, 3, 4, 5].send(@method, 0..-1).should == [1, 2, 3, 4, 5]
#   end
# 
#   it "returns all but the last element with [0...-1]" do
#     [1, 2, 3, 4, 5].send(@method, 0...-1).should == [1, 2, 3, 4]
#   end
# 
#   it "returns [3] for [2..-1] out of [1, 2, 3] <Specifies bug found by brixen, Defiler, mae>" do
#     [1,2,3].send(@method, 2..-1).should == [3]
#   end
# 
#   it "returns an empty array when m > n and m, n are positive with [m..n]" do
#     [1, 2, 3, 4, 5].send(@method, 3..2).should == []
#   end
# 
#   it "returns an empty array when m > n and m, n are negative with [m..n]" do
#     [1, 2, 3, 4, 5].send(@method, -2..-3).should == []
#   end
# 
#   it "does not expand array when the indices are outside of the array bounds" do
#     a = [1, 2]
#     a.send(@method, 4).should == nil
#     a.should == [1, 2]
#     a.send(@method, 4, 0).should == nil
#     a.should == [1, 2]
#     a.send(@method, 6, 1).should == nil
#     a.should == [1, 2]
#     a.send(@method, 8...8).should == nil
#     a.should == [1, 2]
#     a.send(@method, 10..10).should == nil
#     a.should == [1, 2]
#   end
# 
#   it "returns a subclass instance when called on a subclass of Array" do
#     ary = ArraySpecs::MyArray[1, 2, 3]
#     ary.send(@method, 0, 0).class.should == ArraySpecs::MyArray
#     ary.send(@method, 0, 2).class.should == ArraySpecs::MyArray
#     ary.send(@method, 0..10).class.should == ArraySpecs::MyArray
#   end
# 
#   not_compliant_on :rubinius do
#     it "raises a RangeError when the start index is out of range of Fixnum" do
#       array = [1, 2, 3, 4, 5, 6]
#       obj = mock('large value')
#       obj.should_receive(:to_int).and_return(0x8000_0000_0000_0000_0000)
#       lambda { array.send(@method, obj) }.should raise_error(RangeError)
# 
#       obj = 8e19
#       lambda { array.send(@method, obj) }.should raise_error(RangeError)
#     end
# 
#     it "raises a RangeError when the length is out of range of Fixnum" do
#       array = [1, 2, 3, 4, 5, 6]
#       obj = mock('large value')
#       obj.should_receive(:to_int).and_return(0x8000_0000_0000_0000_0000)
#       lambda { array.send(@method, 1, obj) }.should raise_error(RangeError)
# 
#       obj = 8e19
#       lambda { array.send(@method, 1, obj) }.should raise_error(RangeError)
#     end
#   end
# 
#   deviates_on :rubinius do
#     it "raises a TypeError when the start index is out of range of Fixnum" do
#       array = [1, 2, 3, 4, 5, 6]
#       obj = mock('large value')
#       obj.should_receive(:to_int).and_return(0x8000_0000_0000_0000_0000)
#       lambda { array.send(@method, obj) }.should raise_error(TypeError)
# 
#       obj = 8e19
#       lambda { array.send(@method, obj) }.should raise_error(TypeError)
#     end
# 
#     it "raises a TypeError when the length is out of range of Fixnum" do
#       array = [1, 2, 3, 4, 5, 6]
#       obj = mock('large value')
#       obj.should_receive(:to_int).and_return(0x8000_0000_0000_0000_0000)
#       lambda { array.send(@method, 1, obj) }.should raise_error(TypeError)
# 
#       obj = 8e19
#       lambda { array.send(@method, 1, obj) }.should raise_error(TypeError)
#     end
#   end
# end

describe :array_slice, :shared => true do
  it "returns the element at index with [index]" do
    ExternalArray[ "a", "b", "c", "d", "e" ].send(@method, 1).should == "b"

    a = ExternalArray[1, 2, 3, 4]

    a.send(@method, 0).should == 1
    a.send(@method, 1).should == 2
    a.send(@method, 2).should == 3
    a.send(@method, 3).should == 4
    a.send(@method, 4).should == nil
    a.send(@method, 10).should == nil

    a.should == [1, 2, 3, 4]
  end

  it "returns the element at index from the end of the array with [-index]" do
    ExternalArray[ "a", "b", "c", "d", "e" ].send(@method, -2).should == "d"

    a = ExternalArray[1, 2, 3, 4]

    a.send(@method, -1).should == 4
    a.send(@method, -2).should == 3
    a.send(@method, -3).should == 2
    a.send(@method, -4).should == 1
    a.send(@method, -5).should == nil
    a.send(@method, -10).should == nil

    a.should == [1, 2, 3, 4]
  end

  it "return count elements starting from index with [index, count]" do
    ExternalArray[ "a", "b", "c", "d", "e" ].send(@method, 2, 3).should == ["c", "d", "e"]

    a = ExternalArray[1, 2, 3, 4]

    a.send(@method, 0, 0).should == []
    a.send(@method, 0, 1).should == [1]
    a.send(@method, 0, 2).should == [1, 2]
    a.send(@method, 0, 4).should == [1, 2, 3, 4]
    a.send(@method, 0, 6).should == [1, 2, 3, 4]
    a.send(@method, 0, -1).should == nil
    a.send(@method, 0, -2).should == nil
    a.send(@method, 0, -4).should == nil

    a.send(@method, 2, 0).should == []
    a.send(@method, 2, 1).should == [3]
    a.send(@method, 2, 2).should == [3, 4]
    a.send(@method, 2, 4).should == [3, 4]
    a.send(@method, 2, -1).should == nil

    a.send(@method, 4, 0).should == []
    a.send(@method, 4, 2).should == []
    a.send(@method, 4, -1).should == nil

    a.send(@method, 5, 0).should == nil
    a.send(@method, 5, 2).should == nil
    a.send(@method, 5, -1).should == nil

    a.send(@method, 6, 0).should == nil
    a.send(@method, 6, 2).should == nil
    a.send(@method, 6, -1).should == nil

    a.should == [1, 2, 3, 4]
  end

  it "returns count elements starting at index from the end of array with [-index, count]" do
    ExternalArray[ "a", "b", "c", "d", "e" ].send(@method, -2, 2).should == ["d", "e"]

    a = ExternalArray[1, 2, 3, 4]

    a.send(@method, -1, 0).should == []
    a.send(@method, -1, 1).should == [4]
    a.send(@method, -1, 2).should == [4]
    a.send(@method, -1, -1).should == nil

    a.send(@method, -2, 0).should == []
    a.send(@method, -2, 1).should == [3]
    a.send(@method, -2, 2).should == [3, 4]
    a.send(@method, -2, 4).should == [3, 4]
    a.send(@method, -2, -1).should == nil

    a.send(@method, -4, 0).should == []
    a.send(@method, -4, 1).should == [1]
    a.send(@method, -4, 2).should == [1, 2]
    a.send(@method, -4, 4).should == [1, 2, 3, 4]
    a.send(@method, -4, 6).should == [1, 2, 3, 4]
    a.send(@method, -4, -1).should == nil

    a.send(@method, -5, 0).should == nil
    a.send(@method, -5, 1).should == nil
    a.send(@method, -5, 10).should == nil
    a.send(@method, -5, -1).should == nil

    a.should == [1, 2, 3, 4]
  end

  it "returns the first count elements with [0, count]" do
    ExternalArray[ "a", "b", "c", "d", "e" ].send(@method, 0, 3).should == ["a", "b", "c"]
  end

  it "tries to convert the passed argument to an Integer using #to_int" do
    obj = mock('to_int')
    obj.stub!(:to_int).and_return(2)

    a = ExternalArray[1, 2, 3, 4]
    a.send(@method, obj).should == 3
    a.send(@method, obj, 1).should == [3]
    a.send(@method, obj, obj).should == [3, 4]
    a.send(@method, 0, obj).should == [1, 2]
  end

  it "checks whether index and count respond to #to_int with [index, count]" do
    obj = mock('method_missing to_int')
    obj.should_receive(:respond_to?).with(:to_int).any_number_of_times.and_return(true)
    obj.should_receive(:method_missing).with(:to_int).and_return(2, 2)
    ExternalArray[1, 2, 3, 4].send(@method, obj, obj).should == [3, 4]
  end

  it "returns the elements specified by Range indexes with [m..n]" do
    ExternalArray[ "a", "b", "c", "d", "e" ].send(@method, 1..3).should == ["b", "c", "d"]
    ExternalArray[ "a", "b", "c", "d", "e" ].send(@method, 4..-1).should == ['e']
    ExternalArray[ "a", "b", "c", "d", "e" ].send(@method, 3..3).should == ['d']
    ExternalArray[ "a", "b", "c", "d", "e" ].send(@method, 3..-2).should == ['d']
    ExternalArray['a'].send(@method, 0..-1).should == ['a']

    a = ExternalArray[1, 2, 3, 4]

    a.send(@method, 0..-10).should == []
    a.send(@method, 0..0).should == [1]
    a.send(@method, 0..1).should == [1, 2]
    a.send(@method, 0..2).should == [1, 2, 3]
    a.send(@method, 0..3).should == [1, 2, 3, 4]
    a.send(@method, 0..4).should == [1, 2, 3, 4]
    a.send(@method, 0..10).should == [1, 2, 3, 4]

    a.send(@method, 2..-10).should == []
    a.send(@method, 2..0).should == []
    a.send(@method, 2..2).should == [3]
    a.send(@method, 2..3).should == [3, 4]
    a.send(@method, 2..4).should == [3, 4]

    a.send(@method, 3..0).should == []
    a.send(@method, 3..3).should == [4]
    a.send(@method, 3..4).should == [4]

    a.send(@method, 4..0).should == []
    a.send(@method, 4..4).should == []
    a.send(@method, 4..5).should == []

    a.send(@method, 5..0).should == nil
    a.send(@method, 5..5).should == nil
    a.send(@method, 5..6).should == nil

    a.should == [1, 2, 3, 4]
  end

  it "returns elements specified by Range indexes except the element at index n with [m...n]" do
    ExternalArray[ "a", "b", "c", "d", "e" ].send(@method, 1...3).should == ["b", "c"]

    a = ExternalArray[1, 2, 3, 4]

    a.send(@method, 0...-10).should == []
    a.send(@method, 0...0).should == []
    a.send(@method, 0...1).should == [1]
    a.send(@method, 0...2).should == [1, 2]
    a.send(@method, 0...3).should == [1, 2, 3]
    a.send(@method, 0...4).should == [1, 2, 3, 4]
    a.send(@method, 0...10).should == [1, 2, 3, 4]

    a.send(@method, 2...-10).should == []
    a.send(@method, 2...0).should == []
    a.send(@method, 2...2).should == []
    a.send(@method, 2...3).should == [3]
    a.send(@method, 2...4).should == [3, 4]

    a.send(@method, 3...0).should == []
    a.send(@method, 3...3).should == []
    a.send(@method, 3...4).should == [4]

    a.send(@method, 4...0).should == []
    a.send(@method, 4...4).should == []
    a.send(@method, 4...5).should == []

    a.send(@method, 5...0).should == nil
    a.send(@method, 5...5).should == nil
    a.send(@method, 5...6).should == nil

    a.should == [1, 2, 3, 4]
  end

  it "returns elements that exist if range start is in the array but range end is not with [m..n]" do
    ExternalArray[ "a", "b", "c", "d", "e" ].send(@method, 4..7).should == ["e"]
  end

  it "accepts Range instances having a negative m and both signs for n with [m..n] and [m...n]" do
    a = ExternalArray[1, 2, 3, 4]

    a.send(@method, -1..-1).should == [4]
    a.send(@method, -1...-1).should == []
    a.send(@method, -1..3).should == [4]
    a.send(@method, -1...3).should == []
    a.send(@method, -1..4).should == [4]
    a.send(@method, -1...4).should == [4]
    a.send(@method, -1..10).should == [4]
    a.send(@method, -1...10).should == [4]
    a.send(@method, -1..0).should == []
    a.send(@method, -1..-4).should == []
    a.send(@method, -1...-4).should == []
    a.send(@method, -1..-6).should == []
    a.send(@method, -1...-6).should == []

    a.send(@method, -2..-2).should == [3]
    a.send(@method, -2...-2).should == []
    a.send(@method, -2..-1).should == [3, 4]
    a.send(@method, -2...-1).should == [3]
    a.send(@method, -2..10).should == [3, 4]
    a.send(@method, -2...10).should == [3, 4]

    a.send(@method, -4..-4).should == [1]
    a.send(@method, -4..-2).should == [1, 2, 3]
    a.send(@method, -4...-2).should == [1, 2]
    a.send(@method, -4..-1).should == [1, 2, 3, 4]
    a.send(@method, -4...-1).should == [1, 2, 3]
    a.send(@method, -4..3).should == [1, 2, 3, 4]
    a.send(@method, -4...3).should == [1, 2, 3]
    a.send(@method, -4..4).should == [1, 2, 3, 4]
    a.send(@method, -4...4).should == [1, 2, 3, 4]
    a.send(@method, -4...4).should == [1, 2, 3, 4]
    a.send(@method, -4..0).should == [1]
    a.send(@method, -4...0).should == []
    a.send(@method, -4..1).should == [1, 2]
    a.send(@method, -4...1).should == [1]

    a.send(@method, -5..-5).should == nil
    a.send(@method, -5...-5).should == nil
    a.send(@method, -5..-4).should == nil
    a.send(@method, -5..-1).should == nil
    a.send(@method, -5..10).should == nil

    a.should == [1, 2, 3, 4]
  end

  it "tries to convert Range elements to Integers using #to_int with [m..n] and [m...n]" do
    from = mock('from')
    to = mock('to')
  
    # So we can construct a range out of them...
    def from.<=>(o) 0 end
    def to.<=>(o) 0 end
  
    def from.to_int() 1 end
    def to.to_int() -2 end
  
    a = ExternalArray[1, 2, 3, 4]
  
    a.send(@method, from..to).should == [2, 3]
    a.send(@method, from...to).should == [2]
    a.send(@method, 1..0).should == []
    a.send(@method, 1...0).should == []
  
    lambda { a.slice("a" .. "b") }.should raise_error(TypeError)
    lambda { a.slice("a" ... "b") }.should raise_error(TypeError)
    lambda { a.slice(from .. "b") }.should raise_error(TypeError)
    lambda { a.slice(from ... "b") }.should raise_error(TypeError)
  end

  it "checks whether the Range elements respond to #to_int with [m..n] and [m...n]" do
    from = mock('from')
    to = mock('to')

    def from.<=>(o) 0 end
    def to.<=>(o) 0 end

    from.should_receive(:respond_to?).with(:to_int).any_number_of_times.and_return(true)
    from.should_receive(:method_missing).with(:to_int).and_return(1)
    
    to.should_receive(:respond_to?).with(:to_int).any_number_of_times.and_return(true)
    to.should_receive(:method_missing).with(:to_int).and_return(-2)
    
    ExternalArray[1, 2, 3, 4].send(@method, from..to).should == [2, 3]
  end

  it "returns the same elements as [m..n] and [m...n] with Range subclasses" do
    a = ExternalArray[1, 2, 3, 4]
    range_incl = ArraySpecs::MyRange.new(1, 2)
    range_excl = ArraySpecs::MyRange.new(-3, -1, true)
  
    a[range_incl].should == [2, 3]
    a[range_excl].should == [2, 3]
  end

  it "returns nil for a requested index not in the array with [index]" do
    ExternalArray[ "a", "b", "c", "d", "e" ].send(@method, 5).should == nil
  end

  it "returns [] if the index is valid but length is zero with [index, length]" do
    ExternalArray[ "a", "b", "c", "d", "e" ].send(@method, 0, 0).should == []
    ExternalArray[ "a", "b", "c", "d", "e" ].send(@method, 2, 0).should == []
  end

  it "returns nil if length is zero but index is invalid with [index, length]" do
    ExternalArray[ "a", "b", "c", "d", "e" ].send(@method, 100, 0).should == nil
    ExternalArray[ "a", "b", "c", "d", "e" ].send(@method, -50, 0).should == nil
  end

  # This is by design. It is in the official documentation.
  it "returns [] if index == array.size with [index, length]" do
    ExternalArray[*%w|a b c d e|].send(@method, 5, 2).should == []
  end
  
  it "returns nil if index > array.size with [index, length]" do
    ExternalArray[*%w|a b c d e|].send(@method, 6, 2).should == nil
  end
  
  it "returns nil if length is negative with [index, length]" do
    ExternalArray[*%w|a b c d e|].send(@method, 3, -1).should == nil
    ExternalArray[*%w|a b c d e|].send(@method, 2, -2).should == nil
    ExternalArray[*%w|a b c d e|].send(@method, 1, -100).should == nil
  end

  it "returns nil if no requested index is in the array with [m..n]" do
    ExternalArray[ "a", "b", "c", "d", "e" ].send(@method, 6..10).should == nil
  end

  it "returns nil if range start is not in the array with [m..n]" do
    ExternalArray[ "a", "b", "c", "d", "e" ].send(@method, -10..2).should == nil
    ExternalArray[ "a", "b", "c", "d", "e" ].send(@method, 10..12).should == nil
  end

  it "returns an empty array when m == n with [m...n]" do
    ExternalArray[1, 2, 3, 4, 5].send(@method, 1...1).should == []
  end

  it "returns an empty array with [0...0]" do
    ExternalArray[1, 2, 3, 4, 5].send(@method, 0...0).should == []
  end

  it "returns a subarray where m, n negatives and m < n with [m..n]" do
    ExternalArray[ "a", "b", "c", "d", "e" ].send(@method, -3..-2).should == ["c", "d"]
  end

  it "returns an array containing the first element with [0..0]" do
    ExternalArray[1, 2, 3, 4, 5].send(@method, 0..0).should == [1]
  end

  it "returns the entire array with [0..-1]" do
    ExternalArray[1, 2, 3, 4, 5].send(@method, 0..-1).should == [1, 2, 3, 4, 5]
  end

  it "returns all but the last element with [0...-1]" do
    ExternalArray[1, 2, 3, 4, 5].send(@method, 0...-1).should == [1, 2, 3, 4]
  end

  it "returns [3] for [2..-1] out of [1, 2, 3] <Specifies bug found by brixen, Defiler, mae>" do
    ExternalArray[1,2,3].send(@method, 2..-1).should == [3]
  end

  it "returns an empty array when m > n and m, n are positive with [m..n]" do
    ExternalArray[1, 2, 3, 4, 5].send(@method, 3..2).should == []
  end

  it "returns an empty array when m > n and m, n are negative with [m..n]" do
    ExternalArray[1, 2, 3, 4, 5].send(@method, -2..-3).should == []
  end

  it "does not expand array when the indices are outside of the array bounds" do
    a = ExternalArray[1, 2]
    a.send(@method, 4).should == nil
    a.should == [1, 2]
    a.send(@method, 4, 0).should == nil
    a.should == [1, 2]
    a.send(@method, 6, 1).should == nil
    a.should == [1, 2]
    a.send(@method, 8...8).should == nil
    a.should == [1, 2]
    a.send(@method, 10..10).should == nil
    a.should == [1, 2]
  end

  it "returns a subclass instance when called on a subclass of Array" do
    ary = ArraySpecs::MyArray[1, 2, 3]
    ary.send(@method, 0, 0).class.should == ArraySpecs::MyArray
    ary.send(@method, 0, 2).class.should == ArraySpecs::MyArray
    ary.send(@method, 0..10).class.should == ArraySpecs::MyArray
  end

  not_compliant_on :rubinius do
    it "raises a RangeError when the start index is out of range of Fixnum" do
      array = ExternalArray[1, 2, 3, 4, 5, 6]
      obj = mock('large value')
      obj.should_receive(:to_int).and_return(0x8000_0000_0000_0000_0000)
      lambda { array.send(@method, obj) }.should raise_error(RangeError)

      obj = 8e19
      lambda { array.send(@method, obj) }.should raise_error(RangeError)
    end

    it "raises a RangeError when the length is out of range of Fixnum" do
      array = ExternalArray[1, 2, 3, 4, 5, 6]
      obj = mock('large value')
      obj.should_receive(:to_int).and_return(0x8000_0000_0000_0000_0000)
      lambda { array.send(@method, 1, obj) }.should raise_error(RangeError)

      obj = 8e19
      lambda { array.send(@method, 1, obj) }.should raise_error(RangeError)
    end
  end

  deviates_on :rubinius do
    it "raises a TypeError when the start index is out of range of Fixnum" do
      array = ExternalArray[1, 2, 3, 4, 5, 6]
      obj = mock('large value')
      obj.should_receive(:to_int).and_return(0x8000_0000_0000_0000_0000)
      lambda { array.send(@method, obj) }.should raise_error(TypeError)

      obj = 8e19
      lambda { array.send(@method, obj) }.should raise_error(TypeError)
    end

    it "raises a TypeError when the length is out of range of Fixnum" do
      array = ExternalArray[1, 2, 3, 4, 5, 6]
      obj = mock('large value')
      obj.should_receive(:to_int).and_return(0x8000_0000_0000_0000_0000)
      lambda { array.send(@method, 1, obj) }.should raise_error(TypeError)

      obj = 8e19
      lambda { array.send(@method, 1, obj) }.should raise_error(TypeError)
    end
  end
end

###############################################################################
# Duplicated and modified for ExternalIndex
#
# changes:
# - inputs and comparisons are framed
# - character formats/defaults are set where necessary
# - the nil values in comparisons are replaced
#   with the default nil value [0]
#
###############################################################################
describe :external_index_slice, :shared => true do
  it "returns the element at index with [index]" do
    ExternalIndex[ "a", "b", "c", "d", "e", {:format => 'a', :nil_value => ['z']}].send(@method, 1).should == ["b"]
  
    a = ExternalIndex[1, 2, 3, 4]
  
    a.send(@method, 0).should == [1]
    a.send(@method, 1).should == [2]
    a.send(@method, 2).should == [3]
    a.send(@method, 3).should == [4]
    a.send(@method, 4).should == nil
    a.send(@method, 10).should == nil
  
    a.should == [[1], [2], [3], [4]]
  end
  
  it "returns the element at index from the end of the array with [-index]" do
    ExternalIndex[ "a", "b", "c", "d", "e", {:format => 'a', :nil_value => ['z']}].send(@method, -2).should == ["d"]
  
    a = ExternalIndex[1, 2, 3, 4]
  
    a.send(@method, -1).should == [4]
    a.send(@method, -2).should == [3]
    a.send(@method, -3).should == [2]
    a.send(@method, -4).should == [1]
    a.send(@method, -5).should == nil
    a.send(@method, -10).should == nil
  
    a.should == [[1], [2], [3], [4]]
  end
  
  it "return count elements starting from index with [index, count]" do
    ExternalIndex[ "a", "b", "c", "d", "e", {:format => 'a', :nil_value => ['z']}].send(@method, 2, 3).should == [["c"], ["d"], ["e"]]
  
    a = ExternalIndex[1, 2, 3, 4]
  
    a.send(@method, 0, 0).should == []
    a.send(@method, 0, 1).should == [[1]]
    a.send(@method, 0, 2).should == [[1], [2]]
    a.send(@method, 0, 4).should == [[1], [2], [3], [4]]
    a.send(@method, 0, 6).should == [[1], [2], [3], [4]]
    a.send(@method, 0, -1).should == nil
    a.send(@method, 0, -2).should == nil
    a.send(@method, 0, -4).should == nil
  
    a.send(@method, 2, 0).should == []
    a.send(@method, 2, 1).should == [[3]]
    a.send(@method, 2, 2).should == [[3], [4]]
    a.send(@method, 2, 4).should == [[3], [4]]
    a.send(@method, 2, -1).should == nil
  
    a.send(@method, 4, 0).should == []
    a.send(@method, 4, 2).should == []
    a.send(@method, 4, -1).should == nil
      
    a.send(@method, 5, 0).should == nil
    a.send(@method, 5, 2).should == nil
    a.send(@method, 5, -1).should == nil
      
    a.send(@method, 6, 0).should == nil
    a.send(@method, 6, 2).should == nil
    a.send(@method, 6, -1).should == nil
      
    a.should == [[1], [2], [3], [4]]
  end
  
  it "returns count elements starting at index from the end of array with [-index, count]" do
    ExternalIndex[ "a", "b", "c", "d", "e", {:format => 'a', :nil_value => ['z']}].send(@method, -2, 2).should == [["d"], ["e"]]
  
    a = ExternalIndex[1, 2, 3, 4]
  
    a.send(@method, -1, 0).should == []
    a.send(@method, -1, 1).should == [[4]]
    a.send(@method, -1, 2).should == [[4]]
    a.send(@method, -1, -1).should == nil
  
    a.send(@method, -2, 0).should == []
    a.send(@method, -2, 1).should == [[3]]
    a.send(@method, -2, 2).should == [[3], [4]]
    a.send(@method, -2, 4).should == [[3], [4]]
    a.send(@method, -2, -1).should == nil
  
    a.send(@method, -4, 0).should == []
    a.send(@method, -4, 1).should == [[1]]
    a.send(@method, -4, 2).should == [[1], [2]]
    a.send(@method, -4, 4).should == [[1], [2], [3], [4]]
    a.send(@method, -4, 6).should == [[1], [2], [3], [4]]
    a.send(@method, -4, -1).should == nil
  
    a.send(@method, -5, 0).should == nil
    a.send(@method, -5, 1).should == nil
    a.send(@method, -5, 10).should == nil
    a.send(@method, -5, -1).should == nil
  
    a.should == [[1], [2], [3], [4]]
  end
  
  it "returns the first count elements with [0, count]" do
    ExternalIndex[ "a", "b", "c", "d", "e", {:format => 'a', :nil_value => ['z']}].send(@method, 0, 3).should == [["a"], ["b"], ["c"]]
  end
  
  it "tries to convert the passed argument to an Integer using #to_int" do
    obj = mock('to_int')
    obj.stub!(:to_int).and_return(2)
  
    a = ExternalIndex[1, 2, 3, 4]
    a.send(@method, obj).should == [3]
    a.send(@method, obj, 1).should == [[3]]
    a.send(@method, obj, obj).should == [[3], [4]]
    a.send(@method, 0, obj).should == [[1], [2]]
  end
  
  it "checks whether index and count respond to #to_int with [index, count]" do
    obj = mock('method_missing to_int')
    obj.should_receive(:respond_to?).with(:to_int).any_number_of_times.and_return(true)
    obj.should_receive(:method_missing).with(:to_int).and_return(2, 2)
    ExternalIndex[1, 2, 3, 4].send(@method, obj, obj).should == [[3], [4]]
  end
  
  it "returns the elements specified by Range indexes with [m..n]" do
    config = {:format => 'a', :nil_value => ['z']}
    ExternalIndex[ "a", "b", "c", "d", "e", config].send(@method, 1..3).should == [["b"], ["c"], ["d"]]
    ExternalIndex[ "a", "b", "c", "d", "e", config].send(@method, 4..-1).should == [['e']]
    ExternalIndex[ "a", "b", "c", "d", "e", config].send(@method, 3..3).should == [['d']]
    ExternalIndex[ "a", "b", "c", "d", "e", config].send(@method, 3..-2).should == [['d']]
    ExternalIndex['a', config].send(@method, 0..-1).should == [['a']]
  
    a = ExternalIndex[1, 2, 3, 4]
  
    a.send(@method, 0..-10).should == []
    a.send(@method, 0..0).should == [[1]]
    a.send(@method, 0..1).should == [[1], [2]]
    a.send(@method, 0..2).should == [[1], [2], [3]]
    a.send(@method, 0..3).should == [[1], [2], [3], [4]]
    a.send(@method, 0..4).should == [[1], [2], [3], [4]]
    a.send(@method, 0..10).should == [[1], [2], [3], [4]]
  
    a.send(@method, 2..-10).should == []
    a.send(@method, 2..0).should == []
    a.send(@method, 2..2).should == [[3]]
    a.send(@method, 2..3).should == [[3], [4]]
    a.send(@method, 2..4).should == [[3], [4]]
  
    a.send(@method, 3..0).should == []
    a.send(@method, 3..3).should == [[4]]
    a.send(@method, 3..4).should == [[4]]
  
    a.send(@method, 4..0).should == []
    a.send(@method, 4..4).should == []
    a.send(@method, 4..5).should == []
  
    a.send(@method, 5..0).should == nil
    a.send(@method, 5..5).should == nil
    a.send(@method, 5..6).should == nil
  
    a.should == [[1], [2], [3], [4]]
  end
  
  it "returns elements specified by Range indexes except the element at index n with [m...n]" do
    ExternalIndex[ "a", "b", "c", "d", "e", {:format => 'a', :nil_value => ['z']}].send(@method, 1...3).should == [["b"], ["c"]]
  
    a = ExternalIndex[1, 2, 3, 4]
  
    a.send(@method, 0...-10).should == []
    a.send(@method, 0...0).should == []
    a.send(@method, 0...1).should == [[1]]
    a.send(@method, 0...2).should == [[1], [2]]
    a.send(@method, 0...3).should == [[1], [2], [3]]
    a.send(@method, 0...4).should == [[1], [2], [3], [4]]
    a.send(@method, 0...10).should == [[1], [2], [3], [4]]
  
    a.send(@method, 2...-10).should == []
    a.send(@method, 2...0).should == []
    a.send(@method, 2...2).should == []
    a.send(@method, 2...3).should == [[3]]
    a.send(@method, 2...4).should == [[3], [4]]
  
    a.send(@method, 3...0).should == []
    a.send(@method, 3...3).should == []
    a.send(@method, 3...4).should == [[4]]
  
    a.send(@method, 4...0).should == []
    a.send(@method, 4...4).should == []
    a.send(@method, 4...5).should == []
  
    a.send(@method, 5...0).should == nil
    a.send(@method, 5...5).should == nil
    a.send(@method, 5...6).should == nil
  
    a.should == [[1], [2], [3], [4]]
  end
  
  it "returns elements that exist if range start is in the array but range end is not with [m..n]" do
    ExternalIndex[ "a", "b", "c", "d", "e", {:format => 'a', :nil_value => ['z']}].send(@method, 4..7).should == [["e"]]
  end
  
  it "accepts Range instances having a negative m and both signs for n with [m..n] and [m...n]" do
    a = ExternalIndex[1, 2, 3, 4]
  
    a.send(@method, -1..-1).should == [[4]]
    a.send(@method, -1...-1).should == []
    a.send(@method, -1..3).should == [[4]]
    a.send(@method, -1...3).should == []
    a.send(@method, -1..4).should == [[4]]
    a.send(@method, -1...4).should == [[4]]
    a.send(@method, -1..10).should == [[4]]
    a.send(@method, -1...10).should == [[4]]
    a.send(@method, -1..0).should == []
    a.send(@method, -1..-4).should == []
    a.send(@method, -1...-4).should == []
    a.send(@method, -1..-6).should == []
    a.send(@method, -1...-6).should == []
  
    a.send(@method, -2..-2).should == [[3]]
    a.send(@method, -2...-2).should == []
    a.send(@method, -2..-1).should == [[3], [4]]
    a.send(@method, -2...-1).should == [[3]]
    a.send(@method, -2..10).should == [[3], [4]]
    a.send(@method, -2...10).should == [[3], [4]]
  
    a.send(@method, -4..-4).should == [[1]]
    a.send(@method, -4..-2).should == [[1], [2], [3]]
    a.send(@method, -4...-2).should == [[1], [2]]
    a.send(@method, -4..-1).should == [[1], [2], [3], [4]]
    a.send(@method, -4...-1).should == [[1], [2], [3]]
    a.send(@method, -4..3).should == [[1], [2], [3], [4]]
    a.send(@method, -4...3).should == [[1], [2], [3]]
    a.send(@method, -4..4).should == [[1], [2], [3], [4]]
    a.send(@method, -4...4).should == [[1], [2], [3], [4]]
    a.send(@method, -4...4).should == [[1], [2], [3], [4]]
    a.send(@method, -4..0).should == [[1]]
    a.send(@method, -4...0).should == []
    a.send(@method, -4..1).should == [[1], [2]]
    a.send(@method, -4...1).should == [[1]]
  
    a.send(@method, -5..-5).should == nil
    a.send(@method, -5...-5).should == nil
    a.send(@method, -5..-4).should == nil
    a.send(@method, -5..-1).should == nil
    a.send(@method, -5..10).should == nil
  
    a.should == [[1], [2], [3], [4]]
  end
  
  it "tries to convert Range elements to Integers using #to_int with [m..n] and [m...n]" do
    from = mock('from')
    to = mock('to')
  
    # So we can construct a range out of them...
    def from.<=>(o) 0 end
    def to.<=>(o) 0 end
  
    def from.to_int() 1 end
    def to.to_int() -2 end
  
    a = ExternalIndex[1, 2, 3, 4]
  
    a.send(@method, from..to).should == [[2], [3]]
    a.send(@method, from...to).should == [[2]]
    a.send(@method, 1..0).should == []
    a.send(@method, 1...0).should == []
  
    lambda { a.slice("a" .. "b") }.should raise_error(TypeError)
    lambda { a.slice("a" ... "b") }.should raise_error(TypeError)
    lambda { a.slice(from .. "b") }.should raise_error(TypeError)
    lambda { a.slice(from ... "b") }.should raise_error(TypeError)
  end
  
  it "checks whether the Range elements respond to #to_int with [m..n] and [m...n]" do
    from = mock('from')
    to = mock('to')
  
    def from.<=>(o) 0 end
    def to.<=>(o) 0 end
  
    from.should_receive(:respond_to?).with(:to_int).any_number_of_times.and_return(true)
    from.should_receive(:method_missing).with(:to_int).and_return(1)
    
    to.should_receive(:respond_to?).with(:to_int).any_number_of_times.and_return(true)
    to.should_receive(:method_missing).with(:to_int).and_return(-2)
    
    ExternalIndex[1, 2, 3, 4].send(@method, from..to).should == [[2], [3]]
  end
  
  it "returns the same elements as [m..n] and [m...n] with Range subclasses" do
    a = ExternalIndex[1, 2, 3, 4]
    range_incl = ArraySpecs::MyRange.new(1, 2)
    range_excl = ArraySpecs::MyRange.new(-3, -1, true)
  
    a[range_incl].should == [[2], [3]]
    a[range_excl].should == [[2], [3]]
  end
  
  it "returns nil for a requested index not in the array with [index]" do
    ExternalIndex[ "a", "b", "c", "d", "e", {:format => 'a', :nil_value => ['z']}].send(@method, 5).should == nil
  end
  
  it "returns [] if the index is valid but length is zero with [index, length]" do
    ExternalIndex[ "a", "b", "c", "d", "e", {:format => 'a', :nil_value => ['z']}].send(@method, 0, 0).should == []
    ExternalIndex[ "a", "b", "c", "d", "e", {:format => 'a', :nil_value => ['z']}].send(@method, 2, 0).should == []
  end
  
  it "returns nil if length is zero but index is invalid with [index, length]" do
    ExternalIndex[ "a", "b", "c", "d", "e", {:format => 'a', :nil_value => ['z']}].send(@method, 100, 0).should == nil
    ExternalIndex[ "a", "b", "c", "d", "e", {:format => 'a', :nil_value => ['z']}].send(@method, -50, 0).should == nil
  end
  
  # This is by design. It is in the official documentation.
  # ... required modification as %w cannot (and should not) be
  # made to return an ExternalIndex
  it "returns [] if index == array.size with [index, length]" do
    input = %w|a b c d e|
    input << {:format => 'a', :nil_value => ['z']}
    ExternalIndex[*input].send(@method, 5, 2).should == []
  end
  
  it "returns nil if index > array.size with [index, length]" do
    input = %w|a b c d e|
    input << {:format => 'a', :nil_value => ['z']}
    ExternalIndex[*input].send(@method, 6, 2).should == nil
  end
  
  it "returns nil if length is negative with [index, length]" do
    input = %w|a b c d e|
    input << {:format => 'a', :nil_value => ['z']}
    ExternalIndex[*input].send(@method, 3, -1).should == nil
    ExternalIndex[*input].send(@method, 2, -2).should == nil
    ExternalIndex[*input].send(@method, 1, -100).should == nil
  end
  
  it "returns nil if no requested index is in the array with [m..n]" do
    ExternalIndex[ "a", "b", "c", "d", "e", {:format => 'a', :nil_value => ['z']}].send(@method, 6..10).should == nil
  end
  
  it "returns nil if range start is not in the array with [m..n]" do
    ExternalIndex[ "a", "b", "c", "d", "e", {:format => 'a', :nil_value => ['z']}].send(@method, -10..2).should == nil
    ExternalIndex[ "a", "b", "c", "d", "e", {:format => 'a', :nil_value => ['z']}].send(@method, 10..12).should == nil
  end
  
  it "returns an empty array when m == n with [m...n]" do
    ExternalIndex[1, 2, 3, 4, 5].send(@method, 1...1).should == []
  end
  
  it "returns an empty array with [0...0]" do
    ExternalIndex[1, 2, 3, 4, 5].send(@method, 0...0).should == []
  end
  
  it "returns a subarray where m, n negatives and m < n with [m..n]" do
    ExternalIndex[ "a", "b", "c", "d", "e", {:format => 'a', :nil_value => ['z']}].send(@method, -3..-2).should == [["c"], ["d"]]
  end
  
  it "returns an array containing the first element with [0..0]" do
    ExternalIndex[1, 2, 3, 4, 5].send(@method, 0..0).should == [[1]]
  end
  
  it "returns the entire array with [0..-1]" do
    ExternalIndex[1, 2, 3, 4, 5].send(@method, 0..-1).should == [[1], [2], [3], [4], [5]]
  end
  
  it "returns all but the last element with [0...-1]" do
    ExternalIndex[1, 2, 3, 4, 5].send(@method, 0...-1).should == [[1], [2], [3], [4]]
  end
  
  it "returns [3] for [2..-1] out of [1, 2, 3] <Specifies bug found by brixen, Defiler, mae>" do
    ExternalIndex[1,2,3].send(@method, 2..-1).should == [[3]]
  end
  
  it "returns an empty array when m > n and m, n are positive with [m..n]" do
    ExternalIndex[1, 2, 3, 4, 5].send(@method, 3..2).should == []
  end
  
  it "returns an empty array when m > n and m, n are negative with [m..n]" do
    ExternalIndex[1, 2, 3, 4, 5].send(@method, -2..-3).should == []
  end
  
  it "does not expand array when the indices are outside of the array bounds" do
    a = ExternalIndex[1, 2]
    a.send(@method, 4).should == nil
    a.should == [[1], [2]]
    a.send(@method, 4, 0).should == nil
    a.should == [[1], [2]]
    a.send(@method, 6, 1).should == nil
    a.should == [[1], [2]]
    a.send(@method, 8...8).should == nil
    a.should == [[1], [2]]
    a.send(@method, 10..10).should == nil
    a.should == [[1], [2]]
  end
  
  ######################################################
  # Non-compliant, [] always returns an Array
  ######################################################
  # class MyExternalIndex < ExternalIndex; end
  # 
  # it "returns a subclass instance when called on a subclass of Array" do
  #   ary = MyExternalIndex[1, 2, 3]
  #   ary.send(@method, 0, 0).class.should == MyExternalIndex
  #   ary.send(@method, 0, 2).class.should == MyExternalIndex
  #   ary.send(@method, 0..10).class.should == MyExternalIndex
  # end
  
  not_compliant_on :rubinius do
    ######################################################
    # Non-compliant... raises a TypeError
    ######################################################
    # it "raises a RangeError when the start index is out of range of Fixnum" do
    #   array = ExternalIndex[1, 2, 3, 4, 5, 6]
    #   obj = mock('large value')
    #   obj.should_receive(:to_int).and_return(0x8000_0000_0000_0000_0000)
    #   lambda { array.send(@method, obj) }.should raise_error(RangeError)
    #   
    #   obj = 8e19
    #   lambda { array.send(@method, obj) }.should raise_error(RangeError)
    # end
  
    it "raises a RangeError when the length is out of range of Fixnum" do
      array = ExternalIndex[1, 2, 3, 4, 5, 6]
      obj = mock('large value')
      obj.should_receive(:to_int).and_return(0x8000_0000_0000_0000_0000)
      lambda { array.send(@method, 1, obj) }.should raise_error(RangeError)
  
      obj = 8e19
      lambda { array.send(@method, 1, obj) }.should raise_error(RangeError)
    end
  end
  
  # deviates_on :rubinius do
  #   it "raises a TypeError when the start index is out of range of Fixnum" do
  #     array = [1, 2, 3, 4, 5, 6]
  #     obj = mock('large value')
  #     obj.should_receive(:to_int).and_return(0x8000_0000_0000_0000_0000)
  #     lambda { array.send(@method, obj) }.should raise_error(TypeError)
  # 
  #     obj = 8e19
  #     lambda { array.send(@method, obj) }.should raise_error(TypeError)
  #   end
  # 
  #   it "raises a TypeError when the length is out of range of Fixnum" do
  #     array = [1, 2, 3, 4, 5, 6]
  #     obj = mock('large value')
  #     obj.should_receive(:to_int).and_return(0x8000_0000_0000_0000_0000)
  #     lambda { array.send(@method, 1, obj) }.should raise_error(TypeError)
  # 
  #     obj = 8e19
  #     lambda { array.send(@method, 1, obj) }.should raise_error(TypeError)
  #   end
  # end
end
