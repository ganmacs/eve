require "eve/cli"

module Eve
  class << self
    def logger
      @logger ||= ::Logger.new(log_device, level: log_level)
    end

    def set_logger(device, level)
      @logger = ::Logger.new(
        log_device(device),
        level: log_level(level)
      )
    end

    def log_device(dev = ENV["LOG_DEV"])
      case dev
      when "STDOUT"
        STDOUT
      when "STDERR"
        STDERR
      when "", nil              # not set
        STDOUT
      else                      # file
        ENV["LOG_DEV"]
      end
    end

    def log_level(level = ENV["LOG_LEVEL"])
      case level
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
