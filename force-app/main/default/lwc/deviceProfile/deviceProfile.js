import { LightningElement, track } from 'lwc';
import { getQueryParams, pushStateToUrl } from "c/communitiesNavigation";
import DeviceProfileService from "./deviceProfileService";
import { registerListener, unregisterAllListeners } from 'c/pubsub';

export default class DeviceProfile extends LightningElement {

    pageHeaderLabel = "Device";
    @track schoolId;
    @track selectedfilter = { dateFilter: { start: null, end: null } };
    @track queryParams = {};
    
    pageRef = { attributes: { name: "nav" } };

    @track deviceInformationItems = [];

    @track currentTab = null;
    @track previousTab = null;

    @track usersTabInActive = true;
    @track categoriesTabInActive = true;
    @track appsTabInActive = true;
    @track contentTabInActive = true;
    deviceProfileService = null;
    @track title = "";

    @track isLoaded = false;

    constructor() {
        super();
        this.deviceProfileService = new DeviceProfileService();
    }

    get deviceId() {
        if(this.queryParams) {
            return this.queryParams.deviceid ? this.queryParams.deviceid.replace("+", " ") : "";
        }
        return "";
    }

    async connectedCallback() {
        this.queryParams = getQueryParams(window.location.search);

        if (this.queryParams.schoolId) {
            this.schoolId = this.queryParams.schoolId;
            this.selectedfilter.dateFilter.start = this.queryParams.start;
            this.selectedfilter.dateFilter.end = this.queryParams.end;
            if(this.queryParams.curtab) {
                this.currentTab = this.queryParams.curtab;
            }
            this.load().then(() => {
                this.isLoaded = true;
            });
        }
        registerListener('navigationChanged', this.handleNavigationChanged, this);
    }

    disconnectedCallback() {
        unregisterAllListeners(this);
    }

    handleNavigationChanged(event) {
        if(event.route === "device-profile") {
            if(event.args.params.deviceid !== this.deviceId) {
                this.queryParams = getQueryParams(window.location.search);
                //reload
                this.isLoaded = false;
                this.load().then(() => {
                    this.isLoaded = true;
                });
            }

            this.queryParams = getQueryParams(window.location.search);
            if(this.queryParams.curtab && this.currentTab !== this.queryParams.curtab) {
                this.previousTab = this.currentTab;
                this.currentTab = this.queryParams.curtab;
            }
        }
    }

    handleActive(event) {
        let activeTab = event.target.value;
        this.previousTab = this.currentTab;

        this.queryParams.curtab = activeTab;
        this.currentTab = activeTab;

        this.categoriesTabInActive = activeTab !== "categories";
        this.usersTabInActive  = activeTab !== "users";
        this.appsTabInActive = activeTab !== "apps";
        this.contentTabInActive = activeTab !== "websites";
        if(this.previousTab !== this.currentTab) {
            this.queryParams.curtab = this.currentTab;
            delete this.queryParams.view;
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
                eventCategory: 'DeviceProfile',
                eventAction: action,
                eventLabel: label
            });
        }
    }

    load() {
        this.deviceInformationItems = [];
        return this.deviceProfileService.getDeviceInformation(this.schoolId, this.deviceId, this.selectedfilter.dateFilter.start, this.selectedfilter.dateFilter.end)
        .then(res => {
            this.title = res.deviceName ? res.deviceName : res.deviceMac;
            this.deviceInformationItems.push({ label: "Device Name", detail: res.deviceName ? res.deviceName : res.deviceMac });
            this.deviceInformationItems.push({ label: "Device Type", detail: res.deviceType ? res.deviceType : "Unknown" });
            this.deviceInformationItems.push({ label: "Mac Address", detail: res.deviceMac ? res.deviceMac : "Unknown" });
            this.deviceInformationItems.push({ label: "Operating System", detail: res.osName ? res.osName : "Unknown" });
            this.deviceInformationItems.push({ label: "Operating System Version", detail: res.osVersion ? res.osVersion : "Unknown" });
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

        this.load().then(() => {
            this.isLoaded = true;
        });
    }
}