module External
  module Patches
    module Ruby18Io
      attr_reader :generic_mode
  
      def self.extended(base)
        base.instance_variable_set(:@generic_mode, Utils.mode(base))
      end
      
      # True if self is a File or Tempfile
      def file?
        self.kind_of?(File) || self.kind_of?(Tempfile)
      end
  
      def flush
        super unless generic_mode == "r"
      end
  
      def fsync
        super unless generic_mode == "r"
      end
    end
  end
  
  Io::PATCHES << Patches::Ruby18Io
end
