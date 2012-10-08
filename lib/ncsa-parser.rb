
require 'ncsa-parser/version'
require 'ncsa-parser/parser'
require 'ncsa-parser/helper'
require 'ncsa-parser/parsed_line'
require 'ncsa-parser/log'

module NCSAParser
  class << self
    # Opens a log file and iterates through the lines.
    def each_line(log, options = {}, &block)
      self.open(log, options).each(&block)
    end
    alias :foreach :each_line

    # Opens a log file for parsing. This is a convenience method that proxies
    # to NCSAParser::Log.open.
    def open(log, options = {})
      Log.open(log, options)
    end
  end
end
