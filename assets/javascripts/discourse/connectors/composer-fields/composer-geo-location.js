import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";

export default class ComposerGeoLocation extends Component {
    @tracked locationData = null;

    get model() {
        return this.args.outletArgs?.model;
    }

    get showLocationSelector() {
        const model = this.model;
        if (!model) {
            return false;
        }
        // Discourse uses string action types
        const act = model.get ? model.get("action") : model.action;
        return (
            act === "createTopic" ||
            act === "edit" ||
            act === "privateMessage" ||
            // Always show if model exists and it's the first post
            model.get?.("topicFirstPost")
        );
    }

    get existingCountryId() {
        return this.model?.topic?.geo_location?.country_id || null;
    }

    get existingRegionId() {
        return this.model?.topic?.geo_location?.region_id || null;
    }

    get existingCityId() {
        return this.model?.topic?.geo_location?.city_id || null;
    }

    @action
    onLocationChange(data) {
        this.locationData = data;
        const model = this.model;
        if (model) {
            if (model.set) {
                model.set("geo_country_id", data.countryId);
                model.set("geo_region_id", data.regionId);
                model.set("geo_city_id", data.cityId);
            }
        }
    }
}
