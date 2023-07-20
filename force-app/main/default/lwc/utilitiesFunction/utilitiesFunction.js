import authenticate from "@salesforce/apex/JWTController.authenticate";
import USER_ID from "@salesforce/user/Id";
import { iconNameMapping } from "./iconMapping";

const schoolConfig = {};

function getDeviceName(name, mac) {
  return name ? name : mac;
}

function cleanId(id) {
  if (!id) {
    return "";
  }
  return id.replace(/\+/g, " ");
}

function getIdFromTarget(targetId) {
  return targetId
    ? targetId.substring(0, targetId.lastIndexOf("-")).trim()
    : null;
}

function formatNumber(num) {
  //to format number formatNumber(111102665)) to 111,102,665
  //reference https://blog.abelotech.com/posts/number-currency-formatting-javascript/
  if (num === null) {
    return "0";
  }
  return num.toString().replace(/(\d)(?=(\d{3})+(?!\d))/g, "$1,");
}

function auth() {
  return authenticate({ userid: USER_ID }).then(result => {
    return result;
  });
}

function resolveEnvironment() {
  var hostname = window.location.hostname;
  if (hostname.startsWith("reporting-n4lportal") || hostname.includes("demo.n4l.co.nz")) {
    return "demo";
  }

  if (hostname.includes("reporting.n4l.co.nz")) {
    return "production";
  }

  if(hostname.startsWith("test-n4lportal")) {
    return "test";
  }

  if(hostname.startsWith("reportingd-n4lportal")) {
    return "development";
  }

  return "local";
}

function resolveApiUrl(urlBase) {
  if (urlBase) {
    return urlBase;
  }

  let env = resolveEnvironment();

  if (env === "development") {
    return "https://dev-reporting.n4l.co.nz";
  }

  if (env === "test") {
    return "https://test-reporting.n4l.co.nz";
  }

  if (env === "demo") {
    return "https://demo-reporting-api.n4l.co.nz";
  }

  if (env === "production") {
    return "https://api.n4l.co.nz";
  }

  return "https://localtest.me";
}

const urlBase = "";
function fetchData(path, context) {
  const fullUrl = `${resolveApiUrl(urlBase)}/sr/${context}${path}`;
  return fetchDataRaw(fullUrl);
}

function fetchDataRaw(fullUrl) {
  return auth().then(t => {
    const fetchParams = {
      method: "GET",
      mode: "cors",
      headers: {
        Authorization: "Bearer " + t
      }
    };
    return fetch(fullUrl, fetchParams).then(res => res.json());
  });
}

function getSchoolConfig(context) {
  if(!schoolConfig._id) {
    const fullUrl = `${resolveApiUrl(urlBase)}/school-configs/${context}`;
    return fetchDataRaw(fullUrl).then((res) => {
      const data = res.data;
      schoolConfig.hasUserData = data ? data.hasUserData : true; 
      schoolConfig.hasDeviceData = data ? data.hasDeviceData : true;
      schoolConfig._id = context;
      return schoolConfig;
    });
  }
  return Promise.resolve(schoolConfig);
}

const iconName = category => {
  var name = "report"; //default to show error icon https://material.io/tools/icons/?icon=report&style=baseline
  if (!category) {
    return name;
  }
  let object = iconNameMapping.filter(
    item => item.category.toLowerCase() === category.toLowerCase()
  );
  if (object.length === 1) {
    name = object[0].name;
  }
  return name;
};

const getWebsiteCategory = (categoryAsCsv) => {
  let categories = categoryAsCsv ? categoryAsCsv.split(',') : [];
  return categories.length > 0 ? categories[0].trim() : "";
}

const getCategoryIcon = (categoryAsCsv) => {
  return iconName(getWebsiteCategory(categoryAsCsv));
}

const generateRandomNumber = () => {
  return Math.round(Math.random() * 100);
};

const getDateRangeDescription = (date1, date2) => {
  return `(${date1.format("D MMM YYYY")} - ${date2.format("D MMM YYYY")})`;
};

const getReadableDuration = duration => {
  if (duration === 0) {
    return "00:00:00";
  }
  let result = "";
  let hours = Math.floor(duration / 3600);
  let minutes = Math.floor((duration - hours * 3600) / 60);
  let seconds = duration - hours * 3600 - minutes * 60;

  // round seconds
  seconds = Math.round(seconds * 100) / 100;

  result = hours < 10 ? "0" + hours : hours;
  result += ":" + (minutes < 10 ? "0" + minutes : minutes);
  result += ":" + (seconds < 10 ? "0" + seconds : seconds);
  return result;
};

const getPercentage = (value, max) => {
  var percentage = 100.0; //default to 100%
  if (Number(max) > 0) {
    if (typeof Number(value) === "number") {
      percentage = (value / max) * 100;
    }
  }
  return percentage;
};

const bytesToUnit = (bytes, unit) => {
  var units = {};
  units.B = 1;
  units.KB = units.B / 1024;
  units.MB = units.KB / 1024;
  units.GB = units.MB / 1024;
  units.TB = units.GB / 1024;
  units.PB = units.TB / 1024;

  return (bytes * units[unit].toFixed(20)).toFixed(2);
};

export {
  formatNumber,
  fetchData,
  iconName,
  getSchoolConfig,
  schoolConfig,
  generateRandomNumber,
  getDateRangeDescription,
  getReadableDuration,
  getPercentage,
  bytesToUnit,
  getDeviceName,
  getIdFromTarget,
  cleanId,
  getCategoryIcon,
  getWebsiteCategory,
  resolveEnvironment,
  fetchDataRaw
};