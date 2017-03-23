require "timeout"

module Eve
  class Ticker
    DEFAULT_TIMEOUT = 5
    def initialize
      @observers = []
    end

    def self.execute(duraiton, timout_interval: DEFAULT_TIMEOUT, &block)
      new.execute(duraiton, timout_interval, &block)
    end

    def add_observer(observer)
      @observers << observer
    end

    def delete_observer(observer)
      @observers -= [observer]
    end

    def execute(duration, timout_interval, &block)
      Thread.new do
        loop do
          exec_at = Time.now.to_i
          execute_once(timout_interval, &block)
          next_start_at = exec_at + duration
          finish_at = Time.now.to_i
          sleep(next_start_at - finish_at) if next_start_at > finish_at
        end
      end
    end

    private

    def execute_once(timout_interval, &block)
      result = nil
      err = nil
      begin
        Timeout.timeout(timout_interval) do
          result = block.call
        end
      rescue => e
        err = e
      end

      @observers.each do |ob|
        ob.update(result, err)
      end
    end
  end
end
