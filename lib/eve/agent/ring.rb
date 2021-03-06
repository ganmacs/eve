require "eve/agent/base"
require "eve/util/retry"

# Following data are exmples of sending data
#
#
# In election, the process added its unique id
# { type: 'election', params: [2001,2002,2003] }
#
# After election, the process send message which contains the leader of the cluster
# { type: 'coordinate', params: leader_id }
#
# heartbeat message
# { type: 'heartbeat' }
#

module Eve
  module Agent
    class Ring < Base
      # message types
      ELECTION = "ELECTION"
      COORDINATOR = "COORDINATOR"
      HEARTBEAT = "HEARTBEAT"
      REELECTION = "REELECTION"

      attr_reader :clients

      def self.build(evloop, options)
        new(evloop, options[:addr], options[:port], options[:nodes])
      end

      def initialize(evloop, addr, port, nodes)
        super(evloop, addr, port, nodes)
        @state = State.new
        @crashed = []
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
        when REELECTION
          @state.reelection!
          send_re_vote_msg(data["params"])
        when COORDINATOR
        when HEARTBEAT
        # here is nothing to do
        else
          raise "Invalid message #{data}"
        end
      end

      def handle_in_voted(data)
        case data["type"]
        when ELECTION
          leader_id = data["params"].max
          Eve.logger.info("This is leader") if leader_id == @port
          send_coordinate_msg(leader_id)
        when REELECTION
          leader_id = data["params"].max
          Eve.logger.info("This is leader") if leader_id == @port
          send_coordinate_msg(leader_id)
        when COORDINATOR
          leader_id = data["params"]
          Eve.logger.info("This is leader") if leader_id == @port
          send_coordinate_msg(leader_id)
        when HEARTBEAT
        # ingore
        else
          raise "Invalid message #{data}"
        end
      end

      def handle_in_coordinated(data)
        case data["type"]
        when REELECTION
          @state.reelection!
          send_re_vote_msg(data["params"])
        when COORDINATOR
        when HEARTBEAT
        # here is nothing to do
        else
          raise "Invalid message #{data}"
        end
      end

      def after_start
        set_heartbeat

        return unless trigger?
        # sleep(2)                # wait untill other nodes starts
        send_vote_msg
      end

      # To invoke origin msg, search max number of port
      def trigger?
        @clients.last.port.to_i < @port
      end

      def set_heartbeat
        Ticker.execute(2) do
          next unless @state.state == State::COORDINATED
          async_send_msg(next_node, type: HEARTBEAT)
        end
      end

      def start_election
        Eve.logger.info("election re-start")
        # this code runs once, so if this method failed, never restart eletion
        send_re_vote_msg
      end

      def send_coordinate_msg(v)
        @state.coordinated!(v)
        async_send_msg(next_node, type: COORDINATOR, params: v)
      end

      def send_re_vote_msg(list = [])
        @state.voted!
        async_send_msg(next_node, type: REELECTION, params: list << @port)
      end

      def send_vote_msg(list = [])
        @state.voted!
        async_send_msg(next_node, type: ELECTION, params: list << @port)
      end

      def async_send_msg(node, data)
        t = Thread.current
        Thread.new do
          begin
            send_msg(node, data)
          rescue => e
            t.raise(e)
          end
        end
      end

      def send_msg(node, data)
        r = Eve::Retry.new(3).set_fallback do |e|
          @crashed << node
          if e.is_a?(Eve::Connection::ConnectionError) && @state.state == State::VOTED
            # invoke this code only after calling start_election
            send_msg(next_node, data) # search next node and retry
          end

          if @state.leader?(node.port)
            @state.uncoordinated! # stop heartbeat
            start_election
          end
        end

        r.start(on: [Eve::Future::Timeout, Eve::Future::Cancel, Eve::Connection::ConnectionError]) do
          v = node.async_request(data)
          raise(v.error) if v.error
          Eve.logger.info("Received: #{v.get}")
        end
      end

      def next_node(port = @port)
        less, greater = (@clients - @crashed).partition { |c| c.port < port }
        v = greater + less
        raise 'Available node is nothing' if v.empty?
        v.first
      end

      class State
        VOTED = 'voted'
        COORDINATED = 'coordinated'
        UNCOORDINATED = 'uncoordinated'
        STATES = [VOTED, COORDINATED, UNCOORDINATED]

        attr_reader :leader_id

        def initialize
          @leader_id = -1
          @state = UNCOORDINATED
          @mutex = Mutex.new
        end

        def state
          @mutex.synchronize do
            @state
          end
        end

        def leader?(id)
          @leader_id == id
        end

        def reelection!
          @leader_id = -1
          @mutex.synchronize do
            @state = UNCOORDINATED
          end
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
