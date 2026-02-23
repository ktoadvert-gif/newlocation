import { withPluginApi } from "discourse/lib/plugin-api";

export default {
    name: "discourse-geo-location",

    initialize(container) {
        const siteSettings = container.lookup("service:site-settings");
        if (!siteSettings.discourse_geo_location_enabled) {
            return;
        }

        withPluginApi("1.0", (api) => {
            // Serialize geo-location fields when creating a topic
            api.serializeOnCreate("geo_country_id");
            api.serializeOnCreate("geo_region_id");
            api.serializeOnCreate("geo_city_id");
        });
    },
};
