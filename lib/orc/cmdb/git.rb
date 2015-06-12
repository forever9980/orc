require 'git'
require 'logger'
require 'timeout'
require 'orc/cmdb/namespace'

class Orc::CMDB::Git
  def initialize(options = {})
    @repo_url = options[:origin] || raise("Need origin option")
    @local_path = options[:local_path] || raise("Need local_path option")
    @branch = options[:branch] || "master"
    @timeout = options[:timeout] || 60
    @debug = false
  end

  def update
    logger = @debug ? Logger.new(STDOUT) : nil
    if File.directory?(@local_path)
      Timeout::timeout(@timeout) do
        @git = Git.open(@local_path, :log => logger)
        @git.remotes.first.fetch
        @git.fetch('origin')
        @git.merge('origin', 'merge concurrent modifications')
        @git.pull
      end
      Timeout::timeout(@timeout) do
        Dir.chdir(@local_path) do
          system('git gc')
        end
      end
    else
      Timeout::timeout(@timeout) do
        @git = Git.clone(@repo_url, @local_path, :log => logger)
      end
    end

    if get_branch != @branch
      Timeout::timeout(@timeout) do
        @git.branch(@branch).checkout
      end
    end
  end

  def get_branch
    @git.current_branch
  end

  def commit_and_push(message = 'orc auto-updating cmdb')
    if File.directory?(@local_path)
      if @git.status.changed.size > 0
        Timeout::timeout(@timeout) do
          @git.commit_all(message)
          @git.fetch('origin')
          @git.merge('origin', 'merge concurrent modifications')
          @git.push
        end
      end
    else
      raise "#{@local_path} doesn't exist"
    end
  end
end
