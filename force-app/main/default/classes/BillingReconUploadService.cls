/**
* @author Ben Edwards (beedwards@deloitte.co.nz)
* @date 12th June 2020
* @description Service class for processing the batch upload CSV process
*
* CHANGE LOG
**/
public with sharing class BillingReconUploadService {

    /**
    * @author Ben Edwards (beedwards@deloitte.co.nz)
    * @date 12th June 2020
    * @description Retrieve the file to process
    **/
    public static Blob getFile (Id billingReconStatementId) {
        return [
            SELECT 
                ContentDocument.LatestPublishedVersion.VersionData
            FROM 
                ContentDocumentLink 
            WHERE 
                LinkedEntityId = :billingReconStatementId
            ORDER BY 
                ContentDocument.CreatedDate DESC
            LIMIT 
                1
        ].ContentDocument.LatestPublishedVersion.VersionData; 
    }
    
    // Build a map of Accounts/Schools used ot map lines to the correct
    // School/Account
    public static Map<String, Id> getSchoolsMap() {

        Map<String, Id> schoolsMap = new Map<String, Id>();

        for (Account school :[
            SELECT Name, MoE_External_ID__c 
            FROM Account 
            WHERE RecordType.DeveloperName IN ('School', 'School_Additional_Site')
        ]){ 
            
            // Adding in 2x different keys, to support matching on either site ID or account ID
            schoolsMap.put(school.MoE_External_ID__c, school.Id);
            schoolsMap.put(school.Name, school.Id);
        }

        return schoolsMap;
    }

    public static final Map<String, String> columnHeaderToField = new Map<String, String>{
        'Node Description' => 'Node_Description__c',
        'Description' => 'Description__c',
        'GL Code' => 'GL_Code__c',
        'Account Number' => 'Account_Number__c',
        'Statement Date' => 'Statement_Date__c',
        'Line Number' => 'Line_Number__c',
        'Charge Type' => 'Charge_Type__c',
        'From Date' => 'From_Date__c',
        'To Date' =>  'To_Date__c',
        'GST Indicator' => 'GST_Indicator__c',
        'Charge' => 'Charge__c',
        'MAC' => 'MAC__c',
        'Product/Service' => 'Product_Service__c'
    };


    // Dynamically return the value based on the type of field it is
    public static Object getValue (String fieldName, String stringValue) {

        // Retrieve the field type
        Schema.DisplayType fieldType = getFieldType(fieldName);

        // If blank, return false for boolean
        // Else return nul
        if (String.isBlank(stringValue)) {
            return (fieldType == Schema.DisplayType.Boolean) ? false : null;
        }
        
        // replace double quote in the description and currency
        stringValue = stringValue.replace('"', '');

        // Process different field types
        if (fieldType == Schema.DisplayType.Date) {
            
            List<String> dateParts = stringValue.split('\\/');
            return Date.newInstance(Integer.valueOf(dateParts[2]), Integer.valueOf(dateParts[1]), Integer.valueOf(dateParts[0]));
        }
        else if (fieldType == Schema.DisplayType.Double) {

            return Decimal.valueOf(stringValue);
        }
        else if (fieldType == Schema.DisplayType.Currency) {

            // Remove all non-numeric characters
            String convertedValue = stringValue.replaceAll('\\s+', '').replaceAll('[^0-9]', '');

            // Convert to decimal and divide by 100 (as number $120.00 becomes 12000, as has trailing decimals)
            Decimal decimalValue = Decimal.valueOf(convertedValue) / 100;

            // If starts with a negative, we need to convert to neagative value.
            return stringValue.startsWith('-') ? (decimalValue * -1) : decimalValue;
        }
        return stringValue;
    }

    
    // Dynamically return the field type for a given field name
    public static Map<String, Schema.SObjectField> billingReconCostFields;
    public static Schema.DisplayType getFieldType (String fieldName) {

        if (billingReconCostFields == null) {
            billingReconCostFields = Schema.Billing_Recon_Statement_Cost__c.SObjectType.getDescribe().fields.getMap();
        }

        return billingReconCostFields.get(fieldName).getDescribe().getType();
    }


    // For a given CSV Row, parse the details in order to build a 
    // list of cells for the line.
    public static List<String> getCSVRowCells(String csvRow){

        String prevLine = csvRow;
        Integer startIndex;
        Integer endIndex;

        // Use temporary strings to replace and unreplace quotes and commas
        String quotesReplacementString = ':quotes:';
        String commaReplacementString = ':comma:';

        // If the row contains quotes in it, it likely includes a comma
        // Within the cell. This has issues with splitting on comma so we 
        // need ot process that first
        while (csvRow.indexOf('"') > -1){

            if (startIndex == null) {
                
                startIndex = csvRow.indexOf('"');
                csvRow = csvRow.substring(0, startIndex) + quotesReplacementString + csvRow.substring(startIndex+1, csvRow.length());
            }
            else {
                
                if (endIndex == null){
                    endIndex = csvRow.indexOf('"');
                    csvRow = csvRow.substring(0, endIndex) + quotesReplacementString + csvRow.substring(endIndex+1, csvRow.length());
                }
            }
            
            if (startIndex != null && endIndex != null){

                String sub = csvRow.substring(startIndex, endIndex);
                sub = sub.replaceAll(',', commaReplacementString);
                csvRow = csvRow.substring(0, startIndex) + sub + csvRow.substring(endIndex, csvRow.length());
                startIndex = null;
                endIndex = null;
            }
        }
        
        // Now finally, split on commas to return the cells to use.
        List<String> csvCellsForRow = new List<String>();

        for (String column : csvRow.split(',')){
            column = column.replaceAll(quotesReplacementString, '').replaceAll(commaReplacementString, ',');
            csvCellsForRow.add(column);
        }

        return csvCellsForRow; 
    }

    // Build a set of BillingReconStatementCost fields
    // If they don't exist, we won't try and map them
    public static Set<String> getBillingReconStatementCostFields() {

        Set<String> billingReconStatementCostFields = new Set<String>();

        for (Schema.SObjectField field :Schema.SObjectType.Billing_Recon_Statement_Cost__c.fields.getMap().values()) {

            if (field.getDescribe().isCreateable()) {

                billingReconStatementCostFields.add(field.getDescribe().getName().toLowerCase());
            }
        }
        return billingReconStatementCostFields;
    }
}