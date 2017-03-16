require "cool.io"
require "eve/safe_buffer"
require "eve/future"

module Eve
  class Client
    def initialize(evloop, addr, port, name)
      @addr = addr
      @port = port
      @evloop = evloop
      @name = name
      Eve.logger.debug("client intilized #{addr}:#{port}")
    end

    def request(data)
      conn = try_connect        # always establish new connction
      future = conn.send_request(data)
      unless future.error
        Eve.logger.info("[CLIENT] #{future.get}") # blocking
      end
    end

    def write(socket, buffer)
      data = buffer.to_data
      socket.write(data)
    end

    private

    def try_connect
      conn = ClientConnection.connect(@addr, @port, self)
      @evloop.attach(conn)
      conn
    end

    class ClientConnection < Cool.io::TCPSocket
      def initialize(io, client)
        super(io)
        @client = client
        @buffer = SafeBuffer.new
        @mutex = Mutex.new
        @connected = false
        @future = Future.new(self) do |result, err|
          if err == "connection failed"
            err
          elsif err
            close
            err
          else
            close
            result
          end
        end
      end

      def send_request(data)
        @buffer.add(data)
        flash if connected?
        @future
      end

      def on_connect
        Eve.logger.debug("[CLIENT] connected #{remote_addr}:#{remote_port}")
        @mutex.synchronize { @connected = true }
        flash
      end

      def on_close
        Eve.logger.debug("[CLIENT] closed #{remote_addr}:#{remote_port}")
      end

      def on_read(data)
        @future.set(data)
        Eve.logger.debug("[CLIENT] returned from server: #{data}")
      end

      def on_connect_failed
        Eve.logger.error("[CLIENT] connect failed, meaning our connection to their port was rejected")
        @future.cancel("connection failed")
        close if connected?
      end

      private

      def connected?
        @mutex.synchronize do
          @connected
        end
      end

      def flash
        return unless @buffer.buffered?
        @client.write(self, @buffer)
        Eve.logger.debug("[CLIENT] trying sending...")
        @buffer.reset
      end
    end
  end
end
