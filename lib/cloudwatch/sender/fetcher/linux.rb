module Cloudwatch
  module Sender
    module Fetcher
      class Linux < EC2

        private

        def aws_metric_meta(component_meta, metric, instance)
          if metric["name"].start_with?"Disk"
            dimensions  = [{ :name => "InstanceId", :value => instance},
              { :name => "Filesystem", :value => metric["filesystem"]},
              { :name => "MountPath", :value => metric["mount_path"]}]
          else
            dimensions  = [{ :name => "InstanceId", :value => instance}]
          end
          {
            :namespace   => component_meta["namespace"],
            :metric_name => metric["name"],
            :dimensions  => dimensions,
            # :dimensions  => [{ :name => "InstanceId", :value => instance},
            #   { :name => "Filesystem", :value => metric["filesystem"]},
            #   { :name => "MountPath", :value => metric["mount_path"]}],
            :start_time  => Time.now - START_TIME,
            :end_time    => Time.now,
            :period      => 5 * 60,
            :statistics  => metric["statistics"],
            :unit        => metric["unit"]
          }
        end
      end
    end
  end
end
