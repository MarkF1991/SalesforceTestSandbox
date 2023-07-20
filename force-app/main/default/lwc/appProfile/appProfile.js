import { LightningElement, track } from 'lwc';
import { getQueryParams, pushStateToUrl } from "c/communitiesNavigation";
import { registerListener, unregisterAllListeners } from 'c/pubsub';
import { cleanId, getSchoolConfig } from "c/utilitiesFunction";

export default class AppProfile extends LightningElement {

    pageHeaderLabel = "Application";
    @track schoolId;
    @track selectedfilter = { dateFilter: { start: null, end: null } };
    @track queryParams = {};
    @track currentTab = null;
    @track previousTab = null;

    pageRef = { attributes: { name: "nav" } };

    @track appInformationItems = [];

    @track usersTabInActive = true;
    @track categoriesTabInActive = true;
    @track devicesTabInActive = true;
    
    @track noUserData = false;
    @track noDeviceData = false;

    @track isLoaded = false;

    get appId() {
        if(this.queryParams) {
            return cleanId(this.queryParams.appid);
        }
        return "";
    }

    get title() {
        return this.appId;
    }

    async connectedCallback() {
        this.queryParams = getQueryParams(window.location.search);

        if (this.queryParams.schoolId) {
            this.schoolId = this.queryParams.schoolId;
            getSchoolConfig(this.schoolId).then(config => {
                if(config) {
                    this.noDeviceData = !config.hasDeviceData;
                    this.noUserData = !config.hasUserData;
                }
            });
            this.selectedfilter.dateFilter.start = this.queryParams.start;
            this.selectedfilter.dateFilter.end = this.queryParams.end;
            if(this.queryParams.curtab) {
                this.currentTab = this.queryParams.curtab;
            }

            this.load();
            this.isLoaded = true;
        }
        registerListener('navigationChanged', this.handleNavigationChanged, this);
    }

    disconnectedCallback() {
        unregisterAllListeners(this);
    }

    handleNavigationChanged(event) {
        if(event.route === "apps-profile") {

            if(cleanId(event.args.params.appid) !== this.appId) {
                this.queryParams = getQueryParams(window.location.search);
                //reload
                this.isLoaded = false;
                this.load();
                this.isLoaded = true;
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
        this.devicesTabInActive = activeTab !== "devices";

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
                eventCategory: 'AppProfile',
                eventAction: action,
                eventLabel: label
            });
        }
    }

    load() {
        this.appInformationItems = [];
        this.appInformationItems.push({ label: "App Name", detail: this.title });
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
        this.isLoaded = true;
    }
}