require "logger"
require "cool.io"
require "eve/ticker"
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
        @port = port
        @nodes = nodes || []
        @name = ENV["NODE_NAME"] || "#{@addr}:#{@port}"
      end

      def start
        before_setup
        @server = Server.new(self)
        @clients = @nodes.map do |node|
          Client.new(@loop, node[:addr], node[:port])
        end

        before_start
        @server.listen
        after_start
      end

      # echo
      def write_in_server(socket, data)
        socket.write(data)
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
