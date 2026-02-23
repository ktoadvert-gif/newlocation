# frozen_string_literal: true

class CreateGeoLocationTables < ActiveRecord::Migration[7.0]
  def change
    create_table :geo_countries do |t|
      t.string :name, null: false
      t.timestamps
    end
    add_index :geo_countries, :name, unique: true

    create_table :geo_regions do |t|
      t.string :name, null: false
      t.integer :country_id, null: false
      t.timestamps
    end
    add_index :geo_regions, :country_id
    add_foreign_key :geo_regions, :geo_countries, column: :country_id

    create_table :geo_cities do |t|
      t.string :name, null: false
      t.integer :region_id, null: false
      t.timestamps
    end
    add_index :geo_cities, :region_id
    add_foreign_key :geo_cities, :geo_regions, column: :region_id

    create_table :geo_topic_locations do |t|
      t.integer :topic_id, null: false
      t.integer :country_id, null: false
      t.integer :region_id, null: false
      t.integer :city_id, null: false
      t.timestamps
    end
    add_index :geo_topic_locations, :topic_id, unique: true
    add_index :geo_topic_locations, :country_id
    add_index :geo_topic_locations, :region_id
    add_index :geo_topic_locations, :city_id
    add_index :geo_topic_locations, [:country_id, :region_id, :city_id], name: "idx_geo_topic_loc_hierarchy"
    add_foreign_key :geo_topic_locations, :topics, column: :topic_id, on_delete: :cascade
    add_foreign_key :geo_topic_locations, :geo_countries, column: :country_id
    add_foreign_key :geo_topic_locations, :geo_regions, column: :region_id
    add_foreign_key :geo_topic_locations, :geo_cities, column: :city_id
  end
end
