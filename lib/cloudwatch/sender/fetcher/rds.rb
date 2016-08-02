module Cloudwatch
  module Sender
    module Fetcher
      class RDS
        def initialize(cloudwatch, sender)
          @cloudwatch = cloudwatch
          @sender = sender
        end

        def metrics(component_meta, metric)
          resp = cloudwatch.get_metric_statistics(
            :namespace   => component_meta["namespace"],
            :metric_name => metric["name"],
            :dimensions  => [{ :name => "DBInstanceIdentifier", :value => component_meta["DBInstanceIdentifier"] }],
            :start_time  => Time.now.utc - START_TIME,
            :end_time    => Time.now.utc,
            :period      => 60,
            :statistics  => metric["statistics"],
            :unit        => metric["unit"]
          )
          name = component_meta["DBInstanceIdentifier"]
          name_metrics(resp, name, metric["statistics"])
        end

        private

        attr_reader :cloudwatch, :sender

        # previos second
        START_TIME = 2 * 60

        def name_metrics(resp, name, statistics)
          resp.data["datapoints"].each do |data|
            time = data["timestamp"].to_i
            check_statistics(name, resp.data["label"], statistics, time, data)
          end
        end

        def check_statistics(name, label, statistics, time, data)
          statistics.each do |stat|
            data = {
              :tags      => {
                "metrics" => label,
                "service" => name
              },
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
