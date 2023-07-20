const items = [
  {
    id: "item-05",
    label: "Apps by Bandwidth Usage",
    value: "apps-bandwidth-usage",
    sort: "bandwidth",
    context: "application",
    columns: [
      // Your column data here
      {
        label: "App",
        type: "inlineChip",
        fieldName: "id",
        typeAttributes: {
          imagetype: { fieldName: "imageType" },
          imagename: { fieldName: "imageName" },
          imageclass: { fieldName: "imageClass" },
          href: { fieldName: "url" },
          label: { fieldName: "application" },
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
        initialWidth: 250
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
  }
];

export { items };