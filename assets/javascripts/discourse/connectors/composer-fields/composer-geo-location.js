import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";

export default class ComposerGeoLocation extends Component {
    @tracked locationData = null;

    get model() {
        return this.args.outletArgs?.model;
    }

    get showLocationSelector() {
        // Show for new topics (action === CREATE_TOPIC)
        const model = this.model;
        if (!model) {
            return false;
        }
        // action 4 = CREATE_TOPIC, action 7 = EDIT
        return model.action === 4 || model.action === 7;
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
        // Store on the composer model so it can be sent with topic creation
        if (this.model) {
            this.model.set("geo_country_id", data.countryId);
            this.model.set("geo_region_id", data.regionId);
            this.model.set("geo_city_id", data.cityId);
        }
    }
}
