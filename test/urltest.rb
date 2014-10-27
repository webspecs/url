fs = require('fs')
punycode = require('../reference-implementation/punycode')

eval fs.readFileSync('reference-implementation/url.js', 'utf8')
eval fs.readFileSync('reference-implementation/urlparser.js', 'utf8')

eval fs.readFileSync('test/urltestparser.js', 'utf8').
  gsub ': { get:', ': { enumerable: true, get:'

properties = %w(href protocol username password hostname port pathname search hash)

data = URLTestParser(fs.readFileSync('test/urltestdata.txt', 'utf8'))
for i in 0...data.length
  test = data[i]

  url = Url.new(test.input, test.base)
  test.pathname ||= test.path
  test.hostname ||= test.host

  test.input = input = test.input.trim()

  if properties.any? {|prop| url[prop] != test[prop]}
    console.log "test #{i} failed\n"

    console.log "input: #{JSON.stringify(test.input)}"
    console.log "base: #{JSON.stringify(test.base)}\n"
    test.delete('input')
    test.delete('base')

    console.log "expected: #{JSON.stringify(test)}\n"
    console.log "found: #{JSON.stringify(url)}\n"

    console.log "differences:"
    test.input = input
    properties.each do |prop| 
      console.log [prop, test[prop], url[prop]] if url[prop] != test[prop]
    end

    process.exit 1
  end
end

console.log "all tests pass"
