fs = require('fs')

fs.readFile('../test/urltestparser.js', 'utf8', function (err,script) {
  script = script.replace(/: \{ get:/g, ': { enumerable: true, get:');
  eval(script);
  fs.readFile('../test/urltestdata.txt', 'utf8', function (err,data) {
    console.log(JSON.stringify(URLTestParser(data)));
  });
});
