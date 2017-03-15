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
      Runner.new(@options).run
    end

    private

    def opt_parser
      @opt_parser ||= OptionParser.new do |opt|
        opt.on("-t", "--type=VAL") { |v| @options[:type] = v }
        opt.on("-p", "--port=VAL") { |v| @options[:port] = Integer(v) }
        opt.on("-a", "--addr=VAL") { |v| @options[:addr] = v }

        opt.on("--loglevel=VAL") { |v| @options[:log_level] = v }
        opt.on("--logdev=VAL") { |v| @options[:log_dev] = v }
      end
    end
  end
end
