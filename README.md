<<<<<<< HEAD
url
===

The URL specification
=======

This repository hosts the 
[URL Standard](https://specs.webplatform.org/url/webspecs/develop/). 
Please do not include `url.bs` in pull requests. Tests can be found in the
`url/` directory of
[`w3c/web-platform-tests`](https://github.com/w3c/web-platform-tests).

Contains:
   * [reference implementation](https://github.com/webspecs/url/tree/develop/reference-implementation#readme)
     in JavaScript.  This directory also contains web pages that demonstate
     live parsing of URLs entered in an HTML input field.
   * [evaluate](https://github.com/webspecs/url/tree/develop/evaluate) programs
     and scripts which capture and compare test results against a number
     of implementations.

Running `make` at the top level will build the spec, build the reference
implementation, and run the tests against the reference implementation.  See
the [Makefile](https://github.com/webspecs/url/tree/develop/Makefile) for a list
of prerequisites.

Deploy the `evaluate` directory to a web browser capable of running CGI
programs.  The
[urltest](https://github.com/webspecs/url/tree/develop/evaluate/urltest.cgi)
script will capture and automatically upload test results based on the browser
that visited the page.  The
[urltest-results](https://github.com/webspecs/url/tree/develop/evaluate/urltest-results.cgi)
script will display the aggregated results.

Running `make` in the `evaluate` directory will capture test results for a
number of non-web browser URL/URI implementations.  See the
[Makefile](https://github.com/webspecs/url/tree/develop/evaluate/Makefile) for a
list of prerequisites.
