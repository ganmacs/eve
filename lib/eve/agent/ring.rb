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

        unless data.include?(@port)
          Thread.new do
            v = pass_next(data)
            if v.error
              Eve.logger.debug("recieve failed #{v.error}")
            else
              Eve.logger.debug("Received!!!! #{v.get}")
            end
          end
        end
      end

      private

      def after_start
        @clients.sort! { |a, b| b.port <=> a.port }

        return unless leader_candidate?
        # sleep(2)                # wait untill other nodes starts
        Eve.logger.info("leader!!")
        Thread.new do
          v = pass_next
          if v.error
            Eve.logger.debug("recieve failed: #{v.error}")
          else
            Eve.logger.debug("Received!!!!: #{v.get}")
          end
        end
      end

      def leader_candidate?
        # max number of port
        @clients.first.port.to_i < @port
      end

      def pass_next(list = [])
        node = select_next_node
        node.async_request(list << @port)
      end

      def select_next_node
        @clients.find { |c| c.port < @port } || @clients.first
      end
    end
  end
end
