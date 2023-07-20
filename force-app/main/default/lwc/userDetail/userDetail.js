import { LightningElement, track, api } from 'lwc';
import { getQueryParams } from "c/communitiesNavigation";
import UserDetailService from "./userDetailService";
import { registerListener, unregisterAllListeners } from "c/pubsub";

export default class UserDetail extends LightningElement {
    @track schoolId;
    @track selectedfilter = { dateFilter: { start: null, end: null } };
    @track error;
    @api id;
    maxValue = 0;
    resultsTotal = 0;
    @track queryParams = {};

    pageRef = { attributes: { name: "nav" } };

    @track categoryInsightsDataIsLoading = false;
    @track appInsightsDataIsLoading = false;
    @track safetyInsightsDataIsLoading = false;
    @track websiteInsightsDataIsLoading = false;

    //for JSON response - data
    @track categoryInsightsResponseData;
    @track websiteInsightsResponseData;
    @track safetyInsightsResponseData;
    @track appInsightsResponseData;

    safetyInsightsFooter = { title: "View all", route: "user-profile", params: { curtab: "categories", view: "safety-categories-blocked-attempts", fromContext: ["userid"]}}
    websiteInsightsFooter = { title: "View all", route: "user-profile", params: { curtab: "websites", view: "websites-browsing-time", fromContext: ["userid"]}}
    appInsightsFooter = { title: "View all", route: "user-profile", params: { curtab: "apps", view: "apps-bandwidth-usage", fromContext: ["userid"]}}
    categoryInsightsFooter = { title: "View all", route: "user-profile", params: { curtab: "categories", view: "categories-browsing-time", fromContext: ["userid"]}}

    service = null;

    constructor() {
        super();
        this.service = new UserDetailService();
    }

    get userId() {
        if(this.userid) {
            return this.userid.replace("+", " ");
        }
        if(this.queryParams) {
            return this.queryParams.userid ? this.queryParams.userid.replace("+", " ") : "";
        }
        return "";
    }

    get title() {
        return this.userId;
    }

    async connectedCallback() {
        this.queryParams = getQueryParams(window.location.search);

        if (this.queryParams.schoolId) {
            this.schoolId = this.queryParams.schoolId;
            this.selectedfilter.dateFilter.start = this.queryParams.start;
            this.selectedfilter.dateFilter.end = this.queryParams.end;
            this.load();
        }
        registerListener("filterChanged", this.handleFilterChanged, this);
        registerListener('navigationChanged', this.handleNavigationChanged, this);
    }

    disconnectedCallback() {
        unregisterAllListeners(this);
    }

    handleNavigationChanged(event) {
        if(event.route === "user-profile" && event.args.params.userid !== this.userId) {
            this.queryParams = getQueryParams(window.location.search);
            //reload
            this.load();
        }
    }

    load() {
        this.userInsightsDataIsLoading = true;
        this.safetyInsightsDataIsLoading = true;
        this.websiteInsightsDataIsLoading = true;
        this.categoryInsightsDataIsLoading = true;
        this.appInsightsDataIsLoading = true;

        let start = this.selectedfilter.dateFilter.start;
        let end = this.selectedfilter.dateFilter.end;
        if (start && end) {

            this.service.safetyInsightsFetchData(this.schoolId, start, end, this.userId).then(res => {
                this.safetyInsightsResponseData = res;
                this.safetyInsightsDataIsLoading = false;
            });

            this.service.getWebsiteInsights(this.schoolId, start, end, this.userId).then(res => {
                this.websiteInsightsResponseData = res;
                this.websiteInsightsDataIsLoading = false;
            });

            this.service.getCategoryInsights(this.schoolId, start, end, this.userId).then(res => {
                this.categoryInsightsResponseData = res;
                this.categoryInsightsDataIsLoading = false;
            });

            this.service.getApplicationInsights(this.schoolId, start, end, this.userId).then(res => {
                this.appInsightsResponseData = res;
                this.appInsightsDataIsLoading = false;
            });
        }
    }

    // eslint-disable-next-line no-unused-vars
    handleFilterChanged(filters) {
        this.queryParams = getQueryParams(window.location.search);

        if (this.queryParams.schoolId) {
            this.schoolId = this.queryParams.schoolId;

            this.selectedfilter.dateFilter.start = this.queryParams.start;
            this.selectedfilter.dateFilter.end = this.queryParams.end;
            this.load();
        }
    }
}