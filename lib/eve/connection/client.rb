require "eve/connection/base"
require "eve/util/future"
require "eve/util/safe_buffer"

module Eve
  module Connection
    class Client < Base
      def initialize(io, client)
        super(io)
        @client = client
        @buffer = SafeBuffer.new
        @mutex = Mutex.new
        @connected = false
        @future = Future.new
      end

      def send_request(data)
        @buffer.add(data)
        flash if connected?
        @future
      end

      def on_connect
        super
        @mutex.synchronize { @connected = true }
        flash
      end

      def on_connect_failed
        Eve.logger.error("[CLIENT] connect failed, meaning our connection to their port was rejected")
        @future.cancel("connection failed")
        close if connected?
      end

      private

      def read_message(data)
        Eve.logger.debug("[CLIENT] returned from server: #{data}")
        close
        @future.set(data)
      end

      def connected?
        @mutex.synchronize do
          @connected
        end
      end

      def flash
        return unless @buffer.buffered?
        @client.send_message(self, @buffer)
        Eve.logger.debug("[CLIENT] sent data to #{remote_addr}:#{remote_port}")
        @buffer.reset
      end
    end
  end
end
