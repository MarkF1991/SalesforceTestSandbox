import { fetchData, getCategoryIcon, iconName } from "c/utilitiesFunction";
import { TileChipClass } from "c/utilitiesClass";

export default class GlobalSearchService {
    search = (schoolId, start, end, q) => {
        return fetchData(`/search/${start}/${end}?q=${q}`, schoolId).then(res => {
            let data = res.data;
            let mapped = {
                users: [],
                applications: [],
                devices: [],
                websites: [],
                categories: []
            };
            mapped.users = data.users.map((user) => {
                let key = user.key;
                let item = TileChipClass();
                item.id =key;
                item.label = key;
                item.href = "user-profile";
                item.image.type = "avatar";
                item.image.name = key.substring(0, 1).toUpperCase();
                return item;
             });
             mapped.devices = data.devices.map((device) => {
                let key = device.key;
                let item = TileChipClass();
                item.id = key;
                item.label = device.value;
                item.href = "device-profile";
                item.image.type = "icon";
                item.image.name = iconName(device.category ? device.category : "devices");
                item.image.class = "device";
                return item;
             });
             mapped.applications = data.applications.map((app) => {
                let key = app.key;
                let item = TileChipClass();
                item.id = key;
                item.label = key;
                item.href = "apps-profile";
                item.image.type = "icon";
                item.image.name = getCategoryIcon(app.category);
                item.image.class = "application";
                return item;
             });
             mapped.categories = data.categories.map((cat) => {
                let key = cat.key;
                let item = TileChipClass();
                item.id = key;
                item.label = key;
                item.href = "category-profile";
                item.image.type = "icon";
                item.image.name = getCategoryIcon(key);
                item.image.class = "category";
                return item;
             });
             mapped.websites = data.websites.map((web) => {
                let key = web.key;
                let item = TileChipClass();
                item.id = key;
                item.label = key;
                item.href = "content-profile";
                item.image.type = "icon";
                item.image.name = getCategoryIcon(web.category);
                item.image.class = "content";
                return item;
             }); 
             return mapped;
        });
    };
}