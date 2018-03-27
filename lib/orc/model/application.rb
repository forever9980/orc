require 'orc/model/namespace'
require 'orc/exceptions'

class Orc::Model::Application
  attr_reader :instances, :name
  def initialize(args)
    @instances = args[:instances]
    @name = args[:name]
    @mismatch_resolver = args[:mismatch_resolver] || raise('Must pass :mismatch resolver')
    @progress_logger = args[:progress_logger] || raise('Must pass :progress_logger')
    @max_loop = 100
    @options = {}
  end

  def participating_instances
    instances.select(&:in_pool?)
  end

  def get_resolutions
    proposed_resolutions = get_proposed_resolutions_for @instances

    if @options[:debug]
      @progress_logger.log("Proposed resolutions:")
      proposed_resolutions.each { |r| @progress_logger.log("    #{r.class.name} on #{r.host} group #{r.group_name}") }
    end

    incomplete_resolutions = proposed_resolutions.reject(&:complete?)

    useable_resolutions = incomplete_resolutions.reject do |resolution|
      reject = true
      begin
        resolution.check_valid(self)
        reject = false
      rescue Exception
      end
      reject
    end

    if useable_resolutions.size == 0 && incomplete_resolutions.size > 0
      raise Orc::Exception::FailedToResolve.new("Needed actions to resolve, but no actions could be taken (all " \
      "result in invalid state) - manual intervention required")
    end

    useable_resolutions
  end

  private

  def get_proposed_resolutions_for(live_instances)
    proposed_resolutions = []
    live_instances.each do |instance|
      proposed_resolutions << @mismatch_resolver.resolve(instance)
    end
    proposed_resolutions.sort_by(&:precedence)
  end
end
