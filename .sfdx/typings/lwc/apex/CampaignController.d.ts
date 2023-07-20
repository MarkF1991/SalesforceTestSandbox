declare module "@salesforce/apex/CampaignController.sendCampaignEmail" {
  export default function sendCampaignEmail(param: {campaignId: any, mode: any}): Promise<any>;
}
declare module "@salesforce/apex/CampaignController.getCampaignAccounts" {
  export default function getCampaignAccounts(param: {campaignId: any, input: any}): Promise<any>;
}
declare module "@salesforce/apex/CampaignController.getCampaignAccountContacts" {
  export default function getCampaignAccountContacts(param: {campaignId: any}): Promise<any>;
}
declare module "@salesforce/apex/CampaignController.createCampaignMembers" {
  export default function createCampaignMembers(param: {campaignId: any, excludeOptOut: any}): Promise<any>;
}
