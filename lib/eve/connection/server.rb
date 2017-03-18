require "eve/connection/base"

module Eve
  module Connection
    class Server < Base
      def initialize(io, agent)
        super(io)
        @agent = agent
      end

      def send_response(data)
        Eve.logger.debug("send response #{data} ")
        send_message(data)
      end

      private

      def read_message(data)
        Eve.logger.info("[SERVER] recv data: #{data}")
        @agent.on_read(self, data)
      end
    end
  end
end
