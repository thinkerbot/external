# 4a4c4af9baf1941fea8e13e25b541ae9
# Generated: 2008-09-22 16:25:09
################################################################################
# require File.dirname(__FILE__) + '/../../spec_helper'
# require File.dirname(__FILE__) + '/fixtures/classes'
# 
# describe "Array#delete_if" do
#   it "removes each element for which block returns true" do
#     a = [ "a", "b", "c" ] 
#     a.delete_if { |x| x >= "b" }.should equal(a)
#     a.should == ["a"]
#   end
# 
#   compliant_on :ruby, :jruby do
#     it "raises a TypeError on a frozen array" do
#       lambda { ArraySpecs.frozen_array.delete_if {} }.should raise_error(TypeError)
#     end
#   end
# end

puts 'not implemented: delete_if_spec.rb'
unless true
require File.dirname(__FILE__) + '/../../spec_helper'
require File.dirname(__FILE__) + '/fixtures/classes'

describe "Array#delete_if" do
  it "removes each element for which block returns true" do
    a = [ "a", "b", "c" ] 
    a.delete_if { |x| x >= "b" }.should equal(a)
    a.should == ["a"]
  end

  compliant_on :ruby, :jruby do
    it "raises a TypeError on a frozen array" do
      lambda { ArraySpecs.frozen_array.delete_if {} }.should raise_error(TypeError)
    end
  end
end
end # remove with unless true
