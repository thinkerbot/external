# bae65d030ad669b67e9d0810b71130b9
# Generated: 2008-09-22 16:25:09
################################################################################
# require File.dirname(__FILE__) + '/../../spec_helper'
# require File.dirname(__FILE__) + '/fixtures/classes'
# 
# describe "Array#eql?" do
#   it "returns true if other is the same array" do
#     a, b = [1], [2]
# 
#     a.should_not eql(b)
#     a.should eql(a)
#   end
#   
#   it "returns true if other has the same length and elements" do
#     a = [1, 2, 3, 4]
#     b = [1, 2, 3, 4]
#     c = [1, 2]
#     d = ['a', 'b', 'c', 'd']
# 
#     a.should eql(b)
#     a.should_not eql(c)
#     a.should_not eql(d)
#     [].should eql([])
#   end
# 
#   it "properly handles recursive arrays" do
#     empty = ArraySpecs.empty_recursive_array
#     empty2 = []; empty2 << empty2
#     empty.should eql(empty.dup)
#     empty.should_not eql(empty2)
# 
#     array = ArraySpecs.recursive_array
#     array.should eql(array)
#     array.should eql(array.dup)
# 
#     array.should_not eql(empty)
#     array.should_not eql([1, 2])
#   end
# 
#   it "ignores array class differences" do
#     ArraySpecs::MyArray[1, 2, 3].should eql([1, 2, 3])
#     ArraySpecs::MyArray[1, 2, 3].should eql(ArraySpecs::MyArray[1, 2, 3])
#     [1, 2, 3].should eql(ArraySpecs::MyArray[1, 2, 3])
#   end
# end

puts 'not implemented: eql_spec.rb'
unless true
require File.dirname(__FILE__) + '/../../spec_helper'
require File.dirname(__FILE__) + '/fixtures/classes'

describe "Array#eql?" do
  it "returns true if other is the same array" do
    a, b = [1], [2]

    a.should_not eql(b)
    a.should eql(a)
  end
  
  it "returns true if other has the same length and elements" do
    a = [1, 2, 3, 4]
    b = [1, 2, 3, 4]
    c = [1, 2]
    d = ['a', 'b', 'c', 'd']

    a.should eql(b)
    a.should_not eql(c)
    a.should_not eql(d)
    [].should eql([])
  end

  it "properly handles recursive arrays" do
    empty = ArraySpecs.empty_recursive_array
    empty2 = []; empty2 << empty2
    empty.should eql(empty.dup)
    empty.should_not eql(empty2)

    array = ArraySpecs.recursive_array
    array.should eql(array)
    array.should eql(array.dup)

    array.should_not eql(empty)
    array.should_not eql([1, 2])
  end

  it "ignores array class differences" do
    ArraySpecs::MyArray[1, 2, 3].should eql([1, 2, 3])
    ArraySpecs::MyArray[1, 2, 3].should eql(ArraySpecs::MyArray[1, 2, 3])
    [1, 2, 3].should eql(ArraySpecs::MyArray[1, 2, 3])
  end
end
end # remove with unless true
