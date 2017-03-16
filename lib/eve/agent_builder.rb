require 'eve/agent'
require 'eve/config'

module Eve
  class AgentBuilder
    DEFAULT_ADDR = "127.0.0.1"
    DEFAULT_PORT = 4321

    def self.build(evloop, options)
      new(evloop).build(options)
    end

    def initialize(evloop)
      @evloop = evloop
    end

    def build(options)
      opt = { addr: DEFAULT_ADDR, port: DEFAULT_PORT }.merge(options)

      type = options[:type]

      if options[:file_path]
        config = Config.new(options[:file_path])
        type ||= config[:type]
        opt = config.merge(options)
      end

      agent_class(type).build(@evloop, opt)
    end

    private

    def agent_class(type)
      case type
      when nil
        raise "agent type is required"
      when "hb", "heartbeat"
        Eve::Agent::HeartBeat
      else
        Eve::Agent.const_get(type.capitalize.to_sym)
      end
    end
  end
end
