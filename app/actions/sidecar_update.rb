module VCAP::CloudController
  class SidecarUpdate
    class InvalidSidecar < StandardError; end

    class << self
      def update(sidecar, message)
        if message.requested?(:memory_in_mb)
          sidecar.memory = message.memory_in_mb
        elsif message.requested?(:memory)
          sidecar.memory = message.memory
        end

        if message.requested?(:memory_in_mb) || message.requested?(:process_types) || message.requested?(:memory)
          validate_memory_allocation!(message, sidecar)
        end

        sidecar.name    = message.name    if message.requested?(:name)
        sidecar.command = message.command if message.requested?(:command)


        SidecarModel.db.transaction do
          sidecar.save

          if message.requested?(:process_types)
            sidecar.sidecar_process_types_dataset.destroy
            message.process_types.each do |process_type|
              sidecar_process_type = SidecarProcessTypeModel.new(type: process_type, app_guid: sidecar.app_guid)
              sidecar.add_sidecar_process_type(sidecar_process_type)
            end
          end
        end

        sidecar
      rescue Sequel::ValidationFailed => e
        error = InvalidSidecar.new(e.message)
        error.set_backtrace(e.backtrace)
        raise error
      end

      private

      def validate_memory_allocation!(message, sidecar)
        process_types = if message.requested?(:process_types)
                          message.process_types
                        else
                          sidecar.process_types
                        end
        memory = sidecar.memory

        processes = ProcessModel.where(
          app_guid: sidecar.app.guid,
          type: process_types,
        )

        processes.each do |process|
          total_sidecar_memory = process.sidecars.sum(&:memory) + memory

          if total_sidecar_memory >= process.memory
            raise InvalidSidecar.new("The memory allocation defined is too large to run with the dependent \"#{process.type}\" process")
          end
        end
      end
    end
  end
end
