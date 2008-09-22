# 6bc98e6584d9c7f180f0d72aa050de3b
# Generated: 2008-09-22 16:25:09
################################################################################
# require File.dirname(__FILE__) + '/../../spec_helper'
# require File.dirname(__FILE__) + '/fixtures/classes'
# 
# describe "Array.[]" do
#   it "returns a new array populated with the given elements" do
#     Array.[](5, true, nil, 'a', "Ruby").should == [5, true, nil, "a", "Ruby"]
# 
#     a = ArraySpecs::MyArray.[](5, true, nil, 'a', "Ruby")
#     a.class.should == ArraySpecs::MyArray
#     a.inspect.should == [5, true, nil, "a", "Ruby"].inspect
#   end
# end
# 
# describe "Array[]" do
#   it "is a synonym for .[]" do
#     Array[5, true, nil, 'a', "Ruby"].should == Array.[](5, true, nil, "a", "Ruby")
# 
#     a = ArraySpecs::MyArray[5, true, nil, 'a', "Ruby"]
#     a.class.should == ArraySpecs::MyArray
#     a.inspect.should == [5, true, nil, "a", "Ruby"].inspect
#   end
# end

puts 'not implemented: constructor_spec.rb'
unless true
require File.dirname(__FILE__) + '/../../spec_helper'
require File.dirname(__FILE__) + '/fixtures/classes'

describe "Array.[]" do
  it "returns a new array populated with the given elements" do
    Array.[](5, true, nil, 'a', "Ruby").should == [5, true, nil, "a", "Ruby"]

    a = ArraySpecs::MyArray.[](5, true, nil, 'a', "Ruby")
    a.class.should == ArraySpecs::MyArray
    a.inspect.should == [5, true, nil, "a", "Ruby"].inspect
  end
end

describe "Array[]" do
  it "is a synonym for .[]" do
    Array[5, true, nil, 'a', "Ruby"].should == Array.[](5, true, nil, "a", "Ruby")

    a = ArraySpecs::MyArray[5, true, nil, 'a', "Ruby"]
    a.class.should == ArraySpecs::MyArray
    a.inspect.should == [5, true, nil, "a", "Ruby"].inspect
  end
end
end # remove with unless true
