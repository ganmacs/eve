require "cool.io"
require "eve/protocol/msg_packable"

module Eve
  module Connection
    class ConnectionError < StandardError; end

    class Base < Cool.io::TCPSocket
      include Eve::Protocol::MsgPackable

      def on_connect
        Eve.logger.debug("Connected #{remote_addr}:#{remote_port}")
      end

      def on_close
        Eve.logger.debug("Closed #{remote_addr}:#{remote_port}")
      end

      def on_read(bin_data)
        unpack_each(bin_data) do |d|
          read_message(d)
        end
      end

      def send_message(data)
        pack(data) do |d|
          write(d)
        end
      end

      private

      def read_message(data)
        NotImplementedError
      end
    end
  end
end
