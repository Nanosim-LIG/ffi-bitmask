Gem::Specification.new do |s|
  s.name = 'ffi-bitmask'
  s.version = "0.1.0"
  s.author = "Brice Videau"
  s.email = "brice.videau@imag.fr"
  s.homepage = "https://github.com/Nanosim-LIG/ffi-bitmask"
  s.summary = "bitmask support for ffi"
  s.description = "bitmask support for ffi heavily relying on FFI internals"
  s.files = Dir['ffi-bitmask.gemspec', 'LICENSE', 'lib/**/*']
  s.has_rdoc = true
  s.license = 'BSD-2-Clause'
  s.required_ruby_version = '>= 1.9.3'
  s.add_dependency 'ffi', '~> 1.9', '>=1.9.3'
end
