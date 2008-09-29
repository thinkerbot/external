require File.join(File.dirname(__FILE__), 'external_test_helper.rb') 
require 'external'

class ReadmeTest < Test::Unit::TestCase
  acts_as_file_test
  
  #
  # YAML issues
  #
  
  def test_yaml_issues_documentation
    block = lambda {}
    assert_raise(TypeError) { YAML.load(YAML.dump(block)) }
    assert_raise(TypeError) { YAML.dump(Object) }

    assert_equal nil, YAML.load(YAML.dump("\r"))
    assert_equal "", YAML.load(YAML.dump("\r\n"))
    assert_equal "string with \n inside", YAML.load(YAML.dump("string with \r\n inside")) 

    assert_equal "", YAML.load(YAML.dump("\n"))
    assert_equal "",YAML.load(YAML.dump("\n\n"))
    
    assert_equal Time, YAML.load(YAML.dump(DateTime.now)).class
  end
  
  #
  # ExternalArray usage
  #
  
  def test_external_array_readme_documentation
    a = ExternalArray['str', {'key' => 'value'}]
    assert_equal "str", a[0]
    assert_equal({'key' => 'value'}, a.last)
    a << [1,2]
    assert_equal ['str', {'key' => 'value'}, [1,2]], a.to_a

    condition_test(:ruby_1_8) { assert_equal Tempfile, a.io.class }
    condition_test(:ruby_1_9) { assert_equal File, a.io.class }
    
    a.io.rewind
    assert_equal "--- str\n--- \nkey: value\n--- \n- 1\n- 2\n", a.io.read

    assert_equal Array, a.io_index.class
    assert_equal [[0, 8], [8, 16], [24, 13]], a.io_index.to_a

    example = method_tempfile('example.yml')
    index = example.chomp(".yml") + ".index"
    a.close(example)
    assert_equal "--- str\n--- \nkey: value\n--- \n- 1\n- 2\n", File.read(example) 
    assert_equal [0, 8, 8, 16, 24, 13], File.read(index).unpack('I*')

    ExternalArray.open(example) do |b|
      assert_equal File.basename(index), File.basename(b.io_index.io.path)
      assert_equal ['str', {'key' => 'value'}, [1,2]], b.to_a
    end

    FileUtils.rm(index)
    ExternalArray.open(example) do |b|
      assert_equal ['str', {'key' => 'value'}, [1,2]], b.to_a
    end
    
    c = ExternalArray.new File.open(example)
    assert_equal [], c.to_a

    c.reindex
    assert_equal ['str', {'key' => 'value'}, [1,2]], c.to_a
    c.close
  end
  
  #
  # ExternalArchive usage
  #
  
  class FastaEntry
    attr_reader :header, :body

    def initialize(str)
      @body = str.split(/\r?\n/)
      @header = body.shift
    end
  end

  class FastaArchive < ExternalArchive
    def str_to_entry(str); FastaEntry.new(str); end
    def entry_to_str(entry); ([entry.header] + entry.body).join("\n"); end

    def reindex
      reindex_by_sep('>', :entry_follows_sep => true)
    end
  end
  
  def test_external_archive_readme_documentation
    arc = ExternalArchive["swift", "brown", "fox"]
    assert_equal "fox", arc[2]
    assert_equal ["swift", "brown", "fox"], arc.to_a

    arc.io.rewind
    assert_equal "swiftbrownfox", arc.io.read
    
    fasta = FastaArchive.new File.open(File.dirname(__FILE__) + '/../docs/tiny_fasta.txt')
    fasta.reindex
    
    assert_equal 5, fasta.length
    assert_equal ">gi|114329651|ref|YP_740470.1| photosystem II protein D2 [Citrus sinensis]", fasta[1].header
    assert_equal ["MEVNILAFIATTLFVLVPTAFLLIIYVKTVSQSD"], fasta[0].body
  end
  
  #
  # ExternalIndex usage
  #
  
  def test_external_index_readme_documentation
    index = ExternalIndex[1, 2, 3, 4, 5, 6, {:format => 'II'}]
    assert_equal 'I*', index.format
    assert_equal 2, index.frame
    assert_equal [3,4], index[1]
    assert_equal [[1,2], [3,4], [5,6]], index.to_a
    
    Tempfile.new('sample.txt') do |file|
      file << [1,2,3].pack("IQS")
      file << [4,5,6].pack("IQS")
      file << [7,8,9].pack("IQS")
      file.flush

      index = ExternalIndex.new(file, :format => "IQS")
      assert_equal [4,5,6], index[1]
      assert_equal [[1,2,3], [4,5,6], [7,8,9]], index.to_a
    end
  end
end