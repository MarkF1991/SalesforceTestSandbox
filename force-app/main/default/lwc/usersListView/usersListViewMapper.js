import { bytesToUnit, getReadableDuration } from "c/utilitiesFunction";

const getMaxValue = (ls, sort) => {
    switch(sort) {
        case "btime":
            return ls.length > 0 ? ls[0].browse_time : 1;
        case "blocked":
            return ls.length > 0 ? ls[0].blocked_requests : 1;
        case "bandwidth":
            return ls.length > 0 ? ls[0].bandwidth : 1;
        default:
            return ls.length > 0 ? ls[0].value : 1;
    }
}

const getUserInitial = (user) => {
    return user ? user.charAt(0).toUpperCase() : "";
}

const mapResponse = (obj, sort, max, removeLink, icon, iconClass) => {
    let type = "bandwidthUsage";
    let displayvalue = obj.value;
    let sub = obj.value;
    let value = 0;
    let url = !removeLink ? `user-profile` : null;

    if(sort === "btime") {
        type = "browsingTime";
        value = obj.browse_time;
        displayvalue = getReadableDuration(obj.browse_time);
    } else if(sort === "blocked") {
        type = "blockedAttempts";
        value = Math.round(obj.blocked_requests);
        displayvalue = value;
    } else if(sort === "bandwidth") {
        displayvalue = bytesToUnit(obj.bandwidth, "GB");
        let inTraffic = obj.traffic_in ? obj.traffic_in : 0;
        sub = obj.bandwidth - (obj.bandwidth - inTraffic);
        value = obj.bandwidth;
    } else if( sort === "all") {
        let inTraffic = obj.traffic_in ? obj.traffic_in : 0;
        let busub = obj.bandwidth - (obj.bandwidth - inTraffic);
        return {
            devices: obj.devices,
            user: obj.user,
            buvalue: obj.bandwidth,
            btvalue: obj.browse_time,
            bavalue: Math.round(obj.blocked_requests),
            sub: sub,
            url: url,
            busub: busub,
            btdisplayvalue: getReadableDuration(obj.browse_time),
            budisplayvalue: bytesToUnit(obj.bandwidth, "GB"),
            badisplayvalue: Math.round(obj.blocked_requests),
            btmax: max.browse_time,
            bumax: max.bandwidth,
            bamax: Math.round(max.blocked_requests),
            butype: type,
            batype: "blockedAttempts",
            bttype: "browsingTime",
            id: `${Math.random()}`,
            imageType: !icon ? "avatar" : 'icon',
            imageName: !icon ? getUserInitial(obj.user) : icon,
            imageClass: !iconClass ? "content" : iconClass
        };
    }

    return {
        devices: obj.devices,
        user: obj.user,
        value: value,
        sub:  sub,
        displayvalue: displayvalue,
        max: max,
        type: type,
        url: url,
        id: `${Math.random()}`,
        imageType: !icon ? "avatar" : 'icon',
        imageName: !icon ? getUserInitial(obj.user) : icon,
        imageClass: !iconClass ? "content" : iconClass
    };
}

export {
    mapResponse,
    getMaxValue
}