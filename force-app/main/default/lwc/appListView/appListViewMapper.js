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

const mapResponse = (obj, sort, max) => {
    let type = "bandwidthUsage";
    let displayvalue = obj.value;
    let sub = obj.value;
    let value = 0;
    let url = `apps-profile`;
    if(sort === "btime") {
        type = "browsingTime";
        displayvalue = getReadableDuration(obj.browse_time);
        value = obj.browse_time;
    } else if(sort === "blocked") {
        type = "blockedAttempts";
        value = obj.blocked_requests;
        displayvalue = value;
    } else if(sort === "bandwidth") {
        displayvalue = bytesToUnit(obj.bandwidth, "GB");
        let inTraffic = obj.traffic_in ? obj.traffic_in : 0;
        sub = obj.bandwidth - (obj.bandwidth - inTraffic);
        value = obj.bandwidth;
    }

    return {
        num_users: obj.num_users,
        website: obj.website,
        application: obj.application,
        category: obj.category,
        value: value,
        sub:  sub,
        displayvalue: displayvalue,
        max: max,
        url: url,
        type: type,
        identifier: `${obj.application}`,
        imageType: "icon",
        imageName: "apps",
        imageClass: "application"
    };
}

export {
    mapResponse,
    getMaxValue
}