# frozen_string_literal: true

require "rake/clean"

CLEAN.include("tmp")
CLOBBER.include("tmp")

Dir["integration/tasks/**/*.rake"].each { |f| import f }

require "rubocop/rake_task"

RuboCop::RakeTask.new

desc "Open a pry console in the Backup context"
task :console do
  require "pry"
  require "backup"
  ARGV.clear
  Pry.start || exit
end

def version_file
  File.join(File.expand_path("lib/backup/version.rb"))
end

def current_version
  Backup.send(:remove_const, :VERSION)
  load version_file
  Backup::VERSION
end

# Validates version numbers
#
# Valid version number format:
# - 10.0.0
# - 10.0.1.alpha
# - 10.0.1.alpha.1
# - 10.0.1.beta
# - 10.0.1.beta.1
# - 10.0.1.rc
# - 10.0.1.rc.1
def valid_version?(version)
  version =~ %r{\d+\.\d+\.\d+(\.(alpha|beta|rc)(\.\d+)?)?}
end

def current_branch
  `git rev-parse --abbrev-ref HEAD`.chomp
end

# Using the gemspec to get the actual version used by RubyGems because
# of the .pre automatic prefixing
def gemspec
  Gem::Specification.load(__dir__ + "/backupii.gemspec")
end

desc "Release new BackupII gem version. Use this to release a new version."
task :release do
  puts "Current version: #{current_version}"
  print "Enter new version: "
  new_version = $stdin.gets.chomp

  abort "ERROR: Invalid version number: #{new_version.inspect}" unless valid_version?(new_version)

  puts "Creating new version: #{new_version}"

  lines = File.readlines(version_file)
  File.open(version_file, "w+") do |file|
    lines.each do |line|
      if line =~ %r{VERSION =}
        file.puts %(  VERSION = "#{new_version}")
      else
        file.write line
      end
    end
  end

  # Check if file saved correctly
  unless current_version == new_version
    abort "ERROR: Versions don't match!\n"\
      "Current version:#{current_version}\n"\
      "New version: #{new_version}"
  end

  puts `gem build backupii.gemspec`

  puts "Pushing to repository.."
  puts `git commit -m "Release v#{new_version} [ci skip]" #{version_file}`
  puts `git tag v#{new_version}`
  puts `git push origin v#{new_version} #{current_branch}`

  puts "Publishing BackupII version #{new_version}"
  puts `gem push backupii-#{gemspec.version}.gem`

  puts "BackupII version #{new_version} released!"
end

namespace :docker do
  task :build do
    sh "docker-compose build"
  end
  desc "Prepare the bundle on the Docker machine"
  task prepare: ["docker:build"] do
    run_in_docker_container "bin/docker_test prepare"
  end
  desc "Remove Docker containers and images for Backup"
  task :clobber do
    images = `docker images | grep 'backup/test-suite' | awk '{ print $3 }'`
      .tr("\n", " ")
    `docker rmi #{images}` unless images.empty?
  end
  desc "Run RSpec integration tests with Docker Compose"
  task integration: ["docker:build", "integration:files"] do
    run_in_docker_container "bin/docker_test integration"
  end
  desc "Start a container environment with an interactive shell"
  task shell: ["docker:build"] do
    run_in_docker_container "bin/docker_test console"
  end
  desc "Run RSpec unit tests with Docker Compose"
  task spec: ["docker:build"] do
    run_in_docker_container "bin/docker_test rspec"
  end

  def run_in_docker_container(command)
    sh "docker-compose run --rm ruby_backup_tester #{command}"
  end
end
