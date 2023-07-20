import { LightningElement, track } from "lwc";
import { getQueryParams } from "c/communitiesNavigation";
import CategoryDetailService from "./categoryDetailService";
import { registerListener, unregisterAllListeners } from "c/pubsub";
import { cleanId, getSchoolConfig } from "c/utilitiesFunction";

export default class CategoryDetail extends LightningElement {
  pageHeaderLabel = "Category";
  @track schoolId;
  @track selectedfilter = { dateFilter: { start: null, end: null } };
  pageRef = { attributes: { name: "nav" } };
  maxValue = 0;
  resultsTotal = 0;
  @track queryParams = {};
  @track userInsightsDataIsLoading = false;
  @track deviceInsightsDataIsLoading = false;
  @track websiteInsightsDataIsLoading = false;

  @track noUserData = false;
  @track noDeviceData = false;

  //for JSON response - data
  @track userInsightsResponseData;
  @track deviceInsightsResponseData;
  @track websiteInsightsResponseData;

  userInsightsFooter  = { title: "View all", route: "category-profile", params: { curtab: "users", view: "all", fromContext: ["categoryid"]}}
  deviceInsightsFooter  = { title: "View all", route: "category-profile", params: { curtab: "devices", view: "all-devices", fromContext: ["categoryid"]}}
  websiteInsightsFooter  = { title: "View all", route: "category-profile", params: { curtab: "websites", view: "websites-browsing-time", fromContext: ["categoryid"]}}

  service = null;

  get id() {
    return this.queryParams ? cleanId(this.queryParams.categoryid) : "";
  }
  
  get title() {
    return this.id;
  }

  constructor() {
    super();
    this.service = new CategoryDetailService();
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
    if(event.route === "category-profile" && event.args.params.categoryid !== this.id) {
        this.queryParams = getQueryParams(window.location.search);
        //reload
        this.load();
    }
  }

  load() {
    let start = this.selectedfilter.dateFilter.start;
    let end = this.selectedfilter.dateFilter.end;
    if (start && end) {
      let category = encodeURI(this.id);

      //User Insights - using ./userDetailService.js to map data object
      this.categoryInformationDataIsLoading = true;
      this.userInsightsDataIsLoading = true;
      this.deviceInsightsDataIsLoading = true;
      this.websiteInsightsDataIsLoading = true;

      this.service.categoryInformationFetchData(this.schoolId, category).then(res => {
        let isBlocked = res.data ? res.data.blocked : false;

        this.service.userInsightsFetchData(this.schoolId, start, end, category, isBlocked).then(userInsightsRes => {
          this.userInsightsResponseData = userInsightsRes;
          this.userInsightsDataIsLoading = false;
        });

        this.service.getWebsiteInsights(this.schoolId, start, end, category, isBlocked).then(websiteResponse => {
          this.websiteInsightsResponseData = websiteResponse;
          this.websiteInsightsDataIsLoading = false;
        });

        this.service.deviceInsightsFetchData(
          this.schoolId, start, end, category, isBlocked).then(deviceInsightsRes => {
          this.deviceInsightsResponseData = deviceInsightsRes;
          this.deviceInsightsDataIsLoading = false;
        });
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