const items = [
  {
    id: "item-01",
    label: "All Users",
    value: "all",
    sort: "all",
    context: "list",
    columns: [
      // Your column data here
      {
        label: "User",
        type: "inlineChip",
        initialWidth: 300,
        fieldName: "id",
        sortable: true,
        typeAttributes: {
          imagetype: { fieldName: "imageType" },
          imagename: { fieldName: "imageName" },
          imageclass: { fieldName: "imageClass" },
          href: { fieldName: "url" },
          label: { fieldName: "user" }
        }
      },
      {
        label: "# Devices",
        type: "inlineText",
        initialWidth: 100,
        cellAttributes: { alignment: "left" },
        typeAttributes: {
          text: { fieldName: "devices" },
          align: "left"
        }
      },
      {
        label: "Browsing Time",
        type: "inlineBar",
        fieldName: "id",
        typeAttributes: {
          total: { fieldName: "btvalue" },
          sub: { fieldName: "sub" },
          max: { fieldName: "btmax" },
          category: { fieldName: "bttype" }
        }
      },
      {
        label: "(HH:MM:SS)",
        type: "inlineText",
        initialWidth: 150,
        typeAttributes: {
          text: { fieldName: "btdisplayvalue" },
          align: "left"
        }
      },
      {
        label: "Bandwidth Usage",
        type: "inlineBar",
        fieldName: "id",
        typeAttributes: {
          total: { fieldName: "buvalue" },
          sub: { fieldName: "busub" },
          max: { fieldName: "bumax" },
          category: { fieldName: "butype" }
        }
      },
      {
        label: "(GB)",
        type: "inlineText",
        initialWidth: 150,
        typeAttributes: {
          text: { fieldName: "budisplayvalue" },
          align: "left"
        }
      },
      {
        label: "Blocked Attempts",
        type: "inlineBar",
        fieldName: "id",
        typeAttributes: {
          total: { fieldName: "bavalue" },
          sub: { fieldName: "sub" },
          max: { fieldName: "bamax" },
          category: { fieldName: "batype" }
        }
      },
      {
        label: "",
        type: "inlineText",
        initialWidth: 100,
        typeAttributes: {
          text: { fieldName: "badisplayvalue" }
        }
      }
    ]
  },
  {
    id: "item-02",
    label: "Users By Browsing Time",
    value: "users-browsing-time",
    sort: "btime",
    context: "list",
    columns: [
      // Your column data here
      {
        label: "User",
        type: "inlineChip",
        fieldName: "id",
        sortable: true,
        typeAttributes: {
          imagetype: { fieldName: "imageType" },
          imagename: { fieldName: "imageName" },
          imageclass: { fieldName: "imageClass" },
          href: { fieldName: "url" },
          label: { fieldName: "user" }
        }
      },
      {
        label: "# Devices",
        type: "inlineText",
        typeAttributes: {
          text: { fieldName: "devices" },
          align: "left"
        },
        initialWidth: 100,
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
          text: { fieldName: "displayvalue" }
        },
        initialWidth: 150
      }
    ]
  },
  {
    id: "item-03",
    label: "Users By Bandwidth Usage",
    value: "users-bandwidth-usage",
    sort: "bandwidth",
    context: "list",
    columns: [
      // Your column data here
      {
        label: "User",
        type: "inlineChip",
        fieldName: "id",
        sortable: true,
        typeAttributes: {
          imagetype: { fieldName: "imageType" },
          imagename: { fieldName: "imageName" },
          imageclass: { fieldName: "imageClass" },
          href: { fieldName: "url" },
          label: { fieldName: "user" }
        }
      },
      {
        label: "# Devices",
        fieldName: "devices",
        type: "inlineText",
        typeAttributes: {
          text: { fieldName: "devices" },
          align: "left"
        },
        initialWidth: 100,
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
          text: { fieldName: "displayvalue" }
        },
        initialWidth: 150
      }
    ]
  },
  {
    id: "item-04",
    label: "Users by Blocked Attempts",
    value: "users-blocked-attempts",
    sort: "blocked",
    context: "list",
    columns: [
      // Your column data here
      {
        label: "User",
        type: "inlineChip",
        fieldName: "id",
        sortable: true,
        typeAttributes: {
          imagetype: { fieldName: "imageType" },
          imagename: { fieldName: "imageName" },
          imageclass: { fieldName: "imageClass" },
          href: { fieldName: "url" },
          label: { fieldName: "user" }
        }
      },
      {
        label: "# Devices",
        type: "inlineText",
        typeAttributes: {
          text: { fieldName: "devices" },
          align: "left"
        },
        initialWidth: 100,
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
          text: { fieldName: "displayvalue" }
        },
        initialWidth: 100
      }
    ]
  }
];

export { items };