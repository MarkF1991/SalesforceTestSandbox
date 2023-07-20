/**
* @author Ben Edwards (beedwards@deloitte.co.nz)
* @date 12th June 2020
* @description Service class for calculating a charge type for a provided cost line
*
* CHANGE LOG
**/
public without sharing class BillingReconChargeTypeService {

    /**
    * @author Ben Edwards (beedwards@deloitte.co.nz)
    * @date 12th June 2020
    * @description Determine the charge type based on the provided sobject record
    **/
    public static String getChargeType (Id recordId) {

        return getChargeType([
            SELECT 
                Charge_Type__c
                , Charge__c
                , Comments__c
                , Description__c
                , GL_Code__c
                , Node_Description__c
                , Product_Service__c
                , School_Name__c
            FROM 
                Billing_Recon_Statement_Cost__c
            WHERE  
                Id = :recordId
        ]);
    }

    
    /**
    * @author Ben Edwards (beedwards@deloitte.co.nz)
    * @date 12th June 2020
    * @description Determine the charge type based on the provided sobject record
    **/
    public static String getChargeType (SObject record) {

        // Default charge type to Unknown. 
        // If a charge type cannot be found, this is returned 
        String chargeType = 'Unknown';

        for (Billing_Recon_Categorisation_Rule__c rule :categorisationRules) {

            // If the rule is deemed to be matching
            // Then we can return it as we iterate through priority
            // First matching rule wins!
            if (isMatchingRule(record, rule)) {

                return rule.Charge_Category__c;
            }
        }   

        return chargeType;
    }
    
    /**
    * @author Ben Edwards (beedwards@deloitte.co.nz)
    * @date 12th June 2020
    * @description Determines if the current rule matches the charge type
    **/
    public static Boolean isMatchingRule (SObject record, Billing_Recon_Categorisation_Rule__c rule) {

        // Controls whether the entire rule is met or 
        // not
        Boolean isMatchingRule = false;

        for (Billing_Recon_Categorisation_Condition__c condition :rule.Conditions__r) {

            Boolean conditionMatches = false;

            // If there is no source value, suggest we just fail the role rule
            if (record.get(condition.Field_Name__c) == null) {
                break;
            }

            // Retrieve the values to match against
            String sourceValue = String.valueOf(record.get(condition.Field_Name__c));
            String matchToValue = condition.Value__c;

            // Switch statement to determine if the source value and matching value
            // meet conditions
            switch on condition.Operator__c {

                when 'Equals' {

                    conditionMatches = sourceValue == matchToValue;
                }
                when 'Does Not Equal' {
                    
                    conditionMatches = sourceValue != matchToValue;
                }
                when 'Starts With' {
                    
                    conditionMatches = sourceValue.startsWithIgnoreCase(matchToValue);
                }
                when 'Contains' {
                    
                    conditionMatches = sourceValue.containsIgnoreCase(matchToValue);
                }
                when 'Does Not Contain' {
                    
                    conditionMatches = !sourceValue.containsIgnoreCase(matchToValue);
                }
            }

            // Now we know if this particular condition matches or not, but we need to take into 
            // account the overall condition logic
            switch on rule.Conditions__c {

                when 'All' {

                    // For All, every single condition needs to be true
                    // So needs to have context of the other rules
                    // If this doesn't match, then we can mark as false and break the loop
                    if (!conditionMatches) {

                        isMatchingRule = false;
                        break;
                    }
                    // If this does match however, let's mark the match is true
                    // And it'll be marked as false in the next loop if it needs to be
                    else {

                        // Mark as overall matching. 
                        // But don't break the loop, this will need to get re-evaluated above
                        isMatchingRule = true;
                    }
                }
                when 'Any' {

                    // If any condition, then we just need one condition to match
                    // In that case, if this one matches we can return as matching
                    // and break the loop
                    if (conditionMatches) {
                        isMatchingRule = true;
                        break;
                    }
                }
            }
        }

        return isMatchingRule;
    }


    /**
    * @author Ben Edwards (beedwards@deloitte.co.nz)
    * @date 12th June 2020
    * @description Query for the active categorisation rules
    **/
    public static List<Billing_Recon_Categorisation_Rule__c> categorisationRules {
        get {
            if (categorisationRules == null) {

                categorisationRules = [
                    SELECT 
                        Charge_Category__c
                        , Conditions__c 
                        , (
                            SELECT 
                                Field_Name__c
                                , Operator__c 
                                , Value__c
                            FROM 
                                Conditions__r
                        )
                    FROM 
                        Billing_Recon_Categorisation_Rule__c 
                    WHERE   
                        Active__c = true 
                    ORDER BY 
                        Priority__c
                ];
            }
            return categorisationRules;
        }
        set;
    }

}