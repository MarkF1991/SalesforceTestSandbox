/* eslint-disable no-console */
import { track, api } from "lwc"; //import { LightningElement, track, api } from 'lwc';
import { FilterItemClass } from "c/utilitiesClass";
import TimeElement from "c/utilitiesTime";
import {
  generateRandomNumber,
  getDateRangeDescription,
  resolveEnvironment
} from "c/utilitiesFunction";
import { visualPickerOptions } from "./filterData";
import { fireEvent } from 'c/pubsub';

export default class Filter extends TimeElement {

  @track filters = [];
  @api selectedFilter;
  @track options = [];
  @api showFilters = false;
  @track showOptions = false;
  @track selectedOption;

  pageRef = { attributes: { name: "nav" } };

  async connectedCallback() {
    if(!this.environment) {
      this.environment = resolveEnvironment();
    }

    this.options = visualPickerOptions("Date Range");
    
    this.initMoment()
      .then(() => {
        this.prepareOptions(); //prepare the values in this.options
      })
      .catch((err) => {
        console.log('error initializing filter', err);
      });
  }

  prepareOptions() {
    //loop through the Date Range options to update description and UTC dates for query dates: start and end
    if (this.options) {
      for (let item of this.options) {
        if (item.label === "This Week") {
          item.start = this.now
            .startOf("isoWeek")
            .toISOString(); //Start of this week in UTC
          item.end = this.now
            .endOf("isoWeek")
            .toISOString(); //End of this week in UTC
          item.description = getDateRangeDescription(
            this.now.startOf("week"),
            this.now.endOf("week")
          );
        } else if (item.label === "Last Week") {
          item.start = this.now
            .subtract(1, "weeks")
            .startOf("isoWeek")
            .toISOString(); //Start of last week in UTC
          item.end = this.now
            .subtract(1, "weeks")
            .endOf("isoWeek")
            .toISOString(); //End of last week in UTC
          item.description = getDateRangeDescription(
            this.now
              .subtract(1, "weeks")
              .startOf("week"),
              this.now
              .subtract(1, "weeks")
              .endOf("week")
          );
        } else if (item.label === "This Month") {
          item.start = this.now
            .startOf("month")
            .toISOString(); //Start of this week in UTC
          item.end = this.now
            .endOf("month")
            .toISOString(); //End of this week in UTC
          item.description = getDateRangeDescription(
            this.now.startOf("month"),
            this.now.endOf("month")
          );
        } else if (item.label === "Last Month") {
          item.start = this.now
            .subtract(1, "months")
            .startOf("month")
            .toISOString(); //Start of last week in UTC
          item.end = this.now
            .subtract(1, "months")
            .endOf("month")
            .toISOString(); //End of last week in UTC
          item.description = getDateRangeDescription(
            this.now
              .subtract(1, "months")
              .startOf("month"),
            this.now
              .subtract(1, "months")
              .endOf("month")
          );
        } else if(this.selectedFilter && this.selectedFilter.dateFilter) {
            item.start = this.selectedFilter.dateFilter.start;
            item.end = this.selectedFilter.dateFilter.end;
            // eslint-disable-next-line no-undef
            item.description = getDateRangeDescription(moment(item.start), moment(item.end));
        }
      }

      let newfilter = null;
      if (this.selectedFilter) {
        const index = this.getCurrentlySelectedOptionIndex(
          this.selectedFilter,
          this.options
        );
        let opt = this.options[index >= 0 ? index : 0];
        newfilter = this.generateNewFilter(opt);

        this.dispatchEvent(
          new CustomEvent("currentlyselectedoptions", {
            detail: { value: [newfilter] }
          })
        );
      } else {
        newfilter = this.generateNewFilter(this.options[0]); //use the first member of array as default filter
        this.dispatchEvent(
          new CustomEvent("currentlyselectedoptions", {
            detail: { value: [newfilter] }
          })
        );
      }
      this.filters.push(newfilter); //populate array: filters
    }
  }

  handleCloseClick(event) {
    // Prevents the anchor element from navigating to a URL.
    event.preventDefault();

    // Creates the event with the goto navigation target
    const returnEvent = new CustomEvent("closefilterselect", {
      value: true
    });

    // Dispatches the event.
    this.dispatchEvent(returnEvent);
  }

  handleFilterItemClicked() {
    this.toggleShowOptions(); //to hide filter and then show option
  }

  get optionsWithSelection() {
    if (this.selectedFilter && this.options) {
      const index = this.getCurrentlySelectedOptionIndex(
        this.selectedFilter,
        this.options
      );
      this.options.forEach(item => {
        item.isChecked = false;
      });
      if (index >= 0) {
        let opt = this.options[index];
        opt.isChecked = true;
        if(this.selectedFilter && this.selectedFilter.dateFilter) {
          opt.start = this.selectedFilter.dateFilter.start;
          opt.end = this.selectedFilter.dateFilter.end;
          // eslint-disable-next-line no-undef
          opt.description = getDateRangeDescription(moment(opt.start), moment(opt.end));
        }
      }
    }
    return this.options;
  }

  getCurrentlySelectedOptionIndex(selectedFilter, options) {
    let idx =  options.findIndex( item => item.start === selectedFilter.dateFilter.start && item.end === selectedFilter.dateFilter.end );
    if(idx < 0) {
      return options.findIndex((i) => i.id === 'custom-date-range');
    }
    return idx;
  }

  toggleShowOptions() {
    this.showFilters = this.showOptions; //get the initial showOptions
    this.showOptions = !this.showOptions; //then, inverse the showoption
  }

  sendAnalyticsEvent(action, label) {
    try {
      // eslint-disable-next-line no-undef
      if(ga) {
        // eslint-disable-next-line no-undef
        ga('send', {
            hitType: 'event',
            eventCategory: 'Calendar',
            eventAction: action,
            eventLabel: label
        });
      }
    } catch(err) {
      // Ignore
    }
  }

  selectionSaved(event) {
    let selected = event.detail.value;
    if(selected.id === 'custom-date-range') {
      // eslint-disable-next-line no-undef
      const start = moment(selected.start);
      // eslint-disable-next-line no-undef
      const end = moment(selected.end);
      selected.description = getDateRangeDescription(start, end);
      try {
        let difference = end.diff(start, 'days', true);
        // eslint-disable-next-line no-undef
        let offset = moment().diff(start, 'days', true);
        this.sendAnalyticsEvent('filter', `Custom (${Math.round(offset)},${Math.round(difference)})`);
      // eslint-disable-next-line no-empty
      } catch(err) {}
      
    } else {
      this.sendAnalyticsEvent('filter', selected.label);
    }
    
    this.selectedOption = selected;
    this.toggleShowOptions();
    this.refreshFilterList(); //filter array and clear the date range filter, then add new selected filter based on the selected option from value picker
    
    this.fireEventFilterChanged(event);
  }

  refreshFilterList() {
    if (this.filters) {
      // Defensive programming!
      //step 1: find the index of the filter in array, ie: type = 'Date Range'
      const index = this.filters.findIndex(
        item => item.type === this.selectedOption.type
      );

      //step 2: then, replace it with new selected filter based on the selected option from value picker
      const newfilter = this.generateNewFilter(this.selectedOption);

      this.filters[index] = newfilter;
    }
  }

  generateNewFilter(option) {
    var newfilter = FilterItemClass();
    newfilter.id = "filter" + generateRandomNumber();
    newfilter.type = option.type;
    newfilter.label = option.type;
    newfilter.description = option.label + " " + option.description;
    newfilter.option = option;

    return newfilter;
  }

  fireEventFilterChanged(event) {
    // Prevents the anchor element from navigating to a URL.
    event.preventDefault();

    // Creates the event with the goto navigation target
    const returnEvent = new CustomEvent("filterchanged", {
      detail: { value: this.filters }
    });

    // Dispatches the event.
    this.dispatchEvent(returnEvent);
    // application level event
    fireEvent(this.pageRef, 'filterChanged', { filters: [].concat(this.filters) });
  }

  selectionCancelled(event) {
    this.selectedOption = event.detail.value; //returning null
    this.toggleShowOptions();
  }
}