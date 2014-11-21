require 'yaml'
require 'json'

puts <<-EOF
var fs = require("fs");
var punycode = require("../punycode");
var unorm = require("../unorm");
eval(fs.readFileSync("reference-implementation/idna.js", "utf8"));
eval(fs.readFileSync("reference-implementation/url.js", "utf8"));
eval(fs.readFileSync("reference-implementation/urlparser.js", "utf8"));
EOF

data = YAML.load_file(File.expand_path('../urlsettest.yml', __FILE__))
data.each do |attr, testcases|
  puts
  puts "exports.#{attr} = {"
  testcases.each_with_index do |testcase, index|
    puts "" unless index == 0
    puts "  #{testcase['testname']}: function(test) {"
    puts "    var url = new Url(#{testcase['url'].inspect});"
    puts "    url.#{attr} = #{testcase['value'].inspect};"
    testcase['tests'].each do |property, value|
      puts "    test.equal(url.#{property}, #{value.inspect});"
    end
    puts "    test.done();"
    puts "  },"
  end
  puts "};"
end
