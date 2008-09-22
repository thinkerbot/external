module External
  class Array
  end
end

require 'test/unit'

class NamespaceConfilctsCheck < Test::Unit::TestCase
  include External
  
  # this is why it's problematic to use a naming scheme like:
  #   External::Index
  #   External::Array
  #   External::Archive
  #
  # even if you alias to the top level, within External itself
  # there is some ambiguity about whether you're using Array
  # or External::Array
  
  def test_array_now_refers_to_external_array
    assert_equal Array, External::Array
  end
end
