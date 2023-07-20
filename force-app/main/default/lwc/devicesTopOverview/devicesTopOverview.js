import { LightningElement, track } from "lwc";
import { registerListener, unregisterAllListeners } from "c/pubsub";
import { TileItemClass } from "c/utilitiesClass";
import {
  formatNumber,
  getReadableDuration,
  bytesToUnit,
  getDeviceName,
  iconName,
  getSchoolConfig
} from "c/utilitiesFunction";
import { getQueryParams } from "c/communitiesNavigation";
import { fetchData } from "c/utilitiesFunction";

export default class DevicesTopOverview extends LightningElement {
  @track items = [];
  @track queryParams = {};
  @track selectedfilter = { dateFilter: { start: null, end: null } };
  @track schoolId;
  @track hasNoData = false;
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
      getSchoolConfig(this.schoolId).then(config => {
        if(config) {
            this.hasNoData = !config.hasDeviceData;
        }
      });
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
      fetchData(`/device/top/${start}/${end}`, this.schoolId).then(res => {
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
      const deviceByBandwidth = data.deviceByBandwidth;
      const deviceByBrowsingTime = data.deviceByBrowsingTime;
      const deviceByBlocked = data.deviceByBlocked;

      if (deviceByBrowsingTime) {
        //top user by browsing time
        item1.id = '101';
        item1.title = "Top Device by Browsing Time";
        item1.value = getReadableDuration(deviceByBrowsingTime.value); 
        item1.unit = "(HH:MM:SS)";
        item1.path = 'device-profile';
        item1.identifier = deviceByBrowsingTime.deviceMac;
        item1.chip.label = getDeviceName(deviceByBrowsingTime.deviceName, deviceByBrowsingTime.deviceMac);
        item1.chip.description = deviceByBrowsingTime.deviceCategory;
        item1.chip.image.type = "icon";
        item1.chip.image.name = this.iconNameForCategory(
          deviceByBrowsingTime.deviceCategory
        );
        item1.chip.image.class = "devices";
        array.push(item1);
      }

      if (deviceByBandwidth) {
        //top user by Bandwidth Usage
        item2.id = '102';
        item2.title = "Top Device by Bandwidth Usage";
        item2.value = bytesToUnit(deviceByBandwidth.value, "GB"); //display number with , seperator
        item2.unit = "(GB)";
        item2.path = 'device-profile';
        item2.identifier = deviceByBandwidth.deviceMac;
        item2.chip.label = getDeviceName(deviceByBandwidth.deviceName, deviceByBandwidth.deviceMac);
        item2.chip.description = deviceByBandwidth.deviceCategory;
        item2.chip.image.type = "icon";
        item2.chip.image.name = this.iconNameForCategory(deviceByBandwidth.deviceCategory);
        item2.chip.image.class = "devices";

        array.push(item2);
      }

      if (deviceByBlocked) {
        //top user by Blocked Attempts
        item3.id = '103';
        item3.title = "Top Device by Blocked Attempts";
        item3.value = formatNumber(deviceByBlocked.value); //display number with , seperator
        item3.unit = " "; //nothing to display, but occupy the top space
        item3.path = 'device-profile';
        item3.identifier = deviceByBlocked.deviceMac;
        item3.chip.label = getDeviceName(
          deviceByBlocked.deviceName,
          deviceByBlocked.deviceMac
        );
        item3.chip.description = deviceByBlocked.deviceCategory;
        item3.chip.image.type = "icon";
        item3.chip.image.name = this.iconNameForCategory(
          deviceByBlocked.deviceCategory
        );
        item3.chip.image.class = "devices";

        array.push(item3);
      }
    }
    return array;
  }
}