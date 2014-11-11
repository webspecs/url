source = File.read(File.expand_path('../IdnaMappingTable.txt', __FILE__))

puts '/*'
puts source[/(#.*\n)+/]
puts '*/'
puts

source.gsub! /\s*#.*/, ''
source.gsub! /\A\n+/, ''
source.gsub! /\s*;\s*/, ';'

table = []
source.split("\n").each do |line|
  codepoints, value, mapping, status = line.split(';')
  first, last = codepoints.split('..')
  last ||= first
  first = first.to_i(16)
  last = last.to_i(16)
  if mapping
    mapping = mapping.split(' ').map {|n| n.to_i(16)}
    if mapping.length == 0
      mapping = nil 
    elsif mapping.length == 1
      mapping = mapping.first
    end
  end

  if mapping
    table << [first, last, value, mapping]
  else
    table << [first, last, value]
  end
end

(table.length-2).downto(0) do |i|
  if not table[i][3] and not table[i+1][3] and table[i][2] == table[i+1][2]
    table[i][1] = table[i+1][1]
    table.delete_at(i+1)
  end
  if Fixnum === table[i][3] and Fixnum === table[i+1][3] and table[i][3]+1 == table[i+1][3]
    table[i][1] = table[i+1][1]
    table.delete_at(i+1)
  end
end

# http://www.unicode.org/reports/tr46/#IDNA_Mapping_Table
puts <<-EOF
IDNA = {
  valid: function(codepoint) {return codepoint;},
  ignored: function() {return [];},
  mapped: function(codepoint, mapping) {return mapping;},
  disallowed: function(codepoint) {
    throw new Error("Invalid codepoint in a domain: U+" +
       ("000" + codepoint.toString(16)).slice(-4).toUpperCase());
  },
  deviation: function(codepoint, mapping, useSTD3ASCIIRules, transitional) {
    return (transitional ?  mapping : codepoint);
  },
  disallowed_STD3_valid: function(codepoint, mapping, useSTD3ASCIIRules) {
    if (useSTD3ASCIIRules) IDNA.disallowed(codepoint);
    return codepoint;
  },
  disallowed_STD3_mapped: function(codepoint, mapping, useSTD3ASCIIRules) {
    if (useSTD3ASCIIRules) IDNA.disallowed(codepoint);
    return mapping;
  }
};
EOF

puts "\nIDNA.MAPPING_TABLE = ["
table.each do |row|
  puts '  ' + row.inspect + ','
end
puts "];\n\n"

# http://www.unicode.org/reports/tr46/#Processing
puts <<-'EOF'
IDNA.processing_map = function(domain, useSTD3ASCIIRules, transitional) {

  return punycode.ucs2.decode(domain).map(function(codepoint) {

    /* binary search IDNA.MAPPING_TABLE using codepoint */
    var min = 0;
    var max = IDNA.MAPPING_TABLE.length - 1;
    while (max > min) {
      var mid = (min + max) >> 1;
      if (codepoint > IDNA.MAPPING_TABLE[mid][1]) {
        min = mid;
      } else if (codepoint < IDNA.MAPPING_TABLE[mid][0]) {
        max = mid;
      } else {
        min = max = mid;
      }
    }

    /* extract row */
    var row = IDNA.MAPPING_TABLE[min];

    /* interpolate mapping within range */
    var mapping = row[3];
    if (typeof mapping == "number") mapping += codepoint - row[0];

    /* perform specified IDNA Mapping */
    var replacement = IDNA[row[2]](codepoint, mapping,
      useSTD3ASCIIRules, transitional);

    /* return Basic Multilingual Plane characters; wrap rest in array */
    if (typeof replacement == "number") {
      if (replacement < 0x10000) return String.fromCharCode(replacement);
      replacement = [ replacement ];
    }

    /* convert codepoints to string */
    return punycode.ucs2.encode(replacement);
  }).join('');

}
EOF
