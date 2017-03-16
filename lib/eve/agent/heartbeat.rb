require "eve/agent/base"
require "eve/ticker"

module Eve
  module Agent
    class HeartBeatAgent < Base
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

      # echo
      def write_in_server(socket, data)
        if data == "ping"
          socket.write("pong")
        else
          super
        end
      end

      private

      def after_start
        return unless leader?

        Ticker.start(@hb_period) do
          heartbeat
        end
      end

      def leader?
        !@clients.empty?
      end

      def heartbeat
        Eve.logger.debug("Start heartbeat ...")

        current = Thread.current
        @clients.each do |cli|
          Thread.new(cli) do |c| # to limit
            begin
              c.request("ping")
            rescue => e
              current.raise(e)
              break
            end
          end
        end
      end
    end
  end
end
