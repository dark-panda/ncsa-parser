
module NCSAParser
  class ParsedLine
    TOKEN_CONVERSIONS = {
      :datetime_parsed => proc { |match, options|
        DateTime.strptime(match[:datetime], options[:datetime_format])
      },

      :request_uri => proc { |match, options|
        begin
          URI.parse("http://#{options[:domain]}#{match[:request_path]}")
        rescue
        end
      },

      :http_method => proc { |match, options|
        match[:request].scan(/^"([A-Z]+)/) rescue nil
      },

      :request_path => proc { |match, options|
        NCSAParser::Helper.clean_uri(match[:request].split(' ')[1]) rescue nil
      },

      :request_http_version => proc { |match, options|
        match[:request].scan(/(\d\.\d)"$/) rescue nil
      },

      :query_string => proc { |match, options|
        if match[:request_uri] && match[:request_uri].query
          CGI.parse(match[:request_uri].query)
        else
          Hash.new
        end
      },

      :referer_uri => proc { |match, options|
        if match[:referer] != '"-"'
          referer = match[:referer].sub(/^"(.+)"$/, '\1')
          NCSAParser::Helper.clean_uri(referer)

          begin
            URI.parse(referer)
          rescue
          end
        else
          '-'
        end
      },

      :browscap => proc { |match, options|
        options[:browscap].match(match[:ua].sub(/^"(.+)"$/, '\1')) if options[:browscap]
      }
    }

    %w{ status instream outstream bytes }.each do |field|
      class_eval(<<-EOF, __FILE__, __LINE__ + 1)
        TOKEN_CONVERSIONS[:#{field}] = proc { |match, options|
          match.attributes[:#{field}].to_i rescue nil
        }
      EOF
    end

    attr_reader :attributes

    def initialize(attributes, options = {})
      @attributes, @options = attributes, options
      @parsed_attributes = {}
    end

    def [](key)
      key = key.to_sym unless key.is_a?(Symbol)

      if @parsed_attributes.has_key?(key)
        @parsed_attributes[key]
      elsif TOKEN_CONVERSIONS[key]
        @parsed_attributes[key] = TOKEN_CONVERSIONS[key].call(self, @options)
      else
        @attributes[key]
      end
    end

    def to_hash
      TOKEN_CONVERSIONS.each { |t, v| self[t] }
      @attributes
    end
  end
end
