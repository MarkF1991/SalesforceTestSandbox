/* eslint-disable no-console */
import { track } from "lwc";
import TimeElement from "c/utilitiesTime";
import { getQueryParams, pushStateToUrl } from "c/communitiesNavigation";
import { fetchData, getSchoolConfig } from "c/utilitiesFunction";
import getAccount_uuid from '@salesforce/apex/AccountController.getAccount_uuid';
import ReportingDashboardService from './reportingDashboardService';

export default class MainDashboard extends TimeElement {

  pageHeaderLabel = "Reporting";
  crumbs = [];
  @track schoolId;
  @track account; //for response from getAccount_uuid to get School Name
  @track selectedfilter = { dateFilter: {start: null, end: null} };
  @track userInsightsDataIsLoading = false;
  @track categoryInsightsDataIsLoading = false;
  @track deviceCountsDataIsLoading = false;
  @track websiteInsightsDataIsLoading = false;
  @track safetyInsightsDataIsLoading = false;
  @track appInsightsDataIsLoading = false;

  //for JSON response - data
  @track categoryInsightsResponseData;
  @track userInsightsResponseData;
  @track websiteInsightsResponseData;
  @track deviceCountsResponseData;
  @track safetyInsightsResponseData;
  @track appInsightsResponseData;

  @track filtersReady = false;
  @track schoolConfig = null; 
  @track queryParams = {};

  safetyInsightsFooter = { title: "View all", route: "categories-list-view", params: { view: "safety-categories-blocked-attempts"}}
  userInsightsFooter = { title: "View all", route: "users-list-view", params: { view: "all"}}
  deviceInsightsFooter = { title: "View all", route: "devices-list-view", params: { view: "all-devices"}}
  websiteInsightsFooter = { title: "View all", route: "content-list-view", params: { view: "websites-browsing-time"}}
  categoryInsightsFooter = { title: "View all", route: "categories-list-view", params: { view: "categories-browsing-time"}}
  appInsightsFooter = { title: "View all", route: "apps-list-view", params: { view: "apps-bandwidth-usage"}}

  service = null;

  constructor() {
    super();
    this.service = new ReportingDashboardService();
  }

  connectedCallback() {
    this.queryParams = getQueryParams(window.location.search);

    if (this.queryParams.schoolId) {
      this.schoolId = this.queryParams.schoolId;
      getSchoolConfig(this.schoolId).then(config => {
        this.schoolConfig = config;
      });
      this.init();
    } else {
      this.service.getAccessibleSchoolsForCurrentUser().then(schools => {
        if(schools && schools.length > 0) {
          this.schoolId = schools[0].uuid__c;
          this.queryParams.schoolId = this.schoolId;
          getSchoolConfig(this.schoolId).then(config => {
            this.schoolConfig = config;
          });
          this.init();
        }
      });
    }
  }

  init() {
    this.selectedfilter.dateFilter.start = this.queryParams.start;
    this.selectedfilter.dateFilter.end = this.queryParams.end;
    if(!this.queryParams.start || !this.queryParams.end) {
      this.initMoment().then(() => {

        this.queryParams.start = this.now
          .startOf("isoWeek")
          .toISOString(); //Start of this week in UTC
        this.queryParams.end = this.now
          .endOf("isoWeek")
          .toISOString(); //End of this week in UTC
        this.selectedfilter.dateFilter.start = this.queryParams.start;
        this.selectedfilter.dateFilter.end = this.queryParams.end;
        pushStateToUrl(this.queryParams);
        this.filtersReady = true;
        this.reload();
      });
    } else {
      this.filtersReady = true;
      this.reload();
    }

    this.setAccountUUID();
  }

  reload() {
    this.userInsightsDataIsLoading = true;
    this.contentInsightsDataIsLoading = true;
    this.deviceCountsDataIsLoading = true;
    this.websiteInsightsDataIsLoading = true;
    this.safetyInsightsDataIsLoading = true;
    this.appInsightsDataIsLoading = true;

    let start = this.selectedfilter.dateFilter.start;
    let end = this.selectedfilter.dateFilter.end;

    if (start && end) {
      this.service.getCategoryInsights(this.schoolId, start, end).then(res => {
        this.categoryInsightsResponseData = res;
        this.categoryInsightsDataIsLoading = false;
      });

      fetchData(`/user/top/${start}/${end}`, this.schoolId).then(res => {
          this.userInsightsResponseData = res;
          this.userInsightsDataIsLoading = false;
      });

      this.service.getWebsiteInsights(this.schoolId, start, end).then(res => {
        this.websiteInsightsResponseData = res;
        this.websiteInsightsDataIsLoading = false;
      });

      this.service.getApplicationInsights(this.schoolId, start, end).then(res => {
        this.appInsightsResponseData = res;
        this.appInsightsDataIsLoading = false;
      });

      Promise.all(
        [
          this.service.getInfectedDeviceCount(this.schoolId, start, end),
          this.service.getDeviceTypeCounts(this.schoolId, start, end)
        ]
      ).then(results => {
        var data = results[1];
        data.infectedDeviceCount = results[0];
        this.deviceCountsResponseData = data;
        this.deviceCountsDataIsLoading = false;
      });

      this.service.safetyInsightsFetchData(this.schoolId, start, end).then(res => {
          this.safetyInsightsResponseData = res;
          this.safetyInsightsDataIsLoading = false;
      });
    }
  }

  setAccountUUID() {
    // eslint-disable-next-line @lwc/lwc/no-async-operation
    getAccount_uuid({ uuid: this.schoolId })
            .then(result => {
                this.account = result;
                this.error = undefined;
            })
            .catch(error => {
                this.error = error;
                this.account = undefined;
            });
  }

  get pageHeaderTitle() {
    if(this.account && this.account.Name){
      return this.account.Name;
    }
    return 'School';
  }

  applyFilter(event) {
    var filters = event.detail.value; //value is returned as an array of JSON objects from tilePageHeader.html

    //1. update URL Param.
    filters.forEach(function(data) {
      if (data.type === "Date Range") {
        let start = data.option.start;
        let end = data.option.end;
        this.queryParams.start = start;
        this.queryParams.end = end;
        this.selectedfilter.dateFilter.start = start;
        this.selectedfilter.dateFilter.end = end;
      }
    }, this); //must add ,this at the end when we are updating this.start, this.end, etc within a for loop

    pushStateToUrl(this.queryParams);

    this.reload();
  }
}