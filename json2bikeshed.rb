require 'json'
require 'stringio'

source = File.read('url.src')
config = File.read('.git/config')

group = config[/\[remote "origin"\]\s+url =.*?:(.*?)\//, 1].upcase

source.gsub!(/#ifdef.*?#endif\n/m) do |conditions|
  result = nil
  conditions.split(/^(#.*)\n/)[1..-2].each_slice(2) do |condition, text|
    if ["#ifdef #{group}", '#else'].include? condition
      result ||= text
    end
  end
  result
end

def hyphenate(name)
  name.gsub(/([a-z])([A-Z])/, '\1-\2').downcase
end

def expression(node, indent, output)
  if node['type'] == 'choice'
    output.puts ''.ljust(indent) + 'Choice:'
    node['alternatives'].each do |alternative|
      expression(alternative, indent+2, output)
    end
  elsif node['type'] == 'rule_ref'
    output.puts ''.ljust(indent) + 'N: rule-' + hyphenate(node['name'])
  elsif node['type'] == 'literal'
    output.puts ''.ljust(indent) + 'T: ' + node['value']
  elsif node['type'] == 'any'
    output.puts ''.ljust(indent) + 'T: any'
  elsif node['type'] == 'class'
    text = node['rawText'].sub('[^', '[').sub(']i', ']')
    if node['inverted']
      output.puts ''.ljust(indent) + 'T: any except ' + text
    elsif text =~ /^\[\\?(.)\\?(.)\]$/
      output.puts ''.ljust(indent) + 'Choice:'
      output.puts ''.ljust(indent) + "  T: #{$1}"
      output.puts ''.ljust(indent) + "  T: #{$2}"
    else
      output.puts ''.ljust(indent) + 'T: any of ' + text
    end
  elsif node['type'] == 'action'
    expression(node['expression'], indent, output)
  elsif node['type'] == 'labeled'
    expression(node['expression'], indent, output)
  elsif node['type'] == 'optional'
    output.puts ''.ljust(indent) + 'Optional:'
    expression(node['expression'], indent+2, output)
  elsif node['type'] == 'zero_or_more'
    output.puts ''.ljust(indent) + 'ZeroOrMore:'
    expression(node['expression'], indent+2, output)
  elsif node['type'] == 'one_or_more'
    output.puts ''.ljust(indent) + 'OneOrMore:'
    expression(node['expression'], indent+2, output)
  elsif node['type'] == 'sequence'
    output.puts ''.ljust(indent) + 'Sequence:'
    node['elements'].each do |element|
      expression(element, indent+2, output)
    end
  elsif node['type'] == 'semantic_and'
  else
    output.puts ''.ljust(indent) + '??? ' + node['type'] + ' ???'
  end
end

grammar = File.read('url.pegjs')
header = {}

prose = Hash[grammar.scan(/^\/\*\n?(.*?)\*\/\s*(\w+)/m).map { |text, name|
  if text =~ /\A *\*/
    header[name] = "\n" + text[/(\s*\*\s.*\n)+/].gsub(/^\s*\*\s/, '')
    text = text[/\/\*\n?(.*)/m, 1]
  end

  indent = text.split("\n").map {|line| line[/^ */]}.reject(&:empty?).min
  text.gsub!(/@([A-Z][-\w]+)'?/) do
    "<code class=grammar-rule><a href=#rule-#{hyphenate $1}>#{hyphenate $1}</a></code>"
  end
  text.gsub!(/\$([a-z](\.\w|\w)*)/) do
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
  text.gsub!(/\b(\d+)\b/) do
    "<code>#{$1}</code>"
  end
  text.gsub!(/`(.*?)`/) do
    "<code>#{$1.gsub(/<\/?code>/, '')}</code>"
  end
  text.gsub!(/href="(.*?)"/) do
    "href=\"#{$1.gsub(/<\/?code>/, '')}\""
  end
  [name, text.gsub(/^#{indent}/, '')]
}]

rules = JSON.load(File.read('url.pegjson'))['rules']
output = StringIO.new
rules.each do |rule|
  name = hyphenate(rule['name'])
  output.puts header[rule['name']] if header[rule['name']]
  output.puts
  output.puts "<h4 id=rule-#{name} class=no-toc>#{name}(input)</h4>"

  returns = prose[rule['name']].slice! /returns: .*?\s*\n\n/m

  output.puts "\n" + returns if returns
  output.puts
  output.puts "<pre class=railroad>"
  expression(rule['expression'], 0, output)
  output.puts "</pre>"

  if prose[rule['name']]
    output.puts 
    output.puts prose[rule['name']]
  end
end

source.sub! /^#include <url.pegjs>\n/, output.string

puts source
