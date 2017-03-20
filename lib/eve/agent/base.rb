require "eve/server"
require "eve/client"

module Eve
  module Agent
    class Base
      attr_reader :name, :port, :addr, :loop

      def self.build(evloop, options)
        new(evloop, options[:addr], options[:port], options[:nodes])
      end

      def initialize(evloop, addr, port, nodes)
        @loop = evloop
        @addr = addr
        @port = port.to_i
        @nodes = nodes || []
        @name = ENV["NODE_NAME"] || "#{@addr}:#{@port}"
      end

      def start
        before_setup
        @server = Server.new(self)
        @clients = @nodes.map { |node|
          Client.new(@loop, node[:addr], node[:port])
        }.sort! { |a, b| a.port <=> b.port }

        before_start
        @server.listen
        after_start

        Eve.logger.info("Start agent!!")
      end

      # This method is server's on_read.
      def on_read(socket, data)
      end

      private

      # hook method
      def before_setup
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
