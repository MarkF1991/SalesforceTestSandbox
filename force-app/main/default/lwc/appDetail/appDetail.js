import { LightningElement, track } from "lwc";
import { getQueryParams } from "c/communitiesNavigation";
import AppDetailService from "./appDetailService";
import { registerListener, unregisterAllListeners } from "c/pubsub";
import { cleanId, getSchoolConfig } from "c/utilitiesFunction";

export default class AppDetail extends LightningElement {
    @track schoolId;
    @track selectedfilter = { dateFilter: { start: null, end: null } };
    pageRef = { attributes: { name: "nav" } };
    maxValue = 0;
    resultsTotal = 0;
    @track queryParams = {};
    @track userInsightsDataIsLoading = false;
    @track deviceInsightsDataIsLoading = false;
  
    //for JSON response - data
    @track userInsightsResponseData;
    @track deviceInsightsResponseData;

    userInsightsFooter  = { title: "View all", route: "apps-profile", params: { curtab: "users", view: "all", fromContext: ["appid"]}}
    deviceInsightsFooter  = { title: "View all", route: "apps-profile", params: { curtab: "devices", view: "all-devices", fromContext: ["appid"]}}

    @track noUserData = false;
    @track noDeviceData = false;

    service = null;

    constructor() {
      super();
      this.service = new AppDetailService();
    }
  
    get Id() {
      return this.queryParams ? cleanId(this.queryParams.appid) : "Unknown";
    }

    get title() {
      return this.Id;
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
      if(event.route === "apps-profile" && event.args.params.appid !== this.Id) {
          this.queryParams = getQueryParams(window.location.search);
          //reload
          this.load();
      }
  }
  
    load() {
      let start = this.selectedfilter.dateFilter.start;
      let end = this.selectedfilter.dateFilter.end;
      if (start && end) {
        let app = encodeURI(this.Id);

        this.userInsightsDataIsLoading = true;
        this.deviceInsightsDataIsLoading = true;
        this.service.userInsightsFetchData(this.schoolId, start, end, app).then(userInsightsRes => {
            this.userInsightsResponseData = userInsightsRes;
            this.userInsightsDataIsLoading = false;
        });

        this.service.deviceInsightsFetchData(this.schoolId, start, end, app).then(deviceInsightsRes => {
            this.deviceInsightsResponseData = deviceInsightsRes;
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