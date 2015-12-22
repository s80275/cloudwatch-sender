module Cloudwatch
  module Sender
    module Fetcher
      class EC2
        def initialize(cloudwatch, sender)
          @cloudwatch = cloudwatch
          @sender = sender
        end

        def metrics(component_meta, metric)
          ec2_metrics(instance_list(component_meta), component_meta, metric)
        end

        private

        attr_reader :cloudwatch, :sender

        # previos second
        START_TIME = 10 * 60
        #puts(Time.now.utc - START_TIME)
        #puts(Time.now.utc)

        def ec2_metrics(instance_list, component_meta, metric)
          instance_list.each do |instance|
            metric_data = aws_metric_meta(component_meta, metric, instance)
            resp = cloudwatch.get_metric_statistics metric_data
            service = ec2.get_instance_name(instance)
            puts(instance + " : " + service)
            name_metrics(resp, instance, component_meta["ec2_tag_value"], metric["statistics"], service)
          end
        end

        def aws_metric_meta(component_meta, metric, instance)
          {
            :namespace   => component_meta["namespace"],
            :metric_name => metric["name"],
            :dimensions  => [{ :name => "InstanceId", :value => instance }],
            :start_time  => Time.now - START_TIME,
            :end_time    => Time.now,
            :period      => 5 * 60,
            :statistics  => metric["statistics"],
            :unit        => metric["unit"]
          }
        end

        def ec2
          Cloudwatch::Sender::EC2.new
        end

        def instance_list(component_meta)
          ec2.list_instances(
            component_meta["ec2_tag_key"], component_meta["ec2_tag_value"]
          ).flatten
        end

        def name_metrics(resp, instance, name, statistics, service)
          resp.data["datapoints"].each do |data|
            check_statistics(instance, name, resp.data["label"], statistics, metric_time(data), data, service)
          end
        end

        def metric_time(data)
          data["timestamp"].to_i
        end

        def check_statistics(instanceid, name, label, statistics, time, data, service)
          statistics.each do |stat|
            data = {
              :tags      => { "metrics" => label, "instance" => instanceid, "service" => service.tr("^A-Za-z0-9", "") },
              :timestamp => time,
              :values    => { :value => data[stat.downcase] }
            }
            # puts data
            sender.write_data(data)
          end
        end
      end
    end
  end
end
