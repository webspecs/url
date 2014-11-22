# Prereqs:
#    install jdk, rust, cargo
#    gem install addressable
#    clean make in parent directory

all: useragent-results testdata

testdata: \
	urlsettest.json

urlsettest.json: ../reference-implementation/test/yml2test.rb \
	../reference-implementation/test/urlsettest.yml
	ruby ../reference-implementation/test/yml2test.rb --json > $@

useragent-results: \
	useragent-results/galimatias \
	useragent-results/nodejs \
	useragent-results/rusturl \
	useragent-results/refimpl \
	useragent-results/urltestdata

softerror: softerror.rb \
	useragent-results/galimatias \
	useragent-results/refimpl
	ruby softerror.rb

clean:
	rm -rf target *.class Cargo.lock urltestdata.json urlsettest.json \
	useragent-results/galimatias \
	useragent-results/nodejs \
	useragent-results/rusturl \
	useragent-results/refimpl \
	useragent-results/urltestdata

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
	echo refimpl > $@
	date >> $@
	node testrefimpl.js >> $@

useragent-results/urltestdata: urltestdata.json \
	../reference-implementation/test/urltestdata.txt
	echo urltestdata > $@
	/bin/echo -n "Fetched " >> $@ 
	node -e "require('fs').stat('../reference-implementation/test/urltestdata.txt', \
		function(err,stats) {console.log(stats.mtime)})" >> $@
	cat urltestdata.json >> $@

testgalimatias.class: testgalimatias.java \
	icu4j-54.1.1.jar galimatias-0.0.4.jar json-20140107.jar
	export CLASSPATH=.:icu4j.1.1.jar:galimatias-0.0.4.jar:json-20140107.jar; \
	javac testgalimatias.java

useragent-results/galimatias: testgalimatias.class urltestdata.json
	echo galimatias > $@
	echo galimatias-0.2.0 >> $@
	export CLASSPATH=.:icu4j.1.1.jar:galimatias-0.0.4.jar:json-20140107.jar; \
	java testgalimatias >> $@

useragent-results/nodejs: testnodejs.js \
	../reference-implementation/test/urltestparser.js \
	../reference-implementation/test/urltestdata.txt
	echo nodejs > $@
	echo 'node.js' $(nodejs -v) >> $@
	node testnodejs.js >> $@

target/test_rust_url: Cargo.toml src/main.rs \
	../reference-implementation/test/urltestdata.txt
	cargo build

useragent-results/rusturl: target/test_rust_url
	echo rust > $@
	grep rust-url Cargo.lock  | cut -d '"' -f 2 | head -1 >> $@
	target/test_rust_url >> $@

icu4j-54.1.1.jar: 
	wget http://central.maven.org/maven2/com/ibm/icu/icu4j/54.1.1/icu4j-54.1.1.jar

galimatias-0.0.4.jar:
	wget http://central.maven.org/maven2/io/mola/galimatias/galimatias/0.0.4/galimatias-0.0.4.jar

json-20140107.jar:
	wget http://central.maven.org/maven2/org/json/json/20140107/json-20140107.jar
