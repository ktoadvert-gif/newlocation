import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { ajax } from "discourse/lib/ajax";
import { i18n } from "discourse-i18n";

export default class GeoLocationFilterBar extends Component {
    @tracked countries = [];
    @tracked regions = [];
    @tracked cities = [];
    @tracked selectedCountryId = null;
    @tracked selectedRegionId = null;
    @tracked selectedCityId = null;

    constructor() {
        super(...arguments);
        this._initializeFromUrl();
        this._loadCountries();
    }

    _initializeFromUrl() {
        const params = new URLSearchParams(window.location.search);
        const countryId = params.get("country_id");
        const regionId = params.get("region_id");
        const cityId = params.get("city_id");

        if (countryId) {
            this.selectedCountryId = parseInt(countryId, 10);
            this._loadRegions(this.selectedCountryId);
        }

        if (regionId) {
            this.selectedRegionId = parseInt(regionId, 10);
            this._loadCities(this.selectedRegionId);
        }

        if (cityId) {
            this.selectedCityId = parseInt(cityId, 10);
        }
    }

    async _loadCountries() {
        try {
            const result = await ajax("/geo-location/countries");
            this.countries = result.countries;
        } catch (e) {
            // silent
        }
    }

    async _loadRegions(countryId) {
        try {
            const result = await ajax("/geo-location/regions", {
                data: { country_id: countryId },
            });
            this.regions = result.regions;
        } catch (e) {
            // silent
        }
    }

    async _loadCities(regionId) {
        try {
            const result = await ajax("/geo-location/cities", {
                data: { region_id: regionId },
            });
            this.cities = result.cities;
        } catch (e) {
            // silent
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

    get showClearButton() {
        return !!this.selectedCountryId;
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

        this._applyFilter();
    }

    @action
    async onRegionChange(regionId) {
        this.selectedRegionId = regionId;
        this.selectedCityId = null;
        this.cities = [];

        if (regionId) {
            await this._loadCities(regionId);
        }

        this._applyFilter();
    }

    @action
    onCityChange(cityId) {
        this.selectedCityId = cityId;
        this._applyFilter();
    }

    @action
    clearFilter() {
        this.selectedCountryId = null;
        this.selectedRegionId = null;
        this.selectedCityId = null;
        this.regions = [];
        this.cities = [];
        this._applyFilter();
    }

    _applyFilter() {
        // Build query string and reload page with filter params
        const params = new URLSearchParams(window.location.search);

        // Remove old geo params
        params.delete("country_id");
        params.delete("region_id");
        params.delete("city_id");

        if (this.selectedCountryId) {
            params.set("country_id", this.selectedCountryId);
        }
        if (this.selectedRegionId) {
            params.set("region_id", this.selectedRegionId);
        }
        if (this.selectedCityId) {
            params.set("city_id", this.selectedCityId);
        }

        const queryString = params.toString();
        const newUrl = queryString
            ? `${window.location.pathname}?${queryString}`
            : window.location.pathname;

        window.location.assign(newUrl);
    }
}
