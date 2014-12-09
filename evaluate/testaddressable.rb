require 'json'
require 'addressable/uri'

constructor_results = []

JSON.parse(File.read('urltestdata.json')).each do |test|
  result = {}

  begin
    uri = Addressable::URI.parse(test['input'])
    uri = Addressable::URI.join(test['base'], uri)
  rescue Addressable::URI::InvalidURIError => e
    result[:exception] =  e.message
    uri = Addressable::URI.parse('')
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

useragent = `gem list addressable`[/addressable \([.\d]+/]+')'

puts JSON.pretty_generate(useragent: useragent, constructor: constructor_results)
