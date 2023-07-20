import { LightningElement, track } from 'lwc';
import GlobalSearchService from './globalSearchService';
import { getQueryParams } from "c/communitiesNavigation";
import { registerListener, unregisterAllListeners } from "c/pubsub";

export default class GlobalSearch extends LightningElement {

    @track users = [];
    @track devices = [];
    @track applications = [];
    @track categories = [];
    @track websites = [];
    @track start = null;
    @track end = null;
    @track showResults = false;
    @track dropdownCss = "search-results-wrapper hidden";
    service = null;
    pageRef = { attributes: { name: "nav" } };

    constructor() {
        super();
        this.service = new GlobalSearchService();
    }

    async connectedCallback() {
        this.populateState();
        registerListener("filterChanged", this.handleFilterChanged, this);
    }

    disconnectedCallback() {
        unregisterAllListeners(this);
    }

    populateState() {
        this.queryParams = getQueryParams(window.location.search);

        if (this.queryParams.schoolId) {
            this.schoolId = this.queryParams.schoolId;
            this.start = this.queryParams.start;
            this.end = this.queryParams.end;
        }
    }

    // eslint-disable-next-line no-unused-vars
    handleNavigate(event) {
        this.sendAnalyticsEvent('navigate', event.detail.entityType);
        this.reset();
    }

    // eslint-disable-next-line no-unused-vars
    handleFilterChanged(filters) {
        this.populateState();
    }

    reset() {
        this.dropdownCss = "search-results-wrapper hidden";
        this.users = [];
        this.devices = [];
        this.applications = [];
        this.categories = [];
        this.websites = [];
    }

    sendAnalyticsEvent(action, label) {
        // eslint-disable-next-line no-undef
        if(ga) {
            // eslint-disable-next-line no-undef
            ga('send', {
                hitType: 'event',
                eventCategory: 'GlobalSearch',
                eventAction: action,
                eventLabel: label
            });
        }
    }

    handleOnChange(event) {
        let value = event.target.value;
        if(value && value.trim().length > 0) {
            if(!this.schoolId) {
                this.populateState();
            }

            this.service.search(this.schoolId, this.start, this.end, value).then(res => {
                this.users = res.users;
                if(this.users.length <= 0) {
                    this.users.push({id: "none", label: `No users found that match '${value}'`, href: null, image: {}});
                }
                this.devices = res.devices;
                if(this.devices.length <= 0) {
                    this.devices.push({id: "none", label: `No devices found that match '${value}'`, href: null, image: {}});
                }
                this.applications = res.applications;
                if(this.applications.length <= 0) {
                    this.applications.push({id: "none", label: `No applications found that match '${value}'`, href: null, image: {}});
                }
                this.categories = res.categories;
                if(this.categories.length <= 0) {
                    this.categories.push({id: "none", label: `No categories found that match '${value}'`, href: null, image: {}});
                }
                this.websites = res.websites;
                if(this.websites.length <= 0) {
                    this.websites.push({id: "none", label: `No websites found that match '${value}'`, href: null, image: {}});
                }
                this.dropdownCss = "search-results-wrapper";
            });

        } else {
            this.reset();
            this.sendAnalyticsEvent('reset', 'reset');
        }
    }
}