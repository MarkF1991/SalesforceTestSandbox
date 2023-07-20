import { LightningElement, track } from "lwc";
import { registerListener, unregisterAllListeners } from "c/pubsub";
import { TileItemClass } from "c/utilitiesClass";
import {
  formatNumber,
  getReadableDuration,
  bytesToUnit,
  getSchoolConfig
} from "c/utilitiesFunction";
import { getQueryParams } from "c/communitiesNavigation";
import { fetchData } from "c/utilitiesFunction";

export default class UserTopOverview extends LightningElement {
  @track items = [];
  @track queryParams = {};
  @track selectedfilter = { dateFilter: { start: null, end: null } };
  @track schoolId;
  @track hasNoData = false;
  pageRef = { attributes: { name: "nav" } };

  connectedCallback() {
    this.refresh();
    
    registerListener("filterChanged", this.handleFilterChanged, this);
  }

  disconnectedCallback() {
    unregisterAllListeners(this);
  }

  // eslint-disable-next-line no-unused-vars
  handleFilterChanged(filters) {
    this.refresh();
  }

  refresh() {
    this.queryParams = getQueryParams(window.location.search);

    if (this.queryParams.schoolId) {
      this.schoolId = this.queryParams.schoolId;
      getSchoolConfig(this.schoolId).then(config => {
        if(config) {
            this.hasNoData = !config.hasUserData;
        }
      });
      this.selectedfilter.dateFilter.start = this.queryParams.start;
      this.selectedfilter.dateFilter.end = this.queryParams.end;
      this.reload();
    }
  }

  reload() {
    this.userInsightsDataIsLoading = true;

    let start = this.selectedfilter.dateFilter.start;
    let end = this.selectedfilter.dateFilter.end;

    if (start && end) {
      fetchData(`/user/top/${start}/${end}`, this.schoolId).then(res => {
        this.items = this.map(res.data);
        this.userInsightsDataIsLoading = false;
      });
    }
  }

  map(data) {
    var array = [];
    var item1 = TileItemClass();
    var item2 = TileItemClass();
    var item3 = TileItemClass();

    if (data) {
      const userBrowsingTime = data.userBrowsingTime;
      const userBandwidthUsage = data.userBandwidthUsage;
      const userBlockedAttempts = data.userBlockedAttempts;

      if (userBrowsingTime) {
        //top user by browsing time
        item1.id = '201';
        item1.title = "Top User by Browsing Time";
        item1.value = getReadableDuration(userBrowsingTime.value); //api provided data in seconds, we need to convert it to readable hh:mm:ss format //old comment :
        item1.unit = "(HH:MM:SS)";
        item1.path = `user-profile`;
        item1.identifier = userBrowsingTime.label;
        item1.chip.label = userBrowsingTime.label;
        item1.chip.description = userBrowsingTime.description;
        item1.chip.image.type = "avatar";
        item1.chip.image.name = userBrowsingTime.label ? userBrowsingTime.label.substring(0, 1).toUpperCase() : ""; //initial
        item1.chip.image.class = "user"; //fixed as user - this will affect class to render colour based on tileChip.css
        array.push(item1);
      }

      if (userBandwidthUsage) {
        //top user by Bandwidth Usage
        item2.id = '202';
        item2.title = "Top User by Bandwidth Usage";
        item2.value = bytesToUnit(userBandwidthUsage.value, "GB"); //display number with , seperator
        item2.unit = "(GB)";
        item2.path = `user-profile`;
        item2.identifier = userBandwidthUsage.label;
        item2.chip.label = userBandwidthUsage.label;
        item2.chip.description = userBandwidthUsage.description;
        item2.chip.image.type = "avatar";
        item2.chip.image.name = userBandwidthUsage.label ? userBandwidthUsage.label.substring(0, 1).toUpperCase() : ""; //initial
        item2.chip.image.class = "user"; //fixed as user - this will affect class to render colour based on tileChip.css
        array.push(item2);
      }

      if (userBlockedAttempts) {
        //top user by Blocked Attempts
        item3.id = '203';
        item3.title = "Top User by Blocked Attempts";
        item3.value = formatNumber(userBlockedAttempts.value); //display number with , seperator
        item3.unit = " "; //nothing to display, but occupy the top space
        item3.path = `user-profile`;
        item3.identifier = userBlockedAttempts.label;
        item3.chip.label = userBlockedAttempts.label;
        item3.chip.description = userBlockedAttempts.description;
        item3.chip.image.type = "avatar";
        item3.chip.image.name = userBlockedAttempts.label ? userBlockedAttempts.label.substring(0, 1).toUpperCase() : ""; //initial
        item3.chip.image.class = "user"; //fixed as user - this will affect class to render colour based on tileChip.css
        array.push(item3);
      }
    }

    return array;
  }
}