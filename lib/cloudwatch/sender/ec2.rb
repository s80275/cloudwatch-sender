require "aws-sdk"

module Cloudwatch
  module Sender
    class EC2
      def initialize
        @ec2 = Aws::EC2::Client.new
        @instances_service
      end

      def list_instances(key, value)
        list_instance_ids aws_resp(key, value)
      end

      def get_instance_name(instanceid)
        puts("----------------")
        instances = ec2.describe_instances({
          dry_run: false,
          instance_ids: [instanceid]
        })
        instances.reservations.map do |reservations|
          tags = reservations.instances[0].tags
          tags.select do |tag|
            if tag["key"] == "Name"
              return tag["value"]
            end
          end
        end
        # instance.reservations[0].instances[0].tags.map do |tag|
        #   puts(tag.value)
        # end
      end

      private

      attr_reader :ec2
      attr_reader :instances_service

      def aws_resp(key, value)
        ec2.describe_instances(
          :filters => [
            {
              :name   => "tag-key",
              :values => [key]
            },
            {
              :name   => "tag-value",
              :values => [value]
            }
          ]
        )
      end

      def list_instance_ids(instances)
        instances.reservations.map do |reservations|
          reservations.instances.map(&:instance_id)
        end
      end
    end
  end
end
