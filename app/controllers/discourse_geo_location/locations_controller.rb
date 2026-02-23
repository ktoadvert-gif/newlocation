# frozen_string_literal: true

module ::DiscourseGeoLocation
  class LocationsController < ::ApplicationController
    requires_plugin DiscourseGeoLocation::PLUGIN_NAME
    skip_before_action :check_xhr, only: [:countries, :regions, :cities]

    def countries
      countries = Country.order(:name).select(:id, :name)
      render json: { countries: countries.as_json(only: [:id, :name]) }
    end

    def regions
      params.require(:country_id)
      regions = Region.where(country_id: params[:country_id]).order(:name).select(:id, :name, :country_id)
      render json: { regions: regions.as_json(only: [:id, :name]) }
    end

    def cities
      params.require(:region_id)
      cities = City.where(region_id: params[:region_id]).order(:name).select(:id, :name, :region_id)
      render json: { cities: cities.as_json(only: [:id, :name]) }
    end
  end
end
