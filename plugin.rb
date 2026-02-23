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

  # Define association on Topic for easier joining
  add_to_class(:topic, :geo_topic_location) do
    DiscourseGeoLocation::TopicLocation.find_by(topic_id: self.id)
  end

  # Named module for cleaner prepending and better error messages
  module ::DiscourseGeoLocation::ListControllerExtension
    def build_topic_list_options
      options = super
      options[:geo_country_id] = params[:country_id] if params[:country_id].present?
      options[:geo_region_id] = params[:region_id] if params[:region_id].present?
      options[:geo_city_id] = params[:city_id] if params[:city_id].present?
      options
    end
  end

  # Extend TopicQuery to support location filtering
  reloadable_patch do
    ListController.prepend(::DiscourseGeoLocation::ListControllerExtension)

    TopicQuery.add_custom_filter(:geo_location) do |results, topic_query|
      c_id = topic_query.options[:geo_country_id]
      r_id = topic_query.options[:geo_region_id]
      i_id = topic_query.options[:geo_city_id]

      if c_id.present?
        # Only join if not already joined
        unless results.to_sql.include?("geo_topic_locations")
          results = results.joins("INNER JOIN geo_topic_locations ON geo_topic_locations.topic_id = topics.id")
        end
        
        results = results.where("geo_topic_locations.country_id = ?", c_id.to_i)
        results = results.where("geo_topic_locations.region_id = ?", r_id.to_i) if r_id.present?
        results = results.where("geo_topic_locations.city_id = ?", i_id.to_i) if i_id.present?
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

  # ── Seed location data (idempotent) ──────────────────────────────────
  unless Rails.env.test?
    begin
      if ActiveRecord::Base.connection.table_exists?("geo_countries")
        # Ukraine
        ua = DiscourseGeoLocation::Country.find_or_create_by!(name: "Ukraine")
        kharkiv_obl = DiscourseGeoLocation::Region.find_or_create_by!(name: "Kharkiv Oblast", country_id: ua.id)
        DiscourseGeoLocation::City.find_or_create_by!(name: "Kharkiv", region_id: kharkiv_obl.id)
        DiscourseGeoLocation::City.find_or_create_by!(name: "Izium", region_id: kharkiv_obl.id)
        kyiv_obl = DiscourseGeoLocation::Region.find_or_create_by!(name: "Kyiv Oblast", country_id: ua.id)
        DiscourseGeoLocation::City.find_or_create_by!(name: "Kyiv", region_id: kyiv_obl.id)
        DiscourseGeoLocation::City.find_or_create_by!(name: "Brovary", region_id: kyiv_obl.id)

        # Poland
        pl = DiscourseGeoLocation::Country.find_or_create_by!(name: "Poland")
        masovian = DiscourseGeoLocation::Region.find_or_create_by!(name: "Masovian Voivodeship", country_id: pl.id)
        DiscourseGeoLocation::City.find_or_create_by!(name: "Warsaw", region_id: masovian.id)
        DiscourseGeoLocation::City.find_or_create_by!(name: "Radom", region_id: masovian.id)
        lesser_pl = DiscourseGeoLocation::Region.find_or_create_by!(name: "Lesser Poland Voivodeship", country_id: pl.id)
        DiscourseGeoLocation::City.find_or_create_by!(name: "Krakow", region_id: lesser_pl.id)
        DiscourseGeoLocation::City.find_or_create_by!(name: "Tarnow", region_id: lesser_pl.id)

        Rails.logger.info("[DiscourseGeoLocation] Seed data loaded: 2 countries, 4 regions, 8 cities.")
      end
    rescue => e
      Rails.logger.warn("[DiscourseGeoLocation] Seed data error: #{e.message}")
    end
  end
end
