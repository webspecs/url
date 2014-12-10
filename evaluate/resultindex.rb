require 'json'
require 'digest/md5'

Dir.chdir 'useragent-results'

agents = (Dir['*'] - ['index']).sort

tests = []
agents.each do |agent|
  results = JSON.parse(File.read(agent))
  if results['constructor']
    results['constructor'].each do |result|
      tests << {
        input: result['input'],
        base: result['base'],
      }
    end
  end
end

tests.uniq!

tests.each do |test|
  test[:index] = Digest::MD5.hexdigest("#{test[:input]} #{test[:base]}")
end

puts JSON.pretty_generate(agents: agents, tests: tests)
