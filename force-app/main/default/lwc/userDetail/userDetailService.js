import { TileItemClass } from "c/utilitiesClass";
import {
  fetchData,
  formatNumber,
  iconName
} from "c/utilitiesFunction";

export default class UserDetailService {

  getCategoryInsights = (schoolId, start, end, userId) => {
    return fetchData(`/content/category/top/${start}/${end}?user=${userId}`, schoolId).then(res => {
      let data = res.data;
      return {
        data: {
          categoryByBrowsingTime: {
            label: data.topCategoryByBtime.label,
            category: data.topCategoryByBtime.label,
            value: data.topCategoryByBtime.value,
            route: {
              page: 'user-profile',
              params: {
                curtab: "categories",
                view: "categories-browsing-time",
                fromContext: ["userid"]
              }
            }
          },
          categoryByBandwidth: {
            label: data.topCategoryByBandwidth.label,
            category: data.topCategoryByBandwidth.label,
            value: data.topCategoryByBandwidth.value,
            route: {
              page: 'user-profile',
              params: {
                curtab: "categories",
                view: "categories-bandwidth-usage",
                fromContext: ["userid"]
              }
            }
          },
          categoryByBlocked: {
            label: data.topCategoryByBlocked.label,
            category: data.topCategoryByBlocked.label,
            value: data.topCategoryByBlocked.value,
            route: {
              page: 'user-profile',
              params: {
                curtab: "categories",
                view: "categories-blocked-attempts",
                fromContext: ["userid"]
              }
            }
          }
        }
      };
    });
  }

  getApplicationInsights = (schoolId, start, end, userId) => {
    return fetchData(`/content/application/top/${start}/${end}?user=${userId}`, schoolId).then(res => {
      let data = res.data;
      return {
        data: {
          appByBandwidth: {
            label: data.topApplicationByBandwidth.label,
            category: 'informationTechnology',
            value: data.topApplicationByBandwidth.value,
            route: {
              page: 'user-profile',
              params: {
                curtab: "apps",
                view: "apps-bandwidth-usage",
                fromContext: ["userid"]
              }
            }
          }
        }
      };
    });
  }

  getWebsiteInsights = (schoolId, start, end, userId) => {
      return fetchData(`/content/website/top/${start}/${end}?user=${userId}`, schoolId).then(res => {
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
                page: 'user-profile',
                params: {
                  curtab: "websites",
                  view: "websites-browsing-time",
                  fromContext: ["userid"]
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
                page: 'user-profile',
                params: {
                  curtab: "websites",
                  view: "websites-bandwidth-usage",
                  fromContext: ["userid"]
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
                page: 'user-profile',
                params: {
                  curtab: "websites",
                  view: "websites-blocked-attempts",
                  fromContext: ["userid"]
                }
              }
            }
          }
        }
    });
  }

  simpleObjectMapping(objectData, href, context) {
    //prepare json object arrays for tileItemObject component.
    var simpleObject = TileItemClass();
    simpleObject.id = objectData.identifier;
    simpleObject.identifier = objectData.identifier;
    simpleObject.title = null;
    simpleObject.value = objectData.value ? formatNumber(objectData.value) : null;
    simpleObject.unit = null;
    simpleObject.path = href;
    simpleObject.chip.label = objectData.label;
    simpleObject.chip.description = objectData.description;
    simpleObject.chip.image.type = "icon";
    if (objectData.category) {
      simpleObject.chip.image.name = iconName(objectData.category);
    } else {
      simpleObject.chip.image.name = null;
    }
    simpleObject.chip.image.class = objectData.isInfected ? "security" : context;
    return simpleObject;
  }
  // ------------ end of associatedDevicesFetchData ------------------------------------------------------------------------------------------------------

  // ------------ safetyInsightsFetchData ------------------------------------------------------------------------------------------------------
  safetyInsightsFetchData = (schoolId, start, end, userid) => {
    return fetchData(`/safety/summary/${start}/${end}?user=${userid}`, schoolId).then(res => {
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
        result = result.concat(filtered.map(obj => this.safetyInsights_simpleObjectMapping(obj, href, filtered.length)))
          .sort((a, b) => {
            return b.rank - a.rank;
          });
        return result.slice(0, 5);
      }
      return [
        this.safetyInsights_simpleObjectMapping({ category: "Nothing to show here.", rank: "3", value: " " }, href, filtered.length)
      ];
    }
    return result;
  }

  safetyInsights_simpleObjectMapping(objectData, href, count) {
    //prepare json object arrays for tileItemObject component.
    var simpleObject = TileItemClass();
    simpleObject.id = `${Math.random()}`;
    simpleObject.title = null;

    if (objectData.blocked_requests) {
      simpleObject.value = formatNumber(objectData.blocked_requests);
    }

    if(objectData.value) {
      simpleObject.value = objectData.value;
    }
    simpleObject.unit = null;
    simpleObject.path = href;
    simpleObject.route = {
      page: 'user-profile',
      params: {
        curtab: "categories",
        view: "safety-categories-blocked-attempts",
        fromContext: ["userid"]
      }
    }
    simpleObject.identifier = objectData.category;
    simpleObject.chip.label = objectData.category;
    simpleObject.chip.description = null;
    let imageClass = objectData.rank === "1" ? "security" : "content";
    let imageName = iconName(objectData.category);
    if(count <= 0) {
      imageClass = "success";
      imageName = iconName("success");
    }
    simpleObject.chip.image.type = "icon";
    simpleObject.chip.image.name = imageName;
    simpleObject.chip.image.class = imageClass;
    return simpleObject;
  }
  // ------------ end of safetyInsightsFetchData ------------------------------------------------------------------------------------------------------

}