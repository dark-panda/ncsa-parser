
module NCSAParser
  module Helper
    def self.clean_uri(uri)
      uri.
        gsub(/ /, '+').
        gsub(/\\"/, '%22').
        gsub(/,/, '%2C')
    end

    def self.deep_symbolize_keys(hash)
      hash.inject({}) do |memo, (key, value)|
        key = key.to_sym if key.respond_to?(:to_sym) rescue :nil
        value = NCSAHelper.deep_symbolize_keys(value) if value.is_a?(Hash)
        memo[key] = value
        memo
      end
    end
  end
end
