public with sharing class ExposedServiceContactsBatch implements Database.Batchable<sObject>, Database.Stateful {
    public Id campaignId;
    public String partialURL;

    public ExposedServiceContactsBatch(Id campaignId) {
        this.campaignId = campaignId;
        this.partialURL = Helper.supportHubURL();
    }

    //Query Campaign Members to process
    public Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator([
            SELECT id, Campaign__c, Contact__c, Contact__r.Email, Contact__r.FirstName, Campaign_Account__r.Account__c 
            FROM Campaign_Account_Contact__c 
            WHERE Campaign__c =: campaignId
            ORDER BY Campaign_Account__r.Account__c, Contact__r.FirstName
        ]);
    }

    // process each batch of records
    public void execute(Database.BatchableContext BC, List<Campaign_Account_Contact__c> scope) {
        List<Campaign_Account_Contact__c> CampaignAccountContacts = new List<Campaign_Account_Contact__c>();

                    for (Campaign_Account_Contact__c CampaignAccountContact : scope){
                         MethodResponse mrs = ExposedServiceController.campaign_email_actions(CampaignAccountContact, partialURL,false);              
                    }
         
                   
    }

    public void finish(Database.BatchableContext batchableContext) {
        // execute any post-processing operations
        
    }
}