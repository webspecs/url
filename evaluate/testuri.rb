require 'json'
require 'uri'

constructor_results = []

JSON.parse(File.read('urltestdata.json')).each do |test|
  result = {}

  begin
    uri = URI.parse test['input']
    uri = URI.join test['base'], uri
  rescue URI::InvalidURIError, URI::InvalidComponentError => e
    result[:exception] =  e.message
    uri = URI.parse('')
  end

  result.merge!({
    input: test['input'], 
    base: test['base'],
    href: uri.to_s,
    protocol: "#{uri.scheme}:",
    port: uri.port.to_s,
    hostname: uri.host,
    pathname: uri.path
  })

  result[:search] = "?#{uri.query}" unless uri.query.to_s.empty?
  result[:hash] = "##{uri.fragment}" unless uri.fragment.to_s.empty?

  constructor_results << result
end

useragent = `ruby -v`.chomp

puts JSON.pretty_generate(useragent: useragent, constructor: constructor_results)
