import { LightningElement, track } from 'lwc';
import { getQueryParams, pushStateToUrl } from "c/communitiesNavigation";
import { registerListener, unregisterAllListeners } from 'c/pubsub';
import UserProfileService from './userProfileService';
import { getSchoolConfig } from "c/utilitiesFunction";

export default class UserProfile extends LightningElement {
    
    pageHeaderLabel = "User";
    @track schoolId;
    @track selectedfilter = { dateFilter: { start: null, end: null } };
    @track queryParams = {};
    @track userInformationItems = [];

    @track noDeviceData = false;

    pageRef  = { attributes: { name: "nav" } };

    @track currentTab = "overview";
    @track previousTab = null;
    @track categoriesTabInActive = true;
    @track devicesTabInActive = true;
    @track appsTabInActive = true;
    @track contentTabInActive = true;

    service = null;
    @track isLoaded = false;

    get userId() {
        if(this.queryParams) {
            return this.queryParams.userid ? this.queryParams.userid.replace("+", " ") : "";
        }
        return "";
    }

    get title() {
        return this.userId;
    }

    constructor() {
        super();
        this.service = new UserProfileService();
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
        if(event.route === "user-profile") {
            if(event.args.params.userid !== this.userId) {
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
                eventCategory: 'UserProfile',
                eventAction: action,
                eventLabel: label
            });
        }
    }

    load() {
        this.userInformationItems = [];
        return this.service.getUserDetails(this.schoolId, this.selectedfilter.dateFilter.start, this.selectedfilter.dateFilter.end, this.userId).then(user => {
            this.userInformationItems.push({ label: "Name", detail: user.id });
            this.userInformationItems.push({ label: "Group(s)", detail: user.groups.join(', ') });
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