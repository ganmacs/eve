require "eve/agent/base"
require "eve/ticker"

module Eve
  module Agent
    class HeartBeatAgent < Base
      DEFAULT_HEARTBEAT_PERIOD = 3      # sec

      def initialize(evloop, addr, port, nodes, hb_period: DEFAULT_HEARTBEAT_PERIOD)
        super(evloop, addr, port, nodes)
        @hb_period = hb_period
      end

      private

      def after_start
        return unless leader?

        Ticker.start(@heartbeat_rate) do
          heartbeat
        end
      end

      def leader?
        !@nodes.empty?
      end

      def heartbeat
        Eve.logger.debug("Start heartbeat ...")
        @nodes.each do |node|
          Thread.new(node) do |n|   # to limit
            n.request("ping")
          end
        end
      end
    end
  end
end
