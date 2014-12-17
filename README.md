The URL Standard
=======

The URL Standard is being developed at two locations:

  * On a continuing basis, the
    [WHATWG URL Standard](https://url.spec.whatwg.org/) with source at
    [github.com/whatwg](https://github.com/whatwg/url).
    For more information, see [What is the WHATWG?](https://wiki.whatwg.org/wiki/FAQ#What_is_the_WHATWG.3F).
  * By [request](http://lists.w3.org/Archives/Public/public-w3process/2014Nov/0149.html),
    and on a [provisional basis](http://lists.w3.org/Archives/Public/public-w3process/2014Nov/0177.html),
    the [Web Platform URL Standard](https://specs.webplatform.org/url/webspecs/develop/) with source at
    [github.com/webspecs](https://github.com/webspecs/url).
    For more information, see [Web Platform Specs](https://specs.webplatform.org/docs/).

See [workmode](docs/workmode.md#preface) for a [proposal for W3C sponsored snapshots](http://www.w3.org/TR/url/).

See [draft-ruby-url-problem](http://xml2rfc.tools.ietf.org/cgi-bin/xml2rfc.cgi?url=https%3A%2F%2Fraw.githubusercontent.com%2Fwebspecs%2Furl%2Fdevelop%2Fdocs%2Furl-problem-statement.xml&modeAsFormat=html%2Fascii) ([plain text](http://xml2rfc.tools.ietf.org/cgi-bin/xml2rfc.cgi?url=https%3A%2F%2Fraw.githubusercontent.com%2Fwebspecs%2Furl%2Fdevelop%2Fdocs%2Furl-problem-statement.xml&modeAsFormat=txt%2Fascii&type%3Dascii)) for both a problem statement as well as a proposed plan for integration with IETF standards.


Contents
---

   * Specification.  Source is contained in [url.src](url.src) and [url.pegjs](url.pegjs).
   * [Reference implementation](reference-implementation#readme)
     in JavaScript.  This directory also contains web pages that demonstate
     live parsing of URLs entered in an HTML input field.  The latest version is deployed live:
       * [liveview](https://url.spec.whatwg.org/reference-implementation/liveview.html) - parse a single URL.
       * [liveview2](https://url.spec.whatwg.org/reference-implementation/liveview2.html) - parse a single URL against a base you provide.
       * [liveview3](https://url.spec.whatwg.org/reference-implementation/liveview3.html) - parse a single URL and then interactively invoke setters against the result.
   * [Evaluate](evaluate#evaluation-programs-and-results) programs
     and results.  Source for the tests is the
     [web-platform-tests](https://github.com/w3c/web-platform-tests/tree/master/url) GitHub repository.
     Captured [test results](evaluate/useragent-results) against a number of implementations
     are available.  These results can be [explored interactively](https://url.spec.whatwg.org/interop/test-results/)
     online.

Running `make` at the top level will build the spec, build the reference
implementation, and run the tests against the reference implementation.  See
the [Makefile](Makefile) for a list
of prerequisites.

Deploy the `evaluate` directory to a web server capable of running CGI
programs in ruby.  The [urltest](develop/evaluate/urltest.cgi)
script will capture and automatically upload test results based on the browser
that visited the page.  The [urltest-results](urltest-results.cgi)
script will display the aggregated results.

Running `make` in the `evaluate` directory will capture test results for a
number of non-web browser URL/URI implementations.  See the
[Makefile](evaluate/Makefile) for a
list of prerequisites.
