# frozen_string_literal: true

DiscourseGeoLocation::Engine.routes.draw do
  get "/geo-location/countries" => "locations#countries"
  get "/geo-location/regions" => "locations#regions"
  get "/geo-location/cities" => "locations#cities"
  post "/geo-location/topics/:topic_id/location" => "topic_locations#update"
end

Discourse::Application.routes.draw do
  mount ::DiscourseGeoLocation::Engine, at: "/"
end
