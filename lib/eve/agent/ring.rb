require "eve/agent/base"

module Eve
  module Agent
    class Ring < Base
      RETRY_COUNT = 1
      attr_reader :clients

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
        @state = State.new
        @retry_count = retry_count
      end

      def on_read(socket, data)
        socket.send_response(status: 200, msg: "success")

        case @state.state
        when State::COORDINATED
          if data["type"] == 'voting'
            @state.voted!
            vote_and_pass(data["data"])
          elsif data["type"] == 'coordi'
            Eve.logger.debug("finish! election is over!!")
          else
            raise "Invalid message #{data}"
          end
        when State::VOTED
          if data["type"] == 'voting'
            v = data["data"].max
            @state.leader! if v == @port
            @state.coordinated!
            announce(type: 'coordi', msg: v)
          elsif data["type"] == 'coordi'
            @state.coordinated!
           announce(data)
          else
            raise "Invalid message #{data}"
          end
        else
          raise "Unknow state #{@state.state}"
        end
      end

      private

      def after_start
        @clients.sort! { |a, b| b.port <=> a.port }

        return unless leader_candidate?
        # sleep(2)                # wait untill other nodes starts
        @state.voted!
        vote_and_pass
      end

      def leader_candidate?
        # max number of port
        @clients.first.port.to_i < @port
      end

      def announce(data)
        node = select_next_node
        Thread.new do
          v = node.async_request(data)
          msg = v.error ? "recieve failed: #{v.error}" : "Received!!!!: #{v.get}"
          Eve.logger.debug(msg)
        end
      end

      def vote_and_pass(list = [])
        node = select_next_node
        Thread.new do
          v = node.async_request(type: 'voting', data: list << @port)
          msg = v.error ? "recieve failed: #{v.error}" : "Received!!!!: #{v.get}"
          Eve.logger.debug(msg)
        end
      end

      def select_next_node
        @clients.find { |c| c.port < @port } || @clients.first
      end

      class State
        VOTED = :voted
        COORDINATED = :coordinated
        STATES = [VOTED, COORDINATED]

        attr_reader :state

        def initialize
          @leader = nil
          @state = COORDINATED
          @mutex = Mutex.new
        end

        def leader?
          @leader
        end

        def leader!
          @leader = true
        end

        STATES.each do |s|
          define_method("#{s}!") do
            @mutex.synchronize do
              @state = s
            end
          end

          define_method("#{s}?") do
            @mutex.synchronize do
              @state == s
            end
          end
        end
      end
    end
  end
end
