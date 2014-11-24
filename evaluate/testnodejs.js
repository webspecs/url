fs = require('fs');
url = require('url');

fs.readFile('../reference-implementation/test/urltestparser.js', 'utf8', function (err,script) {
  eval(script);
  fs.readFile('../reference-implementation/test/urltestdata.txt', 'utf8', function (err,data) {
    var tests = URLTestParser(data);
    var constructorResults = [];

    for (var i=0; i<tests.length; i++) {
      var test = tests[i];
      var value = url.parse(url.resolve(test.base, test.input));

      if (value.auth) {
        value.username = value.auth.split(':')[0];
        value.password = value.auth.split(':')[1];
      }

      value.input = test.input;
      value.base = test.base;

      constructorResults.push(value);
    }

    var results = {
      useragent: "node.js " + process.versions.node,
      constructor: constructorResults
    }
    console.log(JSON.stringify(results, undefined, 2));
  });
});
