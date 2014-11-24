var fs = require("fs");
var punycode = require("../reference-implementation/punycode");
eval(fs.readFileSync("../reference-implementation/idna.js", "utf8"));
eval(fs.readFileSync("../reference-implementation/unorm.js", "utf8"));
eval(fs.readFileSync("../reference-implementation/url.js", "utf8"));
eval(fs.readFileSync("../reference-implementation/urlparser.js", "utf8"));

eval(
  fs.readFileSync("../reference-implementation/test/urltestparser.js", "utf8").
    replace(/:\ \{\ get:/g, ": { enumerable: true, get:")
);

var data = URLTestParser(fs.
  readFileSync("../reference-implementation/test/urltestdata.txt", "utf8"));

properties = ['href', 'protocol', 'hostname', 'port', 'username', 'password',
  'pathname', 'search', 'hash', 'exception'];

var constructorResults = [];
for (var i = 0; i < data.length; i++) {
  var test = data[i];
  var url = new Url(test.input, test.base);
  result = {input: test.input, base: test.base};
  properties.forEach(function(property) { 
    if (url[property]) result[property] = url[property].toString()
  });
  if (url['exception'] && url['exception'].extension) {
    result['exception_extension'] = true
  }
  constructorResults.push(result)
};

var results = {
  useragent: "reference-implementation @ " + new Date().toString(),
  constructor: constructorResults
}

console.log(JSON.stringify(results, undefined, 2));
