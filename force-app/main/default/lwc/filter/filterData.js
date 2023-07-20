const options = [
  {
    id: "visual-picker-1",
    type: "Date Range",
    value: "visual-picker-1",
    label: "This Week",
    description: "(3-9 Sep 2018)",
    alternativeText: "thisWeekChecked",
    isChecked: false,
    start: null,
    end: null
  },
  {
    id: "visual-picker-2",
    type: "Date Range",
    value: "visual-picker-2",
    label: "Last Week",
    description: "(25 Aug - 2 Sep 2018)",
    alternativeText: "lastWeekChecked",
    isChecked: false,
    start: null,
    end: null
  },
  {
    id: "visual-picker-3",
    type: "Date Range",
    value: "visual-picker-3",
    label: "This Month",
    description: "(1 Sep - 30 Sep 2018)",
    alternativeText: "thisMonthChecked",
    isChecked: false,
    start: null,
    end: null
  },
  {
    id: "visual-picker-4",
    type: "Date Range",
    value: "visual-picker-4",
    label: "Last Month",
    description: "(1 Aug - 31 Aug 2018)",
    alternativeText: "lastMonthChecked",
    isChecked: false,
    start: null,
    end: null
  },
  {
    id: 'custom-date-range',
    type: "Date Range",
    value: 'custom-date-range',
    label: 'Custom',
    description: "Custom",
    alternativeText: "lastMonthChecked",
    isChecked: false,
    start: null,
    end: null
 }
];

const visualPickerOptions = type => {
  return options.filter(item => item.type === type);
};

const defaultFilterOption = (type, index) => {
  var availableOptions = options.filter(item => item.type === type);
  if (index > options.length) {
    return availableOptions[0];
  }
  return availableOptions[index];
};

export { visualPickerOptions, defaultFilterOption };