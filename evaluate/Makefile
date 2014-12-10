# Prereqs:
#    install jdk, rust, cargo, pel
#    gem install addressable
#    cpan URI JSON
#    clean make in parent directory

all: useragent-results/index testdata

testdata: \
	urlsettest.json

urlsettest.json: ../reference-implementation/test/yml2test.rb \
	../reference-implementation/test/urlsettest.yml
	ruby ../reference-implementation/test/yml2test.rb --json > $@

useragent-results/index: resultindex.rb \
	useragent-results/addressable \
	useragent-results/galimatias \
	useragent-results/nodejs \
	useragent-results/perl \
	useragent-results/rusturl \
	useragent-results/refimpl
	ruby resultindex.rb > $@

softerror: softerror.rb \
	useragent-results/galimatias \
	useragent-results/refimpl
	ruby softerror.rb

clean:
	rm -rf target *.class Cargo.lock urltestdata.json urlsettest.json \
	useragent-results/index \
	useragent-results/addressable \
	useragent-results/galimatias \
	useragent-results/nodejs \
	useragent-results/rusturl \
	useragent-results/refimpl

clobber: clean
	rm -f *.jar

urltestdata.json: urltesttojson.js \
	../reference-implementation/test/urltestparser.js \
	../reference-implementation/test/urltestdata.txt
	node urltesttojson.js > $@

useragent-results/refimpl: testrefimpl.js \
	../reference-implementation/url.js \
	../reference-implementation/urlparser.js \
	../reference-implementation/test/urltestdata.txt
	node testrefimpl.js > $@

useragent-results/perl: testuri.pl urltestdata.json
	perl testuri.pl > $@

testgalimatias.class: testgalimatias.java \
	icu4j-54.1.1.jar galimatias-0.2.0.jar json-20140107.jar
	export CLASSPATH=.:icu4j-54.1.1.jar:galimatias-0.2.0.jar:json-20140107.jar; \
	javac testgalimatias.java

useragent-results/addressable: testaddressable.rb urltestdata.json
	ruby testaddressable.rb > $@

useragent-results/galimatias: testgalimatias.class urltestdata.json
	export CLASSPATH=.:icu4j-54.1.1.jar:galimatias-0.2.0.jar:json-20140107.jar; \
	java testgalimatias >> $@

useragent-results/nodejs: testnodejs.js \
	../reference-implementation/test/urltestparser.js \
	../reference-implementation/test/urltestdata.txt
	node testnodejs.js > $@

target/test_rust_url: Cargo.toml src/main.rs \
	../reference-implementation/test/urltestdata.txt
	cargo build

useragent-results/rusturl: target/test_rust_url
	export USERAGENT="$(shell grep rust-url Cargo.lock | cut -d '"' -f 2 | head -1)"; \
	target/test_rust_url | \
        ruby -r json -e "puts JSON.pretty_generate(JSON.parse(STDIN.read))" > $@

icu4j-54.1.1.jar: 
	wget http://central.maven.org/maven2/com/ibm/icu/icu4j/54.1.1/icu4j-54.1.1.jar

galimatias-0.2.0.jar:
	wget http://central.maven.org/maven2/io/mola/galimatias/galimatias/0.2.0/galimatias-0.2.0.jar

json-20140107.jar:
	wget http://central.maven.org/maven2/org/json/json/20140107/json-20140107.jar
