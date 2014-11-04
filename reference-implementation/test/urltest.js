var fs = require("fs");
var punycode = require("../punycode");
eval(fs.readFileSync("reference-implementation/url.js", "utf8"));
eval(fs.readFileSync("reference-implementation/urlparser.js", "utf8"));

eval(
  fs.readFileSync("reference-implementation/test/urltestparser.js", "utf8").
    replace(/:\ \{\ get:/g, ": { enumerable: true, get:")
);

var properties = [
  "href",
  "protocol",
  "username",
  "password",
  "hostname",
  "port",
  "pathname",
  "search",
  "hash"
];

var data = URLTestParser(
  fs.readFileSync("reference-implementation/test/urltestdata.txt", "utf8") +
  fs.readFileSync("reference-implementation/test/moretestdata.txt", "utf8"));

for (var i = 0; i < data.length; i++) {
  var test = data[i];
  var url = new Url(test.input, test.base);
  test.pathname = test.pathname || test.path;
  test.hostname = test.hostname || test.host;
  test.input = input = test.input.trim();

  if (properties.some(function(prop) {
    return url[prop] != test[prop]
  })) {
    console.log("test " + i + " failed\n");
    console.log("input: " + JSON.stringify(test.input));
    console.log("base: " + JSON.stringify(test.base) + "\n");
    delete test["input"];
    delete test["base"];
    console.log("expected: " + JSON.stringify(test) + "\n");
    console.log("found: " + JSON.stringify(url) + "\n");
    console.log("differences:");
    test.input = input;

    properties.forEach(function(prop) {
      if (url[prop] != test[prop]) {
        console.log([prop, test[prop], url[prop]])
      }
    });

    process.exit(1)
  }
};

console.log("all tests pass")
