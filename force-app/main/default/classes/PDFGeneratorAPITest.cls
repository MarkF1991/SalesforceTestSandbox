@IsTest
public class PDFGeneratorAPITest {
    @TestSetup
    private static void setup(){
        TestObjectFactoryForOnboarding.setupOnboardingRecords(True);
    }
    
    private static contract getUnitTestContract(){
        Account account = [SELECT Id, Name FROM Account WHERE uuid__c = 'schoola'];
        Opportunity opportunity = [SELECT Id, Name, Campaign.Programme__c, Campaign.Product__c, Campaign.Type, ContractId FROM Opportunity WHERE AccountId =: account.Id AND Campaign.Name = 'NHR (Pilot)']; //refer to createCampaing in Test Setup Method above
        Map<String,String> result = ContractController.getContract(opportunity.ContractId);
        Contract contract = (Contract) JSON.deserialize(result.get('contract'), Contract.class);
        Contact principal = (Contact) JSON.deserialize(result.get('principal'), Contact.class);
        
        //prepare contract variable to fulfill the validateContract() method
        contract.ActivatedDate = date.newinstance(2020, 10, 1);
        contract.CustomerSignedDate = date.newinstance(2020, 10, 1);
        contract.CustomerSignedTitle = 'principal';
        contract.CustomerSignedUser__c = UserInfo.getUserId();
        contract.Educount_Rolls__c = 1000;
        contract.Educount_Rolls_as_at__c = date.newinstance(2020, 7, 1);
        contract.School_Principal_Email__c = principal.Email;
        contract.School_Principal_Name__c = principal.Name;
        
        return contract;
    }
    
    
    
    
    static testMethod void test_PDFGeneratorAPI() {
        // Set the Mock Class
        Test.setMock(HttpCalloutMock.class, TestClassUtility.setStaticMock(200, 'ServiceEventPDFcreatedMock'));
        
        // //get contract
        // Account account = [SELECT Id, Name FROM Account WHERE uuid__c = 'schoola'];
        // Opportunity opportunity = [SELECT Id, Name, Campaign.Programme__c, Campaign.Product__c, Campaign.Type, ContractId FROM Opportunity WHERE AccountId =: account.Id AND Campaign.Name = 'NHR (Pilot)']; //refer to createCampaing in Test Setup Method above
        // Map<String,String> result = ContractController.getContract(opportunity.ContractId);
        // Contract contract = (Contract) JSON.deserialize(result.get('contract'), Contract.class);
        Contract contract = getUnitTestContract();//this contract must pass validation - missingContractRequiredFields()
        
        // Account account = [SELECT id, Name FROM Account WHERE uuid__c = 'schoola'];      
        // Contract contract = [SELECT id, Name FROM Contract WHERE AccountId =: account.id LIMIT 1];
        //-----------------------RequestBody Start------------------------
        //system.debug('contract'+contract);
        //String jsonContract = json.serialize(contract);
        JSONGenerator body = JSON.createGenerator(false);
        body.writeStartObject();
        body.writeObjectField('parameters', contract);
        body.writeEndObject();
        //-----------------------RequestBody End------------------------
        
        
        Test.startTest();
        MethodResponse res = PDFGeneratorAPI.generatePDF(contract);
        
        Test.stopTest();
        
        //there should be 1 file being created
        String searchFileName = '%' + 'Order Form - ' + contract.Product__c + '%';
        Map<Id, sObject> existingFilesOnContract = new Map<Id, sObject>();
        existingFilesOnContract = FileController.getAttachmentOrFileIds(contract.Id, new List<String>{searchFileName},'Both');
        system.assertEquals(1, existingFilesOnContract.size());  
        
        // System.assertEquals(200,response.getStatusCode());
        
        // // Verify status code
        System.assertEquals(200,res.statuscode);
        
        
    }
    
    static testMethod void test_PDFGeneratorAPI_error1() {
        // Set the Mock Class
        Test.setMock(HttpCalloutMock.class, TestClassUtility.setStaticMock(200, 'ServiceEventPDFcreatedMock'));
        
        
        Test.startTest();
        Account account = [SELECT Id, Name FROM Account WHERE uuid__c = 'schoola'];
        Opportunity opportunity = [SELECT Id, Name, Campaign.Programme__c, Campaign.Product__c, Campaign.Type, ContractId FROM Opportunity WHERE AccountId =: account.Id AND Campaign.Name = 'NHR (Pilot)']; //refer to createCampaing in Test Setup Method above
        
        Contract contract = getUnitTestContract(); //this contract will fail in validation step
        contract.CustomerSignedId = null;
        update contract;
        //-----------------------RequestBody Start------------------------
        
        //String jsonContract = json.serialize(contract);
        JSONGenerator body = JSON.createGenerator(false);
        body.writeStartObject();
        body.writeObjectField('parameters', contract);
        body.writeEndObject();
        //-----------------------RequestBody End------------------------
        
        MethodResponse res = PDFGeneratorAPI.generatePDF(contract);
        
        //should fail in validation step
        System.assertEquals(500,res.statuscode);
        
        
        Test.stopTest();
    }
    
    static testMethod void test_PDFGeneratorAPI_error2() {
        // Set the Mock Class
        Test.setMock(HttpCalloutMock.class, TestClassUtility.setStaticMock(400, 'ServiceEventPDFcreatedMock'));
        
        Test.startTest();
        Contract contract = getUnitTestContract();//this contract must pass validation - missingContractRequiredFields()
        
        //-----------------------RequestBody Start------------------------
        
        //String jsonContract = json.serialize(contract);
        JSONGenerator body = JSON.createGenerator(false);
        body.writeStartObject();
        body.writeObjectField('parameters', contract);
        body.writeEndObject();
        //-----------------------RequestBody End------------------------
        
        MethodResponse res = PDFGeneratorAPI.generatePDF(contract);
        
        
        System.assertEquals(400,res.statuscode);
        
        
        Test.stopTest();
    }
    
    
}