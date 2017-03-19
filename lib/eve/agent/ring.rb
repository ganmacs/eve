require "eve/agent/base"

# Following data is a exmple of sending data
#
#
# In election, the process added its unique id
# { type: 0, params: [2001,2002,2003] } is 'election'
#
# After election, the process send message which contains the leader of the cluster
# { type: 1, params: leader_id } 1 is 'coordinate'
#

module Eve
  module Agent
    class Ring < Base
      # message types
      ELECTION = "ELECTION"
      COORDINATOR = "COORDINATOR"

      attr_reader :clients

      def self.build(evloop, options)
        new(evloop, options[:addr], options[:port], options[:nodes])
      end

      def initialize(evloop, addr, port, nodes)
        super(evloop, addr, port, nodes)
        @state = State.new
      end

      def on_read(socket, data)
        socket.send_response("OK")

        case @state.state
        when State::COORDINATED
          handle_in_coordinated(data)
        when State::VOTED
          handle_in_voted(data)
        else
          raise "Unknow state #{@state.state}"
        end
      end

      private

      def handle_in_coordinated(data)
        case data["type"]
        when ELECTION
          send_vote_msg(data["params"])
        when COORDINATOR
          Eve.logger.info("Leader!!!!") if @state.leader?
          Eve.logger.debug("finish! election is over!!")
        else
          raise "Invalid message #{data}"
        end
      end

      def handle_in_voted(data)
        case data["type"]
        when ELECTION
          v = data["params"].max
          @state.leader! if v == @port
          send_coordinate_msg(v)
        when COORDINATOR
          send_coordinate_msg(data["params"])
        else
          raise "Invalid message #{data}"
        end
      end

      def after_start
        return unless trigger?
        # sleep(2)                # wait untill other nodes starts
        send_vote_msg
      end

      # To invoke origin msg, search max number of port
      def trigger?
        @clients.first.port.to_i < @port
      end

      def send_coordinate_msg(v)
        @state.coordinated!
        send_msg(type: COORDINATOR, params: v)
      end

      def send_vote_msg(list = [])
        @state.voted!
        send_msg(type: ELECTION, params: list << @port)
      end

      def send_msg(data)
        node = select_next_node
        Thread.new do
          v = node.async_request(data)
          msg = v.error ? "recieve failed: #{v.error}" : "Received!!!!: #{v.get}"
          Eve.logger.debug(msg)
        end
      end

      def select_next_node
        @clients.find { |c| c.port < @port } || @clients.first
      end

      class State
        VOTED = 'voted'
        COORDINATED = 'coordinated'
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
        end
      end
    end
  end
end
