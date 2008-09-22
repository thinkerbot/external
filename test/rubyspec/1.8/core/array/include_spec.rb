# 4905d7f1d18d02952d94839dc7d0e3ac
# Generated: 2008-09-22 16:25:09
################################################################################
# require File.dirname(__FILE__) + '/../../spec_helper'
# require File.dirname(__FILE__) + '/fixtures/classes'
# 
# describe "Array#include?" do
#   it "returns true if object is present, false otherwise" do
#     [1, 2, "a", "b"].include?("c").should == false
#     [1, 2, "a", "b"].include?("a").should == true
#   end
# 
#   it "determines presence by using element == obj" do
#     o = mock('')
#   
#     [1, 2, "a", "b"].include?(o).should == false
# 
#     def o.==(other); other == 'a'; end
# 
#     [1, 2, o, "b"].include?('a').should == true
#   end
# 
#   it "calls == on elements from left to right until success" do
#     key = "x"
#     one = mock('one')
#     two = mock('two')
#     three = mock('three')
#     one.should_receive(:==).any_number_of_times.and_return(false)
#     two.should_receive(:==).any_number_of_times.and_return(true)
#     three.should_not_receive(:==)
#     ary = [one, two, three]
#     ary.include?(key).should == true
#   end
# end

puts 'not implemented: include_spec.rb'
unless true
require File.dirname(__FILE__) + '/../../spec_helper'
require File.dirname(__FILE__) + '/fixtures/classes'

describe "Array#include?" do
  it "returns true if object is present, false otherwise" do
    [1, 2, "a", "b"].include?("c").should == false
    [1, 2, "a", "b"].include?("a").should == true
  end

  it "determines presence by using element == obj" do
    o = mock('')
  
    [1, 2, "a", "b"].include?(o).should == false

    def o.==(other); other == 'a'; end

    [1, 2, o, "b"].include?('a').should == true
  end

  it "calls == on elements from left to right until success" do
    key = "x"
    one = mock('one')
    two = mock('two')
    three = mock('three')
    one.should_receive(:==).any_number_of_times.and_return(false)
    two.should_receive(:==).any_number_of_times.and_return(true)
    three.should_not_receive(:==)
    ary = [one, two, three]
    ary.include?(key).should == true
  end
end
end # remove with unless true
