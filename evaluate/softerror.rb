#
# At the moment, there isn't a published list of expected results for
# "soft" errors.  For the moment, compare the reference implementation
# against galimatias.
#
# Note: this script only tests for the presence or absence of errors;
#       it makes no attempt to compare the error message.

require 'json'
RESULTS = File.expand_path("../useragent-results", __FILE__)
galimatias = File.open("#{RESULTS}/galimatias") do |f|
  f.gets
  f.gets
  JSON.parse(f.read)
end
refimpl = File.open("#{RESULTS}/refimpl") do |f|
  f.gets
  f.gets
  JSON.parse(f.read)
end

additional = []
galimatias.zip(refimpl).each_with_index do |(g, r), i|
  if r['exception'] and not g['exception']
    additional << [g, r, i]
  end
end

unless additional.empty?
  puts '*** additional soft errors'
  puts
  additional.each do |g, r, i|
    puts "Test #{i}:"
    puts '  ' + r['input'].inspect
    puts '  ' + r['exception'].inspect
    puts
  end
end

missing = []
galimatias.zip(refimpl).each_with_index do |(g, r), i|
  if g['exception'] and not r['exception']
    missing << [g, r, i]
  end
end

unless missing.empty?
  puts '*** missing soft errors'
  puts
  missing.each do |g, r, i|
    puts "Test #{i}:"
    puts '  ' + r['input'].inspect
    puts '  ' + g['exception'].inspect
    puts
  end
end
