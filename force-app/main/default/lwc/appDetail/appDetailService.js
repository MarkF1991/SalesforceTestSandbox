import { TileItemClass } from "c/utilitiesClass";
import { fetchData, iconName, bytesToUnit, getReadableDuration } from "c/utilitiesFunction";

export default class AppDetailService {

  getDeviceName(name, mac) {
    return name ? name : mac;
  }

  userInsightsFetchData = (schoolId, start, end, app) => {
  
    return fetchData(`/user/top/${start}/${end}?application=${app}`, schoolId).then(res => {
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
  
  
  userInsights_ItemsObjectMapping = (data)  => {
    var array = [];
  
    if (data) {
      const topUserByBandwidth = data.userBandwidthUsage;
      if(topUserByBandwidth) {
        let item2 = TileItemClass();
        item2.id = '202';
        item2.title = "Top User by Bandwidth Usage";
        item2.value = bytesToUnit(topUserByBandwidth.value, "GB"); //display number with , seperator
        item2.unit = "(GB)";
        item2.path = `user-profile`;
        item2.route = {
          page: 'apps-profile',
          params: {
            curtab: "users",
            view: "users-bandwidth-usage",
            fromContext: ["appid"]
          }
        };
        item2.identifier = topUserByBandwidth.label;
        item2.chip.label = topUserByBandwidth.label;
        item2.chip.description = topUserByBandwidth.description;
        item2.chip.image.type = "avatar";
        item2.chip.image.name = topUserByBandwidth.label ? topUserByBandwidth.label.substring(0, 1).toUpperCase() : ""; //initial
        item2.chip.image.class = "user";
        array.push(item2);
      }
  
      const topUserByBtime = data.userBrowsingTime;
      if(topUserByBtime) {
        let item3 = TileItemClass();
        item3.id = '203';
        item3.title = "Top User by Browsing Time";
        item3.value = getReadableDuration(topUserByBtime.value);
        item3.unit = "(HH:MM:SS)";
        item3.path = `device-profile`;
        item3.route = {
          page: 'apps-profile',
          params: {
            curtab: "users",
            view: "users-browsing-time",
            fromContext: ["appid"]
          }
        };
        item3.identifier = topUserByBtime.label;
        item3.chip.label = topUserByBtime.label;
        item3.chip.description = topUserByBtime.description;
        item3.chip.image.type = "avatar";
        item3.chip.image.name = topUserByBtime.label ? topUserByBtime.label.substring(0, 1).toUpperCase() : ""; //initial
        item3.chip.image.class = "user";
        array.push(item3);
      }
    }
    return array;
  }

  deviceInsightsFetchData = (schoolId, start, end, app) => {
    return fetchData(`/device/top/${start}/${end}?application=${app}`, schoolId).then(res => {
      let obj = res.data;
  
      let result = {
        alert: null,
        data: {
            subject: null,
            items: this.deviceInsights_ItemsObjectMapping(obj)
        }
      };
      return result;
    });
  };

  deviceInsights_ItemsObjectMapping = (data) => {
    var array = [];
  
    if (data) {
      const topDeviceByBandwidth = data.deviceByBandwidth;
  
      if(topDeviceByBandwidth) {
        let item2 = TileItemClass();
        item2.id = `${Math.random()}`;
        item2.identifier = topDeviceByBandwidth.deviceMac;
        item2.title = "Top Device by Bandwidth Usage";
        item2.value = bytesToUnit(topDeviceByBandwidth.value, "GB"); //display number with , seperator
        item2.unit = "(GB)";
        item2.path = `device-profile`;
        item2.route = {
          page: 'apps-profile',
          params: {
            curtab: "devices",
            view: "devices-bandwidth-usage",
            fromContext: ["appid"]
          }
        };
        item2.chip.label = this.getDeviceName(topDeviceByBandwidth.deviceName, topDeviceByBandwidth.deviceMac);
        item2.chip.description = topDeviceByBandwidth.deviceCategory;
        item2.chip.image.type = "icon";
        item2.chip.image.name = iconName(topDeviceByBandwidth.deviceCategory);
        item2.chip.image.class = "devices";
        array.push(item2);
      }
  
      const topDeviceByBtime = data.deviceByBrowsingTime;
  
      if(topDeviceByBtime) {
        let item3 = TileItemClass();
        item3.id = `${Math.random()}`;
        item3.identifier = topDeviceByBtime.deviceMac;
        item3.title = "Top Device by Browsing Time";
        item3.value = getReadableDuration(topDeviceByBtime.value); 
        item3.unit = "(HH:MM:SS)";
        item3.path = `device-profile`;
        item3.route = {
          page: 'apps-profile',
          params: {
            curtab: "devices",
            view: "devices-browsing-time",
            fromContext: ["appid"]
          }
        };
        item3.chip.label = this.getDeviceName(topDeviceByBtime.deviceName, topDeviceByBtime.deviceMac);
        item3.chip.description = topDeviceByBtime.deviceCategory;
        item3.chip.image.type = "icon";
        item3.chip.image.name = iconName(topDeviceByBtime.deviceCategory);
        item3.chip.image.class = "devices";
        array.push(item3);
      }
    }
    
    return array;
  }
}