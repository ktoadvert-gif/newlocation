import { withPluginApi } from "discourse/lib/plugin-api";
import { ajax } from "discourse/lib/ajax";

export default {
    name: "discourse-geo-location",

    initialize(container) {
        withPluginApi("1.0", (api) => {
            const siteSettings = container.lookup("service:site-settings");
            if (!siteSettings.discourse_geo_location_enabled) {
                return;
            }

            // Serialize geo-location fields on topic create
            api.serializeOnCreate("geo_country_id");
            api.serializeOnCreate("geo_region_id");
            api.serializeOnCreate("geo_city_id");

            // After topic created, save location via POST
            api.composerBeforeSave(() => {
                return new Promise((resolve) => {
                    resolve();
                });
            });
        });
    },
};
