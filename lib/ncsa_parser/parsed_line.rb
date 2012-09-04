
module NCSAParser
  class ParsedLine
    TOKEN_CONVERSIONS = {
      :datetime => proc { |match, options|
        DateTime.strptime(match.attributes[:datetime], options[:datetime_format])
      },

      :request_uri => proc { |match, options|
        begin
          request = match[:request].scan(/^"[A-Z]+ (.+) HTTP\/\d+\.\d+"$/).flatten[0]
          URI.parse("http://#{options[:domain]}#{request}")
        rescue
        end
      },

      :request_path => proc { |match, options|
        match[:request].scan(/^"[A-Z]+ ([^?]+)/).flatten[0] rescue nil
      },

      :http_method => proc { |match, options|
        match[:request].scan(/^"([A-Z]+)/).flatten[0] rescue nil
      },

      :http_version => proc { |match, options|
        match[:request].scan(/(\d+\.\d+)"$/).flatten[0] rescue nil
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
      },

      :ratio => proc { |match, options|
        match.attributes[:ratio].to_f / 100 rescue nil
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
