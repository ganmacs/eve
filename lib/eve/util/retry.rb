module Eve
  class Retry
    DEFAULT_RETRY_COUNT = 3

    def self.retry(count, &block)
      new(count).start(block)
    end

    def initialize(count)
      @count = count
    end

    def set_fallback(&block)
      @block = block
      self
    end

    def start(on: [], &_block)
      @count.times do |i|
        begin
          yield
          return                # sucess
        rescue *on => e
          Eve.logger.error("rescue in retry: #{e}")
          sleep(i)
        end
      end

      @block.call if @block
    end
  end
end
