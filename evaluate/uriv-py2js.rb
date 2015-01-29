require 'ruby2js/filter/functions'
gist = 'https://gist.github.com/mnot/138549'
uri_validate = 'uri_validate.py'

# fetch gist, if necessary
if not File.exist? uri_validate
  require 'nokogumbo'
  raw = Nokogiri::HTML5.get(gist).at('a[aria-label="View Raw"]')['href']
  Dir.chdir File.dirname(uri_validate) do
    system "wget -O #{uri_validate} #{URI.parse(gist)+raw}"
  end
end

# read Python source
source = File.read(uri_validate)

# extract various sections
source = File.read(uri_validate)
preamble = source[/^"""(.*?)"""/m, 1]
preamble.sub! /They should be processed with re\.VERBOSE\./, 
  "JavaScript translation of #{gist}\n"
license = source[/^__license__\s*=\s*"""\s*(.*?)"""/m, 1]
comments = source.scan(/^(((\s*|#.*)\n)+)(\w+)\s+=/)
scheme_validator = source[/re\.match\("(.*?)" % scheme_validator/, 1].
  sub('%s', '#{known[scheme]}')

# remove preamble
source.sub! /\A.*?###/m, '###'

# remove main program
source.sub! /\s+if "__main__".*/m, ''

# convert verbose triple quoted regular expression strings into simple strings
source.gsub! /\sr""".*?"""/m do |string|
  string[/""(".*?")""/m, 1].gsub(/\s/, '').
    gsub(/\\[$()*+-.?\[\]^|]/) {|str| "\\#{str}"}
end

# convert verbose single quoted regular expression strings into simple strings
source.gsub! /\sr".*?"/ do |string|
  string[/(".*?")/, 1].gsub(/\s/, '').
    gsub(/\\[$()*+-.?\[\]^|]/) {|str| "\\#{str}"}
end

# convert string interpolation into Ruby syntax
source.gsub! /%\((\w+)\)s/, '#{\1}'

# remove reference to locals for substitution
source.gsub! /\s?%\s+locals\(\)/, ''

# extract a list of known schemes (exclude false match for 'absolute')
known = source.scan(/(\w+)_URI/).flatten.uniq - ['absolute']

# append a hash of known schemes and associated regular expression strings
source += "\nknown = {" + 
  known.map {|scheme| "#{scheme}: #{scheme}_URI"}.join(',') +
  "}\n"

# define a uri_validate function
source += <<-EOF
def uri_validate(string)
  if string !~ /^\#{URI_reference}$/
    return false
  elsif not string.include? ':'
    return true
  else
    scheme = string.split(':')[0].downcase()
    return true if not known[scheme]
    return string =~ /#{scheme_validator}/
  end
end
EOF

# convert from Ruby to JavaScript
source = Ruby2JS.convert(source)

# reflow long assignments
source.gsub!(/^var \w+ = .*;$/) do |line|
  next line if line.length <= 80
  parts = line.split(' + ')
  base = ''
  work = parts.shift
  while parts.length > 0
    part = parts.shift
    if work.length <= 26 or work.length + part.length <= 75
      work += ' + ' + part
    else
      base += work + " +\n"
      work = "    #{part}"
    end
  end
  base + work
end

# reinsert comments
comments.each do |comment, *junk, var|
  next unless comment.include? '#'
  source.sub! /^(var #{var} =)/ do |decl|
    "#{comment.gsub(/^#+/) {|hashes| '/' + hashes.gsub('#', '/')}}#{decl}"
  end
end

# prepend preamble and license
source = "/*#{preamble}#{license}*/\n#{source}"

# output result
puts source
