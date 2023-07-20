import { TileItemClass, TileChipClass } from "c/utilitiesClass";
import { fetchData, formatNumber, iconName, bytesToUnit, getReadableDuration } from "c/utilitiesFunction";

function getDeviceName(name, mac) {
  return name ? name : mac;
}

export default class CategoryDetailService {

  getWebsiteInsights = (schoolId, start, end, categoryId, isBlocked) => {
    return fetchData(`/content/website/top/${start}/${end}?category=${categoryId}`, schoolId).then(res => {
      let data = res.data;
      if(isBlocked) {
        return {
          data: {
            websiteByBlocked: {
              label: data.topWebsiteByBlocked.label,
              category: data.topWebsiteByBlocked.category,
              value: data.topWebsiteByBlocked.value,
              identifier: data.topWebsiteByBlocked.label,
              path: 'content-profile',
              id: '2003',
              route: {
                page: 'category-profile',
                params: {
                  curtab: "websites",
                  view: "websites-blocked-attempts",
                  fromContext: ["categoryid"]
                }
              }
            }
          }
        }
      }
      return {
        data: {
          websiteByBrowsingTime: {
            label: data.topWebsiteByBtime.label,
            category: data.topWebsiteByBtime.category,
            value: data.topWebsiteByBtime.value,
            identifier: data.topWebsiteByBtime.label,
            path: 'content-profile',
            id: '2001',
            route: {
              page: 'category-profile',
              params: {
                curtab: "websites",
                view: "websites-browsing-time",
                fromContext: ["categoryid"]
              }
            }
          },
          websiteByBandwidth: {
            label: data.topWebsiteByBandwidth.label,
            category: data.topWebsiteByBandwidth.category,
            value: data.topWebsiteByBandwidth.value,
            identifier: data.topWebsiteByBandwidth.label,
            path: 'content-profile',
            id: '2002',
            route: {
              page: 'category-profile',
              params: {
                curtab: "websites",
                view: "websites-bandwidth-usage",
                fromContext: ["categoryid"]
              }
            }
          },
          websiteByBlocked: {
            label: data.topWebsiteByBlocked.label,
            category: data.topWebsiteByBlocked.category,
            value: data.topWebsiteByBlocked.value,
            identifier: data.topWebsiteByBlocked.label,
            path: 'content-profile',
            id: '2003',
            route: {
              page: 'category-profile',
              params: {
                curtab: "websites",
                view: "websites-blocked-attempts",
                fromContext: ["categoryid"]
              }
            }
          }
        }
      }
  });
}

  // ------------ categoryInformationFetchData ------------------------------------------------------------------------------------------------------
  categoryInformationFetchData = (schoolId, category) => {
    // eslint-disable-next-line no-unused-vars
    return fetchData(`/content/category/${category}`, schoolId).then(res => {
      let data = res.data;
  
      let alert = data.rank < 3 ? { label: "This category is currently being blocked", description: "" } : null;

      let result = {
        alert: this.categoryInformation_AlertObjectMapping(alert),
        data: {
            subject: 'Description',
            information: data.description,
            blocked: data.blocked,
            items: null
        }
      };
      return result;
    });

  };

  categoryInformation_AlertObjectMapping = (resAlert) => {
    if (resAlert) {
      let alert = TileChipClass();
      let isAlert = true;
      alert.label = resAlert.label;
      alert.description = resAlert.description;
      alert.image.type = "icon";
      alert.image.name = iconName(isAlert ? "alert" : "clear");
      alert.image.class = isAlert ? "slds-theme--error" : "slds-theme--success";
      return alert;
    }
    return null;
  }
  // ------------ end of categoryInformationFetchData ------------------------------------------------------------------------------------------------------

  // ------------ userInsightsFetchData ------------------------------------------------------------------------------------------------------
  userInsightsFetchData = (schoolId, start, end, category, blocked) => {

    return fetchData(`/user/top/${start}/${end}?category=${category}`, schoolId).then(res => {
      let obj = res.data;

      let result = {
        alert: null,
        data: {
            subject: null,
            items: this.userInsights_ItemsObjectMapping(obj, blocked)
        }
      };
      
      return result;
    });

  };


  userInsights_ItemsObjectMapping = (data, blocked) => {
    var array = [];
    var item1 = TileItemClass();

    if (data) {
      if(!blocked) {
        const topUserByBandwidth = data.userBandwidthUsage;
        if(topUserByBandwidth) {
          let item2 = TileItemClass();
          item2.id = '202';
          item2.title = "Top User by Bandwidth Usage";
          item2.value = bytesToUnit(topUserByBandwidth.value, "GB"); //display number with , seperator
          item2.unit = "(GB)";
          item2.path = `user-profile`;
          item2.route = {
            page: 'category-profile',
            params: {
              curtab: "users",
              view: "users-bandwidth-usage",
              fromContext: ["categoryid"]
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
            page: 'category-profile',
            params: {
              curtab: "users",
              view: "users-browsing-time",
              fromContext: ["categoryid"]
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
      } else {

        const object1 = data.userBlockedAttempts;

        if(object1) {
          //top user by Blocked Attempts
          item1.id = '201';
          item1.title = "Top User by Blocked Attempts";
          item1.value = formatNumber(object1.value); //display number with , seperator
          item1.unit = " "; //nothing to display, but occupy the top space
          item1.path = `user-profile`;
          item1.route = {
            page: 'category-profile',
            params: {
              curtab: "users",
              view: "users-blocked-attempts",
              fromContext: ["categoryid"]
            }
          };
          item1.identifier = object1.label;
          item1.chip.label = object1.label;
          item1.chip.description = object1.description;
          item1.chip.image.type = "avatar";
          item1.chip.image.name = object1.label ? object1.label.substring(0, 1).toUpperCase() : ""; //initial
          item1.chip.image.class = "user"; //fixed as user - this will affect class to render colour based on tileChip.css
          array.push(item1);
        }
      }
    }
    
    return array;
  }
  // ------------end of userInsightsFetchData ------------------------------------------------------------------------------------------------------

  // ------------ deviceInsightsFetchData ------------------------------------------------------------------------------------------------------
  deviceInsightsFetchData = (schoolId, start, end, category, blocked) => {
    return fetchData(`/device/top/${start}/${end}?category=${category}`, schoolId).then(res => {
      let obj = res.data;

      let result = {
        alert: null,
        data: {
            subject: null,
            items: this.deviceInsights_ItemsObjectMapping(obj, blocked)
        }
      };
      return result;
    });
  };

  deviceInsights_ItemsObjectMapping = (data, blocked) => {
    var array = [];
    var item1 = TileItemClass();

    if (data) {

      if(!blocked) {
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
            page: 'category-profile',
            params: {
              curtab: "devices",
              view: "devices-bandwidth-usage",
              fromContext: ["categoryid"]
            }
          };
          item2.chip.label = getDeviceName(topDeviceByBandwidth.deviceName, topDeviceByBandwidth.deviceMac);
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
          item3.identifier = topDeviceByBandwidth.deviceMac;
          item3.title = "Top Device by Browsing Time";
          item3.value = getReadableDuration(topDeviceByBtime.value); 
          item3.unit = "(HH:MM:SS)";
          item3.path = `device-profile`;
          item3.route = {
            page: 'category-profile',
            params: {
              curtab: "devices",
              view: "devices-browsing-time",
              fromContext: ["categoryid"]
            }
          };
          item3.chip.label = getDeviceName(topDeviceByBtime.deviceName, topDeviceByBtime.deviceMac);
          item3.chip.description = topDeviceByBtime.deviceCategory;
          item3.chip.image.type = "icon";
          item3.chip.image.name = iconName(topDeviceByBtime.deviceCategory);
          item3.chip.image.class = "devices";
          array.push(item3);
        }
      } else {

        const topDeviceByBlocked = data.deviceByBlocked;  

        if(topDeviceByBlocked) {
          item1.id = `${Math.random()}`;
          item1.identifier = topDeviceByBlocked.deviceMac;
          item1.title = "Top Device by Blocked Attempts";
          item1.value = formatNumber(topDeviceByBlocked.value); //display number with , seperator
          item1.unit = null;
          item1.path = `device-profile`;
          item1.route = {
            page: 'category-profile',
            params: {
              curtab: "devices",
              view: "devices-blocked-attempts",
              fromContext: ["categoryid"]
            }
          };
          item1.chip.label = getDeviceName(topDeviceByBlocked.deviceName, topDeviceByBlocked.deviceMac);
          item1.chip.description = topDeviceByBlocked.deviceCategory;
          item1.chip.image.type = "icon";
          item1.chip.image.name = iconName(topDeviceByBlocked.deviceCategory);
          item1.chip.image.class = "devices";
          array.push(item1);
    
        }
      }
    }
    return array;
  }

  // ------------end of deviceInsightsFetchData ------------------------------------------------------------------------------------------------------

}