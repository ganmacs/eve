require 'pathname'
require 'yaml'

module Eve
  class Config
    def initialize(file)
      @file = Pathname.new(file)
    end

    def [](name)
      config[name]
    end

    def merge(opt)
      config.merge(opt)
    end

    private

    def config
      @config ||= begin
        c = load_file
        if c[:nodes]
          c[:nodes] = c[:nodes].map { |n| n.split(":") }.map { |addr, port| { addr: addr, port: port.to_i } }
        end
        c
      end
    end

    def load_file
      raise "#{@file} is not found" unless @file.exist?
      YAML.load(compiled_content)
    end

    def compiled_content
      ERB.new(File.read(@file)).result
    end
  end
end
