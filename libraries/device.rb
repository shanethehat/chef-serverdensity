#
# Cookbook Name:: serverdensity
# Library:: device

module ServerDensity
  class Device

    class << self
      @@cache = {}

      def create(meta)
        name = meta[:name] || meta
        @@cache[name] ||= begin
          device = API.create_device(meta)
          device.extend Base
        end
      end

      def find(meta)
        @@cache[meta] ||= begin
          meta = {:name => meta} if meta.class == String
          device = API.find_device(meta)
          return nil if device.nil?
          device.extend Base
          @@cache[device.name] = device
        end
      end
    end

    module Base

      def agent_key
        self['agentKey']
      end

      def group
        self['group']
      end

      def hostname
        self['hostname']
      end

      def name
        self['name']
      end

      def id
        self['_id']
      end

      def tags
        self['tags']
      end

      def alerts
        @alerts ||= Alert.find(self)
      end

      def watch(*args)
        alert = Alert.create(self, *args)
        alerts << alert if alert
        alert
      end

      def reset
        alerts.delete_if do |alert|
          alert.delete
        end
        @reset = alerts.empty?
      end

      def reset?
        @reset || false
      end

      def update(meta)
        diff = API.update_device(self, meta)
        self.merge! diff if diff
        diff
      end

    end

  end
end
