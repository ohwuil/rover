require 'rubygems'
require 'rake'
require 'echoe'

Echoe.new('rover', '0.1.0') do |p|
  p.description     = "Encapsulate Brookone Rover"
  p.url             = ""
  p.author          = "How Liu"
  p.email           = ""
  p.ignore_pattern  = ["tmp/*", "script/*"]
  p.development_dependencies = []
end

Dir["#{File.dirname(__FILE__)}/tasks/*.rake"].sort.each { |ext| load ext }