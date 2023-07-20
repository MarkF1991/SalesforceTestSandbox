import { LightningElement, track } from "lwc";
import { registerListener, unregisterAllListeners } from "c/pubsub";
import { TileItemClass } from "c/utilitiesClass";
import {
  bytesToUnit,
  getReadableDuration,
  formatNumber,
  getCategoryIcon
} from "c/utilitiesFunction";
import { getQueryParams } from "c/communitiesNavigation";
import { fetchData } from "c/utilitiesFunction";

export default class WebsitesTopOverview extends LightningElement {
  @track items = [];
  @track queryParams = {};
  @track selectedfilter = { dateFilter: { start: null, end: null } };
  @track schoolId;
  pageRef = { attributes: { name: "nav" } };
  @track websiteInsightsDataIsLoading = false;

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

      this.selectedfilter.dateFilter.start = this.queryParams.start;
      this.selectedfilter.dateFilter.end = this.queryParams.end;
      this.reload();
    }
  }

  reload() {
    this.websiteInsightsDataIsLoading = true;

    let start = this.selectedfilter.dateFilter.start;
    let end = this.selectedfilter.dateFilter.end;

    if (start && end) {
      fetchData(`/content/website/top/${start}/${end}`, this.schoolId).then(res => {
        this.items = this.map(res.data);
        this.websiteInsightsDataIsLoading = false;
      });
    }
  }

  map(data) {
    var array = [];
    var item1 = TileItemClass();
    var item2 = TileItemClass();
    var item3 = TileItemClass();

    if (data) {
      const websiteByBrowsingTime = data.topWebsiteByBtime;
      const websiteByBandwidth = data.topWebsiteByBandwidth;
      const websiteByBlocked = data.topWebsiteByBlocked;

      if(websiteByBrowsingTime) {
        //top ... by browsing time
        item1.id = '101';
        item1.title = "Top Website by Browsing Time";
        item1.value = getReadableDuration(websiteByBrowsingTime.value); 
        item1.unit = "(HH:MM:SS)";
        item1.path = 'content-profile';
        item1.identifier = websiteByBrowsingTime.label;
        item1.chip.label = websiteByBrowsingTime.label;
        item1.chip.description = websiteByBrowsingTime.description;
        item1.chip.image.type = "icon";
        item1.chip.image.name = getCategoryIcon(websiteByBrowsingTime.category);
        item1.chip.image.class = "content";
        array.push(item1);
      }

      if(websiteByBandwidth) {
        //top ... by Bandwidth Usage
        item2.id = '102';
        item2.title = "Top Website by Bandwidth Usage";
        item2.value = bytesToUnit(websiteByBandwidth.value, "GB"); //display number with , seperator
        item2.unit = "(GB)";
        item2.path = 'content-profile';
        item2.identifier = websiteByBandwidth.label;
        item2.chip.label = websiteByBandwidth.label;
        item2.chip.description = websiteByBandwidth.description;
        item2.chip.image.type = "icon";
        item2.chip.image.name = getCategoryIcon(websiteByBandwidth.category);
        item2.chip.image.class = "content";
        array.push(item2);
      }

      if(websiteByBlocked) {
        //top ... by Blocked Attempts
        item3.id = '103';
        item3.title = "Top Website by Blocked Attempts";
        item3.value = formatNumber(websiteByBlocked.value); //display number with , seperator
        item3.unit = " "; //nothing to display, but occupy the top space
        item3.path = 'content-profile';
        item3.identifier = websiteByBlocked.label;
        item3.chip.label = websiteByBlocked.label;
        item3.chip.description = websiteByBlocked.description;
        item3.chip.image.type = "icon";
        item3.chip.image.name = getCategoryIcon(websiteByBlocked.category);
        item3.chip.image.class = "content";
        array.push(item3);
      }
    }
    return array;
  }
}