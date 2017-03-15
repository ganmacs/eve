require "cool.io"

module Eve
  class Server
    def initialize(addr, port, loop, name)
      @addr = addr
      @port = port
      @loop = loop
      @name = name
    end

    def listen
      Eve.logger.info "Echo server listening on #{@addr}:#{@port}"
      @server = Cool.io::TCPServer.new(@addr, @port, EchoServerConnection, @name)
      @loop.attach(@server)
    end

    class EchoServerConnection < Cool.io::TCPSocket
      def initialize(io, name)
        super(io)
        @name = name
      end

      def on_connect
        Eve.logger.debug("[SERVER] connected #{remote_addr}:#{remote_port}")
      end

      def on_close
        Eve.logger.debug("[SERVER] closed #{remote_addr}:#{remote_port}")
      end

      def on_read(data)
        Eve.logger.info("[SERVER] recv data #{remote_addr}:#{remote_port}")
        write("#{data}:#{@name}")
      end
    end
  end
end
