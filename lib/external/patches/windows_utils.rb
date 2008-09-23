# This code block modifies IO only if running on windows
require 'Win32API' 

module External
  module Utils
    module_function
    
    # Modfied to properly determine file lengths on Windows. Uses code
    # from 'win32/file/stat' (http://rubyforge.org/projects/win32utils/)
    def file_length(io)
      io.fsync

      # I would have liked to use win32/file/stat to do this... however, some issue
      # arose involving FileUtils.cp, File.stat, and File::Stat.mode.  cp raised an 
      # error because the mode would be nil for files.  I wasn't sure how to fix it, 
      # so I've lifted the relevant code for pulling the large file size.

      # Note this is a simplified version... if you base.path point to a chardev, 
      # this may need to be changed, because apparently the call to the Win32API 
      # may fail

      stat_buf = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0].pack('ISSssssIILILILIL')
      Win32API.new('msvcrt', '_stat64', 'PP', 'I').call(io.path, stat_buf)
      stat_buf[24, 4].unpack('L').first # Size of file in bytes
    end
  end
end
