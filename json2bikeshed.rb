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
!Participate: <a href="mailto:public-webapps@w3.org">public-webapps@w3.org</a> (<a href="http://lists.w3.org/Archives/Public/public-webapps/">archives</a>)
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
href="https://github.com/rubys/url/tree/peg.js/reference-implementation">reference
implementation</a>, where parts of this specification and parts of that
reference implementation are generated from a <a href="https://github.com/rubys/url/blob/peg.js/url.pegjs">common source</a>.
Included in the reference implementation is a <a href="http://intertwingly.net/projects/pegurl/liveview.html">Live DOM URL Viewer</a>.
<li>Integrate with <a href="https://travis-ci.org/">Travis</a> and activate the <a href="http://docs.travis-ci.com/user/getting-started/#Step-two%3A-Activate-GitHub-Webhook">GitHub WebHook</a> so that proposed changes are verified to build correctly and pass the relevant tests.</a>
<li>Reference <a href="https://tools.ietf.org/html/draft-ietf-appsawg-uri-scheme-reg-04">draft-thaler-appsawg-uri-scheme-reg</a> as the scheme registration mechanism in the <a href="https://url.spec.whatwg.org/#url-writing">URL writing</a> section.
<li>Incorporate the substance of the <a href="http://www.w3.org/TR/html5/references.html#refsURL">informative note</a> that precedes the [URL] normative reference in the <a href="http://www.w3.org/TR/html5/">HTML5 Recommendation</a> into a status section or equivalent in this document.
</ol>

Todos {#todos}
=====

These are items that should be done before the proposed merge.

  * Define more soft <a>parse errors</a>.  The 
    <a href="https://url.spec.whatwg.org/">URL living standard</a> has a start,
    but based on <a href="http://intertwingly.net/projects/pegurl/urltest-results/">test
    results</a>, there clearly needs to be more.
  * Make it more clear what is normative; to be honest, I'm confused on this
    point as the only real normative requirement for the parts defined by this
    spec-let is "produce the same output as the algorithm defined herein".

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

Two types of <dfn>parse errors</dfn> are defined.  Hard errors (indicated in
the spec with the following text: <em>terminate processing with a parse
error</em>) are mandatory.  Soft errors (all other errors) are optional.  User
agents are encouraged to expose <a
href="https://url.spec.whatwg.org/#parse-error">parse errors</a> somehow.

Note: the following subsections are intended to replace steps 5-8 in the 
<a href="https://url.spec.whatwg.org/#concept-basic-url-parser">basic url parser</a>.  It also works out better if step 3 were to default <var>base</var> to a
non-null value, ideally one with a non-relative scheme, for example:
<code>{'scheme': 'about'}</code>.
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

puts "\n" + <<-EOF
Common Functions {#common-functions}
=====

To <dfn>cleanse</dfn> a string given an <var>encode set</var>, run these steps:

 * If any character in the string not a
     <a href="https://url.spec.whatwg.org/#url-code-points">URL code point</a>
     or a percent sign ("%"), indicate a parse error.

 * If any U+0009, U+000A, U+000D, U+200B, U+2060, or U+FEFF characters are
    present in the string, remove those characters and indicate a
    <a>parse error</a>.

 * if the <var>encode set</var> is non-null,
    <a href="https://url.spec.whatwg.org/#percent-encode">Percent encode</a>
    the result using the provided <var>encode set</var>.

 * Return the result as a string.

To do <dfn>path concatenation</dfn> given a <var>base</var> array of path
names, and a <var>path<path> array of names, perform the following steps:

 * If <var>base</var> is null, set <var>base</var> to an empty array.  Otherwise
     make a local copy of the <var>base</var> array.

 * If the first element on <var>path</var> is ".", remove this first element
     from <var>path</var> as well as the last element (if any) of
     <var>base</var>.

 * If <var>path.length</var> is one, and the first and only element on the
     <var>path</var> is an empty string, set <var>path</var> to the value of
     <var>base</var>.

 * Otherwise if <var>path.length</var> is greater than one, and the first
     element on the <var>path</var> is the empty string, remove the first
     element from the <var>path</var>.

 * Otherwise, remove the last element (if any) of <var>base</var> and then
     prepend the values of the <var>base</var> array to the <var>path</var>
     array.
EOF
