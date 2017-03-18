module Eve
  class SafeBuffer
    def initialize
      @mutex = Mutex.new
      @buffer = []
    end

    def to_data
      @mutex.synchronize do
        if @buffer.size == 1
          @buffer.first
        else
          @buffer
        end
      end
    end

    def add(data)
      @mutex.synchronize do
        @buffer << data
      end
    end

    def reset
      @mutex.synchronize do
        @buffer = []
      end
    end

    def buffered?
      @mutex.synchronize do
        !@buffer.nil?
      end
    end
  end
end
