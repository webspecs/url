fs = require('fs');
pegjs = require('pegjs');

var parser = pegjs.buildParser(fs.readFileSync('parser.pegjs', 'utf8'));
var grammar = parser.parse(fs.readFileSync('url.pegjs', 'utf8'));

console.log(JSON.stringify(grammar, null, 2));
