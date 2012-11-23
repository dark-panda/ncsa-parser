
require 'rubygems'
require 'minitest/autorun'

if RUBY_VERSION >= '1.9'
  require 'minitest/reporters'
end

require File.join(File.dirname(__FILE__), %w{ .. lib ncsa-parser })

puts "NCSAParser version #{NCSAParser::VERSION}"

module TestHelper
  LOG_COMMON = %{123.123.123.123 - - [08/Oct/2012:14:36:07 -0400] "GET /path/to/something?foo=bar&hello=world HTTP/1.1" 200 923}

  LOG_COMBINED = %{123.123.123.123 - - [08/Oct/2012:14:36:07 -0400] "GET /path/to/something?foo=bar&hello=world HTTP/1.1" 200 923 "http://www.example.com/referer" "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.4 (KHTML, like Gecko) Chrome/22.0.1229.79 Safari/537.4"}

  LOG_USERTRACK = %{123.123.123.123 - - [08/Oct/2012:14:36:07 -0400] "GET /path/to/something?foo=bar&hello=world HTTP/1.1" 200 923 "http://www.example.com/referer" "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.4 (KHTML, like Gecko) Chrome/22.0.1229.79 Safari/537.4" 123.123.123.123.1349718542489266}

  LOG_DEFLATE = %{123.123.123.123 - - [08/Oct/2012:14:36:07 -0400] "GET /path/to/something?foo=bar&hello=world HTTP/1.1" 200 923 "http://www.example.com/referer" "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.4 (KHTML, like Gecko) Chrome/22.0.1229.79 Safari/537.4" 905 1976 45%}
end

if RUBY_VERSION >= '1.9'
  MiniTest::Reporters.use!(MiniTest::Reporters::SpecReporter.new)
end

