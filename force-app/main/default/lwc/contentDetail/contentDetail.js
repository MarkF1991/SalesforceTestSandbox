import { LightningElement, track } from 'lwc';
import { getQueryParams } from "c/communitiesNavigation";
import ContentDetailService from "./contentDetailService";
import { cleanId, getSchoolConfig } from "c/utilitiesFunction";
import { registerListener, unregisterAllListeners } from "c/pubsub";

export default class ContentDetail extends LightningElement {
    pageHeaderLabel = "Content";
    @track schoolId;
    @track selectedfilter = { dateFilter: { start: null, end: null } };
    
    maxValue = 0;
    resultsTotal = 0;
    @track queryParams = {};

    pageRef = { attributes: { name: "nav" } };

    @track userInsightsDataIsLoading = false;
    @track deviceInsightsDataIsLoading = false;
    @track pageHeaderDetailsDataIsLoading = false;
    
    //for JSON response - data
    @track userInsightsResponseData;
    @track deviceInsightsResponseData;
    @track pageHeaderDetailsResponseData;

    @track noUserData = false;
    @track noDeviceData = false;

    userInsightsFooter  = { title: "View all", route: "content-profile", params: { curtab: "users", view: "all", fromContext: ["websiteid"]}}
    deviceInsightsFooter  = { title: "View all", route: "content-profile", params: { curtab: "devices", view: "all-devices", fromContext: ["websiteid"]}}
  
    service = null;

    constructor() {
        super();
        this.service = new ContentDetailService();
    }

    get id() {
        return this.queryParams ? cleanId(this.queryParams.websiteid) : "Unknown";
    }

    get title() {
        return this.id;
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
            this.load();
        }
        registerListener("filterChanged", this.handleFilterChanged, this);
        registerListener('navigationChanged', this.handleNavigationChanged, this);
    }

    disconnectedCallback() {
        unregisterAllListeners(this);
    }

    handleNavigationChanged(event) {
        if(event.route === "content-profile" && event.args.params.websiteid !== this.id) {
            this.queryParams = getQueryParams(window.location.search);
            //reload
            this.load();
        }
    }

    load() {
        let start = this.selectedfilter.dateFilter.start;
        let end = this.selectedfilter.dateFilter.end;
        if (start && end) {
 
            //User Insights - using ./userDetailService.js to map data object
            this.userInsightsDataIsLoading = true;
            this.service.userInsightsFetchData(this.schoolId, start, end, this.id).then(res => {
                this.userInsightsResponseData = res;
                this.userInsightsDataIsLoading = false;
            });

            //Device Insights - using ./userDetailService.js to map data object
            this.deviceInsightsDataIsLoading = true;
            this.service.deviceInsightsFetchData(this.schoolId, start, end, this.id).then(res => {
                this.deviceInsightsResponseData = res;
                this.deviceInsightsDataIsLoading = false;
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