import { LightningElement, api } from "lwc";
import { TileItemClass } from "c/utilitiesClass";
import { formatNumber, bytesToUnit, getReadableDuration, iconName } from "c/utilitiesFunction";

export default class CategoryInsightsTileList extends LightningElement {

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
      const categoryByBrowsingTime = this.object.data.categoryByBrowsingTime;
      const categoryByBandwidth = this.object.data.categoryByBandwidth;
      const categoryByBlocked = this.object.data.categoryByBlocked;

      if(categoryByBrowsingTime) {
        //top ... by browsing time
        item1.id = `${Math.random()}`;
        item1.title = "Top Category by Browsing Time";
        item1.value = getReadableDuration(categoryByBrowsingTime.value); 
        item1.unit = "(HH:MM:SS)";
        item1.path = 'category-profile';
        item1.route = categoryByBrowsingTime.route;
        item1.identifier = categoryByBrowsingTime.label;
        item1.chip.label = categoryByBrowsingTime.label;
        item1.chip.description = categoryByBrowsingTime.description;
        item1.chip.image.type = "icon";
        item1.chip.image.name = this.iconNameForCategory(categoryByBrowsingTime.label);
        item1.chip.image.class = "category";
        array.push(item1);
      }

      if(categoryByBandwidth) {
        //top ... by Bandwidth Usage
        item2.id = `${Math.random()}`;
        item2.title = "Top Category by Bandwidth Usage";
        item2.value = bytesToUnit(categoryByBandwidth.value, "GB"); //display number with , seperator
        item2.unit = "(GB)";
        item2.path = 'category-profile';
        item2.route = categoryByBandwidth.route;
        item2.identifier = categoryByBandwidth.label;
        item2.chip.label = categoryByBandwidth.label;
        item2.chip.description = categoryByBandwidth.description;
        item2.chip.image.type = "icon";
        item2.chip.image.name = this.iconNameForCategory(categoryByBandwidth.label);
        item2.chip.image.class = "category";
        array.push(item2);
      }

      if(categoryByBlocked && categoryByBlocked.label) {
        //top ... by Blocked Attempts
        item3.id = `${Math.random()}`;
        item3.title = "Top Category by Blocked Attempts";
        item3.value = formatNumber(categoryByBlocked.value); //display number with , seperator
        item3.unit = " "; //nothing to display, but occupy the top space
        item3.path = 'category-profile';
        item3.route = categoryByBlocked.route;
        item3.identifier = categoryByBlocked.label;
        item3.chip.label = categoryByBlocked.label;
        item3.chip.description = categoryByBlocked.description;
        item3.chip.image.type = "icon";
        item3.chip.image.name = this.iconNameForCategory(categoryByBlocked.label);
        item3.chip.image.class = "category";
        array.push(item3);
      } else {
        item3.id = `${Math.random()}`;
        item3.title = "Top Category by Blocked Attempts";
        item3.value = "";
        item3.unit = " ";
        item3.path = null;
        item3.identifier = "none";
        item3.chip.label = "No Blocked Attempts";
        item3.chip.description = "";
        item3.chip.image.type = "icon";
        item3.chip.image.name = this.iconNameForCategory("success");
        item3.chip.image.class = "success";
        array.push(item3);
      }
    }
    return array;
  }
}