# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |gem|
  gem.name          = "viera_play"
  gem.version       = "1.0"
  gem.authors       = ["Pip Taylor"]
  gem.email         = ["pip@evilgeek.co.uk"]
  gem.description   = %q{Uses DLNA to play video files on Panasonic Viera
                         TVs from the command line}
  gem.summary       = %q{Play videos on Viera TVs from the command line}
  gem.homepage      = "https://github.com/pipt/viera_play"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
  gem.executables << "viera_play"

  gem.add_runtime_dependency("nokogiri")
  gem.add_runtime_dependency("streamio-ffmpeg")

  gem.add_development_dependency("rspec")
end
