import { LightningElement, track, api } from "lwc";
import { TileItemClass } from "c/utilitiesClass";
import {
  formatNumber,
  getReadableDuration,
  bytesToUnit,
  getIdFromTarget
} from "c/utilitiesFunction";
import { fireEvent } from 'c/pubsub';

export default class userInsightsTileList extends LightningElement {
  @api userinsights;
  @api isLoading;
  @track selectedDetail;
  
  pageRef  = { attributes: { name: "nav" } };
  //input
  @track insightsItems = [];
  @api param;
  @api footer;

  @track hasUserData = true;

  @api get config() {
    return this._config;
  }

  set config(val) {
    this._config = val;
    this.hasUserData = this._config ? this._config.hasUserData : true; 
  }

  @api get object() {
    return this._object;
  }

  set object(val) {
      this._object = val;
      if(this._object) {
        this.insightsItems = this.build();
      }
  }

  tileItemSelected(event) {
    this.selectedDetail = event.detail;
  }

  build() {
    var array = [];
    var item1 = TileItemClass();
    var item2 = TileItemClass();
    var item3 = TileItemClass();

    if (this.object && this.param) {
      const userBrowsingTime = this.object.data.userBrowsingTime;
      const userBandwidthUsage = this.object.data.userBandwidthUsage;
      const userBlockedAttempts = this.object.data.userBlockedAttempts;

      if(userBrowsingTime) {
        //top user by browsing time
        item1.id = '201';
        item1.title = "Top User by Browsing Time";
        item1.value = getReadableDuration(userBrowsingTime.value); //api provided data in seconds, we need to convert it to readable hh:mm:ss format //old comment :
        item1.unit = "(HH:MM:SS)";
        item1.identifier = userBrowsingTime.label;
        item1.path = `user-profile`;
        item1.chip.label = userBrowsingTime.label;
        item1.chip.description = userBrowsingTime.description;
        item1.chip.image.type = "avatar";
        item1.chip.image.name = userBrowsingTime.label ? userBrowsingTime.label.substring(0, 1).toUpperCase() : ""; //initial
        item1.chip.image.class = "user"; //fixed as user - this will affect class to render colour based on tileChip.css
        array.push(item1);
      }

      if(userBandwidthUsage) {
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

      if(userBlockedAttempts) {
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

  notifyClick(event) {
    let itemId = getIdFromTarget(event.target.id);
    let index = this.insightsItems.findIndex((val) => val.id === itemId);
    if(index > -1) {
      let item = this.insightsItems[index];
      this.sendAnalyticsEvent('Widget', 'viewitem', 'User Insights');
      fireEvent(this.pageRef, 'navigateToPage', { route: item.path, args: { data: item, identifier: item.identifier } });
    }
  }

  handleViewAllClick() {
    this.sendAnalyticsEvent('Widget', 'viewall', 'User Insights');
    fireEvent(this.pageRef, 'navigateToPage', { route: this.footer.route, args: { params: this.footer.params } });
  }

  sendAnalyticsEvent(category, action, label) {
    // eslint-disable-next-line no-undef
    if(ga) {
        // eslint-disable-next-line no-undef
        ga('send', {
            hitType: 'event',
            eventCategory: category,
            eventAction: action,
            eventLabel: label
        });
    }
  }
}