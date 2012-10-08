
module NCSAParser
  # NCSAParser::ParsedLine handles some token conversions and the like on the
  # fly after a successful line parse. You can add your own token conversions
  # or override existing ones by passing along a +:token_conversions+ option
  # that contains converters in the same manner as those found in
  # NCSAParser::ParsedLine::TOKEN_CONVERSIONS.
  #
  # To access a parsed value without any sort of token conversion, use the
  # +attributes+ method. The +[]+ method will perform the token conversion
  # on the fly for you.
  #
  # For token converters that handle URIs, the Symbol :bad_uri will be returned
  # if the URI parser fails for whatever reason.
  class ParsedLine
    TOKEN_CONVERSIONS = {
      :datetime => proc { |match, options|
        DateTime.strptime(match.attributes[:datetime], options[:datetime_format])
      },

      :request_uri => proc { |match, options|
        begin
          request = match.attributes[:request].scan(/^"[A-Z]+ (.+) HTTP\/\d+\.\d+"$/).flatten[0]
          URI.parse("http://#{options[:domain]}#{request}")
        rescue
          :bad_uri
        end if match.attributes[:request]
      },

      :request_path => proc { |match, options|
        match.attributes[:request].scan(/^"[A-Z]+ ([^?]+)/).flatten[0] rescue nil if match.attributes[:request]
      },

      :http_method => proc { |match, options|
        match.attributes[:request].scan(/^"([A-Z]+)/).flatten[0] rescue nil if match.attributes[:request]
      },

      :http_version => proc { |match, options|
        match.attributes[:request].scan(/(\d+\.\d+)"$/).flatten[0] rescue nil if match.attributes[:request]
      },

      :query_string => proc { |match, options|
        if match[:request_uri]
          if match[:request_uri] && match[:request_uri].query
            CGI.parse(match[:request_uri].query)
          else
            Hash.new
          end
        end
      },

      :referer_uri => proc { |match, options|
        if match[:referer]
          if match[:referer] != '"-"'
            referer = match[:referer].sub(/^"(.+)"$/, '\1')
            NCSAParser::Helper.clean_uri(referer)

            begin
              URI.parse(referer)
            rescue
              :bad_uri
            end
          else
            '-'
          end
        end
      },

      :browscap => proc { |match, options|
        options[:browscap].query(match[:ua].sub(/^"(.+)"$/, '\1')) if options[:browscap]
      },

      :ratio => proc { |match, options|
        match.attributes[:ratio].to_f / 100 rescue nil if match.attributes[:ratio]
      },

      :host => proc { |match, options|
        if match.attributes[:host]
          match.attributes[:host]
        elsif match.attributes[:host_proxy]
          match.attributes[:host_proxy].split(',')[0].strip
        end
      }
    }

    %w{ status instream outstream bytes }.each do |field|
      class_eval(<<-EOF, __FILE__, __LINE__ + 1)
        TOKEN_CONVERSIONS[:#{field}] = proc { |match, options|
          match.attributes[:#{field}].to_i rescue nil if match.attributes[:#{field}]
        }
      EOF
    end

    attr_reader :attributes

    def initialize(attributes, options = {})
      @attributes, @options = attributes, options
      @parsed_attributes = {}

      if options[:browscap] && !options[:browscap].respond_to?(:query)
        raise ArgumentError.new("The :browscap object should respond to the #query method.")
      end
    end

    # Accesses either an attribute or an attribute that has been passed
    # through a token converter. You can access the raw, unconverted attributes
    # via the +attributes+ method. If a converter fails for whatever reason,
    # a value of +:bad_conversion+ is returned.
    def [](key)
      key = key.to_sym unless key.is_a?(Symbol)

      if @parsed_attributes.has_key?(key)
        @parsed_attributes[key]
      elsif @options[:token_conversions] && @options[:token_conversions][key]
        @parsed_attributes[key] = @options[:token_conversions][key].call(self, @options)
      elsif TOKEN_CONVERSIONS[key]
        @parsed_attributes[key] = (TOKEN_CONVERSIONS[key].call(self, @options) rescue :bad_conversion)
      else
        @attributes[key]
      end
    end

    # Gathers up the requested attributes and spits them out into a Hash.
    # The +values+ argument determines what gets inserted into the Hash:
    #
    # * +:all+ - both attributes and parsed attributes. In cases where
    #   the values share the same names, the parsed attribute wins out.
    # * +:attributes+ - unparsed attributes only.
    # * +:parsed+ - parsed attributes only.
    #
    # The default value is +:all+. Any +nil+ values are automatically stripped
    # from the Hash.
    def to_hash(values = :all)
      retval = {}

      if values == :all || values == :attributes
        retval.merge!(@attributes)
      end

      if values == :all || values == :parsed
        TOKEN_CONVERSIONS.each { |t, v| self[t] }
        retval.merge!(@parsed_attributes)
      end

      retval.reject! { |k, v|
        v.nil?
      }

      retval
    end
  end
end
