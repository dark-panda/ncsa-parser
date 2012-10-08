
$: << File.dirname(__FILE__)
require 'test_helper'

class NCSAParserTests < MiniTest::Unit::TestCase
  include TestHelper

  def test_format_default
    parser = NCSAParser::Parser.new
    parsed = parser.parse_line(LOG_COMBINED)

    assert_equal({
      :host => %{123.123.123.123},
      :ident => %{-},
      :username => %{-},
      :datetime => %{[08/Oct/2012:14:36:07 -0400]},
      :request => %{"GET /path/to/something?foo=bar&hello=world HTTP/1.1"},
      :status => %{200},
      :bytes => %{923},
      :referer => %{"http://www.example.com/referer"},
      :ua => %{"Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.4 (KHTML, like Gecko) Chrome/22.0.1229.79 Safari/537.4"},
      :original => LOG_COMBINED,
    }, parsed.attributes)
  end

  def test_format_common
    parser = NCSAParser::Parser.new(:pattern => NCSAParser::Parser::LOG_FORMAT_COMMON)

    parsed = parser.parse_line(LOG_COMMON)
    assert_equal({
      :host => %{123.123.123.123},
      :ident => %{-},
      :username => %{-},
      :datetime => %{[08/Oct/2012:14:36:07 -0400]},
      :request => %{"GET /path/to/something?foo=bar&hello=world HTTP/1.1"},
      :status => %{200},
      :bytes => %{923},
      :original => LOG_COMMON,
    }, parsed.attributes)
  end

  def test_format_usertrack
    parser = NCSAParser::Parser.new(:pattern => %w{
      host ident username datetime request status bytes referer ua usertrack
    })

    parsed = parser.parse_line(LOG_USERTRACK)

    assert_equal({
      :host => %{123.123.123.123},
      :ident => %{-},
      :username => %{-},
      :datetime => %{[08/Oct/2012:14:36:07 -0400]},
      :request => %{"GET /path/to/something?foo=bar&hello=world HTTP/1.1"},
      :status => %{200},
      :bytes => %{923},
      :referer => %{"http://www.example.com/referer"},
      :ua => %{"Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.4 (KHTML, like Gecko) Chrome/22.0.1229.79 Safari/537.4"},
      :usertrack => %{123.123.123.123.1349718542489266},
      :original => LOG_USERTRACK
    }, parsed.attributes)
  end

  def test_format_deflate
    parser = NCSAParser::Parser.new(:pattern => %w{
      host ident username datetime request status bytes referer ua instream outstream ratio
    })

    parsed = parser.parse_line(LOG_DEFLATE)

    assert_equal({
      :host => %{123.123.123.123},
      :ident => %{-},
      :username => %{-},
      :datetime => %{[08/Oct/2012:14:36:07 -0400]},
      :request => %{"GET /path/to/something?foo=bar&hello=world HTTP/1.1"},
      :status => %{200},
      :bytes => %{923},
      :referer => %{"http://www.example.com/referer"},
      :ua => %{"Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.4 (KHTML, like Gecko) Chrome/22.0.1229.79 Safari/537.4"},
      :instream => %{905},
      :outstream => %{1976},
      :ratio => %{45%},
      :original => LOG_DEFLATE
    }, parsed.attributes)
  end

  def test_format_bad
    parser = NCSAParser::Parser.new

    assert_raises(NCSAParser::BadLogLine) do
      parser.parse_line('what happen')
    end
  end

  def test_open_file
    log = NCSAParser.open('./test/resources/access_log', :pattern => %w{
      host ident username datetime request status bytes referer ua usertrack instream outstream ratio
    })

    expect = {
      :host => %{123.123.123.123},
      :ident => %{-},
      :username => %{-},
      :datetime => %{[08/Oct/2012:14:36:07 -0400]},
      :request => %{"GET /path/to/something?foo=bar&hello=world HTTP/1.1"},
      :status => %{200},
      :bytes => %{923},
      :referer => %{"http://www.example.com/referer"},
      :ua => %{"Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.4 (KHTML, like Gecko) Chrome/22.0.1229.79 Safari/537.4"},
      :usertrack => %{123.123.123.123.1349718542489266},
      :instream => %{905},
      :outstream => %{1976},
      :ratio => %{45%},
      :original => %{123.123.123.123 - - [08/Oct/2012:14:36:07 -0400] "GET /path/to/something?foo=bar&hello=world HTTP/1.1" 200 923 "http://www.example.com/referer" "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.4 (KHTML, like Gecko) Chrome/22.0.1229.79 Safari/537.4" 123.123.123.123.1349718542489266 905 1976 45%}
    }

    log.each do |parsed|
      assert_equal(expect, parsed.attributes)
    end
  end

  def test_token_conversions
    line = %{[08/Oct/2012:14:36:07 -0400] "GET /path/to/something?foo=bar&hello=world HTTP/1.1" "http://www.example.com/referer" 1000 100 10% 123.123.123.123 200 110}

    parser = NCSAParser::Parser.new(:pattern => %w{
      datetime request referer instream outstream ratio host_proxy status bytes
    })

    parsed = parser.parse_line(line)

    assert_equal(DateTime.strptime('[08/Oct/2012:14:36:07 -0400]', '[%d/%b/%Y:%H:%M:%S %Z]'), parsed[:datetime])
    assert_equal(URI.parse('http://www.example.com/path/to/something?foo=bar&hello=world'), parsed[:request_uri])
    assert_equal('/path/to/something', parsed[:request_path])
    assert_equal('GET', parsed[:http_method])
    assert_equal('1.1', parsed[:http_version])
    assert_equal(URI.parse('http://www.example.com/referer'), parsed[:referer_uri])
    assert_equal(0.1, parsed[:ratio])
    assert_equal('123.123.123.123', parsed[:host])
    assert_equal(200, parsed[:status])
    assert_equal(1000, parsed[:instream])
    assert_equal(100, parsed[:outstream])
    assert_equal(110, parsed[:bytes])
  end

  def test_custom_tokens_and_conversion
    parser = NCSAParser::Parser.new(
      :pattern => 'email',

      :tokens => {
        :email => '[^@]+@[^@]+'
      },

      :token_conversions => {
        :email => proc { |match, options|
          URI.parse(match.attributes[:email])
        }
      }
    )

    parsed = parser.parse_line('test@example.com')
    assert_equal(URI.parse('test@example.com'), parsed[:email])
  end

  def test_to_hash
    parser = NCSAParser::Parser.new(:pattern => NCSAParser::Parser::LOG_FORMAT_COMMON)
    parsed = parser.parse_line(LOG_COMMON)

    assert_equal([
      :host, :ident, :username, :datetime, :request, :status, :bytes,
      :original, :request_uri, :request_path, :http_method,
      :http_version, :query_string
    ], parsed.to_hash.keys)
  end
end
