# Prereqs:
#    install jdk, rust, cargo
#    gem install addressable
#    clean make in parent directory

useragent-results: \
	useragent-results/galimatias \
	useragent-results/nodejs \
	useragent-results/rusturl \
        useragent-results/urltestdata

clean:
	rm -rf target *.class Cargo.lock urltestdata.json

clobber:
	rm -f *.jar

urltestdata.json: urltesttojson.js ../test/urltestparser.js ../test/urltestdata.txt
	node urltesttojson.js > $@

useragent-results/urltestdata: urltestdata.json ../test/urltestdata.txt
	echo urltestdata > $@
	/bin/echo -n "Fetched " >> $@ 
	node -e "require('fs').stat('../test/urltestdata.txt', \
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

useragent-results/nodejs: testnodejs.js ../test/urltestparser.js ../test/urltestdata.txt
	echo nodejs > $@
	echo 'node.js' $(nodejs -v) >> $@
	node testnodejs.js >> $@

target/test_rust_url: Cargo.toml src/main.rs ../test/urltestdata.txt
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
