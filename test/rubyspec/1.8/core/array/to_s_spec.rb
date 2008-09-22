# 35b4d9fddfd4507a0d9814a07e28a786
# Generated: 2008-09-22 16:25:10
################################################################################
# require File.dirname(__FILE__) + '/../../spec_helper'
# require File.dirname(__FILE__) + '/fixtures/classes'
# 
# describe "Array#to_s" do
#   it "is equivalent to #join without a separator string" do
#     old = $,
#     begin
#       a = [1, 2, 3, 4]
#       a.to_s.should == a.join
#       $, = '-'
#       a.to_s.should == a.join
#     ensure
#       $, = old
#     end
#   end
# 
#   it "properly handles recursive arrays" do
#     ArraySpecs.empty_recursive_array.to_s.should == "[...]"
#     a = [1, 2, 3]; a << a
#     a.to_s.should == "123123[...]"
#   end
# end

puts 'not implemented: to_s_spec.rb'
unless true
require File.dirname(__FILE__) + '/../../spec_helper'
require File.dirname(__FILE__) + '/fixtures/classes'

describe "Array#to_s" do
  it "is equivalent to #join without a separator string" do
    old = $,
    begin
      a = [1, 2, 3, 4]
      a.to_s.should == a.join
      $, = '-'
      a.to_s.should == a.join
    ensure
      $, = old
    end
  end

  it "properly handles recursive arrays" do
    ArraySpecs.empty_recursive_array.to_s.should == "[...]"
    a = [1, 2, 3]; a << a
    a.to_s.should == "123123[...]"
  end
end
end # remove with unless true
