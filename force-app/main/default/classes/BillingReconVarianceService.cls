/**
* @author Ben Edwards (beedwards@deloitte.co.nz)
* @date 12th June 2020
* @description Service class for calculating variances for cost lines
*
* CHANGE LOG
**/
public with sharing class BillingReconVarianceService {

    /**
    * @author Ben Edwards (beedwards@deloitte.co.nz)
    * @date 12th June 2020
    * @description For a given charge line, calculate the cost
    **/
    public static Billing_Recon_Statement_Cost__c calculateCharge (Billing_Recon_Statement_Cost__c charge) {

        // Set the charge amount to $0
        charge.Calculated_Charge__c = 0;

        // Load the parent school
        Account school = charge.Statement_Account__r.Account__r;

        // The matching pricebookentry 
        PricebookEntry matchingPriceBookEntry;

        // Determine different charge calculation based on Charge Category
        if (charge.Charge_Category__c.startsWith('LFC')) {

            // Determine whether install or rental
            String productType = charge.Charge_Category__c.endsWith('Install') ? 'Install' : 'Rental';

            // The key used to retrieve the charge cost
            String productKey = productType + '-' + getLFCKey(
                school.Billing_Initiative__c, 
                school.Current_Connection_Bandwidth__c, 
                school.LFC_Provider__c, 
                school.LFC_Provider_Access_Type__c
            );

            // If we're found a matching install product
            if (lfcPrices.containsKey(productKey)) {

                // Set the matching PBE
                matchingPriceBookEntry = lfcPrices.get(productKey);

                // assign the charge
                charge.Calculated_Charge__c = matchingPriceBookEntry.UnitPrice;
            }
        }
        // Determine CLNE charges
        else if (charge.Charge_Category__c.startsWith('CLNE')) {

            // If the FortiGate model has a proce
            if (school.Current_CLNE_Make_Model__c != null && clnePrices.containsKey(school.Current_CLNE_Make_Model__c)) {
                
                // Set the matching PBE
                matchingPriceBookEntry = clnePrices.get(school.Current_CLNE_Make_Model__c);

                // assign the charge
                charge.Calculated_Charge__c = matchingPriceBookEntry.UnitPrice;
            }
        }   
        // Determine Safe & Secure charges
        else if (charge.Charge_Category__c.equalsIgnoreCase('Safe & Secure')) {

            // If we have a PBE for Safe & Secure
            if (safeAndSecurePrices.containsKey('SSINTNET')) {

                // Set the matching price book entry
                matchingPriceBookEntry = safeAndSecurePrices.get('SSINTNET');

                // Calculate the total days in the month
                Decimal daysInMonth = Decimal.valueOf(charge.From_Date__c.addMonths(1).toStartOfMonth().addDays(-1).day());

                // Calculate the price per day
                Decimal pricePerDay = (matchingPriceBookEntry.UnitPrice / daysInMonth);

                // Calculate the charge
                charge.Calculated_Charge__c = 
                    (pricePerDay * (school.Billing_Total_Users__c == null ? 0 : school.Billing_Total_Users__c))
                        .setScale(2, RoundingMode.HALF_UP);
            }
        }
        // Determine Safe & Secure 2.0
        else if (charge.Charge_Category__c.equalsIgnoreCase('Safe & Secure 2.0')) {

            // Default to largest size
            String safeAndSecureProductCode = 'SSINTNET-XL';

            // If not funded, we use the standard independent pricing
            if (school.Managed_Network_Service_MoE_Funding__c == 'Not Funded') { 

                safeAndSecureProductCode = 'SSINTNET-IND';
            }
            // Primary school and 0 - 250 Users; OR
            // Not Primary School and 0 - 200 users
            else if (
                (
                    String.isNotBlank(school.School_Type__c) && 
                    FULL_PRIMARY_SCHOOL_TYPES.contains(school.School_Type__c) && 
                    school.Billing_Total_Users__c <= 250
                ) 
                ||
                (
                    school.Billing_Total_Users__c <= 200
                )
            ) {

                safeAndSecureProductCode = 'SSINTNET-S';
            }
            else if (school.Billing_Total_Users__c <= 1000) {

                safeAndSecureProductCode = 'SSINTNET-M';
            }
            else if (school.Billing_Total_Users__c <= 2000) {

                safeAndSecureProductCode = 'SSINTNET-L';
            }

            // If we have a PBE for Safe & Secure
            if (safeAndSecurePrices.containsKey(safeAndSecureProductCode)) {

                // Set the matching price book entry
                matchingPriceBookEntry = safeAndSecurePrices.get(safeAndSecureProductCode);

                // Assign the charge
                charge.Calculated_Charge__c = matchingPriceBookEntry.UnitPrice;
            }
        }

        // If we found a price book, we can apply the charge
        if (matchingPriceBookEntry != null) {

            // Assign charge and product values
            charge.Product__c = matchingPriceBookEntry.Product2Id;
            charge.Pricebook_Entry_Id__c = matchingPriceBookEntry.Id;
        }

        // Pro-Rata the charge based on percentage of the month
        charge.Calculated_Charge__c = proRataCharge(charge.Calculated_Charge__c, charge.From_Date__c, charge.To_Date__c);

        // If the charge is a refund, we calculate the Salesforce charge as a refund too
        charge.Calculated_Charge__c = charge.Charge__c < 0 ? (charge.Calculated_Charge__c * -1) : charge.Calculated_Charge__c;

        return charge;
    }

    /**
    * @author Ben Edwards (beedwards@deloitte.co.nz)
    * @date 12th June 2020
    * @description Pro-rata the charge based on dates used
    **/
    public static Decimal proRataCharge(Decimal value, Date fromDate, Date toDate) {

        // If no value or value is $0, return the value
        // Otehrwise, if no From Date and no To Date, return value
        if (value == null || value == 0 || fromDate == null || toDate == null) return value;

        // If value is for the full month (eg. 1st to last day of month) then we return the full amount
        if (fromDate.day() == 1 && toDate.day() == (toDate.addMonths(1).toStartOfMonth().addDays(-1).day())) return value;

        // Now, failing all above then we have a pro-rata charge. So let's calculate it

        // We get the total days in the month to determining what days is the last in the month
        Integer daysInMonth = fromDate.addMonths(1).toStartOfMonth().addDays(-1).day();

        // Calculate the days between two days
        // We add one because we need inclusive amounts
        Integer daysBetween = fromDate.daysBetween(toDate) + 1;

        // Determine the ratio to use
        Decimal ratio = Decimal.valueOf(daysBetween) / Decimal.valueOf(daysInMonth);

        // Pro-rata the value based on days in the month
        Decimal proRataValue =  value * ratio;

        // Return the rounded value
        return proRataValue.setScale(2, RoundingMode.HALF_UP);
    }

    // Build the key used for LFC pricing
    public static String getLFCKey (String initiative, String bandwidth, String provider, String accessType) {
        return initiative + '-' + bandwidth + '-' + provider + '-' + accessType;
    }


    // Build the map of LFC Install pricing
    public static Map<String, PricebookEntry> lfcPrices {
        get {
            if (lfcPrices == null) {

                lfcPrices = new Map<String, PricebookEntry>();
                
                for (PricebookEntry pbe :allPriceBookEntries) {

                    if (
                        String.isNotBlank(pbe.Product2.Initiative__c) && 
                        String.isNotBlank(pbe.Product2.Service_Bandwidth__c) &&
                        String.isNotBlank(pbe.Product2.LFC_Provider__c) && 
                        String.isNotBlank(pbe.Product2.LFC_Provider_Access_Type__c)
                    ) {

                        // Set the product type based on rental or install charge
                        String productType = 
                            pbe.Product2.RecordType.DeveloperName == 'Billing_Access_Circuit_Rental' ? 
                                'Rental' : 
                                'Install';

                        // Add price 
                        lfcPrices.put(
                            productType + '-' + 
                            getLFCKey(
                                pbe.Product2.Initiative__c, 
                                pbe.Product2.Service_Bandwidth__c, 
                                pbe.Product2.LFC_Provider__c, 
                                pbe.Product2.LFC_Provider_Access_Type__c
                            ),
                            pbe
                        );
                    }
                }
            }
            return lfcPrices;
        }
        set;
    }

    // CLNE Prices
    public static Map<Id, PricebookEntry> clnePrices {
        get {
            if (clnePrices == null) {

                clnePrices = new Map<Id, PricebookEntry>();

                for (Device_Make_Model__c device :[SELECT (SELECT Id FROM Products__r WHERE IS_NEN__c = false LIMIT 1) FROM Device_Make_Model__c]) {

                    // Find the matching PBE
                    for (PricebookEntry pbe :allPriceBookEntries) {

                        if (!device.Products__r.isEmpty() && pbe.Product2Id == device.Products__r[0].Id) {

                            clnePrices.put(device.Id, pbe);
                            break;
                        }
                    }
                }
            }   
            return clnePrices;
        }
        set;
    }


    // The Safe & Secure prices
    public static Map<String, PricebookEntry> safeAndSecurePrices {
        get {
            if (safeAndSecurePrices == null) {

                safeAndSecurePrices = new Map<String, PricebookEntry>();

                for (PricebookEntry pbe :allPriceBookEntries) {

                    if (pbe.Product2.Product_Type__c == 'Save & Secure Internet') {

                        safeAndSecurePrices.put(pbe.Product2.ProductCode, pbe);
                    }
                }
            }
            return safeAndSecurePrices;
        }
        set;
    }

    // Retrieve all active billing pricebook entries
    public static List<PricebookEntry> allPriceBookEntries {
        get {
            if (allPriceBookEntries == null) {

                return [
                    SELECT 
                        Product2Id
                        , Product2.CLNE__c
                        , Product2.Initiative__c
                        , Product2.LFC_Provider__c
                        , Product2.LFC_Provider_Access_Type__c
                        , Product2.ProductCode
                        , Product2.Product_Type__c
                        , Product2.RecordType.DeveloperName
                        , Product2.Service_Bandwidth__c
                        , UnitPrice 
                    FROM  
                        PricebookEntry 
                    WHERE 
                        Pricebook2.Is_Billing_Price_Book__c = true 
                      AND 
                        Pricebook2.IsActive = true
                ];
            }
            return allPriceBookEntries;
        }
        set;
    }   

    // The Set of school types that should be considered "Full Primary"
    public static Set<String> FULL_PRIMARY_SCHOOL_TYPES = new Set<String>{
        'Full Primary',
        'Contributing',
        'Contributing School (Year 1-6)'
    };
}