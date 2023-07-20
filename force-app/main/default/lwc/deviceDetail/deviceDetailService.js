import { TileItemClass, TileChipClass } from "c/utilitiesClass";
import { fetchData, formatNumber, bytesToUnit, getReadableDuration, iconName } from "c/utilitiesFunction";

export default class DeviceDetailService {

  getCategoryInsights = (schoolId, start, end, deviceId) => {
    return fetchData(`/content/category/top/${start}/${end}?device=${deviceId}`, schoolId).then(res => {
      let data = res.data;
      return {
        data: {
          categoryByBrowsingTime: {
            label: data.topCategoryByBtime.label,
            category: data.topCategoryByBtime.label,
            value: data.topCategoryByBtime.value,
            route: {
              page: 'device-profile',
              params: {
                curtab: "categories",
                view: "categories-browsing-time",
                fromContext: ["deviceid"]
              }
            }
          },
          categoryByBandwidth: {
            label: data.topCategoryByBandwidth.label,
            category: data.topCategoryByBandwidth.label,
            value: data.topCategoryByBandwidth.value,
            route: {
              page: 'device-profile',
              params: {
                curtab: "categories",
                view: "categories-bandwidth-usage",
                fromContext: ["deviceid"]
              }
            }
          },
          categoryByBlocked: {
            label: data.topCategoryByBlocked.label,
            category: data.topCategoryByBlocked.label,
            value: data.topCategoryByBlocked.value,
            route: {
              page: 'device-profile',
              params: {
                curtab: "categories",
                view: "categories-blocked-attempts",
                fromContext: ["deviceid"]
              }
            }
          }
        }
      };
    });
  }

  getApplicationInsights = (schoolId, start, end, deviceId) => {
    return fetchData(`/content/application/top/${start}/${end}?device=${deviceId}`, schoolId).then(res => {
      let data = res.data;
      return {
        data: {
          appByBandwidth: {
            label: data.topApplicationByBandwidth.label,
            category: 'informationTechnology',
            value: data.topApplicationByBandwidth.value,
            route: {
              page: 'device-profile',
              params: {
                curtab: "apps",
                view: "apps-bandwidth-usage",
                fromContext: ["deviceid"]
              }
            }
          }
        }
      };
    });
  }

  getWebsiteInsights = (schoolId, start, end, deviceId) => {
      return fetchData(`/content/website/top/${start}/${end}?device=${deviceId}`, schoolId).then(res => {
        let data = res.data;
        return {
          data: {
            websiteByBrowsingTime: {
              label: data.topWebsiteByBtime.label,
              category: 'informationTechnology',
              value: data.topWebsiteByBtime.value,
              identifier: data.topWebsiteByBtime.label,
              path: 'content-profile',
              id: '2001',
              route: {
                page: 'device-profile',
                params: {
                  curtab: "websites",
                  view: "websites-browsing-time",
                  fromContext: ["deviceid"]
                }
              }
            },
            websiteByBandwidth: {
              label: data.topWebsiteByBandwidth.label,
              category: 'informationTechnology',
              value: data.topWebsiteByBandwidth.value,
              identifier: data.topWebsiteByBandwidth.label,
              path: 'content-profile',
              id: '2002',
              route: {
                page: 'device-profile',
                params: {
                  curtab: "websites",
                  view: "websites-bandwidth-usage",
                  fromContext: ["deviceid"]
                }
              }
            },
            websiteByBlocked: {
              label: data.topWebsiteByBlocked.label,
              category: 'informationTechnology',
              value: data.topWebsiteByBlocked.value,
              identifier: data.topWebsiteByBlocked.label,
              path: 'content-profile',
              id: '2003',
              route: {
                page: 'device-profile',
                params: {
                  curtab: "websites",
                  view: "websites-blocked-attempts",
                  fromContext: ["deviceid"]
                }
              }
            }
          }
        }
    });
  }

  // ------------ userInsightsFetchData ------------------------------------------------------------------------------------------------------
  userInsightsFetchData = (schoolId, start, end, deviceId) => {
    return fetchData(`/user/top/${start}/${end}?device=${deviceId}`, schoolId).then(res => {
      let obj = res;

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

  userInsights_ItemsObjectMapping = (resObject) => {
    var array = [];
    var item1 = TileItemClass();
    var item2 = TileItemClass();
    var item3 = TileItemClass();

    if (resObject) {
      const object1 = resObject.data.userBrowsingTime;  
      const object2 = resObject.data.userBandwidthUsage;
      const object3 = resObject.data.userBlockedAttempts;

        if(object1) {
            item1.id = '1';
            item1.title = "Top User By Browsing Time";
            item1.value = getReadableDuration(object1.value); 
            item1.unit = "(HH:MM:SS)";
            item1.path = `user-profile`;
            item1.route = {
              page: 'device-profile',
              params: {
                curtab: "users",
                view: "users-browsing-time",
                fromContext: ["deviceid"]
              }
            };
            item1.identifier = object1.label;
            item1.chip.label = object1.label;
            item1.chip.description = object1.description;
            item1.chip.image.type = "avatar";
            item1.chip.image.name = object1.label ? object1.label.substring(0, 1).toUpperCase() : ""; //initial
            item1.chip.image.class = "user";
            array.push(item1);
        }
        
        if(object2) {
          item2.id = '2';
          item2.title = "Top User by Bandwidth Usage";
          item2.value = bytesToUnit(object2.value, "GB"); 
          item2.unit = "(GB)";
          item2.path = `user-profile`;
          item2.route = {
            page: 'device-profile',
            params: {
              curtab: "users",
              view: "users-bandwidth-usage",
              fromContext: ["deviceid"]
            }
          };
          item2.identifier = object2.label;
          item2.chip.label = object2.label;
          item2.chip.description = object2.description;
          item2.chip.image.type = "avatar";
          item2.chip.image.name = object2.label ? object2.label.substring(0, 1).toUpperCase() : ""; //initial
          item2.chip.image.class = "user";
          array.push(item2);
        }

        if(object3) {
          //top user by Blocked Attempts
          item3.id = '3';
          item3.title = "Top User by Blocked Attempts";
          item3.value = formatNumber(object3.value); //display number with , seperator
          item3.unit = " "; //nothing to display, but occupy the top space
          item3.path = `user-profile`;
          item3.route = {
            page: 'device-profile',
            params: {
              curtab: "users",
              view: "users-blocked-attempts",
              fromContext: ["deviceid"]
            }
          };
          item3.identifier = object3.label;
          item3.chip.label = object3.label;
          item3.chip.description = object3.description;
          item3.chip.image.type = "avatar";
          item3.chip.image.name = object3.label ? object3.label.substring(0, 1).toUpperCase() : ""; //initial
          item3.chip.image.class = "user"; //fixed as user - this will affect class to render colour based on tileChip.css
          array.push(item3);
        }
    }
    return array;
  }
  // ------------end of userInsightsFetchData ------------------------------------------------------------------------------------------------------

  // ------------ safetyInsightsFetchData ------------------------------------------------------------------------------------------------------
  safetyInsightsFetchData = (schoolId, start, end, deviceId) => {
    return fetchData(`/safety/summary/${start}/${end}?device=${deviceId}`, schoolId).then(res => {
      let obj = res;

      let result = {
        alert: null,
        
        data: {
            subject: 'Safety Risk Categories by Blocked Attempts',
            items: this.safetyInsights_ItemsObjectMapping(obj)
        }
      };
      
      return result;
    
    });

  };

  safetyInsights_ItemsObjectMapping = (resObject) => {
    var result = [];
    if(resObject) {
      let href = `category-profile`;
      result = result.concat(resObject.data.map(obj => this.safetyInsights_simpleObjectMapping(obj, href))).sort((a, b) => { return b.rank - a.rank; });
      return result.slice(0, 5);
    }
    return result;
  }

  safetyInsights_simpleObjectMapping = (objectData, href) => {
    //prepare json object arrays for tileItemObject component.
    var simpleObject = TileItemClass();
    simpleObject.id = `${Math.random()}`;
    simpleObject.identifier = objectData.category;
    simpleObject.title = null;
    simpleObject.value = formatNumber(objectData.blocked_requests);
    simpleObject.unit = null;
    simpleObject.path = href;
    simpleObject.route = {
      page: 'device-profile',
      params: {
        curtab: "categories",
        view: "safety-categories-blocked-attempts",
        fromContext: ["deviceid"]
      }
    }
    simpleObject.chip.label = objectData.category;
    simpleObject.chip.description = null;
    simpleObject.chip.image.type = "icon";
    simpleObject.chip.image.name = iconName(objectData.category);
    simpleObject.chip.image.class = objectData.rank === '1' ? 'security' : 'content';

    return simpleObject;
  }

  // ------------ end of safetyInsightsFetchData ------------------------------------------------------------------------------------------------------

  // ------------ securityInsightsFetchData ------------------------------------------------------------------------------------------------------
  securityInsightsFetchData = (schoolId, start, end, deviceId) => {
    return fetchData(`/security/infectedDevice/list/${start}/${end}?device=${deviceId}`, schoolId).then(res => {
      let threats = [];
      let data = res.data;
      if(data && data.length > 0) {
        threats = data[0].threats;
      }
      let alert = {
        value: threats.length,
        infectionsRemoved: 0
      }

      let result = {
        alert: this.securityInsights_AlertObjectMapping(alert),

        data: {
            subject: null,
            items: this.securityInsights_ItemsObjectMapping(threats)
        }
      };    
      return result;
    });

  };

  securityInsights_AlertObjectMapping = (alertRes) => {
    if (alertRes) {
      let alert = TileChipClass();
      let isAlert = alertRes.value > 0;
      alert.label = isAlert ? `Looks like ${alertRes.value} Virus has been found` : `No infection found`;
      alert.description = isAlert ? null : `Great work on getting rid of the ${alertRes.infectionsRemoved} infections that were on this device`;
      alert.image.type = "icon";
      alert.image.name = iconName(isAlert ? "alert" : "clear");
      alert.image.class = isAlert ? "slds-theme--error" : "slds-theme--success";
      return alert;
    }
    return null;
  }

  securityInsights_ItemsObjectMapping = (threats) => {
    var result = [];
    if(threats) {
      let href = "infection-profile";
      result = result.concat(threats.map(threat => this.securityInsights_simpleObjectMapping(threat, href))).sort((a, b) => { return b.value - a.value; });
      return result.slice(0, 5);
    }

    return result;
  }

  securityInsights_simpleObjectMapping = (objectData, href) => {
    //prepare json object arrays for tileItemObject component.
    var simpleObject = TileItemClass();
    simpleObject.id = `${Math.random()}`;
    simpleObject.identifier = objectData.value;
    simpleObject.title = null;
    simpleObject.value = null;
    simpleObject.unit = null;
    simpleObject.path = href; 
    simpleObject.chip.label = objectData.value;
    simpleObject.chip.description = objectData.type;
    simpleObject.chip.image.type = "icon";
    simpleObject.chip.image.name = iconName('attack');
    simpleObject.chip.image.class = 'security';

    return simpleObject;
  }

  // ------------ end of securityInsightsFetchData ------------------------------------------------------------------------------------------------------

  // ------------ pageHeaderDetailsFetchData ------------------------------------------------------------------------------------------------------
  pageHeaderDetailsFetchData = (schoolId, start, end) => {
    // eslint-disable-next-line no-unused-vars
    return fetchData(`/user/top/${start}/${end}`, schoolId).then(res => {
      let obj = {
        data: {
          details: [
            {title:'Name', value:'TODO'},
            {title:'Type', value:'TODO'},
            {title:'MAC Addresses', value:'TODO'},
            {title:'Operating System', value:'TODO'},
            {title:'Operating System Version', value:'TODO'},
            {title:'Last IP Address', value:'TODO'},
          ]
        }
      };
      let result = this.pageHeaderDetail_ItemsObjectMapping(obj); //return as array for tilePageHeader.html to render
      return result;
    });
  };

  pageHeaderDetail_ItemsObjectMapping = (resObject) => {
    var result = [];
    if(resObject) {
      result = result.concat(resObject.data.details.map(obj => this.pageHeaderDetail_simpleObjectMapping(obj)));
      return result;
    }
    return result;
  }

  pageHeaderDetail_simpleObjectMapping =(objectData) => {
    //prepare json object arrays for tileItemObject component.
    var simpleObject = TileItemClass();
    simpleObject.id = `${Math.random()}`;
    simpleObject.title = objectData.title;
    simpleObject.value = objectData.value;
    return simpleObject;
  }

  // ------------ end of pageHeaderDetailsFetchData ------------------------------------------------------------------------------------------------------

}