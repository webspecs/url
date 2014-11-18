var fs = require("fs");
var punycode = require("../punycode");
var unorm = require("../unorm");
eval(fs.readFileSync("reference-implementation/idna.js", "utf8"));
eval(fs.readFileSync("reference-implementation/url.js", "utf8"));
eval(fs.readFileSync("reference-implementation/urlparser.js", "utf8"));

exports.href = {
  setAll: function(test) {
    var url = new Url('foo:');
    url.href = "http://user:pass@host/path?search#hash";
    test.equal(url.href, "http://user:pass@host/path?search#hash");
    test.equal(url.protocol, "http:");
    test.equal(url.username, "user");
    test.equal(url.password, "pass");
    test.equal(url.hostname, "host");
    test.equal(url.pathname, "/path");
    test.equal(url.search, "?search");
    test.equal(url.hash, "#hash");
    test.done();
  },

  resetAll: function(test) {
    var url = new Url("http://user:pass@host/path?search#hash");
    url.href = 'foo:'
    test.equal(url.href, "foo:///");
    test.equal(url.protocol, "foo:");
    test.equal(url.username, "");
    test.equal(url.password, "");
    test.equal(url.hostname, "");
    test.equal(url.pathname, "/");
    test.equal(url.search, "");
    test.equal(url.hash, "");
    test.done();
  },

  error: function(test) {
    var url = new Url("http://user:pass@host/path?search#hash");
    url.href = 'http://localhost:badport';
    test.equal(url.href, "http://user:pass@host/path?search#hash");
    test.equal(url.protocol, "http:");
    test.equal(url.username, "user");
    test.equal(url.password, "pass");
    test.equal(url.hostname, "host");
    test.equal(url.pathname, "/path");
    test.equal(url.search, "?search");
    test.equal(url.hash, "#hash");
    test.done();
  },

};

exports.protocol = {
  withColon : function(test) {
    var url = new Url("http://user:pass@host/path?search#hash");
    url.protocol = 'foo:blahblahblah';
    test.equal(url.href, "foo://user:pass@host/path?search#hash");
    test.equal(url.protocol, "foo:");
    test.done();
  },

  withoutColon : function(test) {
    var url = new Url("http://user:pass@host/path?search#hash");
    url.protocol = 'foo';
    test.equal(url.href, "foo://user:pass@host/path?search#hash");
    test.equal(url.protocol, "foo:");
    test.done();
  },

  empty : function(test) {
    var url = new Url("http://user:pass@host/path?search#hash");
    url.protocol = '';
    test.equal(url.href, "http://user:pass@host/path?search#hash");
    test.equal(url.protocol, "http:");
    test.done();
  },
};

exports.username = {
  relative : function(test) {
    var url = new Url("http://user:pass@host/path?search#hash");
    url.username = 'fred';
    test.equal(url.href, "http://fred:pass@host/path?search#hash");
    test.equal(url.username, "fred");
    test.done();
  },

  userColon : function(test) {
    var url = new Url("http://user:pass@host/path?search#hash");
    url.username = 'fred:secret';
    test.equal(url.href, "http://fred%3Asecret:pass@host/path?search#hash");
    test.equal(url.username, "fred%3Asecret");
    test.done();
  },

  mailto : function(test) {
    var url = new Url("mailto:someone@example.com");
    url.username = 'fred';
    test.equal(url.href, "mailto:someone@example.com");
    test.equal(url.username, "");
    test.done();
  },
}
