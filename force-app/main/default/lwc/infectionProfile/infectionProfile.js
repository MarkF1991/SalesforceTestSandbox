import { LightningElement, track } from 'lwc';
import { getQueryParams, pushStateToUrl } from "c/communitiesNavigation";
import InfectionProfileService from "./infectionProfileService";
import { cleanId, getSchoolConfig } from "c/utilitiesFunction";

export default class InfectionProfile extends LightningElement {
    pageHeaderLabel = "Security";
    @track schoolId;
    @track selectedfilter = { dateFilter: { start: null, end: null } };
    @track queryParams = {};

    @track infectionInformationDataIsLoading = false;

    @track infectionInformationItems = [];
    @track noDeviceData = false;
    @track currentTab = null;
    @track previousTab = null;

    @track devicesTabInActive = true;
    @track devicesListViewOverride = "device-infections";

    service = null;

    constructor() {
        super();
        this.service = new InfectionProfileService();
    }

    get infectionId() {
        if(this.queryParams) {
            return cleanId(this.queryParams.infectionid);
        }
        return "";
    }

    get title() {
        return this.infectionId;
    }

    async connectedCallback() {
        this.queryParams = getQueryParams(window.location.search);

        if (this.queryParams.schoolId) {
            this.schoolId = this.queryParams.schoolId;
            getSchoolConfig(this.schoolId).then(config => {
                if(config) {
                    this.noDeviceData = !config.hasDeviceData;
                }
            });
            this.selectedfilter.dateFilter.start = this.queryParams.start;
            this.selectedfilter.dateFilter.end = this.queryParams.end;
            if(this.queryParams.curtab) {
                this.currentTab = this.queryParams.curtab;
            }
            this.load();
        }
    }

    handleActive(event) {
        let activeTab = event.target.value;
        this.previousTab = this.currentTab;
        
        this.queryParams.curtab = activeTab;
        this.currentTab = activeTab;
        this.devicesTabInActive = activeTab !== "devices";
        if(this.previousTab !== this.currentTab) {
            this.queryParams.curtab = this.currentTab;
            pushStateToUrl(this.queryParams);
            this.sendAnalyticsEvent('switchtab', activeTab);
        }
    }

    sendAnalyticsEvent(action, label) {
        // eslint-disable-next-line no-undef
        if(ga) {
            // eslint-disable-next-line no-undef
            ga('send', {
                hitType: 'event',
                eventCategory: 'InfectionProfile',
                eventAction: action,
                eventLabel: label
            });
        }
    }

    load() {
        this.infectionInformationItems = [];
        this.service.infectionInformationFetchData(this.schoolId, this.infectionId, this.selectedfilter.dateFilter.start, this.selectedfilter.dateFilter.end).then(res => {
            this.infectionInformationDataIsLoading = false;
            let data = res;
            this.infectionInformationItems.push({ label: "Infection Name", detail: this.title });
            this.infectionInformationItems.push({ label: "Infection Type", detail: data.infectionType });
            this.infectionInformationItems.push({ label: "No. Devices Infected", detail: data.deviceCount });
        });
    }

    //TODO refactor as this code is duplicated in a few components, create a generic FilteredComponent to be extended
    applyFilter(event) {
        var filters = event.detail.value; //value is returned as an array of JSON objects from tilePageHeader.html

        //1. update URL Param.
        filters.forEach(function(data) {
            if (data.type === "Date Range") {
                this.selectedfilter.dateFilter.start = data.option.start;
                this.selectedfilter.dateFilter.end = data.option.end;
                this.queryParams.start = this.selectedfilter.dateFilter.start;
                this.queryParams.end = this.selectedfilter.dateFilter.end;
            }
        }, this); //must add ,this at the end when we are updating this.start, this.end, etc within a for loop

        pushStateToUrl(this.queryParams);

        this.load();
    }
}