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

  # Extend TopicQuery to support location filtering
  reloadable_patch do
    # Use class_eval for a more direct patch with a guard clause
    unless ListController.respond_to?(:build_topic_list_options_geo_orig)
      ListController.class_eval do
        alias_method :build_topic_list_options_geo_orig, :build_topic_list_options
        def build_topic_list_options
          options = build_topic_list_options_geo_orig || {}
          
          # Map URL params to unique internal option keys
          if params[:country_id].present?
            options[:geo_country_id] = params[:country_id].to_i
          end
          if params[:region_id].present?
            options[:geo_region_id] = params[:region_id].to_i
          end
          if params[:city_id].present?
            options[:geo_city_id] = params[:city_id].to_i
          end
          
          options
        end
      end
    end

    TopicQuery.add_custom_filter(:geo_location) do |results, topic_query|
      begin
        c_id = topic_query.options[:geo_country_id]
        r_id = topic_query.options[:geo_region_id]
        i_id = topic_query.options[:geo_city_id]

        if c_id.present? && c_id > 0
          # Use a subquery approach - much safer than joins in TopicQuery
          # as it avoids aliasing issues and duplicate join errors.
          subquery = DiscourseGeoLocation::TopicLocation.where(country_id: c_id)
          subquery = subquery.where(region_id: r_id) if r_id.present? && r_id > 0
          subquery = subquery.where(city_id: i_id) if i_id.present? && i_id > 0
          
          results = results.where("topics.id IN (?)", subquery.select(:topic_id))
        end
      rescue => e
        Rails.logger.error("[DiscourseGeoLocation] Filter error: #{e.message}\n#{e.backtrace.first(5).join("\n")}")
      end
      
      results
    end
  end

  # Define association on Topic for display convenience
  add_to_class(:topic, :geo_topic_location) do
    @geo_topic_location ||= DiscourseGeoLocation::TopicLocation.find_by(topic_id: self.id)
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
