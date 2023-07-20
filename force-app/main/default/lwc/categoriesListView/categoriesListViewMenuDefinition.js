const items = [
  {
    id: "item-02",
    label: "Categories by Browsing Time",
    value: "categories-browsing-time",
    sort: "btime",
    context: "category",
    columns: [
      // Your column data here
      {
        label: "Category",
        type: "inlineChip",
        fieldName: "id",
        typeAttributes: {
          imagetype: { fieldName: "imageType" },
          imagename: { fieldName: "imageName" },
          imageclass: { fieldName: "imageClass" },
          href: { fieldName: "url" },
          label: { fieldName: "category" },
          identifier: { fieldName: "identifier" }
        }
      },
      {
        label: "# Users",
        type: "inlineText",
        typeAttributes: {
          text: { fieldName: "num_users" },
          align: "left"
        },
        initialWidth: 250,
        cellAttributes: { alignment: "left" }
      },
      {
        label: "Browsing Time",
        type: "inlineBar",
        fieldName: "id",
        typeAttributes: {
          total: { fieldName: "value" },
          sub: { fieldName: "sub" },
          max: { fieldName: "max" },
          category: { fieldName: "type" }
        }
      },
      {
        label: "(HH:MM:SS)",
        type: "inlineText",
        typeAttributes: {
          text: { fieldName: "displayvalue" },
          align: "left"
        },
        initialWidth: 150
      }
    ]
  },
  {
    id: "item-03",
    label: "Categories by Bandwidth Usage",
    value: "categories-bandwidth-usage",
    sort: "bandwidth",
    context: "category",
    columns: [
      // Your column data here
      {
        label: "Category",
        type: "inlineChip",
        fieldName: "id",
        typeAttributes: {
          imagetype: { fieldName: "imageType" },
          imagename: { fieldName: "imageName" },
          imageclass: { fieldName: "imageClass" },
          href: { fieldName: "url" },
          label: { fieldName: "category" },
          identifier: { fieldName: "identifier" }
        }
      },
      {
        label: "# Users",
        type: "inlineText",
        typeAttributes: {
          text: { fieldName: "num_users" },
          align: "left"
        },
        initialWidth: 250,
        cellAttributes: { alignment: "left" }
      },
      {
        label: "Bandwidth Usage",
        type: "inlineBar",
        fieldName: "id",
        typeAttributes: {
          total: { fieldName: "value" },
          sub: { fieldName: "sub" },
          max: { fieldName: "max" },
          category: { fieldName: "type" }
        }
      },
      {
        label: "(GB)",
        type: "inlineText",
        typeAttributes: {
          text: { fieldName: "displayvalue" },
          align: "left"
        },
        initialWidth: 150
      }
    ]
  },
  {
    id: "item-04",
    label: "Categories by Blocked Attempts",
    value: "categories-blocked-attempts",
    sort: "blocked",
    context: "category",
    columns: [
      // Your column data here
      {
        label: "Category",
        type: "inlineChip",
        fieldName: "id",
        typeAttributes: {
          imagetype: { fieldName: "imageType" },
          imagename: { fieldName: "imageName" },
          imageclass: { fieldName: "imageClass" },
          href: { fieldName: "url" },
          label: { fieldName: "category" },
          identifier: { fieldName: "identifier" }
        }
      },
      {
        label: "# Users",
        type: "inlineText",
        typeAttributes: {
          text: { fieldName: "num_users" },
          align: "left"
        },
        initialWidth: 250,
        cellAttributes: { alignment: "left" }
      },
      {
        label: "Blocked Attempts",
        type: "inlineBar",
        fieldName: "id",
        typeAttributes: {
          total: { fieldName: "value" },
          sub: { fieldName: "sub" },
          max: { fieldName: "max" },
          category: { fieldName: "type" }
        }
      },
      {
        label: "",
        type: "inlineText",
        typeAttributes: {
          text: { fieldName: "displayvalue" },
          align: "left"
        },
        initialWidth: 150
      }
    ]
  },
  {
    id: "item-05",
    label: "Safety Risk Categories by Blocked Attempts",
    value: "safety-categories-blocked-attempts",
    sort: "safety",
    context: "category",
    columns: [
      // Your column data here
      {
        label: "Category",
        type: "inlineChip",
        fieldName: "id",
        typeAttributes: {
          imagetype: { fieldName: "imageType" },
          imagename: { fieldName: "imageName" },
          imageclass: { fieldName: "imageClass" },
          href: { fieldName: "url" },
          label: { fieldName: "category" },
          identifier: { fieldName: "identifier" }
        }
      },
      {
        label: "# Users",
        type: "inlineText",
        typeAttributes: {
          text: { fieldName: "num_users" },
          align: "left"
        },
        initialWidth: 250,
        cellAttributes: { alignment: "left" }
      },
      {
        label: "Blocked Attempts",
        type: "inlineBar",
        fieldName: "id",
        typeAttributes: {
          total: { fieldName: "value" },
          sub: { fieldName: "sub" },
          max: { fieldName: "max" },
          category: { fieldName: "type" }
        }
      },
      {
        label: "",
        type: "inlineText",
        typeAttributes: {
          text: { fieldName: "displayvalue" },
          align: "left"
        },
        initialWidth: 150
      }
    ]
  }
];

export { items };