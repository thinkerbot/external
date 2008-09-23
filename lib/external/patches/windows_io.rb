module External
  module Patches
    module WindowsIo
      POSITION_MAX = 2147483647  # maximum size of long
      
      def self.extended(base)
        base.instance_variable_set("@pos", nil)
      end
      
      # Modified to handle positions past the 2Gb limit
      def pos # :nodoc:
        @pos || super
      end
    
      # Positions larger than the max value of a long cannot be directly given 
      # to the default +pos=+.  This version incrementally seeks to positions 
      # beyond the maximum, if necessary.
      #
      # Note: setting the position beyond the 2Gb limit requires the use of a 
      # sysseek statement.  As such, errors will arise if you try to position 
      # an IO object that does not support this method (for example StringIO... 
      # but then what are you doing with a 2Gb StringIO anyhow?)
      def pos=(pos)
        if pos < POSITION_MAX
          super(pos)
          @pos = nil
        elsif @pos != pos
          # note sysseek appears to be necessary here, rather than io.seek
          @pos = pos
        
          super(POSITION_MAX)
          pos -= POSITION_MAX
        
          while pos > POSITION_MAX
            pos -= POSITION_MAX
            self.sysseek(POSITION_MAX, ::IO::SEEK_CUR)
          end
        
          self.sysseek(pos, ::IO::SEEK_CUR)
        end
      end
    end
  end
  
  Io::PATCHES << Patches::WindowsIo
end
