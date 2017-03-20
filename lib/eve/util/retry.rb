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

    def start(&_block)
      @count.times do
        begin
          yield
          return                # sucess
        rescue => e
          # sleep?
          Eve.logger.error(e)
        end
      end

      @block.call if @block
    end
  end
end
