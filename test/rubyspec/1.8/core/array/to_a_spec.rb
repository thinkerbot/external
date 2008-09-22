# 1c239d2fc183103a9dab0e5c1a3e8d18
# Generated: 2008-09-22 16:25:10
################################################################################
# require File.dirname(__FILE__) + '/../../spec_helper'
# require File.dirname(__FILE__) + '/fixtures/classes'
# 
# describe "Array#to_a" do
#   it "returns self" do
#     a = [1, 2, 3]
#     a.to_a.should == [1, 2, 3]
#     a.should equal(a.to_a) 
#   end
#   
#   it "does not return subclass instance on Array subclasses" do
#     e = ArraySpecs::MyArray.new
#     e << 1
#     e.to_a.class.should == Array
#     e.to_a.should == [1]
#   end
# 
#   it "properly handles recursive arrays" do
#     empty = ArraySpecs.empty_recursive_array
#     empty.to_a.should == empty
# 
#     array = ArraySpecs.recursive_array
#     array.to_a.should == array
#   end
# end

puts 'not implemented: to_a_spec.rb'
unless true
require File.dirname(__FILE__) + '/../../spec_helper'
require File.dirname(__FILE__) + '/fixtures/classes'

describe "Array#to_a" do
  it "returns self" do
    a = [1, 2, 3]
    a.to_a.should == [1, 2, 3]
    a.should equal(a.to_a) 
  end
  
  it "does not return subclass instance on Array subclasses" do
    e = ArraySpecs::MyArray.new
    e << 1
    e.to_a.class.should == Array
    e.to_a.should == [1]
  end

  it "properly handles recursive arrays" do
    empty = ArraySpecs.empty_recursive_array
    empty.to_a.should == empty

    array = ArraySpecs.recursive_array
    array.to_a.should == array
  end
end
end # remove with unless true
