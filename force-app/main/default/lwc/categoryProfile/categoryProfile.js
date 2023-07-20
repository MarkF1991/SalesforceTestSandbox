import { LightningElement, track } from 'lwc';
import { getQueryParams, pushStateToUrl } from "c/communitiesNavigation";
import { categoryInformationFetchData } from "./categoryProfileService";
import { registerListener, unregisterAllListeners } from 'c/pubsub';
import { cleanId, getSchoolConfig } from "c/utilitiesFunction";

export default class CategoryProfile extends LightningElement {
    pageHeaderLabel = "Category";
    @track schoolId;
    @track selectedfilter = { dateFilter: { start: null, end: null } };
    @track queryParams = {};

    pageRef = { attributes: { name: "nav" } };

    @track categoryInformationDataIsLoading = false;

    @track categoryInformationItems = [];

    @track currentTab = null;
    @track previousTab = null;

    @track noUserData = false;
    @track noDeviceData = false;

    @track usersTabInActive = true;
    @track devicesTabInActive = true;
    @track appsTabInActive = true;
    @track contentTabInActive = true;
    @track isBlocked = false;
    @track usersListViewOverride = null;
    @track devicesListViewOverride = null;
    @track websitesListViewOverride = null;

    @track isLoaded = false;

    get categoryId() {
        if(this.queryParams) {
            return cleanId(this.queryParams.categoryid);
        }
        return "";
    }

    get title() {
        return this.categoryId;
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
        if(event.route === "category-profile") {
            if(cleanId(event.args.params.categoryid) !== this.categoryId) {
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

        this.usersTabInActive = activeTab !== "users";
        this.devicesTabInActive = activeTab !== "devices";
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
                eventCategory: 'CategoryProfile',
                eventAction: action,
                eventLabel: label
            });
        }
    }

    load() {
        this.categoryInformationItems = [];
        return categoryInformationFetchData(this.schoolId, this.categoryId).then(res => {
            this.categoryInformationDataIsLoading = false;
            let data = res;
            this.isBlocked = data ? data.blocked : false;
            this.usersListViewOverride = this.isBlocked ? "users-blocked-attempts" : null;
            this.devicesListViewOverride = this.isBlocked ? "devices-blocked-attempts" : null;
            this.websitesListViewOverride = this.isBlocked ? "websites-blocked-attempts" : null;
            this.categoryInformationItems.push({ label: "Category Name", detail: this.title });
            this.categoryInformationItems.push({ label: "Category Description", detail: data.information });
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