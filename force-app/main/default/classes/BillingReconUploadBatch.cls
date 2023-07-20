/**
* @author Ivanna Panchenko
* @date 12th June 2020
* @description Service class for processing the batch upload CSV process
*
* CHANGE LOG
**/
public class BillingReconUploadBatch implements Database.Batchable<String>, Database.Stateful {

    public Id billingReconStatementId;
    
    // Load the service class used to manage statuses and errors
    public BillingReconService service;

    // The CSV headers
    public List<String> headers;

    // The Schools to map against GL Codes and descriptions
    public Map<String, Id> schoolsMap;

    // Hold a set of available cost fields
    // Used to ensure we only put into fields what we have available
    public Set<String> billingReconStatementCostFields;

    // Capture the CSV row number
    public Integer csvRowNum;

    // If a retry batch, will only process error lines
    public Boolean isRetry = false;

    // Hold the set of error row numbers
    public Set<Integer> errorRowNumbers;

    // Constructor to take the file to process
    public BillingReconUploadBatch(Id billingReconStatementId) {

        // Set the Statement ID
        this.billingReconStatementId = billingReconStatementId;

        this.init();
    }

    public BillingReconUploadBatch(Id billingReconStatementId, Boolean isRetry) {

        // Set the Statement ID
        this.billingReconStatementId = billingReconStatementId;

        // If retry batch
        this.isRetry = isRetry;

        this.init();
    }

    public void init() {

        // Load the service class to use across the batch
        this.service = new BillingReconService(billingReconStatementId);

        // Mark statement as having no file to process
        service.startProcessingCsvStatus();

        // Default the CSV row num
        this.csvRowNum = 1;

        // If retry, load the error rows
        if (this.isRetry) {

            this.errorRowNumbers = new Set<Integer>();

            // Query for the errors
            List<Billing_Recon_Error__c> errors = [SELECT CSV_Row__c FROM Billing_Recon_Error__c WHERE Billing_Recon_Statement__c = :billingReconStatementId];

            for (Billing_Recon_Error__c error :errors) {

                // Add to Set to determine which rows to process
                this.errorRowNumbers.add((Integer)error.CSV_Row__c);
            }

            // Now delete the errors, they will get re-created if they error again
            delete errors;
        }
    }

    public Iterable<String> start(Database.batchableContext batchableContext) {

        // Retrieve the file to process
        Blob csvFileToProcess = BillingReconUploadService.getFile(billingReconStatementId);

        // If there is no file to process, handle the error
        if (csvFileToProcess == null) {

            // Mark statement as having no file to process
            service.setStatementStatus(
                'Error', 'Could not process CSV as no file was found.'  
            ); 

            return null;
        }
        else {

            // Build the full list of schools to use for generating the Statement Account records
            this.schoolsMap = BillingReconUploadService.getSchoolsMap();

            // build the set
            this.billingReconStatementCostFields = BillingReconUploadService.getBillingReconStatementCostFields();

            // Return the CSV rows to process
            try {
                
                return new BillingReconCSVIterator(csvFileToProcess.toString(), '\n');
            }
            catch (Exception ex) {

                // Mark statement as having no file to process
                service.setStatementStatus(
                    'Error', ex.getMessage()
                ); 

                return null;
            } 
        }
    }

    public void execute(Database.BatchableContext batchableContext, List<String> csvRows) {

        // Errors to create
        List<Billing_Recon_Error__c> csvRowErrors = new List<Billing_Recon_Error__c>();

        // IF headers is null (will be on first run), then remove the headers
        if (this.headers == null) {
            this.headers = csvRows.remove(0).split(',');
        }

        // Build the map of statement accounts
        Map<String, Billing_Recon_Statement_Account__c> statementAccounts = new Map<String, Billing_Recon_Statement_Account__c>();

        // The new cost lines to create
        List<Billing_Recon_Statement_Cost__c> statementCosts = new List<Billing_Recon_Statement_Cost__c>();

        // Iterate over each row
        for (String csvRow :csvRows) {

            // If this is a retry job and the error numbers don't include this row
            if (isRetry && !this.errorRowNumbers.contains(csvRowNum)) {
                csvRowNum++;
                continue;
            }

            try {

                // Convert the CSV lines to a list of columns
                List<String> csvRowData = BillingReconUploadService.getCSVRowCells(csvRow);

                // Generate the new cost line
                Billing_Recon_Statement_Cost__c newCostLine = newCostLine(csvRowData);

                // Capture the CSV row number
                newCostLine.CSV_Row__c = csvRowNum;

                // If there's no From Date on the line, we can skip it
                if (newCostLine.From_Date__c == null && newCostLine.Charge__c == 0) {
                    // Increment count and then skip the record
                    csvRowNum++;
                    continue;
                }

                // Generate teh statement account
                Billing_Recon_Statement_Account__c billingReconStatementAccount = newCostAccount(newCostLine);

                // Add lookup to the parent school
                newCostLine.Statement_Account__r = new Billing_Recon_Statement_Account__c(
                    External_Id__c = billingReconStatementAccount.External_Id__c
                );

                // If there is no Account found for the CSV line, we need to raise an error for it
                if (billingReconStatementAccount.Account__c == null) {

                    // Create the Error reocrd
                    csvRowErrors.add(createError(
                        csvRowNum,
                        'Could not find matching School for ' + csvRowData[0]
                    ));
                }
                else {

                    // Build the parent cost line
                    statementAccounts.put(
                        csvRowData[0],
                        newCostAccount(newCostLine)
                    );

                    // Calculate the Charge Category
                    newCostLine.Charge_Category__c = BillingReconChargeTypeService.getChargeType(newCostLine);

                    // Add the cost line to create
                    statementCosts.add(newCostLine); 
                }
            }
            catch (Exception ex) {

                // Create the Error reocrd
                csvRowErrors.add(createError(
                    csvRowNum,
                    ex.getMessage() + '\n\n' + ex.getStackTraceString()
                ));
            }

            // Increment row num count
            csvRowNum++;
        }

        // Create the Statement Accounts
        upsert statementAccounts.values() External_Id__c;

        // Create the cost lines
        List<Database.UpsertResult> upsertResults = Database.upsert(statementCosts, false);

        // Process any failed records
        processUpsertResults(statementCosts, upsertResults, csvRowErrors);
    }

    public void finish(Database.BatchableContext batchableContext) {

        // Run the variance calculation and store the new batch job id
        service.billingReconStatement.Batch_Job_Id__c = Database.executeBatch(new BillingReconVarianceBatch(service.billingReconStatement.Id), 100);

        // Update status to Variance Processing
        service.startVarianceCalculationStatus(); 
    }

    /**
    * @author Ben Edwards (beedwards@deloitte.co.nz)
    * @date 12th June 2020
    * @description Build a unique cost account based on the description
    **/
    public Billing_Recon_Statement_Account__c newCostAccount (Billing_Recon_Statement_Cost__c costLine) {

        // Generate the school account
        Billing_Recon_Statement_Account__c statementAccount = new Billing_Recon_Statement_Account__c();
        statementAccount.Billing_Recon_Statement__c = service.billingReconStatement.Id;
        statementAccount.External_Id__c = service.billingReconStatement.Id + '-' + costLine.Node_Description__c;

        // Determine to link account
        statementAccount.Account__c = getAccountId(costLine);

        return statementAccount;
    }

    /**
    * @author Ben Edwards (beedwards@deloitte.co.nz)
    * @date 12th June 2020
    * @description Retrieve the Account ID for the Statement Account
    **/
    public Id getAccountId (Billing_Recon_Statement_Cost__c costLine) {

        // Attempt match on IDs
        if (String.isNotBlank(costLine.MOE_Id__c) && String.isNotBlank(costLine.MoE_Site_Id__c)) {

            if (schoolsMap.containsKey(costLine.MOE_Id__c + '-' + costLine.MoE_Site_Id__c)) {

                return schoolsMap.get(costLine.MOE_Id__c + '-' + costLine.MoE_Site_Id__c);
            }
        }

        // Failing all else, return on the description/school name
        return schoolsMap.get(costLine.School_Name__c);
    }   

    /**
    * @author Ben Edwards (beedwards@deloitte.co.nz)
    * @date 12th June 2020
    * @description Build a cost line from the CSV row
    **/
    public Billing_Recon_Statement_Cost__c newCostLine (List<String> csvRowData) {

        // The cost line to return
        Billing_Recon_Statement_Cost__c costLine = new Billing_Recon_Statement_Cost__c();
        costLine.Billing_Recon_Statement__c = service.billingReconStatement.Id;

        // Iterate over the columns and map to the Salesforce field
        for (Integer columnIndex = 0; columnIndex < csvRowData.size(); columnIndex++) {

            // Retrieve the value
            String value = csvRowData[columnIndex].trim();

            // If this is the first column, we need to do a split to process the values correct
            if (columnIndex == 0) {

                // First line is already description
                costLine.Node_Description__c = value;

                // Split the based on spaces
                List<String> descriptionParts = value.split(' ');

                // IF there's at least 3 items, we can
                // assume there's the MoE Id and SIte
                // But not necessarily...
                if (descriptionParts.size() >= 3) {

                    // If the first element is numeric, we can assume
                    // we have a successful school id match
                    if (descriptionParts[0].isNumeric()) {

                        costLine.MOE_Id__c = descriptionParts.remove(0);
                        costLine.MoE_Site_Id__c = descriptionParts.remove(0);
                        costLine.School_Name__c = String.join(descriptionParts, ' ');
                    }
                    else {

                        // Otherwise, dump the school name from the full description
                        costLine.School_Name__c = value;
                    }
                } 
                else {

                    costLine.School_Name__c = value;
                }
            }
            // Otherwise, we just do a straight mapping of index to 
            else {

                // Get the header name based on the index
                String headerName = headers[columnIndex].trim();
                
                // Retrieve the target field name, based on the header name
                String fieldName = BillingReconUploadService.columnHeaderToField.get(headerName);

                // Only process if the field has a matching Salesforce field, and exists on the object
                if (String.isNotBlank(fieldName) && billingReconStatementCostFields.contains(fieldName.toLowerCase())) {

                    costLine.put(
                        fieldName,
                        BillingReconUploadService.getValue(fieldName, csvRowData[columnIndex])
                    );
                }
            }
        }   

        return costLine;
    }

    /**
    * @author Ben Edwards (beedwards@deloitte.co.nz)
    * @date 12th June 2020
    * @description Build an error record for a failing CSV row
    **/
    public Billing_Recon_Error__c createError (Integer lineNumber, String error) {

        return new Billing_Recon_Error__c(
            Billing_Recon_Statement__c = service.billingReconStatement.Id,
            CSV_Row__c = lineNumber,
            Error_Message__c = error
        );
    }

    /**
    * @author Ben Edwards (beedwards@deloitte.co.nz)
    * @date 12th June 2020
    * @description Process the upsert results
    **/
    public void processUpsertResults (
        List<Billing_Recon_Statement_Cost__c> statementCosts, 
        List<Database.UpsertResult> upsertResults, 
        List<Billing_Recon_Error__c> csvRowErrors
    ) {

        // Process any errors
        for (Integer i = 0; i < upsertResults.size(); i++) {

            if (!upsertResults[i].isSuccess()) {

                // Raise an error against the line
                List<String> errors = new List<String>();

                for (Database.Error error :upsertResults[i].getErrors()) {

                    errors.add(error.getMessage());
                }

                // Create an error for the CSV line
                csvRowErrors.add(createError(
                    (Integer) statementCosts[i].CSV_Row__c,
                    String.join(errors, '\n- ')
                ));
            }
            else {

                // Set the statement date based on the CSV line
                // All CSV Lines should have the same statement date so shouldn't matter
                service.billingReconStatement.Date__c = statementCosts[i].Statement_Date__c;
            }
        }

        if (!csvRowErrors.isEmpty()) {

            insert csvRowErrors;
        }
    }
    
}