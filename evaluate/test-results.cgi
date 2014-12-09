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
          _th 'href'
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
    results = {}

    AGENTS = %w(refimpl chrome firefox galimatias ie nodejs opera perl
      rusturl safari)
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

    def detailView(index)
      document.querySelector('#index').style.display = 'none'
      document.querySelector('#detail').style.display = 'block'
      document.querySelector('#detail h2 span').textContent = "Test #{index}"

      navLeft.setAttribute('data-index', index-1)
      navRight.setAttribute('data-index', index+1)

      rows = []
      refimpl = results.refimpl.constructor[index]
      document.querySelector('#input span').textContent = refimpl.input
      document.querySelector('#base span').textContent = refimpl.base

      tbody = document.querySelector('#results tbody')
      tbody.removeChild(tbody.firstChild) while tbody.hasChildNodes()
      AGENTS.forEach do |agent|
        row = rows[agent] = results[agent].constructor[index]
        tr = document.createElement('tr')
        addCol tr, 'th', agent
        addCol tr, 'td', row.href, refimpl.href || ''
        tbody.appendChild(tr)
      end

      thead = document.querySelector('#properties thead tr')
      thead.removeChild(thead.firstChild) while thead.hasChildNodes()
      addCol thead, 'th', 'Agent'
      visible = []
      PROPERTIES.forEach do |prop|
        if prop != 'href' and AGENTS.any? {|agent| rows[agent][prop]}
          visible << prop 
          addCol thead, 'th', prop
        end
      end

      tbody = document.querySelector('#properties tbody')
      tbody.removeChild(tbody.firstChild) while tbody.hasChildNodes()

      AGENTS.forEach do |agent|
        row = results[agent].constructor[index]
        tr = document.createElement('tr')
        addCol tr, 'th', agent
        visible.forEach do |prop|
          addCol tr, 'td', row[prop], refimpl[prop] || ''
        end
        tbody.appendChild(tr)
      end
    end

    def loadTable(data)
      document.querySelector('#index').style.display = 'block'
      document.querySelector('#detail').style.display = 'none'

      tbody = document.querySelector('#index tbody')
      tbody.removeChild(tbody.firstChild) while tbody.hasChildNodes()
      for i in 0...data.length
        tr = document.createElement('tr')
        addCol tr, 'th', i
        addCol tr, 'td', JSON.stringify(data[i].input)
        addCol tr, 'td', data[i].base
        addCol tr, 'td', data[i].href
        tr.setAttribute('data-index', i);
        tr.addEventListener('click') do |event|
          navigate(event.target.parentNode.getAttribute('data-index'))
        end
        tbody.appendChild(tr)
      end
    end

    def navigate(index) if not history.state or history.state.index == index
        history.replaceState({index: index}, "index", index)
      else
        history.pushState({index: index}, "index", index)
      end

      if index == ''
        loadTable(results.refimpl.constructor)
      else
        detailView(index.to_i)
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
        loadTable(results.refimpl.constructor)
      elsif event.keyCode == 39
        document.querySelector('.navlink.right').click()
      end
    end

    firstPage = location.pathname.split('/').slice(-1)[0]

    def fetchAgents(list)
      if list.length
        agent = list.shift()
        statusArea.textContent = "... loading #{agent}"
        fetch("../useragent-results/#{agent}").then do |response|
          results[agent] = response.json()
          fetchAgents(list)
          navigate('') if firstPage == '' and agent == 'refimpl'
        end
      else
        statusArea.style.display = 'none'
        navigate(firstPage.to_i) if firstPage != ''
      end
    end

    fetchAgents(AGENTS.slice())
  end
end
