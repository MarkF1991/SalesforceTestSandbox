import { bytesToUnit, getReadableDuration, iconName } from "c/utilitiesFunction";

const getMaxValue = (ls, sort) => {
    switch(sort) {
        case "btime":
            return ls.length > 0 ? ls[0].browse_time : 1;
        case "blocked":
            return ls.length > 0 ? ls[0].blocked_requests : 1;
        case "safety":
            return Math.max.apply(Math, ls.map((o) => { return o.blocked_requests; }))
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
    let rank = 2;
    let imageClass = "category";
    let imageName = "folder";

    if(sort === "btime") {
        type = "browsingTime";
        displayvalue = getReadableDuration(obj.browse_time);
        value = obj.browse_time;
        imageName = iconName(obj.category);
    } else if(sort === "blocked") {
        type = "blockedAttempts";
        value = obj.blocked_requests;
        displayvalue = value;
        imageName = iconName(obj.category);
    } else if(sort === "bandwidth") {
        displayvalue = bytesToUnit(obj.bandwidth, "GB");
        let inTraffic = obj.traffic_in ? obj.traffic_in : 0;
        sub = obj.bandwidth - (obj.bandwidth - inTraffic);
        value = obj.bandwidth;
        imageName = iconName(obj.category);
    } else if(sort === "safety") {
        rank = parseInt(obj.rank, 10);
        type = "blockedAttempts";
        value = obj.blocked_requests;
        displayvalue = value;
        imageClass = rank === 1 ? "security" : "category";
        imageName = iconName(obj.category);
    }

    let url = `category-profile`;

    return {
        num_users: obj.num_users,
        website: obj.website,
        application: obj.application,
        category: obj.category,
        value: value,
        sub:  sub,
        displayvalue: displayvalue,
        max: max,
        type: type,
        url: url,
        rank: rank,
        identifier: obj.category,
        imageType: "icon",
        imageName: imageName,
        imageClass: imageClass
    };
}

export {
    mapResponse,
    getMaxValue
}