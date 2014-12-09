#!/usr/bin/ruby

require 'json'
require 'digest/md5'
require 'wunderbar/script'
require 'ruby2js/filter/functions'

agents = {
  refimpl: {hash: 'refimpl'},
  addressable: {hash: 'addressable'},
  chrome: {hash: 'chrome'},
  firefox: {hash: 'firefox'},
  galimatias: {hash: 'galimatias'},
  ie: {hash: 'ie'},
  nodejs: {hash: 'nodejs'},
  opera: {hash: 'opera'},
  perl: {hash: 'perl'},
  rust: {hash: 'rusturl'},
  safari: {hash: 'safari'},
}

results = {}
agents.keys.each do |agent|
  hash = agents[agent][:hash]
  File.open("useragent-results/#{hash}") do |file|
    json = JSON.parse(file.read)
    agents[agent][:useragent] = json['useragent']
    json['constructor'].each do |result|
      hash = Digest::MD5.hexdigest("#{result['input']}|#{result['base']}")
      results[hash] ||= {}
      results[hash][agent] = result

      if agent == :refimpl
        result['protocol'] = "#{result.delete('scheme')}:" if result['scheme']
        result['hostname'] = result.delete('host') if result['host']
        result['pathname'] = result.delete('path') if result['path']
        result.delete('query')
        result.delete('fragment')
      end
    end
  end
end

master_results = results

COLS = %w(href protocol hostname port username password pathname search hash)
def evaluate(row)
  copy = row.dup
  copy.delete(:refimpl)
  results = row.values.first.merge Hash[COLS.map { |col|
    max = copy.map {|agent, row| row[col]}.group_by(&:to_s).values.
      max_by(&:length)
    [col, (max.length > row.length/2 ? max.first.to_s : nil)]
  }]
end

_html do
  _link rel: "stylesheet", href: "../style.css"

  query = (ENV['QUERY_STRING'] ? "?#{ENV['QUERY_STRING']}" : '')
  browser_only = (query == '?browsers')

  results = {}
  master_results.each do |key, value|
    if browser_only
      value = value.dup
      value.keys.each do |key|
        unless %(refimpl chrome firefox ie safari).include? key.to_s
          value.delete key 
        end
      end
    end
    results[key] = value.dup
  end

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
        refimpl = results[:refimpl]
        consensus = evaluate(results)
        if consensus.values.any? {|value| value.nil?}
          klass = 'open'
        elsif refimpl.any? {|prop, value| consensus[prop] != value.to_s}
          klass = 'problem'
        elsif addressable and addressable.any? {|prop, value| consensus[prop] != value.to_s}
          klass = 'diff'
        else
          klass = 'good'
          if browser_only
              results.each do |agent, row|
                next if agent.to_s == 'refimpl'
                next if agent == :addressable
                COLS.each do |col|
                  if row[col].to_s != consensus[col].to_s
                    klass = 'diff'
                  end
                end
              end
            end
        end

        _tr_ class: klass do
          _td index
          _td do
            _a refimpl['input'].inspect, href: key[0..9] + query
          end
          _td do
            _a refimpl['base'], href: key[0..9] + query
          end
          _td do
            if klass == 'diff' or not browser_only
              results.each do |agent, row|
                next if agent.to_s == 'refimpl'
                next if agent == :addressable and browser_only
                if COLS.all? {|col| row[col].to_s != consensus[col].to_s}
                  _em 'no consensus'
                else
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
      end
    end

    _h2 'Legend'

    _ul do
      if browser_only
        _li.problem 'No agreement, i.e., no single set of values matches ' +
          'the majority of implementations'
        _li.diff "One or more browsers don't match the spec"
        _li.good "All browsers match the spec"
      else
        _li.problem 'No agreement, i.e., no single set of values matches ' +
          'the majority of implementations'
        _li.open "Agreement doesn't match expected test results " +
          "(and therefore, likely, WHATWG's URL Standard)"
        _li.diff "Agreement doesn't match addressable's results "+
          "(and therefore, likely, IETF RFC 3986+3987)"
        _li.good "Agreement matches test results and addressable"
      end
    end
  else
    path = _.path_info.to_s[/\w+/]
    row = results[results.keys.find {|key| key.start_with? path}]
    if row and row[:refimpl]
      _title row[:refimpl]['input'].inspect

      cols = []
      row.each do |agent, data|
        data.each do |key, value| 
          next if %w(input base).include? key
          cols << key unless cols.include? key or not value or value.to_s.empty?
        end
      end

      consensus = evaluate(row)

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
        input = row[:refimpl]['input'].inspect
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
        _": #{row[:refimpl]['base'].inspect}"
      end

      _h2_ 'Results'
      _table_ do
        _tr do
          _th 'agent'
          _th 'href'
          _th.exception 'exception' if cols.include? 'exception'
        end
        row.each do |agent, data|
          next if agent == :addressable and browser_only
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
                if data['exception_extension']
                  _td.exception title: 'not defined in WHATWG spec' do
                    _em data['exception']
                  end
                else
                  _td.exception data['exception']
                end
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
