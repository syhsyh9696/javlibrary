# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'javlibrary/version'

Gem::Specification.new do |spec|
  spec.name          = "javlibrary"
  spec.version       = Javlibrary::VERSION
  spec.authors       = ["Yuanhao Sun"]
  spec.email         = ["sunyuanhao123456@gmail.com"]

  spec.summary       = %q{Easy way to create your own AVlibrary}
  spec.description   = %q{It's a web-spider moudule for Javlibrary(Japan AV Library) website.}
  spec.homepage      = "https://github.com/syhsyh9696/javlibrary"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.14"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "mechanize", "~> 2.7"
  spec.add_development_dependency "rest-client", "~> 2.0"
  spec.add_development_dependency "mysql2", "~> 0.4"
  spec.add_development_dependency "nokogiri", "~> 1.7"

end
