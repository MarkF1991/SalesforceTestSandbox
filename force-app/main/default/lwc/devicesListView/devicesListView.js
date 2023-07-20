/* eslint-disable no-console */
import { track, api } from "lwc";
import { getQueryParams, pushStateToUrl } from "c/communitiesNavigation";
import { fetchData, getSchoolConfig } from "c/utilitiesFunction";
import { mapResponse, getMaxValue } from "./devicesListViewMapper";
import { items } from "./devicesListViewMenuDefinition";
import GenericListViewComponent from 'c/genericListViewComponent';
import { registerListener, unregisterAllListeners } from "c/pubsub";
import { cleanId } from "c/utilitiesFunction";

export default class DevicesListView extends GenericListViewComponent {
    pageHeaderLabel = "Devices";
    @track view = "all-devices";
    menuItems = items;
    userid = null;
    deviceTypeId = null;
    categoryId = null;
    websiteId = null;
    appId = null;
    infectionId = null;

    @track hasNoData = false;

    @api get checkNoData() {
        return this._checkNoData;
    }

    set checkNoData(val) {
        this._checkNoData = val;
    }
    @api disableHeader = false;
    @api disableHeaderFilter = false;
    @api overrideCssClass = "list-container";
    @api hideAverages = false;
    pageRef = { attributes: { name: "nav" } };

    constructor() {
        super();
        this.onScoll = this.onScoll.bind(this);
    }

    async connectedCallback() {
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
                        this.hasNoData = !config.hasDeviceData;
                    }
                });
            }
            this.start = this.queryParams.start;
            this.end = this.queryParams.end;
            this.page = this.queryParams.page ? parseInt(this.queryParams.page, 10) : parseInt(this.page, 10);
            this.perPage = this.queryParams.perPage ? this.queryParams.perPage : parseInt(this.perPage, 10);
            this.selectedfilter.dateFilter.start = this.start;
            this.selectedfilter.dateFilter.end = this.end;
            if(this.queryParams.view) {
                this.view = this.overrideView ? this.view : this.queryParams.view;
            }
            this.userid = cleanId(this.queryParams.userid);
            this.deviceTypeId = cleanId(this.queryParams.id);
            this.appId = cleanId(this.queryParams.appid);
            this.infectionId = cleanId(this.queryParams.infectionid);
            this.websiteId = cleanId(this.queryParams.websiteid);
            this.categoryId = cleanId(this.queryParams.categoryid);

            this.overlayMenuItems();

            this.load();
        }

        window.addEventListener('scroll', this.onScoll);

        if(this.disableHeader) {
            this.disableHeaderFilter = true;
        }

        if(this.disableHeaderFilter) {
            registerListener("filterChanged", this.handleFilterChanged, this);
        }
    }

    disconnectedCallback() {
        unregisterAllListeners(this);
        window.removeEventListener('scroll', this.onScoll);
    }

    onScoll() {
        if(!this.disableInfiteScroll) {
            if(this.resultsTotal > this.page * this.perPage && !this.tableLoadingState && (window.scrollY > this.template.querySelector("c-reporting-data-table[id^='devices-table']").height - ( window.screen.height))) {
                this.page += 1;
                this.load();
                this.sendAnalyticsEvent('DevicesListView', 'scroll', `Page ${this.page}`);
            }
        }
    }

    //TODO refactor this out
    overlayMenuItems() {
        if(this.infectionId) {
            this.menuItems.push({
                  id: "item-05",
                  label: "Devices",
                  value: "device-infections",
                  sort: "infected",
                  context: "list",
                  columns: [
                    // Your column data here
                    {
                      label: "Device Name",
                      type: "inlineChip",
                      fieldName: "id",
                      typeAttributes: {
                        imagetype: { fieldName: "imageType" },
                        imagename: { fieldName: "imageName" },
                        imageclass: { fieldName: "imageClass" },
                        href: { fieldName: "url" },
                        label: { fieldName: "devicename" },
                        description: { fieldName: "devicetype" },
                        identifier: { fieldName: "identifier" }
                      }
                    },
                    {
                      label: "# Users",
                      type: "inlineText",
                        typeAttributes: {
                        text: { fieldName: "num_users" },
                        align: "left"
                        }
                    },
                    {
                        label: "",
                        type: "inlineBar",
                        fieldName: "infectionCount",
                        initialWidth: 1,
                        typeAttributes: {
                          total: { fieldName: "value" },
                          sub: { fieldName: "sub" },
                          max: { fieldName: "max" },
                          category: { fieldName: "type" }
                        }
                    }
                  ]
                });
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

    handleFilterChanged(event) {
        if(this.disableHeader) {
            this.doFilter(event.filters);

            this.load();
        }
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

        let url = `/device/${context}/${this.start}/${this.end}?sort=${sort}&page=${this.page}&perPage=${this.perPage}`;
        if(this.userid) {
            url = url += `&user=${this.userid}`;
        }

        if(this.deviceTypeId) {
            url = url += `&device_type=${this.deviceTypeId}`;
        }

        if(this.categoryId) {
            url = url += `&category=${this.categoryId}`;
        }

        if(this.appId) {
            url += `&application=${this.appId}`;
        }

        if(this.websiteId) {
            url += `&website=${this.websiteId}`;
        }

        if(this.infectionId) {
            // this is a different end point
            url = `/security/infectedDevice/list/${this.start}/${this.end}?page=${this.page}&perPage=${this.perPage}&infection=${this.infectionId}`;
        }

        // eslint-disable-next-line no-unused-vars
        fetchData(url, this.schoolId).then(res => {
            let max = this.maxValue;
            if(this.maxValue === 0 && sort !== "all") {
                this.maxValue = getMaxValue(res.data, sort);
                this.resultsTotal = res.metadata.total;
                max = this.maxValue;
            } else if (sort === "all") {
                const browse_time = Math.max(...res.data.map(o => o.browse_time), 0);
                const blocked_requests = Math.max(...res.data.map(o => o.blocked_requests), 0);
                const bandwidth = Math.max(...res.data.map(o => o.bandwidth), 0);
                max = { browse_time: browse_time, blocked_requests: blocked_requests, bandwidth: bandwidth }
                this.resultsTotal = res.metadata.total;
            }

            if(!this.hideAverages && (!this.data || this.data.length <= 0)) {
                this.addAverageCalculations(res.averages, this.data, sort, max);
            }

            let toMap = res.data;
            // Work around a stupid API bug that needs to be patched
            if(res.data.length === 1) {
                toMap = toMap.filter((val) => val.deviceMac || val.deviceName);
            }

            this.data = this.data.concat(toMap.map(obj => mapResponse(obj, sort, max)));
            this.tableLoadingState = false;
        });
    }

    addAverageCalculations(averageCalcs, data, sort, max) {
        if(averageCalcs) {
            data.push(mapResponse({ 
                deviceName: 'School Average',
                bandwidth: averageCalcs.bandwidth,
                blocked_requests: Math.round(averageCalcs.blocked_requests),
                browse_time: Math.round(averageCalcs.browse_time),
                traffic_in: averageCalcs.traffic_in,
                users: '',
                deviceCategory: '',
                deviceTypes: []
            }, sort, max, true, 'location_city', 'devices'));
        }
    }

    applyFilter(event) {
        if(!this.disableHeaderFilter) {
            this.doFilter(event.detail.value);
            this.load();
        }
    }
}