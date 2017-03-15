require "logger"
require "cool.io"
require "eve/ticker"
require "eve/server"
require "eve/client"

module Eve
  module Agent

    class Base
      def initialize(evloop, addr, port, nodes)
        @loop = evloop
        @addr = addr
        @port = port
        @nodes = nodes
        @server = Server.new(@addr, @port, @loop)
        @clients = @nodes.map do |node|
          Client.new(@loop, node[:addr], node[:port])
        end
        after_init
      end

      def start
        before_start
        @server.listen
        after_start
      end

      private

      # hook method
      def after_init
      end

      # hook method
      def before_start
      end

      # hook method
      def after_start
      end

      def leader?
        raise NotImplementedError
      end
    end
  end
end
