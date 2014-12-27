#!/usr/bin/ruby

require 'json'
require 'digest/md5'
require 'wunderbar/script'
require 'ruby2js/filter/functions'

_html do
  _title 'URL test results'
  _link rel: 'stylesheet', href: '../bootstrap.min.css'
  _link rel: 'stylesheet', href: '../analysis.css'
  _script src: '../rfc3986.js'
  _style %{
    th, td {padding-left: 1em}
    td.fail, .fail td, .legend .fail {background-color: #FFFF00}
    #status {font-size: medium}
    #index tr:hover {color: #428bca; cursor: pointer; text-decoration: underline}
    .navlink:hover {text-decoration: none; cursor: pointer}
    .exception {background-color: HotPink}
    .legend {font-size: medium; margin: 1em 0}
    table {margin-top: 1.5em}
  }

  _div.index! do
    _h1! do
      _ 'URL test results'
      _span.status!
    end

    _div do
      _ 'For '
      _select_.domain! do
        _option 'all user agents', value: 'all'
        _option 'all browsers', value: 'browsers'
        _option 'all current browsers', value: 'current'
      end
      _ ' using '
      _select_.baseline!
      _ ' as a baseline, showing '
      _select_.filter! do
        _option 'all inputs'
        _option 'only valid URI references', value: 'valid'
        _option 'only invalid URI references', value: 'invalid'
        _option 'only conforming URLs', value: 'conforming'
        _option 'only nonconforming URLs', value: 'nonconforming'
      end
    end

    _p_!.legend do
      _span.fail 'Highlighted'
      _ ' rows indicate '
      _span.highlight! 'less than two passes'
      _ '.  Click on any row to see detailed results. '
      _a 'Evaluation programs and results', href:
        'https://github.com/webspecs/url/tree/develop/evaluate#evaluation-programs-and-results'
      _ ' are available on GitHub.'
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
      _a
      _span.inspect! do
        _ ' ('
        _a
        _ ')'
      end
    end

    _p!.base! do
      _b 'Base'
      _ ': '
      _a
    end

    _p_!.legend do
      _span.fail 'Highlighted'
      _ ' cells indicate differences.  Exceptions are shown in '
      _span.exception 'hot pink'
      _ '.  Click on '
      _b 'input'
      _ ' or '
      _b 'base'
      _ ' above to explore this test results with the '
      _ 'Live DOM URL Viewer.'
    end

    _h2_ 'Results'
    _table_.results! do
      _thead do
        _tr do
          _th 'Agent'
          _th 'href'
          _th.exception 'exception'
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
    title = {}

    baseline = 'refimpl'
    domain = agents
    filter = 'all inputs'

    PROPERTIES = %w(href protocol hostname port username password pathname
      search hash)

    statusArea = document.getElementById('status')
    selectBaseline = document.getElementById('baseline')
    selectDomain = document.getElementById('domain')
    selectFilter = document.getElementById('filter')

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

    def searchGet(name)
      vars = location.search.substring(1).split('&')
      for i in 0...vars.length
        equal = vars[i].indexOf('=')
        if equal > -1 and decodeURIComponent(vars[i][0...equal]) == name
          return decodeURIComponent(vars[i].substring(equal+1))
        end
      end
    end

    def dispatchEvent(element, eventName)
      event = document.createEvent('HTMLEvents');
      event.initEvent(eventName,true,true);
      element.dispatchEvent(event);
    end

    def addCol(tr, name, value, expected)
      element = document.createElement(name)
      element.textContent = value
      tr.appendChild element
      if not expected === undefined
        element.className = ((value || '')== expected ? 'pass' : 'fail')
      end
      return element
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

      link = index - 1
      if filter == 'valid'
        link = link - 1 while link >= 0 and tests[link].invalid
      elsif filter == 'invalid'
        link = link - 1 while link >= 0 and tests[link].valid
      elsif filter == 'conforming'
        link = link - 1 while link >= 0 and tests[link].nonconforming
      elsif filter == 'nonconforming'
        link = link - 1 while link >= 0 and tests[link].conforming
      end

      if link >= 0
        navLeft.setAttribute('data-index', tests[link].index[0..9])
        navLeft.style.display = 'inline'
      else
        navLeft.style.display = 'none'
      end

      link = index + 1
      if filter == 'valid'
        link = link + 1 while link <= tests.length-1 and tests[link].invalid
      elsif filter == 'invalid'
        link = link + 1 while link < tests.length-1 and tests[link].valid
      elsif filter == 'conforming'
        link = link + 1 while link <= tests.length-1 and tests[link].nonconforming
      elsif filter == 'nonconforming'
        link = link + 1 while link < tests.length-1 and tests[link].conforming
      end

      if link <= tests.length - 1
        navRight.setAttribute('data-index', tests[link].index[0..9])
        navRight.style.display = 'inline'
      else
        navRight.style.display = 'none'
      end

      test = tests[index]
      expected = test.results[baseline]
      document.querySelector('#input a').textContent =
        JSON.stringify(test.input)
      document.querySelector('#base a').textContent =
        JSON.stringify(test.base)
      document.querySelector('#inspect a').textContent =
        test.inspect
      document.querySelector('#inspect').style.display =
        (JSON.stringify(test.input) == test.inspect ? 'none' : 'inline')


      liveview2 = '../../reference-implementation/liveview2.html#' +
        encodeURIComponent(test.base + ' ' + test.input)
      document.querySelector('#input a').href = liveview2
      document.querySelector('#inspect a').href = liveview2
      document.querySelector('#base a').href = liveview2

      rows = domain.slice()
      rows.unshift baseline unless rows.include? baseline

      tbody = document.querySelector('#results tbody')
      tbody.removeChild(tbody.firstChild) while tbody.hasChildNodes()
      document.querySelector('th.exception').style.display = 'none'
      rows.each do |agent|
        next unless test.results[agent]
        tr = document.createElement('tr')
        th = addCol tr, 'th', agent
        th.setAttribute('title', title[agent])
        addCol tr, 'td', test.results[agent].href, expected.href || ''
        if test.results[agent].exception
          exception = addCol tr, 'td', test.results[agent].exception
          exception.className = 'exception'
          document.querySelector('th.exception').style.display = 'block'
        end
        tbody.appendChild(tr)
      end

      thead = document.querySelector('#properties thead tr')
      thead.removeChild(thead.firstChild) while thead.hasChildNodes()
      addCol thead, 'th', 'Agent'
      visible = []
      PROPERTIES.each do |prop|
        if prop != 'href' and 
          rows.any? {|agent| test.results[agent] and test.results[agent][prop]}
        then
          visible << prop 
          addCol thead, 'th', prop
        end
      end

      tbody = document.querySelector('#properties tbody')
      tbody.removeChild(tbody.firstChild) while tbody.hasChildNodes()

      rows.each do |agent|
        row = test.results[agent]
        tr = document.createElement('tr')
        th = addCol tr, 'th', agent
        th.setAttribute('title', title[agent])
        visible.each do |prop|
          if row["#{prop}-exception"]
            exception = addCol tr, 'td', row["#{prop}-exception"]
            exception.className = 'exception'
          else
            addCol tr, 'td', row[prop], expected[prop] || ''
          end
        end
        tbody.appendChild(tr)
      end
    end

    def indexView()
      document.querySelector('#index').style.display = 'block'
      document.querySelector('#detail').style.display = 'none'

      navRight.setAttribute('data-index', tests[0].index[0..9])
      navLeft.setAttribute('data-index', tests[tests.length-1].index[0..9])

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

    def showDiffs()
      tbody = document.querySelector('#index tbody')
      trs = tbody.querySelectorAll('tr')
      for i in 0...trs.length
        tr = trs[i]
        results = tests[i].results

        diffs = []
        domain.each do |agent|
          next unless results[agent] and results[baseline]
          if PROPERTIES.any? {|prop| (results[agent][prop]||'') !=
            (results[baseline][prop]||'')}
          then
            diffs << agent
          end
        end

        td = tr.querySelector('td:last-child')
        td.textContent = diffs.join(', ')

        if diffs.length != 0 and domain.length - diffs.length < 2
          tr.classList.add 'fail'
        end
      end
    end

    def navigate(index)
      index = history.state.index || '' if history.state and not index
      state = {index: index, select: selectDomain.value,
        baseline: selectBaseline.value, filter: selectFilter.value}
      query = []
      query << "select=#{state.select}" unless state.select == 'all'
      query << "baseline=#{state.baseline}" unless state.baseline == 'refimpl'
      query << "filter=#{state.filter}" unless state.filter == 'all inputs'
      state.subpath = index || '.'
      state.subpath = "#{state.subpath}?#{query.join('&')}" if query.length > 0

      if not history.state or not history.state.subpath
        history.replaceState(state, "URL Test Results", state.subpath)
      elsif history.state.subpath != state.subpath
        history.pushState(state, "URL Test Results", state.subpath)
      end

      if index == ''
        indexView()
        showDiffs()
      elsif index
        detailView(index)
      end
    end

    def window.onpopstate(event)
      selectDomain.value = event.state.select || 'all'
      dispatchEvent(selectDomain, 'change')

      selectBaseline.value = event.state.baseline || 'refimpl'
      dispatchEvent(selectBaseline, 'change')

      selectFilter.value = event.state.filter || 'all inputs'
      dispatchEvent(selectFilter, 'change')

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
        navigate('')
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
          json = response.json()
          title[agent] = json.useragent
          json.constructor.each do |result|
            index["#{result.input} #{result.base}"].results[agent] = result
          end

          fetchAgents(list, index)
        end
      else
        rfc3986 = RFC3986.new()

        tests.each do |test|
          if test.results.refimpl
            if test.results.refimpl.exception
              test.nonconforming = true
            else
              test.conforming = true
            end
          end

          if rfc3986.isURIReference(test.input)
            test.valid = true
          else
            test.invalid = true
          end
        end

        statusArea.style.display = 'none'
        dispatchEvent(selectBaseline, 'change')
        dispatchEvent(selectDomain, 'change')
        dispatchEvent(selectFilter, 'change')
        navigate(firstPage) if firstPage != ''
        showDiffs() if firstPage == ''
      end
    end

    statusArea.textContent = "... loading index"
    fetch("../useragent-results/index").then do |response|
      json = response.json()
      tests = json.tests
      agents = json.agents

      agents.each do |agent|
        option = document.createElement('option')
        option.textContent = agent
        selectBaseline.appendChild(option)
        option.selected = true if agent == 'refimpl'

        option = document.createElement('option')
        option.textContent = agent
        selectDomain.appendChild(option)
        option.selected = true if agent == 'all user agents'
      end

      selectBaseline.addEventListener('change') do |event|
        baseline = event.target.value
        navigate()
        showDiffs()
      end

      selectDomain.addEventListener('change') do |event|
        case event.target.value
        when 'all'
          domain = agents
        when 'browsers'
          domain = %w(chrome ie firefox opera safari)
        when 'current'
          domain = %w(chrome ie firefox safari)
        else
          domain = [event.target.value]
        end

        navigate()
        showDiffs()

        document.getElementById('highlight').textContent = 
          (domain.length == 1 ? 'differences' : 'less than two passes')
      end

      selectFilter.addEventListener('change') do |event|
        filter = event.target.value

        navigate()

        trs = document.querySelectorAll('#index tbody tr')
        for i in 0...trs.length
          tr = trs[i]
          if filter == 'conforming' and tests[i].nonconforming
            tr.style.display = 'none'
          elsif filter == 'nonconforming' and tests[i].conforming
            tr.style.display = 'none'
          elsif filter == 'valid' and tests[i].invalid
            tr.style.display = 'none'
          elsif filter == 'invalid' and tests[i].valid
            tr.style.display = 'none'
          else
            tr.style.display = 'table-row'
          end
        end
      end

      value = searchGet('select')
      options = document.querySelectorAll('#domain option')
      for i in 0...options.length
        options[i].selected = true if options[i].value == value
      end

      value = searchGet('baseline')
      options = document.querySelectorAll('#baseline option')
      for i in 0...options.length
        options[i].selected = true if options[i].value == value
      end

      value = searchGet('filter')
      options = document.querySelectorAll('#filter option')
      for i in 0...options.length
        options[i].selected = true if options[i].value == value
      end

      index = {}
      tests.each do |test|
        index["#{test.input} #{test.base}"] = test
        test.results = {}
      end

      navigate('') if firstPage == ''
      fetchAgents(agents.slice(), index)
      domain = agents
    end
  end
end
