/**
* @author Ivanna Panchenko
* @date 12th June 2020
* @description Controller for the BillingReconStatement LWC
*
* CHANGE LOG
**/
public with sharing class BillingReconStatementController {
    
    @AuraEnabled(cacheable=true)
    public static List<Billing_Recon_Statement_Account__c> getStatementAccounts(Id statementId) {
    
       return [
            SELECT 
                Id 
                , Name
                , MoE_Id__c
                , MoE_Site_Id__c
                , Funded__c
                , School_Name__c
                , School_Type__c
                , SF_Total__c
                , CM_Total__c
                , Total_Variance__c
                , Comments__c
                , Status__c

                , LFC_Calculated_Charge_Total__c
                , LFC_Charge_Total__c
                , LFC_Charge_Variance__c

                , LFC_Install_Calculated_Charge_Total__c
                , LFC_Install_Charge_Total__c
                , LFC_Install_Charge_Variance__c

                , CLNE_Calculated_Charge_Total__c
                , CLNE_Charge_Total__c
                , CLNE_Charge_Variance__c

                , Safe_Secure_Calculated_Charge_Total__c
                , Safe_Secure_Charge_Total__c
                , Safe_Secure_Charge_Variance__c

                , MAC_Calculated_Charge_Total__c
                , MAC_Charge_Total__c
                , MAC_Charge_Variance__c

                , Other_Charges_Calculated_Total__c
                , Other_Charges_Total__c
                , Other_Charges_Variance__c
            FROM 
                Billing_Recon_Statement_Account__c
            WHERE 
                Billing_Recon_Statement__c = :statementId
        ];
    }


    @AuraEnabled(cacheable=true)
    public static List<PicklistOption> getStatusOptions () {

        List<PicklistOption> picklistOptions = new List<PicklistOption>{
            new PicklistOption('', '--None--')
        };

        // Build picklist values based on the active options
        for (Schema.PicklistEntry picklistEntry :Schema.Billing_Recon_Statement_Account__c.Status__c.getDescribe().getPicklistValues()) {
            if (picklistEntry.isActive()) {
                picklistOptions.add(new PicklistOption(picklistEntry.getValue(), picklistEntry.getLabel()));
            }
        }
        return picklistOptions;
    }


    public class PicklistOption {

        @AuraEnabled
        public String value {get; set;}

        @AuraEnabled
        public String label {get; set;}

        @AuraEnabled
        public Boolean isSelected {get; set;}

        public PicklistOption(String value, String label) {
            this.isSelected = false;
            this.value = value;
            this.label = label;
        }
    }


}