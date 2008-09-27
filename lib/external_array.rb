require 'external_archive'
require 'yaml'

#--
#  later separate out individual objects logically
#  If writing, create new files:
#    - base/object_id.aio     (new file for recieving appends)
#    - base/object_id.index  (copy of existing index -- made on first insertion)
#    - in index, -index indicates object_id.aio file whereas +index indicates original file
#    - .consolidate(rename) resolves changes in index into the object_id file, renaming as needed
#      requires index rewrite as well, to remove negatives
#
#  If appending, ONLY allow << and all changes get committed to the original file.
#
#  This should allow returning of new arrayio objects under read/write conditions
#  By default read-only.  No insertions.  New ExternalArray objects inherit parent mode.
#
#  Independent modes:
#  -  r
#  -  r+
#  -  For safety, w/w+ will by default act as r/r+, simply creating new .aio and .index files
#     changes to the originals will NOT be made unless .consolidate(rename) is used.  Allow option io_w => true 
#  -  b ALWAYS on with Windows
#++

#--
# YAML cannot/does not properly handle:
# - Proc
# - Class (cannot dump)
# - Carriage return strings (removes "\r"): "\r", "\r\n", "string_with_\r\n_internal"
# - Chains of newlines (loads to ""): "\n", "\n\n" 
# 
#
# Bugs:
#   @cls[ 'cat', 99, /a/, @cls[ 1, 2, 3] ].include?(@cls[ 1, 2, 3])  raises error
#++

class ExternalArray < ExternalArchive
  
  def reindex(&block)
    reindex_by_sep(nil, 
      :sep_regexp => /^-{3} /, 
      :sep_length => 4, 
      :entry_follows_sep => true,
      &block)
  end
  
  def str_to_entry(str)
    str == nil || str.empty? ? nil : YAML.load(str)
  end
  
  def entry_to_str(entry)
    entry.to_yaml
  end

  private :reindex_by_regexp, :reindex_by_sep
end
