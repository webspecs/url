fs = require('fs');
peg = require('pegjs');

var grammar = fs.readFileSync('url.pegjs', 'utf8')
var parser = peg.buildParser(grammar, {output: 'source', allowedStartRules: [
    'Url', 'IPv4Addr', 'setProtocol', 'setUsername', 'setSchemeData'
  ]});
console.log('UrlParser = ' + parser);
