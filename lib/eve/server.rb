require "cool.io"

module Eve
  class Server
    def initialize(agent)
      @agent = agent
    end

    def listen
      Eve.logger.info "Echo server listening on #{@agent.addr}:#{@agent.port}"
      @server = Cool.io::TCPServer.new(@agent.addr, @agent.port, ServerConnection, @agent)
      @agent.loop.attach(@server)
    end

    class ServerConnection < Cool.io::TCPSocket
      def initialize(io, agent)
        super(io)
        @agent = agent
      end

      def on_connect
        Eve.logger.debug("[SERVER] connected #{remote_addr}:#{remote_port}")
      end

      def on_close
        Eve.logger.debug("[SERVER] closed #{remote_addr}:#{remote_port}")
      end

      def on_read(data)
        Eve.logger.info("[SERVER] recv data: #{data}")
        @agent.write_in_server(self, data)
      end
    end
  end
end
