import { LightningElement, track } from 'lwc';
import { getQueryParams } from "c/communitiesNavigation";
import DeviceDetailService from "./deviceDetailService";
import { registerListener, unregisterAllListeners } from "c/pubsub";
import { cleanId } from "c/utilitiesFunction";

export default class DeviceDetail extends LightningElement {
    @track schoolId;
    @track selectedfilter = { dateFilter: { start: null, end: null } };
    pageRef = { attributes: { name: "nav" } };
    maxValue = 0;
    resultsTotal = 0;
    @track queryParams = {};

    @track userInsightsDataIsLoading = false;
    @track safetyInsightsDataIsLoading = false;
    @track securityInsightsDataIsLoading  = false;
    @track categoryInsightsDataIsLoading = false;
    @track appInsightsDataIsLoading = false;
    @track websiteInsightsDataIsLoading = false;

    //for JSON response - data
    @track userInsightsResponseData;
    @track safetyInsightsResponseData;
    @track securityInsightsResponseData;
    @track categoryInsightsResponseData;
    @track websiteInsightsResponseData;
    @track appInsightsResponseData;

    safetyInsightsFooter = { title: "View all", route: "device-profile", params: { curtab: "categories", view: "safety-categories-blocked-attempts", fromContext: ["deviceid"]}}
    websiteInsightsFooter = { title: "View all", route: "device-profile", params: { curtab: "websites", view: "websites-browsing-time", fromContext: ["deviceid"]}}
    appInsightsFooter = { title: "View all", route: "device-profile", params: { curtab: "apps", view: "apps-bandwidth-usage", fromContext: ["deviceid"]}}
    categoryInsightsFooter = { title: "View all", route: "device-profile", params: { curtab: "categories", view: "categories-browsing-time", fromContext: ["deviceid"]}}
    userInsightsFooter  = { title: "View all", route: "device-profile", params: { curtab: "users", view: "all", fromContext: ["deviceid"]}}

    service = null;

    constructor() {
        super();
        this.service = new DeviceDetailService();
    }

    get title() {
        return this.id;
    }

    get id() {
        return this.queryParams ? cleanId(this.queryParams.deviceid) : "Unknown";
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
        if(event.route === "device-profile" && event.args.params.deviceid !== this.id) {
            this.queryParams = getQueryParams(window.location.search);
            //reload
            this.load();
        }
    }

    load() {
        let start = this.selectedfilter.dateFilter.start;
        let end = this.selectedfilter.dateFilter.end;
        if (start && end) {
            this.websiteInsightsDataIsLoading = true;
            this.categoryInsightsDataIsLoading = true;
            this.appInsightsDataIsLoading = true;
            this.userInsightsDataIsLoading = true;
            this.safetyInsightsDataIsLoading = true;
            this.securityInsightsDataIsLoading = true;

            this.service.userInsightsFetchData(this.schoolId, start, end, this.id).then(res => {
                this.userInsightsResponseData = res;
                this.userInsightsDataIsLoading = false;
            });

            this.service.getWebsiteInsights(this.schoolId, start, end, this.id).then(res => {
                this.websiteInsightsResponseData = res;
                this.websiteInsightsDataIsLoading = false;
            });

            this.service.getCategoryInsights(this.schoolId, start, end, this.id).then(res => {
                this.categoryInsightsResponseData = res;
                this.categoryInsightsDataIsLoading = false;
            });

            this.service.getApplicationInsights(this.schoolId, start, end, this.id).then(res => {
                this.appInsightsResponseData = res;
                this.appInsightsDataIsLoading = false;
            });

            this.service.safetyInsightsFetchData(this.schoolId, start, end, this.id).then(res => {
                this.safetyInsightsResponseData = res;
                this.safetyInsightsDataIsLoading = false;
            });

            this.service.securityInsightsFetchData(this.schoolId, start, end, this.id).then(res => {
                this.securityInsightsResponseData = res;
                this.securityInsightsDataIsLoading = false;
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