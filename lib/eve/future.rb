module Eve
  class Future
    def initialize(conn, &block)
      @conn = conn
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

    def cancel(reason = "canceled")
      @set = true
      @err = reason
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
        raise 'Timeout' unless @set
      end
    end
  end
end
