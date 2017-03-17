require 'msgpack'

module Eve
  module Protocol
    module MsgPackable
      def pack(data)
        yield data.to_msgpack
      end

      def unpack_each(data)
        unpacker.feed_each(data) do |obj|
          yield(obj)
        end
      end

      def unpacker
        @unpacker ||= MessagePack::Unpacker.new
      end
    end
  end
end
