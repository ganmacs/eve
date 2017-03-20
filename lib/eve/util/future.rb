module Eve
  class Future
    class Timeout < StandardError; end
    class Cancel < StandardError
      def initialize(message)
        @msg = message
      end

      def to_s
        if @msg
          "Future::Cancel #{@msg}"
        else
          Future::Cancel
        end
      end
    end

    def initialize(&block)
      @set = false
      @result = nil
      @err = nil
      @hook = block
      @thread = Thread.current
    end

    def error
      get
      @err
    end

    def get
      join
      return @hook.call(@result, @err) if @hook

      @result
    end

    def cancel(reason = "")
      @set = true
      @err = if reason.is_a?(String)
               Cancel.new(reason)
             else
               reason.new
             end
      @thread.wakeup
    end

    def set(data, err = nil)
      @set = true
      @result = data
      @err = err
      @thread.wakeup
    end

    private

    def join
      unless @set
        sleep(10)

        raise Eve::Future::Timeout unless @set
      end
    end
  end
end
