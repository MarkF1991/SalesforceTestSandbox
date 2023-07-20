import TimeElement from "c/utilitiesTime";
import { track, api } from "lwc";
import { iconName } from "c/utilitiesFunction";

export default class tilePageHeader extends TimeElement {

  @api label = "Reporting";
  @api title = "...";
  @api selectedfilter;
  @track filteredBy = []; //for display on pageHeader
  @api menuItems; //receive JSON object as a list of menu items from parent component.
  @api get selectedMenuItemValue() {
    return this._selectedMenuItemValue;
  }

  set selectedMenuItemValue(val) {
      if(this._selectedMenuItemValue && this._selectedMenuItemValue !== val) {
        this._selectedMenuItemValue = val;
        this.selectMenuItem();
      }
      this._selectedMenuItemValue = val;
  }
  @track filterExpanded = false;
  @track lastRefreshed;
  @api useAvatar = false;
  @api isDashboard = false;
  @api details; //this is JSON object to list items under page header - column details.
  @api disableFilter = false;
  @api disableSelectionMenu = false;

  toggleFilterExpanded() {
    this.filterExpanded = !this.filterExpanded;
  }

  get filterDropDownClass() {
    var result = "slds-dropdown-trigger slds-dropdown-trigger_click slds-float_right";
    result += this.filterExpanded ? " slds-is-open" : "";
    return result;
  }

  async connectedCallback() {
    //make default selection on menu items
    if (this.showSwitcher) {
      this.selectMenuItem();
    }
  }

  handleFilterChanged(event) {
    var filters = event.detail.value; //value is returned as an array of JSON objects

    this.filteredBy = this.getFilteredBy(filters);
    
    //2. update URL param
    // Prevents the anchor element from navigating to a URL.
    event.preventDefault();
    
    const returnEvent = new CustomEvent("headerfilterchanged", {
      detail: { value: filters }
    });

    // Dispatches the event.
    this.dispatchEvent(returnEvent);
  }

  handleCurrentlySelectedOptions(event) {
    this.filteredBy = this.getFilteredBy(event.detail.value);
  }

  getFilteredBy(filters) {
    var results = [];
    filters.forEach((data) => {
        results.push({ label: data.type, text: ` ${data.description} ` });
    });
    return results;
  }

  handleCloseFilterSelect() {
    this.toggleFilterExpanded();
  }

  handleMenuItemSelected(event) {
    this.selectedMenuItemValue = event.detail.value;
    this.selectMenuItem();
    this.fireEventMenuChanged(event);
  }

  selectMenuItem() {
    const index = this.menuItems.findIndex(
      item => item.value === this.selectedMenuItemValue
    );
    this.title = this.menuItems[index].label;
  }

  fireEventMenuChanged(event) {
    event.preventDefault();

    // Creates the event with the goto navigation target
    const returnEvent = new CustomEvent("menuchanged", {
      detail: { value: this.selectedMenuItemValue }
    });

    // Dispatches the event.
    this.dispatchEvent(returnEvent);
  }

  getLookupKey = () => {
    let lookup = this.label;
    if(this.isDashboard) {
      lookup = this.title ? this.title : this.label;
    }
    return lookup.toLowerCase();
  }

  get showSwitcher() {
    if (!this.disableSelectionMenu && this.selectedMenuItemValue && this.menuItems) {
      return true;
    }
    return false;
  }

  get acronym() {
    var matches = this.title.match(/\b(\w)/g);
    return matches.join('');
  }

  get materialIconName() {
    return iconName(this.getLookupKey());
  }

  get materialIconClass() {
    return "slds-avatar slds-avatar_medium slds-align_absolute-center " + this.getLookupKey();
  }

  //-------show column details at the bottom of page header --------------------------------------
  get showDetails(){
    return this.details ? true : false ;
  }
  //-------end of show column details at the bottom of page header --------------------------------------
}