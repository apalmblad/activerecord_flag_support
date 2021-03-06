Gem::Specification.new do |s|
  s.name        = 'activerecord_flag_support'
  s.version     = '0.0.14'
  s.date        = '2017-12-07'
  s.summary     = 'Boolean flag support for active record'
  s.description = 'Provide an easy way to define boolean getters and settings on an integer column in active record objects.'
  s.authors     = ['Adam Palmblad']
  s.email       = 'apalmblad@gmail.com'
  s.files       = ['lib/activerecord_flag_support.rb', 'README']
  s.homepage    = 'http://github.com/apalmblae/activercord_flag_support'
  s.license     = 'MIT'
  s.add_runtime_dependency 'activerecord', '>= 3.0.0'
end
