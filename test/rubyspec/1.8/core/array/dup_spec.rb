# 6f132d6b5725f303e792a63d5268b303
# Generated: 2008-09-22 16:25:09
################################################################################
# require File.dirname(__FILE__) + '/../../spec_helper'
# require File.dirname(__FILE__) + '/fixtures/classes'
# require File.dirname(__FILE__) + '/shared/clone'
# 
# describe "Array#dup" do
#   it_behaves_like :array_clone, :dup # FIX: no, clone and dup are not alike
# 
#   it "should dup subclasses and return an instance of the subclass" do
#     a = [:array, [:lit, 1], [:lit, 2]]
#     b = ArraySpecs::Sexp.new << :array << [:lit, 1] << [:lit, 2]
# 
#     a.dup.should == a
#     b.dup.should == b
#   end
# end

puts 'not implemented: dup_spec.rb'
unless true
require File.dirname(__FILE__) + '/../../spec_helper'
require File.dirname(__FILE__) + '/fixtures/classes'
require File.dirname(__FILE__) + '/shared/clone'

describe "Array#dup" do
  it_behaves_like :array_clone, :dup # FIX: no, clone and dup are not alike

  it "should dup subclasses and return an instance of the subclass" do
    a = [:array, [:lit, 1], [:lit, 2]]
    b = ArraySpecs::Sexp.new << :array << [:lit, 1] << [:lit, 2]

    a.dup.should == a
    b.dup.should == b
  end
end
end # remove with unless true
