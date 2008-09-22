# 28a8cfadda13f496447dae5b5a346be1
# Generated: 2008-09-22 16:25:10
################################################################################
# require File.dirname(__FILE__) + '/../../spec_helper'
# require File.dirname(__FILE__) + '/fixtures/classes'
# 
# describe "Array#shift" do
#   it "removes and returns the first element" do
#     a = [5, 1, 1, 5, 4]
#     a.shift.should == 5
#     a.should == [1, 1, 5, 4]
#     a.shift.should == 1
#     a.should == [1, 5, 4]
#     a.shift.should == 1
#     a.should == [5, 4]
#     a.shift.should == 5
#     a.should == [4]
#     a.shift.should == 4
#     a.should == []
#   end
#   
#   it "returns nil when the array is empty" do
#     [].shift.should == nil
#   end
# 
#   it "properly handles recursive arrays" do
#     empty = ArraySpecs.empty_recursive_array
#     empty.shift.should == []
#     empty.should == []
# 
#     array = ArraySpecs.recursive_array
#     array.shift.should == 1
#     array[0..2].should == ['two', 3.0, array]
#   end
# 
#   compliant_on :ruby, :jruby do
#     it "raises a TypeError on a frozen array" do
#       lambda { ArraySpecs.frozen_array.shift }.should raise_error(TypeError)
#     end
#   end
# end

puts 'not implemented: shift_spec.rb'
unless true
require File.dirname(__FILE__) + '/../../spec_helper'
require File.dirname(__FILE__) + '/fixtures/classes'

describe "Array#shift" do
  it "removes and returns the first element" do
    a = [5, 1, 1, 5, 4]
    a.shift.should == 5
    a.should == [1, 1, 5, 4]
    a.shift.should == 1
    a.should == [1, 5, 4]
    a.shift.should == 1
    a.should == [5, 4]
    a.shift.should == 5
    a.should == [4]
    a.shift.should == 4
    a.should == []
  end
  
  it "returns nil when the array is empty" do
    [].shift.should == nil
  end

  it "properly handles recursive arrays" do
    empty = ArraySpecs.empty_recursive_array
    empty.shift.should == []
    empty.should == []

    array = ArraySpecs.recursive_array
    array.shift.should == 1
    array[0..2].should == ['two', 3.0, array]
  end

  compliant_on :ruby, :jruby do
    it "raises a TypeError on a frozen array" do
      lambda { ArraySpecs.frozen_array.shift }.should raise_error(TypeError)
    end
  end
end
end # remove with unless true
