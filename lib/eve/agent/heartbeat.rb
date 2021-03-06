require "eve/agent/base"
require "eve/util/ticker"

module Eve
  module Agent
    class HeartBeat < Base
      DEFAULT_HEARTBEAT_PERIOD = 3      # sec

      def self.build(evloop, options)
        self.new(
          evloop,
          options[:addr],
          options[:port],
          options[:nodes],
          hb_period: options[:hb_period] || DEFAULT_HEARTBEAT_PERIOD
        )
      end

      def initialize(evloop, addr, port, nodes, hb_period:)
        super(evloop, addr, port, nodes)
        @hb_period = hb_period
      end

      def on_read(socket, data)
        socket.send_message("ok")
      end

      private

      def after_start
        return unless leader?

        set_heartbeat
      end

      def set_heartbeat
        Ticker.execute(@hb_period) do
          heartbeat
        end
      end

      def leader?
        @clients.last.port.to_i < @port
      end

      def heartbeat
        @clients.each do |cli|
          Thread.new(cli) do |c| # to limit
            future = c.async_request(type: 'HEARTBEAT')
            if future.error
              Eve.logger.error(future.error)
            else
              Eve.logger.info(future.get)
            end
          end
        end
      end
    end
  end
end
