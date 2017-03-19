require "eve/agent/base"

module Eve
  module Agent
    class Ring < Base
      RETRY_COUNT = 1

      def self.build(evloop, options)
        self.new(
          evloop,
          options[:addr],
          options[:port],
          options[:nodes],
          retry_count: options[:retry] || RETRY_COUNT
        )
      end

      def initialize(evloop, addr, port, nodes, retry_count:)
        super(evloop, addr, port, nodes)
        @retry_count = retry_count
        @state = :leader
      end

      def on_read(socket, data)
        socket.send_response(status: 200, msg: "success")

        pass_next(data) unless data.include?(@port)
      end

      private

      def after_start
        @clients.sort! { |a, b| b.port <=> a.port }

        return unless leader_candidate?
        # sleep(2)                # wait untill other nodes starts
        Eve.logger.info("leader!!")
        pass_next
      end

      def leader_candidate?
        # max number of port
        @clients.first.port.to_i < @port
      end

      def pass_next(list = [])
        node = select_next_node
        Thread.new do
          v = node.async_request(list << @port)
          msg = v.error ? "recieve failed: #{v.error}" : "Received!!!!: #{v.get}"
          Eve.logger.debug(msg)
        end
      end

      def select_next_node
        @clients.find { |c| c.port < @port } || @clients.first
      end
    end
  end
end
