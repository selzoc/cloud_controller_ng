module VCAP::CloudController
  class ResourceMatch

    attr_reader :descriptors, :minimum_size, :maximum_size, :resource_batch_id

    FILE_SIZE_GROUPS = {
      '< 1KB':    0...                 1.kilobyte,
      '< 100KB':  1.kilobyte...      100.kilobytes,
      '< 1MB':    100.kilobytes...     1.megabyte,
      '< 100MB':  1.megabyte...      100.megabytes,
      '< 1GB':    100.megabytes...     1.gigabyte,
      '> 1GB':    1.gigabyte..     Float::INFINITY
    }

    def initialize(descriptors)
      @descriptors = descriptors
      @resource_batch_id = SecureRandom.uuid
    end

    def match_resources
      prior_match_log
      time_by_bucket = {}
      FILE_SIZE_GROUPS.keys.each do |key|
        time_by_bucket[key] = 0
      end

      known_resources = []
      resources_by_filesize.each do |name, resources|
        resources.each do |resource|
          start_time = Time.now
          known_resources << resource if resource_pool.resource_known?(resource)
          time_took = Time.now - start_time
          time_by_bucket[name] += time_took
        end
      end
      after_match_log(time_by_bucket)
      known_resources
    end


    def resource_count_by_filesize
      counted = resources_by_filesize.transform_values(&:count)

      FILE_SIZE_GROUPS.keys.each do |key|
        # if a group does not have any resources, we need to set it to 0
        counted[key] ||= 0
      end
      counted
    end

    private

    def resources_by_filesize
      allowed_resources.group_by do |descriptor|
        FILE_SIZE_GROUPS.detect { |_key, range| range.include?(descriptor['size']) }.first
      end
    end


    def prior_match_log
      logger.info({
        resource_match_id: resource_batch_id,
        total_resources_to_match: allowed_resources.count,
        resource_count_by_size: resource_count_by_filesize
      })
    end

    def after_match_log(time_by_bucket)
      logger.info({
        resource_match_id: resource_batch_id,
        total_resources_to_match: allowed_resources.count,
        resource_count_by_size: resource_count_by_filesize,
        resource_match_time_by_size: time_by_bucket
      })
    end

    def allowed_resources
      @allowed_resources ||= descriptors.select { |descriptor| resource_pool.size_allowed?(descriptor['size']) }
    end

    def logger
      @logger ||= Steno.logger('cc.resource_pool')
    end

    def resource_pool
      @resource_pool ||= VCAP::CloudController::ResourcePool.instance
    end

  end
end

