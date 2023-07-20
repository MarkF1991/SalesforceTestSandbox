import { LightningElement, track } from "lwc";
import { registerListener, unregisterAllListeners } from "c/pubsub";
import { TileItemClass } from "c/utilitiesClass";
import {
  bytesToUnit,
  iconName
} from "c/utilitiesFunction";
import { getQueryParams } from "c/communitiesNavigation";
import { fetchData } from "c/utilitiesFunction";

export default class AppsTopOverview extends LightningElement {
  @track items = [];
  @track queryParams = {};
  @track selectedfilter = { dateFilter: { start: null, end: null } };
  @track schoolId;
  pageRef = { attributes: { name: "nav" } };
  @track deviceUsageDataIsLoading = false;

  connectedCallback() {
    this.refresh();
    registerListener("filterChanged", this.handleFilterChanged, this);
  }

  disconnectedCallback() {
    unregisterAllListeners(this);
  }

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
    this.appInsightsDataIsLoading = true;

    let start = this.selectedfilter.dateFilter.start;
    let end = this.selectedfilter.dateFilter.end;

    if (start && end) {
      fetchData(`/content/application/top/${start}/${end}`, this.schoolId).then(
        res => {
          this.items = this.map(res.data);
          this.appInsightsDataIsLoading = false;
        }
      );
    }
  }

  map(data) {
    var array = [];
    var item1 = TileItemClass();

    if (data) {
      const appByBandWidthUsage = data.topApplicationByBandwidth;

      if(appByBandWidthUsage) {
        
        item1.id = '601';
        item1.title = "Top App by Bandwidth Usage";
        item1.value = bytesToUnit(appByBandWidthUsage.value, "GB");
        item1.unit = "(GB)";
        item1.path = 'apps-profile';
        item1.identifier = appByBandWidthUsage.label;
        item1.chip.label = appByBandWidthUsage.label;
        item1.chip.description = appByBandWidthUsage.description;
        item1.chip.image.type = "icon";
        item1.chip.image.name = iconName('informationTechnology');
        item1.chip.image.class = "application";
        array.push(item1);
      }

    }
    return array;
  }
}