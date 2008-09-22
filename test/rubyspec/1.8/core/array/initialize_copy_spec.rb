# fea1f0bb16d51d4659b6dbd0ad3f595d
# Generated: 2008-09-22 16:25:09
################################################################################
# require File.dirname(__FILE__) + '/../../spec_helper'
# require File.dirname(__FILE__) + '/fixtures/classes'
# require File.dirname(__FILE__) + '/shared/replace'
# 
# describe "Array#initialize_copy" do
#  it "is private" do
#    [].private_methods.map { |m| m.to_s }.include?("initialize_copy").should == true
#  end
#  
#  it_behaves_like(:array_replace, :initialize_copy)
# end

puts 'not implemented: initialize_copy_spec.rb'
unless true
require File.dirname(__FILE__) + '/../../spec_helper'
require File.dirname(__FILE__) + '/fixtures/classes'
require File.dirname(__FILE__) + '/shared/replace'

describe "Array#initialize_copy" do
 it "is private" do
   [].private_methods.map { |m| m.to_s }.include?("initialize_copy").should == true
 end
 
 it_behaves_like(:array_replace, :initialize_copy)
end
end # remove with unless true
