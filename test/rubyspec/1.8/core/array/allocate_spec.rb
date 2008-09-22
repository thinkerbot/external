# be1c96ff2775afeef7874d0922251d27
# Generated: 2008-09-22 16:25:09
################################################################################
# require File.dirname(__FILE__) + '/../../spec_helper'
# 
# describe "Array.allocate" do
#   it "returns an instance of Array" do
#     ary = Array.allocate
#     ary.should be_kind_of(Array)
#   end
#   
#   it "returns a fully-formed instance of Array" do
#     ary = Array.allocate
#     ary.size.should == 0
#     ary << 1
#     ary.should == [1]
#   end
# end

puts 'not implemented: allocate_spec.rb'
unless true
require File.dirname(__FILE__) + '/../../spec_helper'

describe "Array.allocate" do
  it "returns an instance of Array" do
    ary = Array.allocate
    ary.should be_kind_of(Array)
  end
  
  it "returns a fully-formed instance of Array" do
    ary = Array.allocate
    ary.size.should == 0
    ary << 1
    ary.should == [1]
  end
end
end # remove with unless true
