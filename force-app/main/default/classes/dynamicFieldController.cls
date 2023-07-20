/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 12-07-2022
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class dynamicFieldController {
    @AuraEnabled(cacheable=true)
    public static List<EmailTemplate> getEmailTemplate(){
        String label = Label.the_folder_name_of_email_template;
        Folder fd = [SELECT Id, Name FROM Folder WHERE Name =: label];
        return [SELECT Id, Body, Name, DeveloperName, FolderId FROM EmailTemplate WHERE FolderId =: fd.Id];
    }

    @AuraEnabled(cacheable=true)
    public static string Email_Template_Name(string campaignId){
        Campaign campaign = [SELECT Id, Email_Template_Name__c, RecordType.Name FROM Campaign where Id = :campaignId];
  
        return campaign.Email_Template_Name__c;
    }

    @AuraEnabled(cacheable=true)
    public static Campaign Update_Email_Template(string campaignId){
        Campaign campaign = [SELECT Id, Description, Email_Template_Name__c, RecordType.Name FROM Campaign where Id = :campaignId];
        return campaign;
    }

}