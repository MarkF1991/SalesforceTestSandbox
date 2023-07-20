import { LightningElement, api } from "lwc";
import { TileItemClass } from "c/utilitiesClass";
import { formatNumber, bytesToUnit, getReadableDuration, iconName } from "c/utilitiesFunction";

export default class AppInsightsTileList extends LightningElement {
  @api isLoading;

  //input
  @api object;
  @api param;
  @api header;
  @api footer;

  iconNameForCategory(category) {
    return iconName(category);
  }

  //output - fields mapping
  get items() {
    var array = [];
    var item1 = TileItemClass();
    var item2 = TileItemClass();
    var item3 = TileItemClass();

    if (this.object && this.param) {
      const appByBrowsingTime = this.object.data.appByBrowsingTime;
      const appByBandwidth = this.object.data.appByBandwidth;
      const appByBlocked = this.object.data.appByBlocked;

      if(appByBrowsingTime) {
        //top ... by browsing time
        item1.id = `${Math.random()}`;
        item1.title = "Top App by Browsing Time";
        item1.value = getReadableDuration(appByBrowsingTime.value); 
        item1.unit = "(HH:MM:SS)";
        item1.path = 'apps-profile';
        item1.route = appByBrowsingTime.route;
        item1.identifier = appByBrowsingTime.label;
        item1.chip.label = appByBrowsingTime.label;
        item1.chip.description = appByBrowsingTime.description;
        item1.chip.image.type = "icon";
        item1.chip.image.name = this.iconNameForCategory(appByBrowsingTime.category);
        item1.chip.image.class = "application";
        array.push(item1);
      }

      if(appByBandwidth) {
        //top ... by Bandwidth Usage
        item2.id = `${Math.random()}`;
        item2.title = "Top App by Bandwidth Usage";
        item2.value = bytesToUnit(appByBandwidth.value, "GB"); //display number with , seperator
        item2.unit = "(GB)";
        item2.path = 'apps-profile';
        item2.route = appByBandwidth.route;
        item2.identifier = appByBandwidth.label;
        item2.chip.label = appByBandwidth.label;
        item2.chip.description = appByBandwidth.description;
        item2.chip.image.type = "icon";
        item2.chip.image.name = this.iconNameForCategory(appByBandwidth.category);
        item2.chip.image.class = "application";
        array.push(item2);
      }

      if(appByBlocked) {
        //top ... by Blocked Attempts
        item3.id = `${Math.random()}`;
        item3.title = "Top App by Blocked Attempts";
        item3.value = formatNumber(appByBlocked.value); //display number with , seperator
        item3.unit = " "; //nothing to display, but occupy the top space
        item3.path = 'apps-profile';
        item3.route = appByBlocked.route;
        item3.chip.label = appByBlocked.label;
        item3.chip.description = appByBlocked.description;
        item3.chip.image.type = "icon";
        item3.chip.image.name = this.iconNameForCategory(appByBlocked.category);
        item3.chip.image.class = "application";
        array.push(item3);
      }
    }
    return array;
  }
}