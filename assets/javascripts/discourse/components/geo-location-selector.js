import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { ajax } from "discourse/lib/ajax";
import { i18n } from "discourse-i18n";

export default class GeoLocationSelector extends Component {
    @tracked countries = [];
    @tracked regions = [];
    @tracked cities = [];
    @tracked selectedCountryId = this.args.countryId || null;
    @tracked selectedRegionId = this.args.regionId || null;
    @tracked selectedCityId = this.args.cityId || null;
    @tracked loading = false;

    constructor() {
        super(...arguments);
        this._loadCountries();

        // If editing with existing values, load dependent dropdowns
        if (this.selectedCountryId) {
            this._loadRegions(this.selectedCountryId).then(() => {
                if (this.selectedRegionId) {
                    this._loadCities(this.selectedRegionId);
                }
            });
        }
    }

    async _loadCountries() {
        try {
            const result = await ajax("/geo-location/countries");
            this.countries = result.countries;
        } catch (e) {
            // eslint-disable-next-line no-console
            console.error("Failed to load countries", e);
        }
    }

    async _loadRegions(countryId) {
        try {
            const result = await ajax("/geo-location/regions", {
                data: { country_id: countryId },
            });
            this.regions = result.regions;
        } catch (e) {
            // eslint-disable-next-line no-console
            console.error("Failed to load regions", e);
        }
    }

    async _loadCities(regionId) {
        try {
            const result = await ajax("/geo-location/cities", {
                data: { region_id: regionId },
            });
            this.cities = result.cities;
        } catch (e) {
            // eslint-disable-next-line no-console
            console.error("Failed to load cities", e);
        }
    }

    @action
    async onCountryChange(countryId) {
        this.selectedCountryId = countryId;
        this.selectedRegionId = null;
        this.selectedCityId = null;
        this.regions = [];
        this.cities = [];

        if (countryId) {
            await this._loadRegions(countryId);
        }

        this._notifyChange();
    }

    @action
    async onRegionChange(regionId) {
        this.selectedRegionId = regionId;
        this.selectedCityId = null;
        this.cities = [];

        if (regionId) {
            await this._loadCities(regionId);
        }

        this._notifyChange();
    }

    @action
    onCityChange(cityId) {
        this.selectedCityId = cityId;
        this._notifyChange();
    }

    _notifyChange() {
        if (this.args.onChange) {
            this.args.onChange({
                countryId: this.selectedCountryId,
                regionId: this.selectedRegionId,
                cityId: this.selectedCityId,
            });
        }
    }

    get countryOptions() {
        return (this.countries || []).map((c) => ({ id: c.id, name: c.name }));
    }

    get regionOptions() {
        return (this.regions || []).map((r) => ({ id: r.id, name: r.name }));
    }

    get cityOptions() {
        return (this.cities || []).map((c) => ({ id: c.id, name: c.name }));
    }
}
