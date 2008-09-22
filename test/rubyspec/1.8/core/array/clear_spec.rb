# 82d099bddd590d3e8ec22f33083901f1
# Generated: 2008-09-22 16:25:09
################################################################################
# require File.dirname(__FILE__) + '/../../spec_helper'
# require File.dirname(__FILE__) + '/fixtures/classes'
# 
# describe "Array#clear" do
#   it "removes all elements" do
#     a = [1, 2, 3, 4]
#     a.clear.should equal(a)
#     a.should == []
#   end  
# 
#   it "returns self" do
#     a = [1]
#     oid = a.object_id
#     a.clear.object_id.should == oid
#   end
# 
#   it "leaves the Array empty" do
#     a = [1]
#     a.clear
#     a.empty?.should == true
#     a.size.should == 0
#   end
# 
#   compliant_on :ruby, :jruby do
#     it "raises a TypeError on a frozen array" do
#       a = [1]
#       a.freeze
#       lambda { a.clear }.should raise_error(TypeError)
#     end
#   end
# end

puts 'not implemented: clear_spec.rb'
unless true
require File.dirname(__FILE__) + '/../../spec_helper'
require File.dirname(__FILE__) + '/fixtures/classes'

describe "Array#clear" do
  it "removes all elements" do
    a = [1, 2, 3, 4]
    a.clear.should equal(a)
    a.should == []
  end  

  it "returns self" do
    a = [1]
    oid = a.object_id
    a.clear.object_id.should == oid
  end

  it "leaves the Array empty" do
    a = [1]
    a.clear
    a.empty?.should == true
    a.size.should == 0
  end

  compliant_on :ruby, :jruby do
    it "raises a TypeError on a frozen array" do
      a = [1]
      a.freeze
      lambda { a.clear }.should raise_error(TypeError)
    end
  end
end
end # remove with unless true
