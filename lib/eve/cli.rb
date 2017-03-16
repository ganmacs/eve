require 'optparse'
require 'eve/runner'

module Eve
  class CLI
    def self.run(args)
      new(args).run
    end

    def initialize(argv = ARGV)
      @argv = argv
      @options = {}
    end

    def run
      opt_parser.parse!(@argv)
      rebuild_logger_if_need
      Runner.new(@options).run
    end

    private

    def rebuild_logger_if_need
      if @options[:log_dev] || @options[:log_level]
        Eve.set_logger(@options[:log_dev], @options[:log_level])
      end
    end

    def opt_parser
      @opt_parser ||= OptionParser.new do |opt|
        opt.on("-t", "--type=VAL") { |v| @options[:type] = v }
        opt.on("-p", "--port=VAL") { |v| @options[:port] = Integer(v) }
        opt.on("-a", "--addr=VAL") { |v| @options[:addr] = v }
        opt.on("--from-file=VAL") { |v| @options[:file_path] = v }
        opt.on("--nodes=VAL", 'like --nodes=127.0.0.1:3001,127.0.0.1:3002') do |v|
          nodes = v.split(",")
          @options[:nodes] = nodes.map { |n| n.split(":") }.map { |addr, port| { addr: addr, port: port.to_i } }
        end

        opt.on("--loglevel=VAL") { |v| @options[:log_level] = v }
        opt.on("--logdev=VAL") { |v| @options[:log_dev] = v }
      end
    end
  end
end
