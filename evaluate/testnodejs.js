fs = require('fs');
url = require('url');

fs.readFile('../test/urltestparser.js', 'utf8', function (err,script) {
  eval(script);
  fs.readFile('../test/urltestdata.txt', 'utf8', function (err,data) {
    var tests = URLTestParser(data);
    var results = [];

    for (var i=0; i<tests.length; i++) {
      console.log([i, tests.length]);
      var test = tests[i];
      var value = url.parse(url.resolve(test.base, test.input));

      if (value.auth) {
        value.username = value.auth.split(':')[0];
        value.password = value.auth.split(':')[1];
      }

      value.input = test.input;
      value.base = test.base;

      results.push(value);
    }

    console.log(JSON.stringify(results));
  });
});
