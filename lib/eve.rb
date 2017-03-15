require "eve/cli"

module Eve
  class << self
    def logger
      @logger = ::Logger.new(log_output, level: log_level)
    end

    def log_output
      case ENV["LOG_DEV"]
      when "STDOUT"
        STDOUT
      when "STDERR"
        STDERR
      when ""                   # not set
        STDOUT
      else                      # file
        ENV["LOG_DEV"]
      end
    end

    def log_level
      case ENV["LOG_LEVEL"]
      when "debug", "DEBUG"
        ::Logger::DEBUG
      when "info", "info"
        ::Logger::DEBUG
      else
        ::Logger::INFO
      end
    end
  end
end
