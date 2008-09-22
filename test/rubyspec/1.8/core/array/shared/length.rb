# cdd4e0c88ef4600f43f271a5ab76c045
# Generated: 2008-09-22 16:25:10
################################################################################
# describe :array_length, :shared => true do
#   it "returns the number of elements" do
#     [].send(@method).should == 0
#     [1, 2, 3].send(@method).should == 3
#   end
# 
#   it "properly handles recursive arrays" do
#     ArraySpecs.empty_recursive_array.send(@method).should == 1
#     ArraySpecs.recursive_array.send(@method).should == 8
#   end
# end

puts 'not implemented: length.rb'
unless true
describe :array_length, :shared => true do
  it "returns the number of elements" do
    [].send(@method).should == 0
    [1, 2, 3].send(@method).should == 3
  end

  it "properly handles recursive arrays" do
    ArraySpecs.empty_recursive_array.send(@method).should == 1
    ArraySpecs.recursive_array.send(@method).should == 8
  end
end
end # remove with unless true
