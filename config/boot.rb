require 'rubygems'

#Testing swapping YAML parser to troubleshoot asset precompilation manifest.yml parsing
#TODO: Adam is filing a bug request with psych (standard YAML parser), we should update this when the bug is fixed
require 'yaml'
YAML::ENGINE.yamler = 'syck'

# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)

require 'bundler/setup' if File.exists?(ENV['BUNDLE_GEMFILE'])
