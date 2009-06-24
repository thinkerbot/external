require 'tap/tasks/dump'
require 'external_index'

module External
  module Dump
    
    # :startdoc::task dump binary data
    #
    class Binary < Tap::Tasks::Dump
    
      config :frames, true, &c.switch
      
      config :format, "I", &c.string
      config :nil_value, nil, &c.yaml
      config :buffer_size, ExternalIndex::DEFAULT_BUFFER_SIZE, &c.integer
      
      def open_io(io, mode='r')
        super do |io|
          extind = ExternalIndex.new(io, config)
          
          begin
            yield(extind)
          ensure
            extind.close
          end 
        end
      end
      
      def dump(data, io)
        if frames
          io.write(data)
        else
          io.unframed_write(data)
        end
      end
    end 
  end
end