# Reference Implementation and Tests

This folder contains a reference implementation of the URL standard. 

 * `urlparse.js` is generated from a common source as the specification, namely
[url.pegjs](https://github.com/rubys/url/blob/peg.js/url.pegjs).

 * The reference implementation also contains a Live DOM URL Viewer which is
deployed [online](http://intertwingly.net/projects/pegurl/liveview.html).

 * A test suite is included inside `test`.


## Historical notes

I started this effort by attempting to create a 
[faithful implementation](http://intertwingly.net/stories/2014/10/13/url_rb.html)
of the URL Standard.
[Like others who attempted to do so](http://lists.w3.org/Archives/Public/www-archive/2014Oct/0021.html),
I found the current description to appear to be easy to follow yet when I
attempted to do so I found I had a hard time determing what should be the
parsing output for a number of cases.  I ended up reverse engineering the
outputs, and actually reading the source code, of other implementations.

This kinda defeats the purpose of a Spec.

I then embarked on an effort to define a formal grammar and selected
[PEG.js](http://pegjs.majda.cz/).  For the parts which aren't covered by the
grammar, I used a path of least resistance:
[a tool to convert Ruby to JS](https://github.com/rubys/ruby2js#readme).  

Had I started from scratch, I likely would have followed the lead of the
[streams reference implementation](https://github.com/whatwg/streams/blob/master/reference-implementation/README.md)
 and used ES6 and [traceur](https://github.com/google/traceur-compiler).

## Plans / Todos

 * Eliminate the ruby2js step and maintain the generated JavaScript instead.
   For the moment, I still prefer to think in terms of higher level
   abstractions like class and instance methods than what ES5 provides, but
   longer term I recognize that will be an impediment to others participating.

 * Settle on some sort of "JavaDoc" like syntax which would enable bikeshed
   flavored syntax to be included as comments and automatically extracted
   during the build process for the purposes of spec generation.

 * Find or build a compliant JavaScript implementation of the
   <a href=https://encoding.spec.whatwg.org/>Encoding Living Standard</a>.
   Until then, the reference implementation tracks and updates the value of
   <var>encoding_override</var>, but doesn't use it.  Instead
   <code>utf-8</code> is always used.

 * Find or build Unicode Normalization logic.  Needed by Unicode
   [processing](http://www.unicode.org/reports/tr46/#Processing) and
   [validation](http://www.unicode.org/reports/tr46/#Validity_Criteria"),
   both of which are used by the
   [host parser](https://url.spec.whatwg.org/#concept-host-parser)
