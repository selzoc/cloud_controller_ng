require 'cloud_controller/diego/docker/lifecycle_data'
require 'cloud_controller/diego/docker/staging_action_builder'
require 'cloud_controller/diego/docker/task_action_builder'

module VCAP
  module CloudController
    module Diego
      module Docker
        class LifecycleProtocol
          def lifecycle_data(staging_details)
            lifecycle_data              = Diego::Docker::LifecycleData.new
            lifecycle_data.docker_image = staging_details.package.image
            lifecycle_data.docker_user = staging_details.package.docker_username
            lifecycle_data.docker_password = staging_details.package.docker_password

            lifecycle_data.message
          end

          def staging_action_builder(config, staging_details)
            StagingActionBuilder.new(config, staging_details)
          end

          def task_action_builder(config, task)
            TaskActionBuilder.new(config, task, { droplet_path: task.droplet.docker_receipt_image })
          end

          def desired_lrp_builder(config, process)
            DesiredLrpBuilder.new(config, builder_opts(process))
          end

          def desired_app_message(process)
            droplet = droplet_from_process(process)
            {
              'start_command' => process.command,
              'docker_image'  => droplet.docker_receipt_image,
              'docker_user' => droplet.docker_receipt_username,
              'docker_password' => droplet.docker_receipt_password,
            }
          end

          private

          def droplet_from_process(process)
            droplet_guid = process.app.revisions_enabled && process.revision&.droplet_guid
            return DropletModel.find(guid: droplet_guid) if droplet_guid
            return process.current_droplet
          end

          def builder_opts(process)
            droplet = droplet_from_process(process)
            {
              ports: Protocol::OpenProcessPorts.new(process).to_a,
              docker_image: droplet.docker_receipt_image,
              execution_metadata: process.execution_metadata,
              start_command: process.command,
            }
          end
        end
      end
    end
  end
end
