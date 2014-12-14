# Evaluation programs and results

This folder contains a number of programs used to capture results from a number of different implementations.
The source for tests is contained in the [url](https://github.com/w3c/web-platform-tests/tree/master/url) directory of
[web-platform-tests](https://github.com/w3c/web-platform-tests#description).

Browser results can be obtained by deploying [urltest.cgi](urltest.cgi), and visiting that page using a variety
of browsers.  A number of evaluation programs are also included:

   * [Java](testgalimatis.java) - [galimatias](https://github.com/smola/galimatias#galimatias)
   * [JavaScript](testrefimpl.js) - [reference implementation](https://github.com/webspecs/url/tree/develop/reference-implementation#reference-implementation-and-tests)
   * [Node.js](testnodejs.js) - [URL](http://nodejs.org/api/url.html)
   * [Rust](src/main.rs) - [url](http://servo.github.io/rust-url/url/index.html)
   * [Ruby](testaddressable.rb) - [addressable](https://github.com/sporkmonger/addressable#addressable)
   * [Perl](testuri.pl) - [URI](http://search.cpan.org/~ether/URI-1.65/URI.pm#NAME)
   * [Python](testurllib.py) - [urllib](https://docs.python.org/3/library/urllib.parse.html)
  
Each program normalizes the results to match the
[URLUtils](https://url.spec.whatwg.org/#urlutils-and-urlutilsreadonly-members) interface, and produces output
in the form of JSON.  Captured [test results](useragent-results) against a number of implementations
are available.  These results can be [explored interactively](https://url.spec.whatwg.org/interop/test-results/)
online.
  
Running `make` will build each program and update the results.
  
Official test results are available on the [w3c](http://w3c.github.io/test-results/url/all.html) site,
including a [filtered](http://w3c.github.io/test-results/url/less-than-2.html) version listing tests with less
than two passes.
