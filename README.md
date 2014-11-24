url
===

The URL specification
=======
This branch contains work-in-progress towards a [peg.js](http://pegjs.majda.cz/)
based description and implementation of
[URL parsing](https://url.spec.whatwg.org/#url-parsing URL parsing).

Contains:
   * [reference implementation](https://github.com/rubys/url/tree/peg.js/reference-implementation#readme)
     in JavaScript.  This directory also contains a web page that demonstates
     live parsing of URLs entered in an HTML input field.
   * [evaluate](https://github.com/rubys/url/tree/peg.js/evaluate) programs
     and scripts which capture and compare test results against a number
     of implementations.

Running `make` at the top level will build the spec, build the reference
implementation, and run the tests against the reference implementation.  See
the [Makefile](https://github.com/rubys/url/tree/peg.js/Makefile) for a list
of prerequisites.

Deploy the `evaluate` directory to a web browser capable of running CGI
programs.  The
[urltest](https://github.com/rubys/url/tree/peg.js/evaluate/urltest.cgi)
script will capture and automatically upload test results based on the browser
that visited the page.  The
[urltest-results](https://github.com/rubys/url/tree/peg.js/evaluate/urltest-results.cgi)
script will display the aggregated results.

Running `make` in the `evaluate` directory will capture test results for a
number of non-web browser URL/URI implementations.  See the
[Makefile](https://github.com/rubys/url/tree/peg.js/evaluate/Makefile) for a
list of prerequisites.
