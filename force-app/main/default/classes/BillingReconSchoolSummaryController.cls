/**
* @author Ben Edwards (beedwards@deloitte.co.nz)
* @date 12th June 2020
* @description Controller for the BillingReconSchoolSummary LWC
*
* CHANGE LOG
**/
public with sharing class BillingReconSchoolSummaryController {

    public static final String UNKNOWN_CHARGE_CATEGORY = 'Unknown';

    /**
    * @author Ben Edwards (beedwards@deloitte.co.nz)
    * @date 12th June 2020
    * @description Retrieve the summary rows to display on the summary page
    **/
    @AuraEnabled(cacheable=true)
    public static List<SummaryRow> getSummaryRows(Id statementSchoolId) {

        Map<String, SummaryRow> summaryRowsByChargeCategory = new Map<String, SummaryRow>();

        // Build a 
        for (Billing_Recon_Categorisation_Rule__c rule :[SELECT Charge_Category__c FROM Billing_Recon_Categorisation_Rule__c ORDER BY Charge_Category__c]) {

            // Build a row for each rule initially
            summaryRowsByChargeCategory.put(
                rule.Charge_Category__c,
                new SummaryRow(rule.Charge_Category__c)
            );
        }

        // Add the "Other Charge" at the bottom
        summaryRowsByChargeCategory.put(UNKNOWN_CHARGE_CATEGORY, new SummaryRow(UNKNOWN_CHARGE_CATEGORY));

        // Now, iterate over every cost for the school
        for (Billing_Recon_Statement_Cost__c cost :[SELECT Charge_Category__c, Charge__c, Calculated_Charge__c FROM Billing_Recon_Statement_Cost__c WHERE Statement_Account__c = :statementSchoolId]) {

            // Build the charge category
            // If doesn't exiost, we set to unknown
            String categoryName = 
                summaryRowsByChargeCategory.containsKey(cost.Charge_Category__c) ? 
                    cost.Charge_Category__c :
                    UNKNOWN_CHARGE_CATEGORY;

            // Retrieve the summary row
            SummaryRow row = summaryRowsByChargeCategory.get(categoryName);

            // Increment charges
            row.calculatedCharge += (cost.Calculated_Charge__c != null ? cost.Calculated_Charge__c : 0);
            row.charge += (cost.Charge__c != null ? cost.Charge__c : 0);

            // Put back to map
            summaryRowsByChargeCategory.put(categoryName, row);
        }   

        // Return the map values
        return summaryRowsByChargeCategory.values();
    }

    
    public class SummaryRow {

        @AuraEnabled
        public String name;

        @AuraEnabled
        public Decimal calculatedCharge;

        @AuraEnabled
        public Decimal charge;

        @AuraEnabled
        public Decimal variance {
            get {
                if (variance == null) {

                    variance = 0;

                    if (calculatedCharge != null && this.charge != null) {
                        
                        variance = this.calculatedCharge - this.charge;
                    }
                }
                return variance;
            }
            set;
        }

        // Build an empty row 
        public SummaryRow (String name) {
            this.name = name;
            this.calculatedCharge = 0;
            this.charge = 0;
        }
    }
}