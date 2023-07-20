public with sharing class InstalledN4LProductFeatureController {
    @AuraEnabled(cacheable=true)
    public static List<Installed_N4L_Product_Feature__c> getAccountProductList(String accountId){
        Set<string> inactiveStatuses = new Set<string>{'Inactive', 'Not Applicable'};       
        List<Installed_N4L_Product_Feature__c> result  = new List<Installed_N4L_Product_Feature__c>();
        if (String.isBlank(accountId)) return result;
        
        result = [SELECT Id, Name, Organisation__c, Status__c, End_Date__c, Active_Date__c, N4l_Product_Name__c 
        FROM Installed_N4L_Product_Feature__c  WHERE Organisation__c =: accountId AND Status__c NOT IN :inactiveStatuses];
       
        return result;
    }
}