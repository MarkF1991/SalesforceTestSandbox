import { bytesToUnit, getReadableDuration } from "c/utilitiesFunction";
import { iconName } from "c/utilitiesFunction";

const getMaxValue = (ls, sort) => {
    switch(sort) {
        case "btime":
            return ls.length > 0 ? ls[0].browse_time : 1;
        case "blocked":
            return ls.length > 0 ? ls[0].blocked_requests : 1;
        case "bandwidth":
            return ls.length > 0 ? ls[0].bandwidth : 1;
        case "infected":
            return ls.length > 0 ? ls[0].threats.length : 1;
        default:
            return ls.length > 0 ? ls[0].value : 1;
    }
}

const mapResponse = (obj, sort, max, removeLink, icon, iconClass) => {
    let type = "bandwidthUsage";
    let displayvalue = obj.value;
    let sub = obj.value;
    let value = 0;
    let url = !removeLink ? `device-profile` : null;

    if(sort === "btime") {
        type = "browsingTime";
        value = obj.browse_time;
        displayvalue = getReadableDuration(obj.browse_time);
    } else if(sort === "blocked") {
        type = "blockedAttempts";
        value = obj.blocked_requests;
        displayvalue = value;
    } else if(sort === "bandwidth") {
        displayvalue = bytesToUnit(obj.bandwidth, "GB");
        let inTraffic = obj.traffic_in ? obj.traffic_in : 0;
        sub = obj.bandwidth - (obj.bandwidth - inTraffic);
        value = obj.bandwidth;
    } else if(sort === "all") {
        let inTraffic = obj.traffic_in ? obj.traffic_in : 0;
        let busub = obj.bandwidth - (obj.bandwidth - inTraffic);
        return {
            num_users: typeof obj.users === 'object' ? obj.users.value : obj.users,
            devicename: obj.deviceName ? obj.deviceName : obj.deviceMac,
            devicetype: obj.deviceTypes.length > 0 ? obj.deviceTypes[0].value : removeLink ? null : "Unknown",
            buvalue: obj.bandwidth,
            btvalue: obj.browse_time,
            bavalue: obj.blocked_requests,
            sub: sub,
            busub: busub,
            btdisplayvalue: getReadableDuration(obj.browse_time),
            budisplayvalue: bytesToUnit(obj.bandwidth, "GB"),
            badisplayvalue: obj.blocked_requests,
            btmax: max.browse_time,
            bumax: max.bandwidth,
            bamax: max.blocked_requests,
            butype: type,
            batype: "blockedAttempts",
            bttype: "browsingTime",
            url: url,
            identifier: `${obj.deviceMac}`,
            imageType: "icon",
            imageName: !icon ? iconName(obj.deviceCategory) : icon,
            imageClass: !iconClass ? "devices" : iconClass
        };
    }  else if(sort === "infected") {
        
        return {
            type: "blockedAttempts",
            num_users: typeof obj.users === 'object' ? obj.users.value : obj.users,
            devicename: obj.deviceName ? obj.deviceName : obj.deviceMac,
            devicetype: obj.deviceTypes.length > 0 ? obj.deviceTypes[0].value : removeLink ? null : "Unknown",
            url: url,
            identifier: `${obj.deviceMac}`,
            imageType: "icon",
            imageName: !icon ? iconName(obj.deviceCategory) : icon,
            imageClass: !iconClass ? "devices" : iconClass
        };
    }
    return {
        num_users: typeof obj.users === 'object' ? obj.users.value : obj.users,
        devicename: obj.deviceName ? obj.deviceName : obj.deviceMac,
        devicetype: obj.deviceTypes.length > 0 ? obj.deviceTypes[0].value : removeLink ? null : "Unknown",
        value: value,
        sub:  sub,
        displayvalue: displayvalue,
        max: max,
        type: type,
        url: url,
        identifier: `${obj.deviceMac}`,
        imageType: "icon",
        imageName: !icon ? iconName(obj.deviceCategory) : icon,
        imageClass: !iconClass ? "devices" : iconClass
    };
}

export {
    mapResponse,
    getMaxValue
}