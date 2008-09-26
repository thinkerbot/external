# 79cabcfc68f3e0a01326cf4bd4cf6117
# Generated: 2008-09-22 16:25:11
################################################################################
# unless ENV['MSPEC_RUNNER']
#   begin
#     require "pp"
#     require 'mspec/version'
#     require 'mspec/helpers'
#     require 'mspec/guards'
#     require 'mspec/runner/shared'
#     require 'mspec/matchers/be_ancestor_of'
#     require 'mspec/matchers/output'
#     require 'mspec/matchers/output_to_fd'
#     require 'mspec/matchers/complain'
#     require 'mspec/matchers/equal_element'
#     require 'mspec/matchers/equal_utf16'
#     require 'mspec/matchers/match_yaml'
# 
#     TOLERANCE = 0.00003 unless Object.const_defined?(:TOLERANCE)
#   rescue LoadError
#     puts "Please install the MSpec gem to run the specs."
#     exit 1
#   end
# end
# 
# v = MSpec::VERSION.split('.').collect { |d| "1%02d" % d.to_i }.join.to_i
# unless v >= 101105100
#   puts "Please install MSpec version >= 1.5.0 to run the specs"
#   exit 1
# end
# 
# $VERBOSE = nil unless ENV['OUTPUT_WARNINGS']
# 
# def has_tty?
#   if STDOUT.tty? then
#     yield
#   end
# end

################################################################################
# added require for external
lib_dir = File.expand_path(File.dirname(__FILE__) + "/../../../lib")
$:.unshift lib_dir unless $:.include?(lib_dir)
require 'external'

# set the default_io_index to run with an ExternalIndex
class << ExternalArchive
  def default_io_index
    ENV['ARRAY'] || ENV['array'] ? [] : ExternalIndex.new('', :format => "II")
  end
end

unless ENV['MSPEC_RUNNER']
  begin
    require "pp"
    require 'mspec/version'
    require 'mspec/helpers'
    require 'mspec/guards'
    require 'mspec/runner/shared'
    require 'mspec/matchers/be_ancestor_of'
    require 'mspec/matchers/output'
    require 'mspec/matchers/output_to_fd'
    require 'mspec/matchers/complain'
    require 'mspec/matchers/equal_element'
    require 'mspec/matchers/equal_utf16'
    require 'mspec/matchers/match_yaml'

    TOLERANCE = 0.00003 unless Object.const_defined?(:TOLERANCE)
  rescue LoadError
    puts "Please install the MSpec gem to run the specs."
    exit 1
  end
end

v = MSpec::VERSION.split('.').collect { |d| "1%02d" % d.to_i }.join.to_i
unless v >= 101105100
  puts "Please install MSpec version >= 1.5.0 to run the specs"
  exit 1
end

$VERBOSE = nil unless ENV['OUTPUT_WARNINGS']

def has_tty?
  if STDOUT.tty? then
    yield
  end
end