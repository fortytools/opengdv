lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'gdv/version'

Gem::Specification.new do |s|
  s.name      = 'opengdv'
  s.version   = GDV::VERSION
  s.date      = '2015-09-22'

  s.homepage    = "https://github.com/vendis/opengdv"
  s.summary = 'Ruby Bibliothek für das Lesen von GDV Dateien'

  s.author = "David Lutterkort"
  s.email = "lutter@watzmann.net"
  s.license           = 'MIT'
  s.description = <<EOF
OpenGDV ist eine Bibliothek zum Lesen von Dateien im GDV Format
(http://gdv-online.de/), einem Standard zum Austausch von Daten über
Versicherungsverträge, Kunden, und andere versicherungsrelevante Details.
EOF

  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ["lib"]

  s.files         = `git ls-files -z`.split("\x0")

  s.add_development_dependency 'yard'
  s.add_development_dependency 'rake'
end
