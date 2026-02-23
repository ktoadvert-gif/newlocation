# frozen_string_literal: true

# name: discourse-geo-location
# about: Geo-location system for topics with Country > Region > City hierarchy
# version: 1.0.0
# authors: Developer
# url: https://github.com/dev/discourse-geo-location
# required_version: 2.7.0

enabled_site_setting :discourse_geo_location_enabled

module ::DiscourseGeoLocation
  PLUGIN_NAME = "discourse-geo-location"
end

require_relative "lib/discourse_geo_location/engine"

register_asset "stylesheets/common/geo-location.scss"

after_initialize do
  %w[
    ../app/models/discourse_geo_location/country
    ../app/models/discourse_geo_location/region
    ../app/models/discourse_geo_location/city
    ../app/models/discourse_geo_location/topic_location
    ../app/controllers/discourse_geo_location/locations_controller
    ../app/controllers/discourse_geo_location/topic_locations_controller
  ].each { |path| load File.expand_path(path + ".rb", __FILE__) }

  # Serialize location into topic_view (single topic page)
  add_to_serializer(:topic_view, :geo_location, respect_plugin_enabled: true) do
    begin
      loc = DiscourseGeoLocation::TopicLocation
        .includes(:country, :region, :city)
        .find_by(topic_id: object.topic.id)
      if loc
        {
          country_id: loc.country_id,
          country_name: loc.country&.name,
          region_id: loc.region_id,
          region_name: loc.region&.name,
          city_id: loc.city_id,
          city_name: loc.city&.name,
        }
      end
    rescue => e
      Rails.logger.warn("[DiscourseGeoLocation] Serializer error: #{e.message}")
      nil
    end
  end

  # Serialize location into topic_list_item (topic list page)
  add_to_serializer(:topic_list_item, :geo_location, respect_plugin_enabled: true) do
    begin
      loc = DiscourseGeoLocation::TopicLocation
        .includes(:country, :region, :city)
        .find_by(topic_id: object.id)
      if loc
        {
          country_id: loc.country_id,
          country_name: loc.country&.name,
          region_id: loc.region_id,
          region_name: loc.region&.name,
          city_id: loc.city_id,
          city_name: loc.city&.name,
        }
      end
    rescue => e
      Rails.logger.warn("[DiscourseGeoLocation] Serializer error: #{e.message}")
      nil
    end
  end

  # Extend TopicQuery to support location filtering via query params
  reloadable_patch do
    TopicQuery.add_custom_filter(:geo_location) do |results, topic_query|
      country_id = topic_query.options[:country_id]
      region_id = topic_query.options[:region_id]
      city_id = topic_query.options[:city_id]

      if country_id.present?
        results = results
          .joins("INNER JOIN geo_topic_locations ON geo_topic_locations.topic_id = topics.id")
          .where("geo_topic_locations.country_id = ?", country_id)

        if region_id.present?
          results = results.where("geo_topic_locations.region_id = ?", region_id)
        end

        if city_id.present?
          results = results.where("geo_topic_locations.city_id = ?", city_id)
        end
      end

      results
    end
  end

  # Save location on topic create
  DiscourseEvent.on(:topic_created) do |topic, opts, user|
    if opts[:geo_country_id].present? && opts[:geo_region_id].present? && opts[:geo_city_id].present?
      begin
        DiscourseGeoLocation::TopicLocation.create!(
          topic_id: topic.id,
          country_id: opts[:geo_country_id],
          region_id: opts[:geo_region_id],
          city_id: opts[:geo_city_id],
        )
      rescue => e
        Rails.logger.warn("[DiscourseGeoLocation] Failed to save topic location: #{e.message}")
      end
    end
  end
end
