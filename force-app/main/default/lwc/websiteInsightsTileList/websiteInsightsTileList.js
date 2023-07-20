import { LightningElement, api } from "lwc";
import { TileItemClass } from "c/utilitiesClass";
import { formatNumber, bytesToUnit, getReadableDuration, getCategoryIcon, iconName } from "c/utilitiesFunction";

export default class WebsiteInsightsTileList extends LightningElement {
  @api isLoading;

  //input
  @api object;
  @api param;
  @api header;
  @api footer;

  //output - fields mapping
  get items() {
    var array = [];
    var item1 = TileItemClass();
    var item2 = TileItemClass();
    var item3 = TileItemClass();

    if (this.object && this.param) {
      const websiteByBrowsingTime = this.object.data.websiteByBrowsingTime;
      const websiteByBandwidth = this.object.data.websiteByBandwidth;
      const websiteByBlocked = this.object.data.websiteByBlocked;

      if(websiteByBrowsingTime) {
        //top ... by browsing time
        item1.id = `${Math.random()}`;
        item1.title = "Top Website by Browsing Time";
        item1.value = getReadableDuration(websiteByBrowsingTime.value); 
        item1.unit = "(HH:MM:SS)";
        item1.path = websiteByBrowsingTime.path;
        item1.route = websiteByBrowsingTime.route;
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
        item2.id = `${Math.random()}`;
        item2.title = "Top Website by Bandwidth Usage";
        item2.value = bytesToUnit(websiteByBandwidth.value, "GB"); //display number with , seperator
        item2.unit = "(GB)";
        item2.path = websiteByBandwidth.path;
        item2.route = websiteByBandwidth.route;
        item2.identifier = websiteByBandwidth.label;
        item2.chip.label = websiteByBandwidth.label;
        item2.chip.description = websiteByBandwidth.description;
        item2.chip.image.type = "icon";
        item2.chip.image.name = getCategoryIcon(websiteByBandwidth.category);
        item2.chip.image.class = "content";
        array.push(item2);
      }

      if(websiteByBlocked && websiteByBlocked.label) {
        //top ... by Blocked Attempts
        item3.id = `${Math.random()}`;
        item3.title = "Top Website by Blocked Attempts";
        item3.value = formatNumber(websiteByBlocked.value); //display number with , seperator
        item3.unit = " "; //nothing to display, but occupy the top space
        item3.path = websiteByBlocked.path;
        item3.route = websiteByBlocked.route;
        item3.identifier = websiteByBlocked.label;
        item3.chip.label = websiteByBlocked.label;
        item3.chip.description = websiteByBlocked.description;
        item3.chip.image.type = "icon";
        item3.chip.image.name = getCategoryIcon(websiteByBlocked.category);
        item3.chip.image.class = "content";
        array.push(item3);
      } else {
        item3.id = `${Math.random()}`;
        item3.title = "Top Website by Blocked Attempts";
        item3.value = " ";
        item3.unit = " ";
        item3.path = null;
        item3.identifier = "none";
        item3.chip.label = "No Blocked Attempts";
        item3.chip.description = "";
        item3.chip.image.type = "icon";
        item3.chip.image.name = iconName("success");
        item3.chip.image.class = "success";
        array.push(item3);
      }
    }
    return array;
  }
}