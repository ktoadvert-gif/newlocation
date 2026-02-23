# frozen_string_literal: true

module ::DiscourseGeoLocation
  class Region < ActiveRecord::Base
    self.table_name = "geo_regions"

    belongs_to :country,
      class_name: "DiscourseGeoLocation::Country",
      foreign_key: "country_id"

    has_many :cities,
      class_name: "DiscourseGeoLocation::City",
      foreign_key: "region_id",
      dependent: :destroy

    validates :name, presence: true
    validates :country_id, presence: true
  end
end
