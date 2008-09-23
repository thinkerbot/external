module External
  module Patches
    module Ruby18Io
      attr_reader :generic_mode
  
      def self.extended(base)
        base.instance_variable_set(:@generic_mode, Utils.mode(base))
      end
  
      def flush
        super unless generic_mode == "r"
      end
  
      def fsync
        super unless generic_mode == "r"
      end
      
      # Quick comparision with another IO.  Returns true if
      # another == self, or if both are file-type IOs and 
      # their paths are equal.
      def quick_compare(another)
        self == another || (
          (self.kind_of?(File) || self.kind_of?(Tempfile)) && 
          (another.kind_of?(File) || another.kind_of?(Tempfile)) && 
          self.path == another.path)
      end
    end
  end
  
  Io::PATCHES << Patches::Ruby18Io
end
