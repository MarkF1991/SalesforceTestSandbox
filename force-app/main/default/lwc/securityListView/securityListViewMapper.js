import { iconName } from "c/utilitiesFunction";

const getMaxValue = (ls, sort) => {
    switch(sort) {
        case "attackBlocked":
            return ls.length > 0 ? ls[0].events : 1;
        case "infection":
            return ls.length > 0 ? ls[0].deviceCount : 1;
        default:
            return ls.length > 0 ? ls[0].value : 1;
    }
}

const mapResponse = (obj, sort, max) => {
    let type = "bandwidthUsage";
    let sub = obj.value;
    let title = "";
    let value = 0;
    let url = null;
    let displayValue = 0;
    let infections = [];
    let imageName = "bug_report";
    let imageClass = "security";
    let category = "";
    let identifier = null;
    if(sort === "infectedDevice") {
        title = obj.deviceName ? obj.deviceName : obj.deviceMac;
        imageName = iconName(obj.deviceCategory);
        category = obj.deviceCategory;
        if(obj.threats) {
            displayValue = obj.threats.length;
            infections = obj.threats.map((threat, index) => { return { id: index, label: threat.value, description: threat.type, imagetype: "icon", imageclass: "security", imagename: "bug_report"  } })
        }
    } else if(sort === "infection") {
        type = "blockedAttempts";
        title = obj.threatName;
        sub = obj.deviceCount;
        value = obj.deviceCount;
        identifier = obj.threatName;
        url = 'infection-profile';
        imageName = iconName("attack");
        category = obj.threatType;
        displayValue = `${obj.deviceCount}`;
    } else if(sort === "attackBlocked") {
        type = "bandwidthUsage";
        value = obj.events;
        displayValue = obj.events;
        title = obj.value;
        imageClass = "success";
        category = obj.type;
    }

    return {
        users: obj.users,
        title: title,
        category: category,
        value: value,
        sub:  sub,
        url: url,
        identifier: identifier,
        infections: infections,
        displayValue: displayValue,
        max: max,
        type: type,
        id: `${Math.random()}`,
        imageType: "icon",
        imageName: imageName,
        imageClass: imageClass
    };
}

export {
    mapResponse,
    getMaxValue
}