import { LightningElement, track } from "lwc";
import { registerListener, unregisterAllListeners } from "c/pubsub";
import { TileItemClass } from "c/utilitiesClass";
import {
  formatNumber,
  getReadableDuration,
  bytesToUnit,
  iconName
} from "c/utilitiesFunction";
import { getQueryParams } from "c/communitiesNavigation";
import { fetchData } from "c/utilitiesFunction";

export default class CategoryTopOverview extends LightningElement {
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
    this.deviceUsageDataIsLoading = true;

    let start = this.selectedfilter.dateFilter.start;
    let end = this.selectedfilter.dateFilter.end;

    if (start && end) {
      fetchData(`/content/category/top/${start}/${end}`, this.schoolId).then(res => {
        this.items = this.map(res.data);
        this.deviceUsageDataIsLoading = false;
      });
    }
  }

  iconNameForCategory(category) {
    return iconName(category);
  }

  map(data) {
    var array = [];
    var item1 = TileItemClass();
    var item2 = TileItemClass();
    var item3 = TileItemClass();
    
    if (data) {
      const categoryByBrowsingTime = data.topCategoryByBtime;
      const categoryByBandwidth = data.topCategoryByBandwidth;
      const categoryByBlocked = data.topCategoryByBlocked;

      if(categoryByBrowsingTime) {
          
        //top ... by browsing time
        item1.id = '401';
        item1.title = "Top Category by Browsing Time";
        item1.value = getReadableDuration(categoryByBrowsingTime.value); 
        item1.unit = "(HH:MM:SS)";
        item1.path = 'category-profile';
        item1.identifier = categoryByBrowsingTime.label;
        item1.chip.label = categoryByBrowsingTime.label;
        item1.chip.description = categoryByBrowsingTime.description;
        item1.chip.image.type = "icon";
        item1.chip.image.name = this.iconNameForCategory('socialMedia');
        item1.chip.image.class = "category";
        array.push(item1);
      }

      if(categoryByBandwidth) {
        //top ... by Bandwidth Usage
        item2.id = '402';
        item2.title = "Top Category by Bandwidth Usage";
        item2.value = bytesToUnit(categoryByBandwidth.value, "GB"); //display number with , seperator
        item2.unit = "(GB)";
        item2.path = 'category-profile';
        item2.identifier = categoryByBandwidth.label;
        item2.chip.label = categoryByBandwidth.label;
        item2.chip.description = categoryByBandwidth.description;
        item2.chip.image.type = "icon";
        item2.chip.image.name = this.iconNameForCategory('gaming');
        item2.chip.image.class = "category";
        array.push(item2);
      }

      if(categoryByBlocked) {
        //top ... by Blocked Attempts
        item3.id = '403';
        item3.title = "Top Category by Blocked Attempts";
        item3.value = formatNumber(categoryByBlocked.value); //display number with , seperator
        item3.unit = " "; //nothing to display, but occupy the top space
        item3.path = 'category-profile';
        item3.identifier = categoryByBlocked.label;
        item3.chip.label = categoryByBlocked.label;
        item3.chip.description = categoryByBlocked.description;
        item3.chip.image.type = "icon";
        item3.chip.image.name = this.iconNameForCategory('fileSharing');
        item3.chip.image.class = "category";
        array.push(item3);
      }
    }
    return array;
  }
}