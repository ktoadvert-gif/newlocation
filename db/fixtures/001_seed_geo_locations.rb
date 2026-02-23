# frozen_string_literal: true

# Seed data for geo-location hierarchy
# Run via: bundle exec rails runner plugins/discourse-geo-location/db/fixtures/001_seed_geo_locations.rb
# Or it will be executed automatically on Discourse rebuild

# Ukraine
ukraine = DiscourseGeoLocation::Country.find_or_create_by!(name: "Ukraine")

kharkiv_oblast = DiscourseGeoLocation::Region.find_or_create_by!(
  name: "Kharkiv Oblast",
  country_id: ukraine.id,
)
DiscourseGeoLocation::City.find_or_create_by!(name: "Kharkiv", region_id: kharkiv_oblast.id)
DiscourseGeoLocation::City.find_or_create_by!(name: "Izium", region_id: kharkiv_oblast.id)

kyiv_oblast = DiscourseGeoLocation::Region.find_or_create_by!(
  name: "Kyiv Oblast",
  country_id: ukraine.id,
)
DiscourseGeoLocation::City.find_or_create_by!(name: "Kyiv", region_id: kyiv_oblast.id)

# Poland
poland = DiscourseGeoLocation::Country.find_or_create_by!(name: "Poland")

masovian = DiscourseGeoLocation::Region.find_or_create_by!(
  name: "Masovian Voivodeship",
  country_id: poland.id,
)
DiscourseGeoLocation::City.find_or_create_by!(name: "Warsaw", region_id: masovian.id)

puts "[DiscourseGeoLocation] Seed data loaded: 2 countries, 3 regions, 4 cities."
