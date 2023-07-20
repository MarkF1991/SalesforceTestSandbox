/**
* @author Ben Edwards (beedwards@deloitte.co.nz)
* @date 30th July 2020
* @description Utility class for the Billing Recon test data
*
* CHANGE LOG
**/
@isTest 
public class BillingReconTestData {
    
    /**
    * 	@author Ben Edwards (beedwards@deloitte.co.nz)
    *	@description Create Billing Recon Categorisation Rules and Conditions
    **/
    public static List<Billing_Recon_Categorisation_Rule__c> createBillingCategorisationRules () {

        // Generate the conditions
        List<Billing_Recon_Categorisation_Rule__c> rules = new List<Billing_Recon_Categorisation_Rule__c>{
            new Billing_Recon_Categorisation_Rule__c(Charge_Category__c = 'LFC', Priority__c = 2),
            new Billing_Recon_Categorisation_Rule__c(Charge_Category__c = 'CLNE', Priority__c = 3),
            new Billing_Recon_Categorisation_Rule__c(Charge_Category__c = 'Safe & Secure', Priority__c = 4),
            new Billing_Recon_Categorisation_Rule__c(Charge_Category__c = 'Safe & Secure 2.0', Priority__c = 1, Conditions__c = 'Any')
        };

        insert rules;

        List<Billing_Recon_Categorisation_Condition__c> conditions = new List<Billing_Recon_Categorisation_Condition__c>{
            new Billing_Recon_Categorisation_Condition__c(
                Billing_Recon_Categorisation_Rule__c = rules[0].Id,
                Field_Name__c = 'Description__c',
                Operator__c = 'Equals',
                Value__c = 'LFC'
            ),
            new Billing_Recon_Categorisation_Condition__c(
                Billing_Recon_Categorisation_Rule__c = rules[1].Id,
                Field_Name__c = 'Description__c',
                Operator__c = 'Contains',
                Value__c = 'CLNE'
            ),
            new Billing_Recon_Categorisation_Condition__c(
                Billing_Recon_Categorisation_Rule__c = rules[2].Id,
                Field_Name__c = 'Description__c',
                Operator__c = 'Starts With',
                Value__c = 'Safe & Secure'
            ),
            new Billing_Recon_Categorisation_Condition__c(
                Billing_Recon_Categorisation_Rule__c = rules[3].Id,
                Field_Name__c = 'Description__c',
                Operator__c = 'Does Not Equal',
                Value__c = 'Safe & Secure 2.0'
            ),
            new Billing_Recon_Categorisation_Condition__c(
                Billing_Recon_Categorisation_Rule__c = rules[3].Id,
                Field_Name__c = 'Description__c',
                Operator__c = 'Does Not Contain',
                Value__c = 'Safe & Secure 2.0'
            ),
            new Billing_Recon_Categorisation_Condition__c(
                Billing_Recon_Categorisation_Rule__c = rules[3].Id,
                Field_Name__c = 'Description__c',
                Operator__c = 'Equals',
                Value__c = 'Safe & Secure 2.0'
            )
        };
        
        insert conditions;

        return rules;
    }

    /**
    * 	@author Ben Edwards (beedwards@deloitte.co.nz)
    *	@description Create Billing Recon pricebook and products
    **/
    public static void createBillingReconProducts () {

        Pricebook2 testBillingPricebook = new Pricebook2();
        testBillingPricebook.Name = 'Billing Pricebook';
        testBillingPricebook.IsActive = true;
        testBillingPricebook.Is_Billing_Price_Book__c = true;
        insert testBillingPricebook;

        List<Product2> products = new List<Product2>{
            new Product2(
                Name = 'Save & Secure Internet',
                IsActive = true,
                Product_Type__c = 'Save & Secure Internet',
                ProductCode = 'SSINTNET'
            ),
            new Product2(
                Name = 'LFC',
                IsActive = true,
                ProductCode = 'LFC',
                Initiative__c = 'RBI',
                Service_Bandwidth__c = '1Gbps',
                LFC_Provider__c = 'Chorus',
                LFC_Provider_Access_Type__c = 'BS4'
            )
        };

        insert products;

        List<PriceBookEntry> standardPBEs = new List<PricebookEntry>();

        for (Product2 product :products) {

            standardPBEs.add(new PriceBookEntry(
                Product2Id = product.Id,
                Pricebook2Id = Test.getStandardPricebookId(),
                IsActive = true,
                UnitPrice = 100
            ));
        }

        insert standardPBEs;

        List<PriceBookEntry> billingPBEs = new List<PricebookEntry>();

        for (Product2 product :products) {

            billingPBEs.add(new PriceBookEntry(
                Product2Id = product.Id,
                Pricebook2Id = testBillingPricebook.Id,
                IsActive = true,
                UnitPrice = 100
            ));
        }

        insert billingPBEs;
    }



    /**
    * 	@author Ben Edwards (beedwards@deloitte.co.nz)
    *	@description Create a Billing Recon Statement
    **/
    public static Billing_Recon_Statement__c createBillingReconStatement() {

        Billing_Recon_Statement__c testStatement = new Billing_Recon_Statement__c();
        insert testStatement;

        return testStatement;
    }

    /**
    * 	@author Ben Edwards (beedwards@deloitte.co.nz)
    *	@description Create a Billing Statement CSV file
    **/
    public static void createBillingReconCSV(Id billingReconStatementId) {

        // Example CSV file
        String csvFile = 
            'Node Description,GL Code,Statement Date,Account Number,Line Number,Charge Type,From Date,To Date,Description,Product/Service,GST Indicator,Charge,MAC\n' +
            '3508 2043 Baradene College,3508 2043,6/05/20,307211548,N4L 120947447,Additional Services,28/04/20,30/04/20,Safe & Secure 2.0,Connectivity,N,$9.65,\n' +
            '3508 2043 Baradene College,3508 2043,6/05/20,307211548,N4L 120947447,Additional Services,1/05/20,31/05/20,LFC,Connectivity,N,$120.00,\n' +
            '3508 2043 Baradene College,3508 2043,6/05/20,307211548,N4L 120947447,Additional Services,1/05/20,31/05/20,CLNE,Connectivity,N,$151.00,\n' +
            '3508 2043 Baradene College,3508 2043,6/05/20,307211548,N4L 120947447,Additional Services,1/05/20,31/05/20,Safe & Secure,Connectivity,N,$96.50,\n' +
            'XXXX NOT FOUND,3508 2043,6/05/20,307211548,"N4L, 120947447",Additional Services,1/05/20,31/05/20,Safe & Secure,Connectivity,N,$96.50,\n';

        // Generate the file
        ContentVersion testContentVersion = new ContentVersion(
            Title = 'Test CSV',
            VersionData = Blob.valueOf(csvFile),
            PathOnClient = 'testfile.csv'
        );
        insert testContentVersion;

        // Retrieve the Content Document ID
        Id contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :testContentVersion.Id].ContentDocumentId;

        insert new ContentDocumentLink(
            ContentDocumentId = contentDocumentId,
            LinkedEntityId = billingReconStatementId,
            ShareType = 'I',
            Visibility = 'AllUsers'
        );
    }

    /**
    * 	@author Ben Edwards (beedwards@deloitte.co.nz)
    *	@description Create a test Statement Account
    **/
    public static Billing_Recon_Statement_Account__c createBillingReconSchool (Id statementId, Id accountId) {

        Billing_Recon_Statement_Account__c testStatementSchool = new Billing_Recon_Statement_Account__c();
        testStatementSchool.Billing_Recon_Statement__c = statementId;
        testStatementSchool.Account__c = accountId;
        insert testStatementSchool;

        return testStatementSchool;
    }

    /**
    * 	@author Ben Edwards (beedwards@deloitte.co.nz)
    *	@description Create a test Statement Cost
    **/
    public static List<Billing_Recon_Statement_Cost__c> createBillingReconCosts (Id statementId, Id schoolId) {

        List<Billing_Recon_Statement_Cost__c> charges = new List<Billing_Recon_Statement_Cost__c>{
            new Billing_Recon_Statement_Cost__c(
                Billing_Recon_Statement__c = statementId,
                Statement_Account__c = schoolId,
                Charge__c = 100,
                CSV_Row__c = 1,
                Description__c = 'CLNE',
                From_Date__c = System.today().toStartOfMonth(),
                To_Date__c = System.today().addMonths(1).toStartOfMonth().addDays(-1),
                MOE_Id__c = '200',
                MoE_Site_Id__c = '10',
                School_Name__c = 'Baradene College',
                Charge_Category__c = 'LFC'
            ),
            new Billing_Recon_Statement_Cost__c(
                Billing_Recon_Statement__c = statementId,
                Statement_Account__c = schoolId,
                Charge__c = 200,
                CSV_Row__c = 2,
                Description__c = 'Safe & Secure 2.0',
                From_Date__c = System.today().toStartOfMonth(),
                To_Date__c = System.today().addMonths(1).toStartOfMonth().addDays(-1),
                MOE_Id__c = '200',
                MoE_Site_Id__c = '10',
                School_Name__c = 'Baradene College',
                Charge_Category__c = 'CLNE'
            ),
            new Billing_Recon_Statement_Cost__c(
                Billing_Recon_Statement__c = statementId,
                Statement_Account__c = schoolId,
                Charge__c = 300,
                CSV_Row__c = 3,
                Description__c = 'Safe & Secure',
                From_Date__c = System.today().toStartOfMonth(),
                To_Date__c = System.today().addMonths(1).toStartOfMonth().addDays(-10),
                MOE_Id__c = '200',
                MoE_Site_Id__c = '10',
                School_Name__c = 'Baradene College',
                Charge_Category__c = 'Safe & Secure'
            ),
            new Billing_Recon_Statement_Cost__c(
                Billing_Recon_Statement__c = statementId,
                Statement_Account__c = schoolId,
                Charge__c = 300,
                CSV_Row__c = 4,
                Description__c = 'Safe & Secure 2.0',
                From_Date__c = System.today().toStartOfMonth(),
                To_Date__c = System.today().addMonths(1).toStartOfMonth().addDays(-10),
                MOE_Id__c = '200',
                MoE_Site_Id__c = '10',
                School_Name__c = 'Baradene College',
                Charge_Category__c = 'Safe & Secure 2.0'
            )
        };

        insert charges;

        return charges;
    }


    /**
    * 	@author Ben Edwards (beedwards@deloitte.co.nz)
    *	@description Create data required for the Billing Reconciliation process
    **/
    public static Billing_Recon_Statement__c createBillingReconData() {

        // Create the School Account
        Account schoolAccount = TestClassUtility.createAccount('Baradene College',  'School');
        schoolAccount.uuid__c = 'schoola';
        schoolAccount.MoE_School_ID__c = '200';
        schoolAccount.Email_Domain__c = 'invalid-domain.com';
        schoolAccount.Billing_Initiative__c = 'RBI';
        schoolAccount.Current_Connection_Bandwidth__c = '1Gbps';
        schoolAccount.LFC_Provider__c = 'Chorus';
        schoolAccount.LFC_Provider_Access_Type__c = 'BS4';
        insert schoolAccount;

        // Create the categorisation rules
        createBillingCategorisationRules();

        // Create Products and pricebooks
        createBillingReconProducts();

        // Create a Billing Recon statement
        Billing_Recon_Statement__c testStatement = createBillingReconStatement();

        // Create a test CSV
        createBillingReconCSV(testStatement.Id);

        return testStatement;
    }
}