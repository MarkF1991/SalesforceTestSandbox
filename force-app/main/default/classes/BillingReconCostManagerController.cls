/**
* @author Ben Edwards (beedwards@deloitte.co.nz)
* @date 12th June 2020
* @description Controller for the BillingReconCostManager LWC
*
* CHANGE LOG
**/
public with sharing class BillingReconCostManagerController {

    @AuraEnabled(cacheable=true)
    public static List<Billing_Recon_Statement_Cost__c> getCosts(Id statementId) {
       return [
            SELECT 
                Id 
                , Account_Number__c
                , Calculated_Charge__c
                , Charge__c
                , Charge_Category__c
                , Charge_Type__c
                , Comments__c
                , Description__c
                , From_Date__c
                , Funded__c
                , GL_Code__c
                , GST_Indicator__c
                , Line_Number__c
                , MAC__c
                , MOE_Id__c
                , MoE_Site_Id__c
                , Node_Description__c
                , Product_Service__c
                , School_Name__c
                , School_Type__c
                , Statement_Date__c
                , To_Date__c
                , Variance__c
            FROM 
                Billing_Recon_Statement_Cost__c
            WHERE 
                Billing_Recon_Statement__c = :statementId
            ORDER BY 
                CSV_Row__c
        ];
    }   

    // Retrieve the unique set of CHarge Category filters
    @AuraEnabled(cacheable=true)
    public static List<String> getChargeCategories(Id statementId) {

        Set<String> chargeCategoriesUnique = new Set<String>();

        // Dynamically build available categories based on current charge categories
        // On the cost records
        for (Billing_Recon_Statement_Cost__c cost :getCosts(statementId)) {
            chargeCategoriesUnique.add(cost.Charge_Category__c);
        }

        // Cast back to List and sort
        List<String> chargeCategories = new List<String>(chargeCategoriesUnique);
        chargeCategories.sort();

        return chargeCategories;
    }

    // Retrieve the available charge category options
    @AuraEnabled(cacheable=true)
    public static List<PicklistOption> getChargeCategoryOptions () {

        List<PicklistOption> picklistOptions = new List<PicklistOption>{
            new PicklistOption('', '--None--')
        };

        Set<String> uniqueCategories = new Set<String>();

        // Build picklist values based on the active options
        for (Billing_Recon_Categorisation_Rule__c rule :[SELECT Charge_Category__c FROM Billing_Recon_Categorisation_Rule__c ORDER BY Charge_Category__c]) {
            uniqueCategories.add(rule.Charge_Category__c);
        }

        // Add a unique rule for each 
        for (String chargeCategory :uniqueCategories) {
            picklistOptions.add(new PicklistOption(chargeCategory, chargeCategory));
        }

        // Add the Unknown option
        picklistOptions.add(new PicklistOption('Unknown', 'Unknown'));

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