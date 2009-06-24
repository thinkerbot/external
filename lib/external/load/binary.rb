require 'tap/tasks/load'
require 'external_index'

module External
  module Load
    
    # :startdoc::task load binary data
    #
    # 
    class Binary < Tap::Tasks::Load
      
      config :n, nil, &c.integer_or_nil
      config :frames, true, &c.switch
      
      config :format, "I", &c.string
      config :nil_value, nil, &c.yaml
      config :buffer_size, ExternalIndex::DEFAULT_BUFFER_SIZE, &c.integer

      def open(io)
        unless io.kind_of?(ExternalIndex)
          io = ExternalIndex.new(super, config)
        end
        
        io
      end
      
      def load(io)
        case
        when frames
          io.read(n)
        when io.process_in_bulk
          io.readbytes(n).unpack(io.format)
        else
          io.read(n).flatten
        end
      end
    end 
  end
end