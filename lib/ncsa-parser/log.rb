
module NCSAParser
  class Log
    include Enumerable

    attr_reader :log, :parser

    def initialize(log, options = {})
      @log = log
      @parser = Parser.new(options)
    end

    def self.open(file, options = {})
      file = if file.is_a?(String)
        File.open(file)
      else
        file
      end

      self.new(file, options)
    end

    def each
      log.rewind

      if block_given?
        self.log.each do |l|
          yield self.parser.parse_line(l)
        end
      else
        self.log.collect do |l|
          self.parser.parse_line(l)
        end
      end
    end

    def next_line
      self.parser.parse_line(self.log.gets).tap { |parsed|
        yield parsed if block_given?
      }
    end
  end
end
