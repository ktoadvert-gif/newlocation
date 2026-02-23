# frozen_string_literal: true

module ::DiscourseGeoLocation
  class City < ActiveRecord::Base
    self.table_name = "geo_cities"

    belongs_to :region,
      class_name: "DiscourseGeoLocation::Region",
      foreign_key: "region_id"

    validates :name, presence: true
    validates :region_id, presence: true
  end
end
