require 'json'

def hyphenate(name)
  name.gsub(/([a-z])([A-Z])/, '\1-\2').downcase
end

def expression(node, indent)
  if node['type'] == 'choice'
    puts ''.ljust(indent) + 'Choice:'
    node['alternatives'].each do |alternative|
      expression(alternative, indent+2)
    end
  elsif node['type'] == 'rule_ref'
    puts ''.ljust(indent) + 'N: ' + hyphenate(node['name'])
  elsif node['type'] == 'literal'
    puts ''.ljust(indent) + 'T: ' + node['value']
  elsif node['type'] == 'any'
    puts ''.ljust(indent) + 'T: any'
  elsif node['type'] == 'class'
    text = node['rawText'].sub('[^', '[').sub(']i', ']')
    if node['inverted']
      puts ''.ljust(indent) + 'T: any except ' + text
    else
      puts ''.ljust(indent) + 'T: any of ' + text
    end
  elsif node['type'] == 'action'
    expression(node['expression'], indent)
  elsif node['type'] == 'labeled'
    expression(node['expression'], indent)
  elsif node['type'] == 'optional'
    puts ''.ljust(indent) + 'Optional:'
    expression(node['expression'], indent+2)
  elsif node['type'] == 'zero_or_more'
    puts ''.ljust(indent) + 'ZeroOrMore:'
    expression(node['expression'], indent+2)
  elsif node['type'] == 'one_or_more'
    puts ''.ljust(indent) + 'OneOrMore:'
    expression(node['expression'], indent+2)
  elsif node['type'] == 'sequence'
    puts ''.ljust(indent) + 'Sequence:'
    node['elements'].each do |element|
      expression(element, indent+2)
    end
  elsif node['type'] == 'semantic_and'
  else
    puts ''.ljust(indent) + '??? ' + node['type'] + ' ???'
  end
end

puts <<-EOF + "\n"
<style>
  .grammar-rule {
    color: black;
    background-color: hsl(120, 100%, 90%);
    font-weight: bold;
    padding: 2px;
    border: 2px solid black;
  }
</style>

<pre class="metadata">
Title: URL Standard
Group: WHATWG
H1: URL
Shortname: url
Status: LS
Editor: Sam Ruby, IBM https://www.ibm.com/, rubys@intertwingly.net, http://intertwingly.net/blog/
Abstract: This specification <a href="http://agiledictionary.com/209/spike/">spike</a> defines parsing rules for URLs
Logo: https://resources.whatwg.org/logo-url.svg
!Version History: <a href="https://github.com/rubys/url/commits/peg.js">https://github.com/rubys/url/commits/peg.js</a>
!Participate: <a href="https://whatwg.org/mailing-list">whatwg@whatwg.org</a> (<a href="https://whatwg.org/mailing-list#specs">archives</a>)
!Participate: <a href="http://wiki.whatwg.org/wiki/IRC">IRC: #whatwg on Freenode</a>
</pre>

Goals {#goals}
=====

<ol>
<li>Resolve 
<a href="https://www.w3.org/Bugs/Public/show_bug.cgi?id=25946">bug 25946</a>
by merging this specification with the
<a href="https://url.spec.whatwg.org/">URL Living Standard</a>.
Once a new baseline has been established, evolve the standard towards greater
web compatibility, greater interoperability, and simpler algorithms, in that
order.
<li>Provide a <a
href="http://intertwingly.net/blog/2014/10/21/pegurl-js">reference
implementation</a>, where parts of this specification and parts of that
reference implementation are generated from a common source.
</ol>

Todos {#todos}
=====

  * define soft parse errors.  The <a href="https://url.spec.whatwg.org/">URL
    living standard</a> has a start, but based on <a
    href="http://intertwingly.net/projects/pegurl/urltest-results/">test
    results</a>, there clearly needs to be more.
  * make it more clear what is normative; to be honest, I'm confused on this
    point as the only real normative requirement for the parts defined by this
    spec-let is "produce the same output as the algorithm defined herein".
  * define where base URLs come from.
  * define path concatention

Other todos appear as notes.
EOF

puts <<-EOF
Parsing Rules {#parsing-rules}
=============

These railroad diagrams, as modified by the accompanying text, define grammar
production rules for URLs.  They are to be evaluated sequentially, first
left-to-right then top-to-bottom, backtracking as necessary, until a complete
match against the input provided is found.

Each rule can be invoked individually.  Rules can also invoke one another.
Rules when evaluated return a JSON objection, typically either a string or an
object where all of the values are strings.  The one exception is path values,
which are arrays of strings.
EOF

grammar = File.read('url.pegjs')

prose = Hash[grammar.scan(/^\/\*\n?(.*?)\*\/\s*(\w+)/m).map { |text, name|
  indent = text.split("\n").map {|line| line[/^ */]}.reject(&:empty?).min
  text.gsub!(/@([A-Z][-\w]+)/) do
    "<code class=grammar-rule>#{hyphenate $1}</code>"
  end
  text.gsub!(/\$([a-z][.\w]+)/) do
    "<code>#{$1}</code>"
  end
  text.gsub!(/"( |\S+)"/) do
    "\"<code>#{$1}</code>\""
  end
  text.gsub!(/(U\+[0-9a-fA-F]{4})/) do
    "<code>#{$1.upcase}</code>"
  end
  text.gsub!(/(0x[0-9a-fA-F]{2}+)/) do
    "<code>#{$1.upcase.sub('0X', '0x')}</code>"
  end
  text.gsub!(/`(.*?)`/) do
    "<code>#{$1.gsub(/<\/?code>/, '')}</code>"
  end
  [name, text.gsub(/^#{indent}/, '')]
}]

rules = JSON.load(File.read('url.pegjson'))['rules']
rules.each do |rule|
  name = hyphenate(rule['name'])
  puts
  puts "## #{name} ## {##{name}}"

  puts
  puts "<pre class=railroad>"
  expression(rule['expression'], 0)
  puts "</pre>"

  if prose[rule['name']]
    puts 
    puts prose[rule['name']]
  end
end
