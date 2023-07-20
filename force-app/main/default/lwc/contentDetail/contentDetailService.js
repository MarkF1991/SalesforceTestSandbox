import { TileItemClass } from "c/utilitiesClass";
import { fetchData, formatNumber, getDeviceName, bytesToUnit, getReadableDuration, iconName } from "c/utilitiesFunction";

export default class ContentDetailService {

  userInsightsFetchData = (schoolId, start, end, contentId) => {
    return fetchData(`/user/top/${start}/${end}?website=${contentId}`, schoolId).then(res => {
      let obj = res.data;
  
      let result = {
        alert: null,
        data: {
            subject: null,
            items: this.userInsights_ItemsObjectMapping(obj)
        }
      };
  
      return result;
    });
  };

  isWebsiteBlocked = (blockedAttempts) => {
    return blockedAttempts && (blockedAttempts.label || blockedAttempts.value > 0);
  }

  userInsights_ItemsObjectMapping = (data) => {
    var array = [];
    var item1 = TileItemClass();
    var item2 = TileItemClass();
    var item3 = TileItemClass();
  
    if (data) {
      const object1 = data.userBrowsingTime;  
      const object2 = data.userBandwidthUsage;
      const userBlockedAttempts = data.userBlockedAttempts;
  
        if(object1 && object1.value > 0) {
            item1.id = '2003';
            item1.identifier = object1.label;
            item1.title = "Top User By Browsing Time";
            item1.value = getReadableDuration(object1.value); 
            item1.unit = "(HH:MM:SS)";
            item1.path = `user-profile`;
            item1.route = {
              page: 'content-profile',
              params: {
                curtab: "users",
                view: "users-browsing-time",
                fromContext: ["websiteid"]
              }
            };
            item1.chip.label = object1.label;
            item1.chip.description = object1.description;
            item1.chip.image.type = "avatar";
            item1.chip.image.name = object1.label ? object1.label.substring(0, 1).toUpperCase() : ""; //initial
            item1.chip.image.class = "user";
            array.push(item1);
        }

        if(object2 && object2.value) {
          item2.id = '2002';
          item2.identifier = object2.label;
          item2.title = "Top User by Bandwidth Usage";
          item2.value = bytesToUnit(object2.value, "GB"); 
          item2.unit = "(GB)";
          item2.path = `user-profile`;
          item2.route = {
            page: 'content-profile',
            params: {
              curtab: "users",
              view: "users-bandwidth-usage",
              fromContext: ["websiteid"]
            }
          };
          item2.chip.label = object2.label;
          item2.chip.description = object2.description;
          item2.chip.image.type = "avatar";
          item2.chip.image.name = object2.label ? object2.label.substring(0, 1).toUpperCase() : ""; //initial
          item2.chip.image.class = "user";
          array.push(item2);
        }

        if(userBlockedAttempts && userBlockedAttempts.label) {
          //top user by Blocked Attempts
          item3.id = '2001';
          item3.title = "Top User by Blocked Attempts";
          item3.value = formatNumber(userBlockedAttempts.value); //display number with , seperator
          item3.unit = " "; //nothing to display, but occupy the top space
          item3.path = 'user-profile';
          item3.route = {
            page: 'content-profile',
            params: {
              curtab: "users",
              view: "users-blocked-attempts",
              fromContext: ["websiteid"]
            }
          };
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
  
  deviceInsightsFetchData = (schoolId, start, end, contentId) => {
    return fetchData(`/device/top/${start}/${end}?website=${contentId}`, schoolId).then(res => {
      let data = res.data;
      let deviceByBrowsingTime = data.deviceByBrowsingTime;
      let deviceByBandwidth = data.deviceByBandwidth;
      let deviceByBlocked = data.deviceByBlocked;
      let mapped = {
        deviceByBrowsingTime: null,
        deviceByBandwidth: null,
        deviceByBlocked: null
      };

      if(deviceByBrowsingTime && getDeviceName(deviceByBrowsingTime.deviceName, deviceByBrowsingTime.deviceMac) && deviceByBrowsingTime.value > 0) {
        let deviceByBrowsingTimeDeviceType = deviceByBrowsingTime.deviceTypes && deviceByBrowsingTime.deviceTypes.length > 0 ? deviceByBrowsingTime.deviceTypes[0].value : "";
        mapped.deviceByBrowsingTime = {
          deviceName: getDeviceName(deviceByBrowsingTime.deviceName, deviceByBrowsingTime.deviceMac),
          deviceCategory: deviceByBrowsingTime.deviceCategory,
          description: deviceByBrowsingTimeDeviceType,
          value: deviceByBrowsingTime.value,
          deviceMac: deviceByBrowsingTime.deviceMac
        }
      }

      if(deviceByBandwidth && getDeviceName(deviceByBandwidth.deviceName, deviceByBandwidth.deviceMac)  && deviceByBandwidth.value > 0) {
        let deviceByBandwidthDeviceType = deviceByBandwidth.deviceTypes && deviceByBandwidth.deviceTypes.length > 0 ? deviceByBandwidth.deviceTypes[0].value : "";
        mapped.deviceByBandwidth = {
          deviceName: getDeviceName(deviceByBandwidth.deviceName, deviceByBandwidth.deviceMac),
          deviceCategory: deviceByBandwidth.deviceCategory,
          description: deviceByBandwidthDeviceType,
          value: deviceByBandwidth.value,
          deviceMac: deviceByBandwidth.deviceMac
        }
      }

      let blockedDeviceName = getDeviceName(deviceByBlocked.deviceName, deviceByBlocked.deviceMac);

      if(deviceByBlocked && blockedDeviceName) {
        let deviceByBlockedDeviceType = deviceByBlocked.deviceTypes && deviceByBlocked.deviceTypes.length > 0 ? deviceByBlocked.deviceTypes[0].value : "";
        mapped.deviceByBlocked = {
          deviceName: blockedDeviceName,
          deviceCategory: deviceByBlocked.deviceCategory,
          description: deviceByBlockedDeviceType,
          value: deviceByBlocked.value,
          deviceMac: deviceByBlocked.deviceMac
        }
      }

      let result = {
        alert: null,
        data: {
            subject: null,
            items: this.deviceInsights_ItemsObjectMapping(mapped)
        }
      };
  
      return result;
    });
  
  };
  
  
  deviceInsights_ItemsObjectMapping = (data) => {
    var array = [];
    var item1 = TileItemClass();
    var item2 = TileItemClass();
    var item3 = TileItemClass();
  
    if (data) {
      const object1 = data.deviceByBrowsingTime;  
      const object2 = data.deviceByBandwidth;
      const topDeviceByBlocked = data.deviceByBlocked;
  
        if(object1) {
            item1.id = '1005';
            item1.identifier = object1.deviceMac;
            item1.title = "Top Device by Browsing Time";
            item1.value = getReadableDuration(object1.value); 
            item1.unit = "(HH:MM:SS)";
            item1.path = `device-profile`;
            item1.route = {
              page: 'content-profile',
              params: {
                curtab: "devices",
                view: "devices-browsing-time",
                fromContext: ["websiteid"]
              }
            };
            item1.chip.label = getDeviceName(object1.deviceName, object1.deviceMac);
            item1.chip.description = object1.deviceCategory;
            item1.chip.image.type = "icon";
            item1.chip.image.name = iconName(object1.deviceCategory);
            item1.chip.image.class = "devices";
            array.push(item1);
        }
  
        if(object2) {
          item2.id = '1006';
          item2.identifier = object2.deviceMac;
          item2.title = "Top Device by Bandwidth Usage";
          item2.value = bytesToUnit(object2.value, "GB"); //display number with , seperator
          item2.unit = "(GB)";
          item2.path = `device-profile`;
          item2.route = {
            page: 'content-profile',
            params: {
              curtab: "devices",
              view: "devices-bandwidth-usage",
              fromContext: ["websiteid"]
            }
          };
          item2.chip.label = getDeviceName(object2.deviceName, object2.deviceMac);
          item2.chip.description = object2.deviceCategory;
          item2.chip.image.type = "icon";
          item2.chip.image.name = iconName(object2.deviceCategory);
          item2.chip.image.class = "devices";
          array.push(item2);
        }

        if(topDeviceByBlocked) {
          item3.id = `${Math.random()}`;
          item3.identifier = topDeviceByBlocked.deviceMac;
          item3.title = "Top Device by Blocked Attempts";
          item3.value = formatNumber(topDeviceByBlocked.value); //display number with , seperator
          item3.unit = null;
          item3.path = `device-profile`;
          item3.route = {
            page: 'content-profile',
            params: {
              curtab: "devices",
              view: "devices-blocked-attempts",
              fromContext: ["websiteid"]
            }
          };
          item3.chip.label = getDeviceName(topDeviceByBlocked.deviceName, topDeviceByBlocked.deviceMac);
          item3.chip.description = topDeviceByBlocked.deviceCategory;
          item3.chip.image.type = "icon";
          item3.chip.image.name = iconName(topDeviceByBlocked.deviceCategory);
          item3.chip.image.class = "devices";
          array.push(item3);
        }
    }
  
    return array;
  }
  
}