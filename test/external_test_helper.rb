require 'test/unit'
require 'benchmark'
require 'pp'

require File.join(File.dirname(__FILE__), 'test_array.rb')

class Test::Unit::TestCase
  
  #
  # Tap::Test::SubsetMethods  to remove dependency 
  #

  class << self
    def match_platform?(*platforms)
      platforms.each do |platform|
        platform.to_s =~ /^(non_)?(.*)/

        non = true if $1
        match_platform = !RUBY_PLATFORM.index($2).nil?
        return false unless (non && !match_platform) || (!non && match_platform)
      end

      true
    end
  end

  def platform_test(*platforms)
    if self.class.match_platform?(*platforms)
      yield
    else
      print ' '
    end
  end

  def prompt_test(*keys, &block)
    run_prompt = false
    ENV.each_pair do |key, value|
      if key =~ /PROMPT/i && value =~ /true/i
        run_prompt = true
        break
      end
    end

    if run_prompt
      puts "\n#{method_name} -- Enter values or 'skip'."

      values = keys.collect do |key|
        print "#{key}: "
        value = gets.strip
        flunk "skipped test" if value =~ /skip/i
        value
      end

      yield(*values)
    else
      print "p"
    end
  end
  
  def pre_ruby19?
    ver = RUBY_VERSION.split(".").collect {|v| v.to_i }
    ver[0] == 1 && ver[1] <= 8
  end
  
  #
  #  The default data 
  #
  
  def string
    "abcdefgh"
  end
  
  def array
    ["a", "b", "c", "d", "e", "f", "g", "h"]
  end

end