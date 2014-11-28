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

Contents
---

   * [reference implementation](reference-implementation#readme)
     in JavaScript.  This directory also contains web pages that demonstate
     live parsing of URLs entered in an HTML input field.
   * [evaluate](evaluate) programs
     and scripts which capture and compare test results against a number
     of implementations.

Tests can be found in the `url/` directory of
[`w3c/web-platform-tests`](https://github.com/w3c/web-platform-tests).

Running `make` at the top level will build the spec, build the reference
implementation, and run the tests against the reference implementation.  See
the [Makefile](Makefile) for a list
of prerequisites.

Deploy the `evaluate` directory to a web browser capable of running CGI
programs.  The [urltest](develop/evaluate/urltest.cgi)
script will capture and automatically upload test results based on the browser
that visited the page.  The [urltest-results](urltest-results.cgi)
script will display the aggregated results.

Running `make` in the `evaluate` directory will capture test results for a
number of non-web browser URL/URI implementations.  See the
[Makefile](evaluate/Makefile) for a
list of prerequisites.
