#!/usr/bin/ruby

require 'wunderbar/script'
require 'ruby2js/filter/jquery'

_html do
  _base.base! href: ''
  _script src: "//ajax.googleapis.com/ajax/libs/jquery/2.1.1/jquery.min.js"

  _p.status! 'Loading'
  _p.useragent!
  _p.ticket!

  _a.a! style: 'display: none'
  
  _script_ do
    base = document.getElementById('base')
    a = document.getElementById('a')

    ~'#status'.text('Downloading test data')
    $$.getJSON('urltestdata.json') do |testdata|
      ~'#status'.text('Running tests')
      all_results = []
      for i in 0...testdata.length
        results = {
          input: testdata[i].input,
          base: testdata[i].base,
        }

        begin
          base.setAttribute('href', testdata[i].base)
          a.setAttribute('href', testdata[i].input)
        rescue => error
          results.exception = error.message
        end

        %w(
          href protocol username password hostname port pathname search hash
        ).forEach do |property|
          begin
            results[property] = a[property]
          rescue => error
            results["#{property}-exception"] = error.message
          end
        end

        all_results << results
      end
      ~'#status'.text('Posting results')
      $$.post('', results: JSON.stringify(all_results)) do |response|
        ~'#status'.text('Test complete')
        ~'#ticket'.text(response.ticket)
        ~'#useragent'.text(response.useragent)
      end
    end
  end
end

_json do
  ticket = Digest::MD5.
    hexdigest "#{ENV['HTTP_USER_AGENT']}:#{ENV['REMOTE_ADDR']}:#{Time.now}"

  File.open("useragent-results/#{ticket}", 'w') do |file|
    file.puts ticket
    file.puts ENV['HTTP_USER_AGENT']
    file.puts @results
  end

  _useragent ENV['HTTP_USER_AGENT']
  _ticket ticket
end
