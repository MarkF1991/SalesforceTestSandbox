import { LightningElement, api } from "lwc";
import { TileItemClass } from "c/utilitiesClass";
import { formatNumber, bytesToUnit, iconName } from "c/utilitiesFunction";

export default class contentInsightsTileList extends LightningElement {
  @api isLoading;

  //input
  @api object;
  @api param;
  @api location = 'reportingDashboard';

  //output - fields mapping
  get items() {
    if (this.object && this.param) {
      if(this.location === 'reportingDashboard'){
        return this.items_for_reportingDashboard();
      } else if(this.location === 'userDetail'){
        //return this.items_for_reportingDashboard();
         return this.items_for_userDetail();   //aka userDashboard
      }
      return this.items_for_reportingDashboard();
    }
    return [];

  }

  items_for_reportingDashboard() {
    var array = [];
    var item1 = TileItemClass();
    var item2 = TileItemClass();
    var item3 = TileItemClass();
    var item4 = TileItemClass();

    if (this.object && this.param) {
      const websiteBandwidthUsage = this.object.data.websiteBandwidthUsage;
      const appBandwidthUsage = this.object.data.appBandwidthUsage;
      const websiteBlockedAttempts = this.object.data.websiteBlockedAttempts;
      const categoryBlockedAttempts = this.object.data.categoryBlockedAttempts;

      //top user by browsing time
      item1.id = `${Math.random()}`;
      item1.title = "Top Website by Bandwidth Usage";
      item1.value = bytesToUnit(websiteBandwidthUsage.value, "GB"); 
      item1.unit = "(GB)";
      item1.path = `content-profile`;
      item1.identifier = websiteBandwidthUsage.label;
      item1.chip.label = websiteBandwidthUsage.label;
      item1.chip.description = websiteBandwidthUsage.category;
      item1.chip.image.type = "icon";
      item1.chip.image.name = "videogame_asset";
      item1.chip.image.class = "content";

      //top user by Bandwidth Usage
      item2.id = `${Math.random()}`;
      item2.title = "Top App by Bandwidth Usage";
      item2.value = bytesToUnit(appBandwidthUsage.value, "GB"); //display number with , seperator
      item2.unit = "(GB)";
      item2.path = `apps-profile`;
      item2.identifier = appBandwidthUsage.label;
      item2.chip.label = appBandwidthUsage.label;
      item2.chip.description = appBandwidthUsage.category;
      item2.chip.image.type = "icon";
      item2.chip.image.name = "videogame_asset"; //initial
      item2.chip.image.class = "content";

      //top user by Blocked Attempts
      item3.id = `${Math.random()}`;
      item3.title = "Top Website by Blocked Attempts";
      item3.value = formatNumber(websiteBlockedAttempts.value); //display number with , seperator
      item3.unit = " "; //nothing to display, but occupy the top space
      item3.path = `content-profile`;
      item3.identifier = websiteBlockedAttempts.label;
      item3.chip.label = websiteBlockedAttempts.label;
      item3.chip.description = websiteBlockedAttempts.category;
      item3.chip.image.type = "icon";
      item3.chip.image.name = "videogame_asset";
      item3.chip.image.class = "content";

      //top user by Blocked Attempts
      item4.id = `${Math.random()}`;
      item4.title = "Top Category by Blocked Attempts";
      item4.value = formatNumber(categoryBlockedAttempts.value); //display number with , seperator
      item4.unit = " "; //nothing to display, but occupy the top space
      item4.path = `category-profile`;
      item4.identifier = categoryBlockedAttempts.label;
      item4.chip.label = categoryBlockedAttempts.label;
      item4.chip.description = categoryBlockedAttempts.category;
      item4.chip.image.type = "icon";
      item4.chip.image.name = "videogame_asset";
      item4.chip.image.class = "content";

      array.push(item1);
      array.push(item2);
      array.push(item3);
      array.push(item4);
    }
    return array;
  }

  items_for_userDetail() { //aka userDashboard
    var array = [];
    var item1 = TileItemClass();
    var item2 = TileItemClass();
    var item3 = TileItemClass();

    if (this.object && this.param) {
      const categoryBandwidthUsage = this.object.data.categoryBandwidthUsage;
      const websiteBandwidthUsage = this.object.data.websiteBandwidthUsage;
      const appBandwidthUsage = this.object.data.appBandwidthUsage;
      
      item1.id = `${Math.random()}`;
      item1.title = "Top Category by Bandwidth Usage";
      item1.value = bytesToUnit(categoryBandwidthUsage.value, "GB"); 
      item1.unit = "(GB)";
      item1.path = `category-profile`;
      item1.identifier = categoryBandwidthUsage.label;
      item1.chip.label = categoryBandwidthUsage.label;
      item1.chip.description = categoryBandwidthUsage.description;
      item1.chip.image.type = "icon";
      item1.chip.image.name = iconName(categoryBandwidthUsage.category);
      item1.chip.image.class = "content";

      //top user by Bandwidth Usage
      item2.id = `${Math.random()}`;
      item2.title = "Top Website by Bandwidth Usage";
      item2.value = bytesToUnit(websiteBandwidthUsage.value, "GB"); //display number with , seperator
      item2.unit = "(GB)";
      item2.path = `content-profile`;
      item2.identifier = websiteBandwidthUsage.label;
      item2.chip.label = websiteBandwidthUsage.label;
      item2.chip.description = websiteBandwidthUsage.description;
      item2.chip.image.type = "icon";
      item2.chip.image.name = iconName(websiteBandwidthUsage.category);
      item2.chip.image.class = "content";

      //top user by Blocked Attempts
      item3.id = `${Math.random()}`;
      item3.title = "Top App by Bandwidth Usage";
      item3.value = bytesToUnit(appBandwidthUsage.value, "GB"); 
      item3.unit = "(GB)";
      item3.path = `apps-profile`;
      item3.identifier = appBandwidthUsage.label;
      item3.chip.label = appBandwidthUsage.label;
      item3.chip.description = appBandwidthUsage.description;
      item3.chip.image.type = "icon";
      item3.chip.image.name = iconName(appBandwidthUsage.category);
      item3.chip.image.class = "content";

      array.push(item1);
      array.push(item2);
      array.push(item3);      
    }
    return array;
  }
}