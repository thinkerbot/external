require 'rubygems'
require 'tap'
require 'tap/test'

#require File.join(File.dirname(__FILE__), 'test_array.rb')

module Test
  module Unit
    class TestCase
      acts_as_subset_test
      
      condition(:windows) { match_platform?('mswin') }
      condition(:non_windows) { match_platform?('non_mswin') }

      condition(:ruby_1_8) do
        ver = RUBY_VERSION.split(".").collect {|v| v.to_i }
        ver[0] == 1 && ver[1] == 8
      end

      condition(:ruby_1_9) do
        ver = RUBY_VERSION.split(".").collect {|v| v.to_i }
        ver[0] == 1 && ver[1] == 9
      end
    end
  end
end