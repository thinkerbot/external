require File.join(File.dirname(__FILE__), 'external_test_helper.rb') 
require 'external'

class ReadmeTest < Test::Unit::TestCase
  acts_as_file_test
  
  def test_external_array_readme_documentation
    a = ExternalArray[1, 2.2, "cat", {:key => 'value'}]
    assert_equal "cat", a[2]
    assert_equal({:key => 'value'}, a.last)
    a << [:a, :b]
    assert_equal [1, 2.2, "cat", {:key => 'value'}, [:a, :b]], a.to_a

    assert_equal StringIO, a.io.class
    assert_equal "--- 1\n--- 2.2\n--- cat\n--- \n:key: value\n--- \n- :a\n- :b\n", a.io.string

    assert_equal Array, a.io_index.class
    assert_equal [[0, 6], [6, 8], [14, 8], [22, 17], [39, 15]], a.io_index.to_a

    example = method_tempfile('example.yml')
    index = example.chomp(".yml") + ".index"
    a.close(example)
    assert_equal "--- 1\n--- 2.2\n--- cat\n--- \n:key: value\n--- \n- :a\n- :b\n", File.read(example) 
    assert_equal [0, 6, 6, 8, 14, 8, 22, 17, 39, 15], File.read(index).unpack('I*')

    ExternalArray.open(example) do |b|
      assert_equal [1, 2.2, "cat", {:key => 'value'}, [:a, :b]], b.to_a
    end

    FileUtils.rm(index)
    ExternalArray.open(example) do |b|
      assert_equal [1, 2.2, "cat", {:key => 'value'}, [:a, :b]], b.to_a
    end
    
    c = ExternalArray.new File.open(example)
    assert_equal [], c.to_a

    c.reindex
    assert_equal [1, 2.2, "cat", {:key => 'value'}, [:a, :b]], c.to_a
  end
  
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

    assert_equal StringIO, arc.io.class
    assert_equal "swiftbrownfox", arc.io.string
    
    fasta = FastaArchive.new File.open(File.dirname(__FILE__) + '/../docs/tiny_fasta.txt')
    fasta.reindex
    
    assert_equal 5, fasta.length
    assert_equal ">gi|114329651|ref|YP_740470.1| photosystem II protein D2 [Citrus sinensis]", fasta[1].header
    assert_equal ["MEVNILAFIATTLFVLVPTAFLLIIYVKTVSQSD"], fasta[0].body
  end
  
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