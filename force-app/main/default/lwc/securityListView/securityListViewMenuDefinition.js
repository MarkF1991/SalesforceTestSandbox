const items = [
  {
    id: "item-01",
    label: "Infections",
    value: "infected-devices",
    sort: "infections",
    context: "infection",
    columns: [
      // Your column data here
      {
        label: "Infection Name",
        type: "inlineChip",
        fieldName: "id",
        typeAttributes: {
          imagetype: { fieldName: "imageType" },
          imagename: { fieldName: "imageName" },
          imageclass: { fieldName: "imageClass" },
          label: { fieldName: "title" },
          href: { fieldName: "url" },
          description: { fieldName: "category" },
          identifier: { fieldName: "identifier" }
        }
      },
      {
        label: "No. Infected Devices",
        type: "inlineBar",
        fieldName: "infectedCount",
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
          text: { fieldName: "displayValue" },
          align: "left"
        },
        initialWidth: 150
      }
    ]
  },
  {
    id: "item-02",
    label: "Attacks Blocked",
    value: "attacks-blocked",
    sort: "attackBlocked",
    context: "attackBlocked",
    columns: [
      // Your column data here
      {
        label: "Attack Name",
        type: "inlineChip",
        fieldName: "id",
        typeAttributes: {
          imagetype: { fieldName: "imageType" },
          imagename: { fieldName: "imageName" },
          imageclass: { fieldName: "imageClass" },
          label: { fieldName: "title" },
          description: { fieldName: "category" }
        }
      },
      {
        label: "Attack Count",
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
          text: { fieldName: "displayValue" },
          align: "left"
        },
        initialWidth: 150
      }
    ]
  }
];

export { items };