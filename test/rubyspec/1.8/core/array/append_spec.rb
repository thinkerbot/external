# d69f907c1c35bdff386660aeada6c60e
# Generated: 2008-09-22 16:25:09
################################################################################
# require File.dirname(__FILE__) + '/../../spec_helper'
# require File.dirname(__FILE__) + '/fixtures/classes'
# 
# describe "Array#<<" do
#   it "pushes the object onto the end of the array" do
#     ([ 1, 2 ] << "c" << "d" << [ 3, 4 ]).should == [1, 2, "c", "d", [3, 4]]
#   end
# 
#   it "returns self to allow chaining" do
#     a = []
#     b = a
#     (a << 1).should equal(b)
#     (a << 2 << 3).should equal(b)
#   end
# 
#   it "correctly resizes the Array" do
#     a = []
#     a.size.should == 0
#     a << :foo
#     a.size.should == 1
#     a << :bar << :baz
#     a.size.should == 3
# 
#     a = [1, 2, 3]
#     a.shift
#     a.shift
#     a.shift
#     a << :foo
#     a.should == [:foo]
#   end
#   
#   compliant_on :ruby, :jruby do
#     it "raises a TypeError on a frozen array" do
#       lambda { ArraySpecs.frozen_array << 5 }.should raise_error(TypeError)
#     end
#   end
# end

puts 'not implemented: append_spec.rb'
unless true
require File.dirname(__FILE__) + '/../../spec_helper'
require File.dirname(__FILE__) + '/fixtures/classes'

describe "Array#<<" do
  it "pushes the object onto the end of the array" do
    ([ 1, 2 ] << "c" << "d" << [ 3, 4 ]).should == [1, 2, "c", "d", [3, 4]]
  end

  it "returns self to allow chaining" do
    a = []
    b = a
    (a << 1).should equal(b)
    (a << 2 << 3).should equal(b)
  end

  it "correctly resizes the Array" do
    a = []
    a.size.should == 0
    a << :foo
    a.size.should == 1
    a << :bar << :baz
    a.size.should == 3

    a = [1, 2, 3]
    a.shift
    a.shift
    a.shift
    a << :foo
    a.should == [:foo]
  end
  
  compliant_on :ruby, :jruby do
    it "raises a TypeError on a frozen array" do
      lambda { ArraySpecs.frozen_array << 5 }.should raise_error(TypeError)
    end
  end
end
end # remove with unless true
