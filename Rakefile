# -*- coding: utf-8 -*-
require 'rake'
require 'rdoc/task'
require 'rake/testtask'
require 'rubygems/package_task'
require 'yard'
require 'gdv/version'

GDV_XML = "format/VUVM2009_011109.xml"
RECTYPES = "lib/gdv/format/data/rectypes.txt"

file RECTYPES => [ GDV_XML, "format/rectypes.rb" ] do |t|
    ruby "format/rectypes.rb", GDV_XML, RECTYPES
end

desc "Compile GDV XML into parse tables"
task :compile => RECTYPES

Rake::RDocTask.new do |t|
    t.main = "README.rdoc"
    t.rdoc_files.include("README.rdoc", "lib/**/*.rb")
end

YARD::Rake::YardocTask.new do |t|
  t.options += ['--title', "OpenGDV #{GDV::VERSION} Documentation"]
end

Rake::TestTask.new(:test) do |t|
    t.test_files = FileList['tests/tc_*.rb']
    t.libs = [ 'lib', 'tests/lib' ]
end

task :default => :test
