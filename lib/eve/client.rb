require "cool.io"
require "eve/connection/client"

module Eve
  class Client
    attr_reader :port, :addr

    def initialize(evloop, addr, port)
      @addr = addr
      @port = port.to_i
      @evloop = evloop
      Eve.logger.debug("client intilized #{addr}:#{port}")
    end

    def request(data)
      conn = try_connect        # always establish new connction
      future = conn.send_request(data)
      unless future.error
        Eve.logger.info("[CLIENT] #{future.get}")
      end
    end

    def async_request(data)
      conn = try_connect        # always establish new connction
      conn.send_request(data)
    end

    def send_message(socket, buffer)
      data = buffer.to_data
      socket.send_message(data)
    end

    private

    def try_connect
      conn = Eve::Connection::Client.connect(@addr, @port, self)
      @evloop.attach(conn)
      conn
    end
  end
end
