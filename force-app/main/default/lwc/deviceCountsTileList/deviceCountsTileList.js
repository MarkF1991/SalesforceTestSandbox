/* eslint-disable no-console */
import { LightningElement, api, track } from "lwc";
import { TileItemClass } from "c/utilitiesClass";
import { formatNumber, iconName } from "c/utilitiesFunction";
import { fireEvent } from 'c/pubsub';
import {
  getIdFromTarget
} from "c/utilitiesFunction";

export default class deviceCountsTileList extends LightningElement {

  get cardIconName() {
    return iconName("devices");
  }

  pageRef = { attributes: { name: "nav" } };

  @api footer;

  @track hasDeviceData = true;

  @api get config() {
    return this._config;
  }

  set config(val) {
    this._config = val;
    this.hasDeviceData = this._config ? this._config.hasDeviceData : true; 
  }

  //input
  @api get object() {
    return this._object;
  }
  set object(val) {
    this._object = val;
    if(this._object) {
      this.initialize();
    }
  }

  @api isLoading;

  @track totalDevices = {};
  @track infectedDevices = {};
  @track devicesByType = [];

  initialize() {
    this.totalDevices = this.deviceObjectmapping(this._object.data.totalDevices, 'Total No. Devices');
    if(this._object.infectedDeviceCount) {
      this.infectedDevices = this.deviceObjectmapping(this._object.infectedDeviceCount, 'No. Infected Devices');
    }
    let result = this._object.data.devicesByType.map(obj => this.deviceObjectmapping(obj, obj.label)).sort((a, b) => { return a.value - b.value; });
    this.devicesByType = result.reverse(); //sort by descending
  }

  deviceObjectmapping(objectData, label) {
    var deviceObject = TileItemClass();
    deviceObject.id = label;
    deviceObject.identifier = label;
    deviceObject.title = null;
    deviceObject.value = formatNumber(objectData.value);
    deviceObject.unit = null;
    deviceObject.path = 'devices-list-view'; 
    deviceObject.chip.label = label;
    deviceObject.chip.description = objectData.description;
    deviceObject.chip.image.type = "icon";
    if (objectData.category) {
      deviceObject.chip.image.name = iconName(objectData.category);
    } else {
      deviceObject.chip.image.name = null;
    }
    deviceObject.chip.image.class = "devices"; //fixed as user - this will affect class to render colour based on tileChip.css
    deviceObject.ticker.trend = objectData.trend > 0 ? 'up' : 'down';
    deviceObject.ticker.value = Math.abs(objectData.trend);
    
    deviceObject.percentage = objectData.percentage;

    return deviceObject;
  }

  notifyClick(event) {
    let itemId = getIdFromTarget(event.target.id);
    let data = this.devicesByType.find((item) => item.id === itemId);
    let route = null;
    if(data) {
      route = data.path;
    }

    if(itemId && data) {
      this.sendAnalyticsEvent('Widget', 'viewitem', 'Device Insights');
      fireEvent(this.pageRef, 'navigateToPage', { route: route, args: { data: data, deviceTypeId: data.identifier ? data.identifier : itemId } });
    } else {
      // eslint-disable-next-line no-console
      console.log('click not registered', route, itemId);
    }
  }

  // eslint-disable-next-line no-unused-vars
  handleNavigationToInfected(event) {
    this.sendAnalyticsEvent('Widget', 'viewinfected', 'Device Insights');
    fireEvent(this.pageRef, 'navigateToPage', { route: "infections-list-view", args: { data: {} } });
  }

  handleViewAllClick() {
    this.sendAnalyticsEvent('Widget', 'viewall', 'Device Insights');
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