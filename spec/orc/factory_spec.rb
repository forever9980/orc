$: << File.join(File.dirname(__FILE__), "..", "../lib")
$: << File.join(File.dirname(__FILE__), "..", "../test")

require 'rubygems'
require 'rspec'
require 'yaml'
require 'orc/factory'
require 'tmpdir'

class Orc::Config
  attr_reader :config_location
end

describe Orc::Factory do
  it 'can read config YAML file' do
    Dir.mktmpdir do |dir|
      home = ENV['HOME']
      ENV['HOME'] = dir
      data = {
        'cmdb_repo_url' => 'git@github.com:footest.git',
        'cmdb_local_path' => '/tmp/test-cmdb',
      }
      fn = "#{dir}/.orc.yaml"
      File.open(fn, 'w') do |f|
        f.write data.to_yaml
      end

      f = Orc::Factory.new()
      data.keys.each { |k| f.config[k].should eql( data[k] ) }
      ENV['HOME'] = home

      # Test factory methods work and don't throw exceptions
      f.cmdb
      f.remote_client
      f.cmdb_git
      f.high_level_orchestration
    end
  end
end

