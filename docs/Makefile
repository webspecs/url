all: url-problem-statement.html url-problem-statement.txt

url-problem-statement.html: url-problem-statement.xml
	xml2rfc $< --html

url-problem-statement.txt: url-problem-statement.xml
	xml2rfc $<
