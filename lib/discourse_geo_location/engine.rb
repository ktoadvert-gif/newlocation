# frozen_string_literal: true

module ::DiscourseGeoLocation
  class Engine < ::Rails::Engine
    engine_name PLUGIN_NAME
    isolate_namespace DiscourseGeoLocation
    config.autoload_paths << File.join(config.root, "lib")
  end
end
