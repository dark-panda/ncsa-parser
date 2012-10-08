
require 'uri'
require 'date'
require 'cgi'

module NCSAParser
  class BadLogLine < Exception
    def initialize(line, pattern)
      super("Bad log line. Pattern: |#{pattern.join(' ')}| Line: |#{line}|")
    end
  end

  class Parser
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
      :usertrack => "(?:#{IP_ADDRESS})[^ ]+|-",
      :outstream => '\d+|-',
      :instream => '\d+|-',
      :ratio => '\d+%|-%'
    }

    LOG_FORMAT_COMMON = %w{
      host ident username datetime request status bytes
    }

    LOG_FORMAT_COMBINED = %w{
      host ident username datetime request status bytes referer ua
    }

    attr_reader :pattern, :matcher, :re

    # Creates a new Parser object.
    #
    # == Options
    #
    # * +:domain+ - when parsing query strings, use this domain as the URL's
    #   domain. The default is +"www.example.com"+.
    # * +:datetime_format+ - sets the datetime format for when tokens are
    #   converted in NCSAParser::ParsedLine. The default is +"[%d/%b/%Y:%H:%M:%S %Z]"+.
    # * +:pattern+ - the default log line format to use. The default is
    #   +LOG_FORMAT_COMBINED+, which matches the "combined" log format in
    #   Apache. The value for +:pattern+ can be either a space-delimited
    #   String of token names or an Array of token names.
    # * +:browscap+ - a browser capabilities object to use when sniffing out
    #   user agents. This object should be able to respond to the +query+
    #   method. Several browscap extensions are available for Ruby, and the
    #   the author of this extension's version is called Browscapper and is
    #   available at https://github.com/dark-panda/browscapper .
    # * +:token_conversions+ - converters to pass along to the line parser.
    #   See NCSAParser::ParsedLine for details.
    # * +:tokens+ - tokens to add to the generated Regexp.
    def initialize(options = {})
      options = {
        :domain => 'www.example.com',
        :datetime_format => '[%d/%b/%Y:%H:%M:%S %Z]',
        :pattern => LOG_FORMAT_COMBINED
      }.merge(options)

      @options = options
      @pattern = if options[:pattern].is_a?(Array)
        options[:pattern]
      else
        options[:pattern].to_s.split(/\s+/)
      end

      @re = '^' + @pattern.collect { |tk|
        tk = tk.to_sym
        token = if options[:tokens] && options[:tokens][tk]
          options[:tokens][tk]
        elsif TOKENS[tk]
          TOKENS[tk]
        else
          raise ArgumentError.new("Token :#{tk} not found!")
        end

        "(#{token})"
      }.join(' ') + '$'
      @matcher = Regexp.new(@re)
    end

    # Parses a single line and returns an NCSAParser::ParsedLine object.
    def parse_line(line)
      match = Hash.new
      if md = @matcher.match(line)
        @pattern.each_with_index do |k, j|
          match[k.to_sym] = md[j + 1]
        end
        match[:original] = line.strip
      else
        raise BadLogLine.new(line, @options[:pattern])
      end
      ParsedLine.new(match, @options)
    end
    alias :parse :parse_line
  end
end
