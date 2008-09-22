# bed73108e2660e86abbd55024e17ffbf
# Generated: 2008-09-22 16:25:10
################################################################################
# require File.dirname(__FILE__) + '/../../spec_helper'
# require File.dirname(__FILE__) + '/fixtures/classes'
# 
# describe "Array#to_ary" do
#   it "returns self" do
#     a = [1, 2, 3]
#     a.should equal(a.to_ary)
#     a = ArraySpecs::MyArray[1, 2, 3]
#     a.should equal(a.to_ary)
#   end
# 
#   it "properly handles recursive arrays" do
#     empty = ArraySpecs.empty_recursive_array
#     empty.to_ary.should == empty
# 
#     array = ArraySpecs.recursive_array
#     array.to_ary.should == array
#   end
# 
# end

puts 'not implemented: to_ary_spec.rb'
unless true
require File.dirname(__FILE__) + '/../../spec_helper'
require File.dirname(__FILE__) + '/fixtures/classes'

describe "Array#to_ary" do
  it "returns self" do
    a = [1, 2, 3]
    a.should equal(a.to_ary)
    a = ArraySpecs::MyArray[1, 2, 3]
    a.should equal(a.to_ary)
  end

  it "properly handles recursive arrays" do
    empty = ArraySpecs.empty_recursive_array
    empty.to_ary.should == empty

    array = ArraySpecs.recursive_array
    array.to_ary.should == array
  end

end
end # remove with unless true
