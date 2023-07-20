const items = [
  {
    id: "item-02",
    label: "Websites By Browsing Time",
    value: "websites-browsing-time",
    sort: "btime",
    context: "website",
    columns: [
      // Your column data here
      {
        label: "Website",
        type: "inlineChip",
        fieldName: "id",
        typeAttributes: {
          imagetype: { fieldName: "imageType" },
          imagename: { fieldName: "imageName" },
          imageclass: { fieldName: "imageClass" },
          href: { fieldName: "url" },
          label: { fieldName: "website" },
          description: { fieldName: "category" },
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
    label: "Websites By Bandwidth Usage",
    value: "websites-bandwidth-usage",
    sort: "bandwidth",
    context: "website",
    columns: [
      // Your column data here
      {
        label: "Website",
        type: "inlineChip",
        fieldName: "id",
        typeAttributes: {
          imagetype: { fieldName: "imageType" },
          imagename: { fieldName: "imageName" },
          imageclass: { fieldName: "imageClass" },
          href: { fieldName: "url" },
          label: { fieldName: "website" },
          description: { fieldName: "category" },
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
    label: "Websites by Blocked Attempts",
    value: "websites-blocked-attempts",
    sort: "blocked",
    context: "website",
    columns: [
      // Your column data here
      {
        label: "Website",
        type: "inlineChip",
        fieldName: "id",
        typeAttributes: {
          imagetype: { fieldName: "imageType" },
          imagename: { fieldName: "imageName" },
          imageclass: { fieldName: "imageClass" },
          href: { fieldName: "url" },
          label: { fieldName: "website" },
          description: { fieldName: "category" },
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