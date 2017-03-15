require 'cool.io'
require 'eve/agent_builder'

module Eve
  class Runner
    def initialize(options)
      @options = options
    end

    def run
      agent = AgentBuilder.build(evloop, @options)
      agent.start
      evloop.run(0.01)
    end

    private

    def evloop
      @evloop ||= Cool.io::Loop.new
    end
  end
end
