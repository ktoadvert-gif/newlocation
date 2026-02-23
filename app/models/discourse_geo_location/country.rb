# frozen_string_literal: true

module ::DiscourseGeoLocation
  class Country < ActiveRecord::Base
    self.table_name = "geo_countries"

    has_many :regions,
      class_name: "DiscourseGeoLocation::Region",
      foreign_key: "country_id",
      dependent: :destroy

    validates :name, presence: true, uniqueness: true
  end
end
