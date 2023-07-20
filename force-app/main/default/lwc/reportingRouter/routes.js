export default class Routes {
    routes = [
        { path: 'dashboard', page: 'dashboard', args: {} },
        { path: 'user-profile', page: 'user-profile', args: {} },
        { path: 'device-profile', page: 'device-profile', args: {} },
        { path: 'category-profile', page: 'category-profile', args: {} },
        { path: 'apps-profile', page: 'apps-profile', args: {} },
        { path: 'content-profile', page: 'content-profile', args: {} },
        { path: 'infection-profile', page: 'infection-profile', args: {} },
        { path: 'devices-list-view', page: 'devices-list-view', args: {} },
        { path: 'infections-list-view', page: 'infections-list-view', args: {} },
        { path: 'attacks-list-view', page: 'attacks-list-view', args: {} },
        { path: 'categories-list-view', page: 'categories-list-view', args: {} },
        { path: 'apps-list-view', page: 'apps-list-view', args: {} },
        { path: 'content-list-view', page: 'content-list-view', args: {} },
        { path: 'users-list-view', page: 'users-list-view', args: {} },
        { path: '', page: 'not-found', args: {} }
    ];

    get(route) {
        if(!route) {
            route = '';
        }
        return this.routes.find((val) => val.path === route);
    }

    contains(route) {
        return this.routes.findIndex((val) => val.path === route) > -1;
    }
}