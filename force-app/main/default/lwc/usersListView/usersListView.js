/* eslint-disable no-console */
import { track, api } from "lwc";
import { getQueryParams, pushStateToUrl } from "c/communitiesNavigation";
import { fetchData, getSchoolConfig } from "c/utilitiesFunction";
import { mapResponse, getMaxValue } from "./usersListViewMapper";
import { items } from "./usersListViewMenuDefinition";
import GenericListViewComponent from 'c/genericListViewComponent';
import { registerListener, unregisterAllListeners } from "c/pubsub";
import { cleanId } from "c/utilitiesFunction";

export default class UsersListView extends GenericListViewComponent {

    pageHeaderLabel = "Users";
    @track view = "all";
    menuItems = items;
    categoryId = null;
    deviceId = null;
    appId = null;
    websiteId = null;
    @track hasNoData = false;

    @api get checkNoData() {
        return this._checkNoData;
    }

    set checkNoData(val) {
        this._checkNoData = val;
    }

    @api disableHeader = false;
    @api disableHeaderFilter = false;
    @api hideAverages = false;
    @api overrideCssClass = "list-container";

    pageRef = { attributes: { name: "nav" } };

    constructor() {
        super();
        this.onScoll = this.onScoll.bind(this);
    }

    async connectedCallback() {

        this.setupState();

        window.addEventListener('scroll', this.onScoll);

        if(this.disableHeader) {
            this.disableHeaderFilter = true;
        }

        if(this.disableHeaderFilter) {
            registerListener("filterChanged", this.handleFilterChanged, this);
            registerListener('navigationChanged', this.handleNavigationChanged, this);
        }
    }

    setupState() {
        this.queryParams = getQueryParams(window.location.search);
        if(this.overrideView) {
            this.view = this.overrideView;
            this.disableSelectionMenu = true;
        }

        if (this.queryParams.schoolId) {
            this.schoolId = this.queryParams.schoolId;
            if(this.checkNoData) {
                getSchoolConfig(this.schoolId).then(config => {
                    if(config) {
                        this.hasNoData = !config.hasUserData;
                    }
                });
            }
            this.start = this.queryParams.start;
            this.end = this.queryParams.end;
            this.page = this.queryParams.page ? parseInt(this.queryParams.page, 10) : parseInt(this.page, 10);
            this.perPage = this.queryParams.perPage ? this.queryParams.perPage : parseInt(this.perPage, 10);
            this.selectedfilter.dateFilter.start = this.start;
            this.selectedfilter.dateFilter.end = this.end;
            this.refresh();
        }
    }

    refresh() {
        if(this.queryParams.view) {
            this.view = this.overrideView ? this.view : this.queryParams.view;
        }
        this.categoryId = cleanId(this.queryParams.categoryid);
        this.deviceId = cleanId(this.queryParams.deviceid);
        this.appId = cleanId(this.queryParams.appid);
        this.websiteId = cleanId(this.queryParams.websiteid);
        this.data = [];
        this.load();
    }

    disconnectedCallback() {
        unregisterAllListeners(this);
        window.removeEventListener('scroll', this.onScoll);
    }

    onScoll() {
        if(!this.disableInfiteScroll) {
            if(this.resultsTotal > this.page * this.perPage && !this.tableLoadingState && (window.scrollY > this.template.querySelector("c-reporting-data-table[id^='users-table']").height - ( window.screen.height))) {
                this.page += 1;
                this.load();
                this.sendAnalyticsEvent('UsersListView', 'scroll', `Page ${this.page}`);
            }
        }
    }

    handleNavigationChanged(event) {
        if(event.args && event.args.params
            && event.args.params.curtab === 'users'
            && event.args.params.view !== this.view) {
            this.queryParams = getQueryParams(window.location.search);
            this.maxValue = 0;
            this.refresh();
        }
    }

    handleFilterChanged(event) {
        if(this.disableHeaderFilter) {
            this.doFilter(event.filters);

            this.load();
        }
    }

    handleMenuChanged(event) {
        this.view = event.detail.value; //value of selected menu item in child component pageHeader

        //update URL param
        this.queryParams.view = this.view;
        this.resetState();
        this.queryParams.page = this.page;
        this.queryParams.perPage = this.perPage;

        pushStateToUrl(this.queryParams);
        this.load();
    }

    // eslint-disable-next-line no-unused-vars
    handleSorting(event) {
        console.log('sort table');
    }

    load() {
        this.tableLoadingState = true;
        let sort = "all";
        let context = "list";

        let item = this.getMenuItemForView(this.view);
        if(item) {
            sort = item.sort;
            context = item.context;
            this.columns = item.columns;
            this.overridePageHeaderTitle = this.overrideView ? item.label : null;
        }

        let url = `/user/${context}/${this.start}/${this.end}?sort=${sort}&page=${this.page}&perPage=${this.perPage}`;
        if(this.categoryId) {
            url += `&category=${this.categoryId}`;
        }

        if(this.deviceId) {
            url += `&device=${this.deviceId}`;
        }

        if(this.appId) {
            url += `&application=${this.appId}`;
        }

        if(this.websiteId) {
            url += `&website=${this.websiteId}`;
        }

        // eslint-disable-next-line no-unused-vars
        fetchData(url, this.schoolId).then(res => {
            let max = this.maxValue;
            let responseData = res.data;
            if(this.maxValue === 0 && sort !== "all") {
                this.maxValue = getMaxValue(responseData, sort);
                this.resultsTotal = res.metadata.total;
                max = this.maxValue;
            } else if (sort === "all") {
                const browse_time = Math.max(...responseData.map(o => o.browse_time), 0);
                const blocked_requests = Math.max(...responseData.map(o => o.blocked_requests), 0);
                const bandwidth = Math.max(...responseData.map(o => o.bandwidth), 0);
                max = { browse_time: browse_time, blocked_requests: blocked_requests, bandwidth: bandwidth }
                this.resultsTotal = res.metadata.total;
            }

            if(!this.hideAverages && (!this.data || this.data.length <= 0)) {
                this.addAverageCalculations(res.averages, this.data, sort, max);
            }

            this.data = this.data.concat(responseData.map(obj => mapResponse(obj, sort, max)));
            this.tableLoadingState = false;
        });
    }

    addAverageCalculations(averageCalcs, data, sort, max) {
        if(averageCalcs) {
            data.push(mapResponse({ 
                user: 'School Average',
                bandwidth: averageCalcs.bandwidth,
                blocked_requests: averageCalcs.blocked_requests,
                browse_time: Math.round(averageCalcs.browse_time),
                traffic_in: averageCalcs.traffic_in,
                devices: ''
            }, sort, max, true, 'location_city', 'users'));
        }
    }

    applyFilter(event) {
        if(!this.disableHeaderFilter) {
            this.doFilter(event.detail.value);
            this.load();
        }
    }
}