# frozen_string_literal: true

module ::DiscourseGeoLocation
  class TopicLocation < ActiveRecord::Base
    self.table_name = "geo_topic_locations"

    belongs_to :topic
    belongs_to :country,
      class_name: "DiscourseGeoLocation::Country",
      foreign_key: "country_id"
    belongs_to :region,
      class_name: "DiscourseGeoLocation::Region",
      foreign_key: "region_id"
    belongs_to :city,
      class_name: "DiscourseGeoLocation::City",
      foreign_key: "city_id"

    validates :topic_id, presence: true, uniqueness: true
    validates :country_id, presence: true
    validates :region_id, presence: true
    validates :city_id, presence: true
  end
end
