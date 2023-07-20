import {
  fetchData,
} from "c/utilitiesFunction";

export default class DeviceProfileService {
  getDeviceInformation = (schoolId, deviceId, start, end) => {
    return fetchData(`/device/${deviceId}/${start}/${end}`, schoolId).then(res => {
      let data = res.data;

      return {
        deviceMac : data.deviceMac,
        deviceName: data.deviceName,
        deviceTypes: data.deviceTypes,
        deviceCategory: data.deviceCategory,
        osName: data.osName,
        osVersion: data.osVersion
      }
    });
  };
}