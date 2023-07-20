const items = [
  {
    id: "item-01",
    label: "All Devices",
    value: "all-devices",
    sort: "all",
    context: "list",
    columns: [
      // Your column data here
      {
        label: "Device Name",
        type: "inlineChip",
        initialWidth: 300,
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
        fieldName: "num_users",
        type: "inlineText",
        typeAttributes: {
          text: { fieldName: "num_users" },
          align: "left"
        },
        initialWidth: 100
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
        typeAttributes: {
          text: { fieldName: "btdisplayvalue" },
          align: "left"
        },
        initialWidth: 150
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
        typeAttributes: {
          text: { fieldName: "budisplayvalue" },
          align: "left"
        },
        initialWidth: 150
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
        typeAttributes: {
          text: { fieldName: "badisplayvalue" },
          align: "left"
        },
        initialWidth: 50
      }
    ]
  },
  {
    id: "item-02",
    label: "Devices By Browsing Time",
    value: "devices-browsing-time",
    sort: "btime",
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
        },
        initialWidth: 100
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
    label: "Devices By Bandwidth Usage",
    value: "devices-bandwidth-usage",
    sort: "bandwidth",
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
        },
        initialWidth: 100
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
    label: "Devices by Blocked Attempts",
    value: "devices-blocked-attempts",
    sort: "blocked",
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
        },
        initialWidth: 100
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