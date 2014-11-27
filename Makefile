# Prereqs:
#    install node, ruby, wget, then:
#
#    npm install -g pegjs
#    npm install -g nodeunit
#    gem install ruby2js
#    https://github.com/tabatkins/bikeshed/blob/master/docs/install.md
#
#    To run the reference-implementation cgi scripts:
#
#    gem install wunderbar

all: spec test

clean:
	rm -f url.html url.bs url.pegjson reference-implementation/url.js \
	reference-implementation/urlparser.js \
	reference-implementation/test/urlsettest.js

#
### specification
#
spec: url.html

url.html: url.bs
	bikeshed spec

url.bs: json2bikeshed.rb url.pegjson url.pegjs url.src
	ruby json2bikeshed.rb > $@

url.pegjson: peg2json.js parser.pegjs url.pegjs
	node peg2json.js > $@

#
### test reference implementation
#
test: settest urltest

urltest: reference-implementation/punycode.js \
        reference-implementation/unorm.js \
        reference-implementation/idna.js \
        reference-implementation/url.js \
	reference-implementation/urlparser.js \
	reference-implementation/test/urltest.js \
	reference-implementation/test/urltestparser.js \
	reference-implementation/test/urltestdata.txt \
	reference-implementation/test/moretestdata.txt \
	reference-implementation/test/patchtestdata.txt
	node reference-implementation/test/urltest.js


reference-implementation/test/urlsettest.js: \
	reference-implementation/test/urlsettest.yml \
	reference-implementation/test/yml2test.rb
	ruby reference-implementation/test/yml2test.rb > $@

reference-implementation/url.js: reference-implementation/ruby2js reference-implementation/url.rb
	ruby reference-implementation/ruby2js reference-implementation/url.rb > $@

reference-implementation/urlparser.js: reference-implementation/pegcompile.js url.pegjs
	node reference-implementation/pegcompile.js > $@

reference-implementation/idna.js: reference-implementation/idna2js.rb \
        reference-implementation/IdnaMappingTable.txt
	ruby reference-implementation/idna2js.rb > $@

settest: reference-implementation/test/urlsettest.js \
	reference-implementation/punycode.js \
        reference-implementation/unorm.js \
        reference-implementation/idna.js \
        reference-implementation/url.js \
	reference-implementation/urlparser.js
	nodeunit reference-implementation/test/urlsettest.js --reporter minimal

#
### Fetch files from other sources
#
clobber: clean
	rm -f test/urltestdata.txt test/urltestparser.js parser.pegjs \
	reference-implementation/test/urltestdata.txt \
	reference-implementation/punycode.js \
	reference-implementation/IdnaMappingTable.txt

fetch: clobber test/urltestdata.txt test/urltestparser.js parser.pegjs \
	reference-implementation/punycode.js

reference-implementation/test/urltestdata.txt:
	cd reference-implementation/test; \
	wget https://raw.githubusercontent.com/w3c/web-platform-tests/master/url/urltestdata.txt

reference-implementation/test/urltestparser.js:
	cd reference-implementation/test; \
	wget https://raw.githubusercontent.com/w3c/web-platform-tests/master/url/urltestparser.js

parser.pegjs:
	wget https://raw.githubusercontent.com/dmajda/pegjs/master/src/parser.pegjs

reference-implementation/punycode.js:
	cd reference-implementation; \
	wget https://raw.githubusercontent.com/bestiejs/punycode.js/master/punycode.js

reference-implementation/unorm.js:
	cd reference-implementation; \
	wget https://raw.githubusercontent.com/walling/unorm/master/lib/unorm.js

reference-implementation/IdnaMappingTable.txt:
	cd reference-implementation; \
	wget http://www.unicode.org/Public/idna/latest/IdnaMappingTable.txt
