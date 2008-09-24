# 5b9bac9f193634b443e9960ed821def5
# Generated: 2008-09-22 16:25:09
################################################################################
# require File.dirname(__FILE__) + '/../../spec_helper'
# require File.dirname(__FILE__) + '/fixtures/classes'
# require File.dirname(__FILE__) + '/shared/slice'
# 
# describe "Array#[]" do
#   it_behaves_like(:array_slice, :[])
# end
# 
# describe "Array.[]" do
#   it "[] should return a new array populated with the given elements" do
#     array = Array[1, 'a', nil]
#     array[0].should == 1
#     array[1].should == 'a'
#     array[2].should == nil
#   end
# 
#   it "when applied to a literal nested array, unpacks its elements into the containing array" do
#     Array[1, 2, *[3, 4, 5]].should == [1, 2, 3, 4, 5]
#   end
# 
#   it "when applied to a nested referenced array, unpacks its elements into the containing array" do
#     splatted_array = Array[3, 4, 5]
#     Array[1, 2, *splatted_array].should == [1, 2, 3, 4, 5]
#   end
#   
#   it "returns an instance of the subtype when called on an Array subclass" do
#     ArraySub = Class.new Array
#     ArraySub[1,2].class.should == ArraySub
#   end
# end

require File.dirname(__FILE__) + '/../../spec_helper'
require File.dirname(__FILE__) + '/fixtures/classes'
require File.dirname(__FILE__) + '/shared/slice'

describe "ExternalArray#[]" do
  it_behaves_like(:array_slice, :[])
end

describe "ExternalArray.[]" do
  it "[] should return a new array populated with the given elements" do
    array = ExternalArray[1, 'a', nil]
    array[0].should == 1
    array[1].should == 'a'
    array[2].should == nil
  end

  it "when applied to a literal nested array, unpacks its elements into the containing array" do
    ExternalArray[1, 2, *[3, 4, 5]].should == [1, 2, 3, 4, 5]
  end

  it "when applied to a nested referenced array, unpacks its elements into the containing array" do
    splatted_array = ExternalArray[3, 4, 5]
    ExternalArray[1, 2, *splatted_array].should == [1, 2, 3, 4, 5]
  end
  
  it "returns an instance of the subtype when called on an Array subclass" do
    ArraySub = Class.new ExternalArray
    ArraySub[1,2].class.should == ArraySub
  end
end
