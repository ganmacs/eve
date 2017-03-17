require "cool.io"
require "eve/connection/server"

module Eve
  class Server
    def initialize(agent)
      @agent = agent
    end

    def listen
      Eve.logger.info "Echo server listening on #{@agent.addr}:#{@agent.port}"
      @server = Cool.io::TCPServer.new(@agent.addr, @agent.port, Eve::Connection::Server, @agent)
      @agent.loop.attach(@server)
    end
  end
end
