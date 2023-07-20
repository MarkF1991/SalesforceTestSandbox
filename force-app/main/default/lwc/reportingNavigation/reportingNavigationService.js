export default class ReportingNavigationService {
    defaultRoute = null;

    constructor(defaultRoute) {
        this.defaultRoute = defaultRoute;
    }

    getSelectedItem(p) {
        let selectedItem = this.defaultRoute;
        if(p && selectedItem !== p) {
            if(p.startsWith("user")) {
                selectedItem = "users-list-view";
            } else if(p.startsWith("device")) {
                selectedItem = "devices-list-view";
            } else if(p.startsWith("category")) {
                selectedItem = "categories-list-view";
            } else if(p.startsWith("content")) {
                selectedItem = "content-list-view";
            } else if(p.startsWith("apps")) {
                selectedItem = "apps-list-view";
            } else if(p.startsWith("infection")) {
                selectedItem = "infections-list-view";
            } else {
                selectedItem = p;
            }
        }

        return selectedItem;
    }
}