#!/usr/bin/ruby

require 'json'
require 'digest/md5'
require 'wunderbar/script'
require 'ruby2js/filter/functions'

_html do
  _link rel: 'stylesheet', href: '../bootstrap.min.css'
  _link rel: 'stylesheet', href: '../analysis.css'
  _style %{
    th, td {padding-left: 1em}
    .fail {background-color: #FFFF00}
    #status {font-size: medium}
    #index tr:hover {color: #428bca; cursor: pointer; text-decoration: underline}
    .navlink:hover {text-decoration: none; cursor: pointer}
  }

  _div.index! do
    _h1! do
      _ 'URL test results'
      _span.status!
    end

    _h3 'Related'
    _ul do
      _li! do
        _ 'Test data: '
        _a 'urltestdata.txt', href: 'https://github.com/w3c/' +
          'web-platform-tests/blob/master/url/urltestdata.txt'
      end
      _li! do
        _ 'Test results: '
        _a 'all', href: 'http://w3c.github.io/test-results/url/all.html'
        _ ', '
        _a 'less than 2 passes', href:
          'http://w3c.github.io/test-results/url/less-than-2.html'
      end
    end

    _table_ do
      _thead do
        _tr do
          _th 'Test'
          _th 'Input'
          _th 'Base'
          _th 'User Agents with differences'
        end
      end

      _tbody do
        _tr do
          _td 'Loading...'
        end
      end
    end
  end

  _div_.detail! do
    _h2_ do
      _a.navlink.left "\u2190"
      _span 'Test'
      _a.navlink.right "\u2192"
    end

    _p!.input! do
      _b 'Input'
      _ ': '
      _span
    end

    _p!.base! do
      _b 'Base'
      _ ': '
      _span
    end

    _h2_ 'Results'
    _table_.results! do
      _thead do
        _tr do
          _th 'Agent'
          _th 'href'
        end
      end
      _tbody
    end

    _h2 'Properties'
    _table_.properties! do
      _thead do
        _tr do
          _th 'Agent'
        end
      end
      _tbody
    end
  end

  _script do
    agents = []
    tests = {}

    PROPERTIES = %w(href protocol hostname port username password pathname
      search hash)

    statusArea = document.getElementById('status')

    def fetch(url)
      xhr = XMLHttpRequest.new()
      def xhr.onreadystatechange()
        self._then(self) if xhr.readyState == 4
      end

      def xhr.then(f)
        @then = f
      end

      def xhr.json()
        return JSON.parse(xhr.responseText)
      end

      xhr.open 'GET', url
      xhr.send nil

      return xhr
    end

    def addCol(tr, name, value, expected)
      element = document.createElement(name)
      element.textContent = value
      tr.appendChild element
      if not expected === undefined
        element.className = ((value || '')== expected ? 'pass' : 'fail')
      end
    end

    navLeft = document.querySelector('a.left')
    navRight = document.querySelector('a.right')

    def findRow(index)
      row = undefined
      tests.each_with_index do |test, i|
        row = i if test.index[0...index.length] == index
      end
      return row
    end

    def detailView(index)
      document.querySelector('#index').style.display = 'none'
      document.querySelector('#detail').style.display = 'block'

      index = findRow(index)

      document.querySelector('#detail h2 span').textContent = "Test #{index}"

      return if index === undefined

      if index > 0
        navLeft.setAttribute('data-index', tests[index-1].index[0..9])
        navLeft.style.display = 'inline'
      else
        navLeft.style.display = 'none'
      end

      if index < tests.length-1
        navRight.setAttribute('data-index', tests[index+1].index[0..9])
        navRight.style.display = 'inline'
      else
        navRight.style.display = 'none'
      end

      rows = []
      test = tests[index]
      refimpl = test.results.refimpl
      document.querySelector('#input span').textContent = refimpl.input
      document.querySelector('#base span').textContent = refimpl.base

      tbody = document.querySelector('#results tbody')
      tbody.removeChild(tbody.firstChild) while tbody.hasChildNodes()
      agents.each do |agent|
        tr = document.createElement('tr')
        addCol tr, 'th', agent
        addCol tr, 'td', test.results[agent].href, refimpl.href || ''
        tbody.appendChild(tr)
      end

      thead = document.querySelector('#properties thead tr')
      thead.removeChild(thead.firstChild) while thead.hasChildNodes()
      addCol thead, 'th', 'Agent'
      visible = []
      PROPERTIES.each do |prop|
        if prop != 'href' and agents.any? {|agent| test.results[agent][prop]}
          visible << prop 
          addCol thead, 'th', prop
        end
      end

      tbody = document.querySelector('#properties tbody')
      tbody.removeChild(tbody.firstChild) while tbody.hasChildNodes()

      agents.each do |agent|
        row = test.results[agent]
        tr = document.createElement('tr')
        addCol tr, 'th', agent
        visible.each do |prop|
          addCol tr, 'td', row[prop], refimpl[prop] || ''
        end
        tbody.appendChild(tr)
      end
    end

    def loadTable()
      document.querySelector('#index').style.display = 'block'
      document.querySelector('#detail').style.display = 'none'

      tbody = document.querySelector('#index tbody')
      tbody.removeChild(tbody.firstChild) while tbody.hasChildNodes()
      for i in 0...tests.length
        tr = document.createElement('tr')
        addCol tr, 'th', i
        addCol tr, 'td', JSON.stringify(tests[i].input)
        addCol tr, 'td', tests[i].base
        addCol tr, 'td', ''
        tr.setAttribute('data-index', tests[i].index[0..9]);
        tr.addEventListener('click') do |event|
          navigate(event.target.parentNode.getAttribute('data-index'))
        end
        tbody.appendChild(tr)
      end
    end

    def navigate(index)
      if not history.state or history.state.index == index
        history.replaceState({index: index}, "index", index)
      else
        history.pushState({index: index}, "index", index)
      end

      if index == ''
        loadTable()
      else
        detailView(index)
      end
    end

    def window.onpopstate(event)
      navigate(event.state ? event.state.index : '')
    end

    def navlink(event)
      navigate(event.target.getAttribute('data-index'))
    end

    document.querySelector('a.left').addEventListener('click', navlink)
    document.querySelector('a.right').addEventListener('click', navlink)

    window.onkeyup = lambda do |event|
      if event.keyCode == 37
        document.querySelector('.navlink.left').click()
      elsif event.keyCode == 38
        loadTable()
      elsif event.keyCode == 39
        document.querySelector('.navlink.right').click()
      end
    end

    firstPage = location.pathname.split('/').slice(-1)[0]

    def fetchAgents(list, index)
      if list.length
        agent = list.shift()
        statusArea.textContent = "... loading #{agent}"
        fetch("../useragent-results/#{agent}").then do |response|
          response.json().constructor.each do |result|
            index["#{result.input} #{result.base}"].results[agent] = result
          end
          fetchAgents(list, index)
        end
      else
        statusArea.style.display = 'none'
        navigate(firstPage) if firstPage != ''
      end
    end

    statusArea.textContent = "... loading index"
    fetch("../useragent-results/index").then do |response|
      json = response.json()
      tests = json.tests
      agents = json.agents

      index = {}
      tests.each do |test|
        index["#{test.input} #{test.base}"] = test
        test.results = {}
      end

      navigate('') if firstPage == ''
      fetchAgents(agents.slice(), index)
    end
  end
end
