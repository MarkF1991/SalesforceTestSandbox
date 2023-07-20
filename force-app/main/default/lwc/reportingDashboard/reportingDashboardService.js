import { TileItemClass } from "c/utilitiesClass";
import {
  fetchData,
  formatNumber,
  iconName
} from "c/utilitiesFunction";
import getAccessibleSchools from "@salesforce/apex/AccountController.getAccessibleSchools";
import USER_ID from "@salesforce/user/Id";

export default class ReportingDashboardService {

  getAccessibleSchoolsForCurrentUser() {
    return getAccessibleSchools({ userid: USER_ID });
  }

  getCategoryInsights = (schoolId, start, end) => {
    return fetchData(`/content/category/top/${start}/${end}`, schoolId).then(res => {
      let data = res.data;
      return {
        data: {
          categoryByBrowsingTime: {
            label: data.topCategoryByBtime.label,
            category: data.topCategoryByBtime.label,
            value: data.topCategoryByBtime.value
          },
          categoryByBandwidth: {
            label: data.topCategoryByBandwidth.label,
            category: data.topCategoryByBandwidth.label,
            value: data.topCategoryByBandwidth.value
          },
          categoryByBlocked: {
            label: data.topCategoryByBlocked.label,
            category: data.topCategoryByBlocked.label,
            value: data.topCategoryByBlocked.value
          }
        }
      };
    });
  }

  getApplicationInsights = (schoolId, start, end) => {
    return fetchData(`/content/application/top/${start}/${end}`, schoolId).then(res => {
      let data = res.data;
      return {
        data: {
          appByBandwidth: {
            label: data.topApplicationByBandwidth.label,
            category: 'informationTechnology',
            value: data.topApplicationByBandwidth.value
          }
        }
      };
    });
  }

  getWebsiteInsights = (schoolId, start, end) => {
      return fetchData(`/content/website/top/${start}/${end}`, schoolId).then(res => {
        let data = res.data;
        return {
          data: {
            websiteByBrowsingTime: {
              label: data.topWebsiteByBtime.label,
              category: data.topWebsiteByBtime.category,
              value: data.topWebsiteByBtime.value,
              identifier: data.topWebsiteByBtime.label,
              path: 'content-profile',
              id: '2001'
            },
            websiteByBandwidth: {
              label: data.topWebsiteByBandwidth.label,
              category: data.topWebsiteByBandwidth.category,
              value: data.topWebsiteByBandwidth.value,
              identifier: data.topWebsiteByBandwidth.label,
              path: 'content-profile',
              id: '2002'
            },
            websiteByBlocked: {
              label: data.topWebsiteByBlocked.label,
              category: data.topWebsiteByBlocked.category,
              value: data.topWebsiteByBlocked.value,
              identifier: data.topWebsiteByBlocked.label,
              path: 'content-profile',
              id: '2003'
            }
          }
        }
    });
  }

  getInfectedDeviceCount = (schoolId, start, end) => {
    return fetchData(`/security/infectedDevice/list/${start}/${end}?page=1&perPage=2000`, schoolId).then(res => {
      let data = res.data;

      return { value: data.length, trend: 0, category: "attack" };
    });
  }

  getDeviceTypeCounts = (schoolId, start, end) => {
    return fetchData(`/device/count/${start}/${end}`, schoolId).then(res => {
      let total = res.data.total;
      let deviceTypesList = res.data.deviceTypesList || [];
      let perUser = res.data.perUser;

      return {
        data: {
          totalDevices: { category: "iPhone", value: total.value, trend: parseFloat(total.trend).toFixed(2) },
          devicesPerUser: { category: "laptop", value: perUser.value, trend: parseFloat(perUser.trend).toFixed(2) },
          devicesByType: deviceTypesList.map((item) => {
              return {
                  category: item.category,
                  label: item.type,
                  value: item.count,
                  trend: item.trend,
                  percentage: parseFloat(item.percent).toFixed(2)
              }
          })
        }
      };
    });
  };

  safetyInsightsFetchData = (schoolId, start, end) => {
      return fetchData(`/safety/summary/${start}/${end}`, schoolId).then(res => {
        let obj = res;
    
        let result = {
          alert: null,
    
          data: {
            subject: "Safety Risk Categories by Blocked Attempts",
            items: this.safetyInsights_ItemsObjectMapping(obj)
          }
        };
        return result;
      });
    };
    
    safetyInsights_ItemsObjectMapping(resObject) {
      var result = [];
      if (resObject) {
        let href = `category-profile`;
        let filtered = resObject.data.filter(val => val.rank < 3);
        if (filtered.length > 0) {
          result = result.concat(filtered.map(obj => this.safetyInsights_simpleObjectMapping(obj, href))).sort((a, b) => {
              return b.rank - a.rank;
            });
          return result.slice(0, 5);
        }
        return [this.safetyInsights_simpleObjectMapping({ category: "Nothing to show here.", rank: "3" }, href)];
      }
      return result;
    }
    
    safetyInsights_simpleObjectMapping(objectData, href) {
      //prepare json object arrays for tileItemObject component.
      var simpleObject = TileItemClass();
      simpleObject.id = objectData.category;
      simpleObject.title = null;
      if (objectData.blocked_requests) {
        simpleObject.value = formatNumber(objectData.blocked_requests);
      }
      simpleObject.unit = null;
      simpleObject.path = href;
      simpleObject.chip.label = objectData.category;
      simpleObject.chip.description = null;
      simpleObject.chip.image.type = "icon";
      simpleObject.chip.image.name = iconName(objectData.category);
      simpleObject.chip.image.class = objectData.rank === "1" ? "security" : "content";

      return simpleObject;
    }
}