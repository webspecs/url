try:
  from urllib.parse import urlparse, urljoin
except ImportError:
  from urlparse import urlparse, urljoin

import json
import sys

f = open('urltestdata.json')
tests = json.load(f)
f.close()

constructor_results = []

for test in tests:
  result = {'input': test['input'], 'base': test['base']}

  try:
    url = urlparse(urljoin(test['base'], test['input']))
  except:
    result['exception'] = str(sys.exc_info()[1])
    url = urlparse('')

  result['href'] = url.geturl()
  result['protocol'] = url.scheme + ':'

  try:
    result['port'] = url.port
  except:
    result['port_exception'] = str(sys.exc_info()[1])

  result['username'] = url.username
  result['password'] = url.password
  result['hostname'] = url.hostname
  result['pathname'] = url.path
  result['search'] = '?' + url.query if url.query else ''
  result['hash'] = '#' + url.fragment if url.fragment else ''

  constructor_results.append(result)

useragent = 'python ' + sys.version.replace(" \n", " ")
print(json.dumps({'useragent': useragent, 'constructor': constructor_results},
  indent=2))
