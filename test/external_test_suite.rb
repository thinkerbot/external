$:.unshift File.join(File.dirname(__FILE__), '../lib')

#ENV["ALL"] = 'true'
Dir.glob("./**/*_test.rb").each {|test| require test}