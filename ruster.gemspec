# encoding: utf-8

Gem::Specification.new do |s|
  s.name              = "ruster"
  s.version           = "0.0.4"
  s.summary           = "A simple Redis Cluster Administration tool"
  s.description       = "Control your Redis Cluster from the command line."
  s.authors           = ["Leandro López"]
  s.email             = ["inkel.ar@gmail.com"]
  s.homepage          = "http://inkel.github.com/ruster"
  s.license           = "MIT"

  s.executables.push("ruster")

  s.add_dependency   "redic"
  s.add_dependency   "clap"

  s.add_development_dependency "protest"

  s.files             = `git ls-files`.split("\n")
end
