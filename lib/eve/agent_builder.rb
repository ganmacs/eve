require 'eve/agent'

module Eve
  class AgentBuilder
    DEFAULT_ADDR = "127.0.0.1"
    DEFAULT_PORT = 4321

    def self.build(loop, options)
      type = options[:type]
      agent_class(type).new(loop, options)
    end

    def agent_class(type)
      case type
      when nil
        raise "--type is required"
      when "hb", "heartbeat"
        Eve::HeartBeatAgent
      else
        Eve::Agent.const_get(type.to_sym)
      end
    end
  end
end
