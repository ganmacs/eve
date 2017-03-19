require "eve/agent/base"

# Following data is a exmple of sending data
#
#
# In election, the process added its unique id
# { type: 'election', params: [2001,2002,2003] }
#
# After election, the process send message which contains the leader of the cluster
# { type: 'coordinate', params: leader_id } 1 is

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
        when State::UNCOORDINATED
          handle_in_uncoordinated(data)
        when State::VOTED
          handle_in_voted(data)
        when State::COORDINATED
          handle_in_coordinated(data)
        else
          raise "Unknow state #{@state.state}"
        end
      end

      private

      def handle_in_uncoordinated(data)
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
          leader_id = data["params"].max
          send_coordinate_msg(leader_id)
        when COORDINATOR
          leader_id = data["params"]
          send_coordinate_msg(leader_id)
        else
          raise "Invalid message #{data}"
        end
      end

      def handle_in_coordinated(data)
        # nothing
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
        @state.coordinated!(v)
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
        UNCOORDINATED = 'uncoordinated'
        STATES = [VOTED, COORDINATED, UNCOORDINATED]

        attr_reader :state, :leader_id

        def initialize
          @leader = -1
          @state = UNCOORDINATED
          @mutex = Mutex.new
        end

        def coordinated!(leader_id)
          @leader_id = leader_id
          @mutex.synchronize do
            @state = COORDINATED
          end
        end

        (STATES - [COORDINATED]).each do |s|
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
