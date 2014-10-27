#!/usr/bin/ruby

require 'json'
require 'digest/md5'
require 'wunderbar/script'
require 'ruby2js/filter/functions'
require 'addressable/uri'

agents = {
  testdata: {hash: 'urltestdata'},
  addressable: {useragent: `gem list addressable`[/addressable \([.\d]+/]+')'},
  chrome: {hash: '2f6730706a88b036565b5eca96b40729'},
  firefox: {hash: 'd4e719d65f63275e8aa91bd295892f2d'},
  galimatias: {hash: 'galimatias'},
  ie: {hash: 'd65a99eb15239dfde051e93a6eb2fe9a'},
  nodejs: {hash: 'nodejs'},
  opera: {hash: '17517deeacb22b7a8cb672cb1402e760'},
  rust: {hash: 'rusturl'},
  safari: {hash: '9691361d0617dfb893d3c8c238fcd16f'},
}

results = {}
agents.keys.each do |agent|
  next if agent == :addressable

  File.open("useragent-results/#{agents[agent][:hash]}") do |file|
    hash = file.gets
    agents[agent][:useragent] = file.gets
    JSON.parse(file.gets).each do |result|
      hash = Digest::MD5.hexdigest("#{result['input']}|#{result['base']}")
      results[hash] ||= {}
      results[hash][agent] = result

      if agent == :testdata
        result['protocol'] = "#{result.delete('scheme')}:" if result['scheme']
        result['hostname'] = result.delete('host') if result['host']
        result['pathname'] = result.delete('path') if result['path']
        result.delete('query')
        result.delete('fragment')

        input,base = result['input'],result['base']
        result = {}
        begin
          uri = Addressable::URI.parse(input)
          uri = Addressable::URI.join(base, uri)
        rescue Addressable::URI::InvalidURIError => e
          result['exception'] =  e.message
          uri = Addressable::URI.parse('')
        end

        result['href'] = uri.to_s
        result['protocol'] = "#{uri.scheme}:"
        result['port'] = uri.port.to_s
        result['hostname'] = uri.host
        result['pathname'] = uri.path
        result['search']   = "?#{uri.query}" unless uri.query.to_s.empty?
        result['hash']     = "##{uri.fragment}" unless uri.fragment.to_s.empty?

        results[hash][:addressable] = result
      end
    end
  end
end

COLS = %w(href protocol hostname port username password pathname search hash)
def evaluate(row)
  copy = row.dup
# copy.delete(:testdata)
  row.values.first.merge Hash[COLS.map { |col|
    max = copy.map {|agent, row| row[col]}.group_by(&:to_s).values.
      max_by(&:length)
    [col, (max.length > row.length/2 ? max.first.to_s : nil)]
  }]
end

_html do
  _link rel: "stylesheet", href: "../style.css"

  if _.path_info == '/'
    _h1 'URL test results'
    _table? do
      _tr do
        _th 'Test'
        _th 'Input'
        _th 'Base'
        _th 'User Agents with differences'
      end

      results.each_with_index do |(key, results), index|
        addressable = results[:addressable]
        testdata = results[:testdata]
        consensus = evaluate(results)
        if consensus.values.any? {|value| value.nil?}
          klass = 'open'
        elsif testdata.any? {|prop, value| consensus[prop] != value.to_s}
          klass = 'problem'
        elsif addressable.any? {|prop, value| consensus[prop] != value.to_s}
          klass = 'diff'
        else
          klass = 'good'
        end

        _tr_ class: klass do
          _td index
          _td do
            _a testdata['input'].inspect, href: key[0..9]
          end
          _td do
            _a testdata['base'], href: key[0..9]
          end
          _td do
            results.each do |agent, row|
              COLS.each do |col|
                if row[col].to_s != consensus[col].to_s
                  _ agent
                  break
                end
              end
            end
          end
        end
      end
    end

    _h2 'Legend'

    _ul do
      _li.problem 'No agreement, i.e., no single set of values matches ' +
        'the majority of implementations'
      _li.open "Agreement doesn't match expected test results " +
        "(and therefore, likely, WHATWG's URL Standard)"
      _li.diff "Agreement doesn't match addressable's results "+
        "(and therefore, likely, IETF RFC 3986+3987)"
      _li.good "Agreement matches test results and addressable"
    end
  else
    path = _.path_info.to_s[/\w+/]
    row = results[results.keys.find {|key| key.start_with? path}]
    if row and row[:testdata]
      _title row[:testdata]['input'].inspect

      cols = []
      row.each do |agent, data|
        data.each do |key, value| 
          next if %w(input base).include? key
          cols << key unless cols.include? key or not value or value.to_s.empty?
        end
      end

      consensus = Hash[cols.map { |col|
        max = row.map {|agent, row| row[col]}.group_by(&:to_s).values.
          max_by(&:length)
        [col, (max.length > row.length/2 ? max.first.to_s : nil)]
      }]

      _h2_ do
        index = results.values.index(row)
        if index and index>0
          _a.navlink.left "\u2190", href: results.keys[index-1][0..9]
        end
        _ "Test #{index}"
        if index and index<results.keys.length-1
          _a.navlink.right "\u2192", href: results.keys[index+1][0..9]
        end
      end

      _p! do
        _b "Input"
        input = row[:testdata]['input'].inspect
        _ ": #{input}"
        if input =~ /[^\x20-\x7E]/
          input.gsub! /[^\x20-\x7E]/  do |c| 
            "\\u#{c.ord.to_s(16).upcase.rjust(4,'0')}"
          end
          _ " (#{input})"
        end
      end
      _p! do
        _b "Base"
        _": #{row[:testdata]['base'].inspect}"
      end

      _h2_ 'Results'
      _table_ do
        _tr do
          _th 'agent'
          _th 'href'
          _th.exception 'exception' if cols.include? 'exception'
        end
        row.each do |agent, data|
          _tr do
            _th agent.to_s

            if data['href-exception']
              _td.exception data["href-exception"]
            elsif data['href'].to_s != consensus['href'].to_s or consensus['href'].nil?
              _td.diff data['href']
            else
              _td data['href']
            end

            if cols.include? 'exception'
              if data.include? 'exception' and data['exception']
                _td.exception data['exception']
              else
                _td
              end
            end
          end
        end
      end

      cols = %w(protocol username password hostname port pathname search hash).
        select {|name| cols.include? name}

      _h3_ 'Properties'
      _table do
        _tr do
          _th 'agent'
          cols.each do |col| 
            _th col, class: ('exception' if col == 'exception')
          end
        end
        row.each do |agent, data|
          _tr_ do
            _th agent.to_s
            cols.each do |col| 
              if data["#{col}-exception"]
                _td data["#{col}-exception"], class: 'exception'
              elsif data[col].to_s != consensus[col].to_s or consensus[col].nil?
                _td.diff data[col]
              else
                _td data[col]
              end
            end
          end
        end
      end

      _h2_ 'User Agents'
      agents.each do |agent, info|
        _p! do
          _b agent.to_s
          _ ": "
          _code info[:useragent].chomp
        end
      end

      _script_ do
        window.onkeyup = lambda do |event|
          link = null

          if event.keyCode == 37
            link = document.querySelector('.navlink.left')
          elsif event.keyCode == 38
            window.location.href.sub! /\w+$/, ''
          elsif event.keyCode == 39
            link = document.querySelector('.navlink.right')
          end

          link.click() if link
        end
      end

    else
      _p 'not found'
    end
  end
end

_json do
  _agents agents
  _results results
end
