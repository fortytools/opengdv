Gem::Specification.new do |s|
  s.name      = 'opengdv'
  s.version   = GDV::VERSION
  s.date      = '2015-09-22'

  s.homepage    = "https://github.com/fortytools/opengdv"
  s.summary     = "Read files in 'GDV eNorm VU-Vermittler' format"

  s.authors           = ['Jeremy Ashkenas', 'Samuel Clay', 'Ted Han']
  s.license           = 'MIT'

  s.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ["lib"]

  s.files         = `git ls-files -z`.split("\x0")
end
