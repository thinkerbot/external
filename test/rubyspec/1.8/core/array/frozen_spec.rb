# dbffe406e30c3cacdc7c530887886c28
# Generated: 2008-09-22 16:25:09
################################################################################
# require File.dirname(__FILE__) + '/../../spec_helper'
# require File.dirname(__FILE__) + '/fixtures/classes'
# 
# compliant_on :ruby, :jruby do
#   describe "Array#frozen?" do
#     it "returns true if array is frozen" do
#       a = [1, 2, 3]
#       a.frozen?.should == false
#       a.freeze
#       a.frozen?.should == true
#     end
# 
#     it "returns true if array is temporarily frozen while being sort!ed" do
#       a = [1, 2, 3]
#       a.sort! { |x,y| a.frozen?.should == true; x <=> y }
#     end
# 
#     it "returns false for arrays being sorted (they aren't temporarily frozen)" do
#       a = [1, 2, 3]
#       a.sort { |x,y| a.frozen?.should == false; x <=> y }
#     end
#   end
# end

puts 'not implemented: frozen_spec.rb'
unless true
require File.dirname(__FILE__) + '/../../spec_helper'
require File.dirname(__FILE__) + '/fixtures/classes'

compliant_on :ruby, :jruby do
  describe "Array#frozen?" do
    it "returns true if array is frozen" do
      a = [1, 2, 3]
      a.frozen?.should == false
      a.freeze
      a.frozen?.should == true
    end

    it "returns true if array is temporarily frozen while being sort!ed" do
      a = [1, 2, 3]
      a.sort! { |x,y| a.frozen?.should == true; x <=> y }
    end

    it "returns false for arrays being sorted (they aren't temporarily frozen)" do
      a = [1, 2, 3]
      a.sort { |x,y| a.frozen?.should == false; x <=> y }
    end
  end
end
end # remove with unless true
