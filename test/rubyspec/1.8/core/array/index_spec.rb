# ec44e14b6c48d4479a145e1d4c295096
# Generated: 2008-09-22 16:25:09
################################################################################
# require File.dirname(__FILE__) + '/../../spec_helper'
# require File.dirname(__FILE__) + '/fixtures/classes'
# 
# describe "Array#index" do
#   it "returns the index of the first element == to object" do
#     x = mock('3')
#     def x.==(obj) 3 == obj; end
# 
#     [2, x, 3, 1, 3, 1].index(3).should == 1
#   end
# 
#   it "returns 0 if first element == to object" do
#     [2, 1, 3, 2, 5].index(2).should == 0
#   end
# 
#   it "returns size-1 if only last element == to object" do
#     [2, 1, 3, 1, 5].index(5).should == 4
#   end
# 
#   it "returns nil if no element == to object" do
#     [2, 1, 1, 1, 1].index(3).should == nil
#   end
# end

puts 'not implemented: index_spec.rb'
unless true
require File.dirname(__FILE__) + '/../../spec_helper'
require File.dirname(__FILE__) + '/fixtures/classes'

describe "Array#index" do
  it "returns the index of the first element == to object" do
    x = mock('3')
    def x.==(obj) 3 == obj; end

    [2, x, 3, 1, 3, 1].index(3).should == 1
  end

  it "returns 0 if first element == to object" do
    [2, 1, 3, 2, 5].index(2).should == 0
  end

  it "returns size-1 if only last element == to object" do
    [2, 1, 3, 1, 5].index(5).should == 4
  end

  it "returns nil if no element == to object" do
    [2, 1, 1, 1, 1].index(3).should == nil
  end
end
end # remove with unless true
