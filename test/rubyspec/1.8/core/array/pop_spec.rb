# 32bbddb79b55138c8aea5f54f43cf8c3
# Generated: 2008-09-22 16:25:10
################################################################################
# require File.dirname(__FILE__) + '/../../spec_helper'
# require File.dirname(__FILE__) + '/fixtures/classes'
# 
# describe "Array#pop" do
#   it "removes and returns the last element of the array" do
#     a = ["a", 1, nil, true]
#     
#     a.pop.should == true
#     a.should == ["a", 1, nil]
# 
#     a.pop.should == nil
#     a.should == ["a", 1]
# 
#     a.pop.should == 1
#     a.should == ["a"]
# 
#     a.pop.should == "a"
#     a.should == []
#   end
#   
#   it "returns nil if there are no more elements" do
#     [].pop.should == nil
#   end
# 
#   it "properly handles recursive arrays" do
#     empty = ArraySpecs.empty_recursive_array
#     empty.pop.should == []
# 
#     array = ArraySpecs.recursive_array
#     array.pop.should == [1, 'two', 3.0, array, array, array, array]
#   end
# 
#   compliant_on :ruby, :jruby do
#     it "raises a TypeError on a frozen array" do
#       lambda { ArraySpecs.frozen_array.pop }.should raise_error(TypeError)
#     end
#   end
# end

puts 'not implemented: pop_spec.rb'
unless true
require File.dirname(__FILE__) + '/../../spec_helper'
require File.dirname(__FILE__) + '/fixtures/classes'

describe "Array#pop" do
  it "removes and returns the last element of the array" do
    a = ["a", 1, nil, true]
    
    a.pop.should == true
    a.should == ["a", 1, nil]

    a.pop.should == nil
    a.should == ["a", 1]

    a.pop.should == 1
    a.should == ["a"]

    a.pop.should == "a"
    a.should == []
  end
  
  it "returns nil if there are no more elements" do
    [].pop.should == nil
  end

  it "properly handles recursive arrays" do
    empty = ArraySpecs.empty_recursive_array
    empty.pop.should == []

    array = ArraySpecs.recursive_array
    array.pop.should == [1, 'two', 3.0, array, array, array, array]
  end

  compliant_on :ruby, :jruby do
    it "raises a TypeError on a frozen array" do
      lambda { ArraySpecs.frozen_array.pop }.should raise_error(TypeError)
    end
  end
end
end # remove with unless true
