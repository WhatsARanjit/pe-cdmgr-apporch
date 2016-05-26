desc 'Validate Vagrantfile'
task :vagrantfile do
  sh 'ruby -c Vagrantfile'
end

desc 'Validate Ruby scripts'
task :validate_ruby do
  Dir['code/**/*.rb'].each do |f|
    sh "ruby -c #{f}"
  end
end

desc 'Validate Puppet code'
task :validate_pp do
  Dir['code/**/*.pp'].each do |f|
    sh "puppet parser validate #{f}"
  end
end

desc 'Validate YAML files'
task :validate_yaml do
  require 'yaml'
  Dir['code/**/*.yaml'].each do |f|
    puts "validate #{f}"
    YAML.load_file f
  end
end

desc 'Validate all syntax'
task :validate_all do
  Rake::Task[:vagrantfile].invoke
  Rake::Task[:validate_ruby].invoke
  Rake::Task[:validate_pp].invoke
  Rake::Task[:validate_yaml].invoke
end
