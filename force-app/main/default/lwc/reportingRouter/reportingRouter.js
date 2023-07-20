import { LightningElement, track } from 'lwc';
import { getQueryParams, pushStateToUrl } from "c/communitiesNavigation";
import { registerListener, unregisterAllListeners } from 'c/pubsub';
import { fireEvent } from 'c/pubsub';
import Routes from './routes';
import { resolveEnvironment } from "c/utilitiesFunction";
import { loadScript } from 'lightning/platformResourceLoader';
import ANALYTICS from '@salesforce/resourceUrl/analytics';

export default class ReportingRouter extends LightningElement {
    @track p = "dashboard";
    pageRef = { attributes: { name: "nav" } };
    @track isLoading = false;
    routes = null;
    environment = null;

    constructor() {
        super();
        this.routes = new Routes();
    }

    get renderDashboard() {
        return this.p === "dashboard";
    }

    get renderUsersListView() {
        return this.p === "users-list-view";
    }

    get renderDevicesListView() {
        return this.p === "devices-list-view";
    }

    get renderContentListView() {
        return this.p === "content-list-view";
    }

    get renderAppsListView() {
        return this.p === "apps-list-view";
    }

    get renderCategoriesListView() {
        return this.p === "categories-list-view";
    }

    get renderInfectionsListView() {
        return this.p === "infections-list-view";
    }

    get renderAttacksListView() {
        return this.p === "attacks-list-view";
    }

    get renderUserProfile() {
        return this.p === "user-profile";
    }

    get renderDeviceProfile() {
        return this.p === "device-profile";
    }

    get renderCategoryProfile() {
        return this.p === "category-profile";
    }

    get renderWebsiteProfile() {
        return this.p === "content-profile";
    }

    get renderAppProfile() {
        return this.p === "apps-profile";
    }

    get renderInfectionProfile() {
        return this.p === "infection-profile";
    }

    get renderNotFound() {
        return this.p === "not-found";
    }

    connectedCallback() {
        this.environment = resolveEnvironment();
        this.queryParams = getQueryParams(window.location.search);
        this.p = this.queryParams.p;

        if(!this.p) {
            this.p = "dashboard";
        }

        registerListener('navigateToPage', this.handleNavigateToPage, this);
        loadScript(this, ANALYTICS)
        .then(() => {
            if(this.environment === 'production') {
                // eslint-disable-next-line no-undef
                ga('create', 'UA-146905135-6', 'auto');
            } else if(this.environment === 'demo') {
                // eslint-disable-next-line no-undef
                ga('create', 'UA-146905135-3', 'auto');
            } else if(this.environment === 'test') {
                // eslint-disable-next-line no-undef
                ga('create', 'UA-146905135-5', 'auto');
            } else if(this.environment === 'development') {
                // eslint-disable-next-line no-undef
                ga('create', 'UA-146905135-4', 'auto');
            } else {
                // eslint-disable-next-line no-undef
                ga('create', 'UA-146905135-2', 'auto');
            }

            // eslint-disable-next-line no-undef
            ga('send', {
                hitType: 'pageview',
                page: this.p,
                title: this.p
            });
        })
        .catch(error => {
            // eslint-disable-next-line no-console
            console.log('error intializing ga', error);
        });
    }

    disconnectedCallback() {
        unregisterAllListeners(this);
    }

    cleanParams() {
        delete this.queryParams.id;
        delete this.queryParams.deviceid;
        delete this.queryParams.userid;
        delete this.queryParams.categoryid;
        delete this.queryParams.appid;
        delete this.queryParams.websiteid;
        delete this.queryParams.infectionid;
        delete this.queryParams.view;
        delete this.queryParams.curtab;
    }

    assignParamsToRoute = (params) => {
        Object.keys(params).forEach((val) => {
            this.queryParams[val] = params[val];
        });
        if(!this.queryParams.curtab) {
            this.queryParams.curtab = "overview";
        }
    }

    sendPageViewEvent(p) {
        // eslint-disable-next-line no-undef
        if(ga) {
            // eslint-disable-next-line no-undef
            ga('send', {
                hitType: 'pageview',
                page: p,
                title: p
            });
            // eslint-disable-next-line no-undef
            ga('send', {
                hitType: 'event',
                eventCategory: 'Router',
                eventAction: 'navigate',
                eventLabel: p
            });
        }
    }

    handleNavigateToPage(selectedItem) {
        // eslint-disable-next-line no-console
        console.log('Navigate to', selectedItem);
        this.queryParams = getQueryParams(window.location.search);

        let args = selectedItem.args;
        let params = {};
        if(args && args.params) {
            //this is done to remove the lwc proxy from the object
            params = JSON.parse(JSON.stringify(args.params));
        }

        if(params.fromContext) {
            params.fromContext.forEach((value) => {
                params[value] = this.queryParams[value];
            }, this);
            delete params.fromContext;
        }

        this.cleanParams();

        window.scrollTo(0, 0);

        //TODO this needs to be refactored into a routes definition
        if(selectedItem.route === "user-profile" && args) {
            this.queryParams.userid = args.identifier ? args.identifier : args.data ? args.data.label : "";
            this.assignParamsToRoute(params);
        } else if(selectedItem.route === "device-profile" && args) {
            this.queryParams.deviceid = args.identifier;
            this.assignParamsToRoute(params);
        } else if(selectedItem.route  === "category-profile" && args) {
            this.queryParams.categoryid = args.identifier;
            this.assignParamsToRoute(params);
        } else if(selectedItem.route  === "apps-profile" && args) {
            this.queryParams.appid = args.identifier;
            this.assignParamsToRoute(params);
        } else if(selectedItem.route  === "content-profile" && args) {
            this.queryParams.websiteid = args.identifier;
            this.assignParamsToRoute(params);
        } else if(selectedItem.route  === "infection-profile" && args) {
            this.queryParams.infectionid = args.identifier;
            this.assignParamsToRoute(params);
        } else if(selectedItem.route  === "devices-list-view" && args && args.deviceTypeId) {
            this.queryParams.id = args.deviceTypeId;
        } else if(params) {
            Object.keys(params).forEach((val) => {
                this.queryParams[val] = params[val];
            });
        } else {
            this.cleanParams();
        }

        this.queryParams.p = selectedItem.route;
        pushStateToUrl(this.queryParams);
        this.p = selectedItem.route;
        this.sendPageViewEvent(this.p);
        fireEvent(this.pageRef, 'navigationChanged', { route: selectedItem.route, args: { params: this.queryParams } });
    }
}