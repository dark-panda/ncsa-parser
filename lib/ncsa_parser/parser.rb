
require 'uri'
require 'date'
require 'cgi'

module NCSAParser
  class BadLogLine < Exception
    def initialize(line)
      super("Bad log line |#{line.strip}|")
    end
  end

  class Parser
    include Enumerable

    IP_ADDRESS = '\d+\.\d+\.\d+\.\d+|unknown'

    TOKENS = {
      :host => "(?:#{IP_ADDRESS}|-|::1)",
      :host_proxy => "(?:#{IP_ADDRESS})(?:,\\s+#{IP_ADDRESS})*|-",
      :ident => '[^\s]+',
      :username => '[^\s]+',
      :datetime => '\[[^\]]+\]',
      :request => '".+"',
      :status => '\d+',
      :bytes => '\d+|-',
      :referer => '".*"',
      :ua => '".*"',
      :usertrack => "#{IP_ADDRESS}|-",
      :outstream => '\d+|-',
      :instream => '\d+|-',
      :ratio => '\d+%|-%'
    }

    attr_reader :matcher

    def initialize(log, pattern = %w{ host ident username datetime request status bytes referer ua }, options = {})
      options = {
        :domain => 'www.example.com',
        :datetime_format => '[%d/%b/%Y:%H:%M:%S %Z]',
        :browscap => nil
      }.merge(options)

      @log, @pattern, @options = log, pattern, options
      @re = '^' + @pattern.collect { |tk|
        "(#{TOKENS[tk.to_sym]})"
      }.join(' ') + '$'
      @matcher = Regexp.new(@re)
    end

    def parse_line(line, i = 0)
      match = Hash.new
      if md = @matcher.match(line)
        @pattern.each_with_index do |k, j|
          match[k.to_sym] = md[j + 1]
        end
        match[:original] = line
      else
        raise BadLogLine.new(line)
      end
      ParsedLine.new(match, @options)
    end

    def each
      @log.each_with_index do |l, i|
        yield self.parse_line(l, i)
      end
    end

    def next_line
      parsed = self.parse_line(@log.gets)
      if block_given?
        yield parsed
      else
        parsed
      end
    end
  end
end
