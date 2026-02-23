# frozen_string_literal: true

module ::DiscourseGeoLocation
  class TopicLocationsController < ::ApplicationController
    requires_plugin DiscourseGeoLocation::PLUGIN_NAME
    before_action :ensure_logged_in

    def update
      topic = Topic.find(params[:topic_id])
      guardian.ensure_can_edit!(topic)

      params.require(:country_id)
      params.require(:region_id)
      params.require(:city_id)

      # Validate that the location hierarchy is correct
      country = Country.find(params[:country_id])
      region = Region.find_by!(id: params[:region_id], country_id: country.id)
      city = City.find_by!(id: params[:city_id], region_id: region.id)

      location = TopicLocation.find_or_initialize_by(topic_id: topic.id)
      location.update!(
        country_id: country.id,
        region_id: region.id,
        city_id: city.id,
      )

      render json: {
        success: true,
        geo_location: {
          country_id: country.id,
          country_name: country.name,
          region_id: region.id,
          region_name: region.name,
          city_id: city.id,
          city_name: city.name,
        }
      }
    end
  end
end
