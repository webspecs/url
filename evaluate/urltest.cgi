#!/usr/bin/ruby

require 'wunderbar/script'
require 'ruby2js/filter/functions'
require 'ruby2js/filter/jquery'

_html do
  _base.base! href: ''
  _script src: "//ajax.googleapis.com/ajax/libs/jquery/2.1.1/jquery.min.js"

  _p.status! 'Loading'
  _pre.results!

  _a.a! style: 'display: none'
  
  _script_ do
    url = null

    # polyfill URL interface for older browsers
    begin
      new URL(location.href)
    rescue => e
      docbase = document.getElementById('base')
      a = document.getElementById('a')
      def this.URL(url, base)
        docbase.setAttribute('href', base)
        a.setAttribute('href', url)
        return a
      end
    end

    def runTests(testdata, settests)
      constructor_results = []
      for i in 0...testdata.length
        results = {
          input: testdata[i].input,
          base: testdata[i].base
        }

        begin
          url = URL.new(results.input, results.base)
        rescue => error
          results.exception = error.message
          url = {href: results.input, protocol: ':'}
        end

        %w(
          href protocol username password hostname port pathname search hash
        ).forEach do |property|
          begin
            results[property] = url[property]
          rescue => error
            results["#{property}-exception"] = error.message
          end
        end

        constructor_results << results
      end

      for attr in settests
        tests = settests[attr]
        for i in 0...tests.length
          url = URL.new(tests[i].url)
          begin
            url[attr] = tests[i].value
          rescue => e
            tests[i].tests['exception'] = (e.message || e.toString())
            url = {protocol: ':'}
          end

          for prop in tests[i].tests
            next if prop == 'exception'
            begin
              tests[i].tests[prop] = url[prop]
            rescue => e
              tests[i].tests.delete(prop)
              tests[i].tests[prop + '_exception'] = (e.message || e.toString())
            end
          end
        end
      end

      return {constructor: constructor_results, setters: settests}
    end

    ~'#status'.text('Downloading test data')
    $$.getJSON('urltestdata.json') do |testdata|
      $$.getJSON('urlsettest.json') do |settests|
        ~'#status'.text('Running tests')

        results = runTests(testdata, settests)

        ~'#status'.text('Posting results')
        $$.post('', results: JSON.stringify(results, null, 2)) do |response|
          results = {
            useragent: response.useragent,
            constructor: results.constructor,
            setters: results.setters
          }

          ~'#status'.text("Test complete, ticket: #{response.ticket}")
          ~'#results'.text(JSON.stringify(results, null, 2))
        end
      end
    end
  end
end

_json do
  ticket = Digest::MD5.
    hexdigest "#{ENV['HTTP_USER_AGENT']}:#{ENV['REMOTE_ADDR']}:#{Time.now}"

  File.open("useragent-results/#{ticket}", 'w') do |file|
    results = {useragent: ENV['HTTP_USER_AGENT']}.merge(JSON.parse(@results))
    file.puts JSON.pretty_generate(results)
  end

  _useragent ENV['HTTP_USER_AGENT']
  _ticket ticket
end
