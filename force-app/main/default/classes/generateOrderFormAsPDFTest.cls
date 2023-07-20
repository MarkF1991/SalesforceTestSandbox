@IsTest
public class generateOrderFormAsPDFTest {
 @TestSetup
    private static void setup(){
        TestObjectFactoryForOnboarding.setupOnboardingRecords(true); //Parameter False is for not creating Onboarding Case, Tasks, and Contract so that we can test it here.
    }
    
    private static contract getUnitTestContract(){
        Account account = [SELECT Id, Name FROM Account WHERE uuid__c = 'schoola'];
        Opportunity opportunity = [SELECT Id, Name, Campaign.Programme__c, Campaign.Product__c, Campaign.Type, ContractId FROM Opportunity WHERE AccountId =: account.Id AND Campaign.Name = 'NHR (Pilot)']; //refer to createCampaing in Test Setup Method above
        Map<String,String> mapContractRoles = ContractController.getContract(opportunity.ContractId);
        Contract contract = (Contract) JSON.deserialize(mapContractRoles.get('contract'), Contract.class);
        Contact principal = (Contact) JSON.deserialize(mapContractRoles.get('principal'), Contact.class);
        
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
    
	public static testMethod void test_GeneratePDF_success() {
        Contract contract = getUnitTestContract();//this contract must pass validation - missingContractRequiredFields()
        List<generateOrderFormAsPDF.request> requests = new List<generateOrderFormAsPDF.request>(); //request from flow
        generateOrderFormAsPDF.request r = new generateOrderFormAsPDF.request();
        r.contract = contract;
        requests.add(r);
        Test.setMock(HttpCalloutMock.class, TestClassUtility.setStaticMock(200, 'ServiceEventPDFcreateResponseMock'));
        
        system.Test.startTest();
        
        List<generateOrderFormAsPDF.result> results = generateOrderFormAsPDF.getContractPDFs(requests);//to call generate PDF
        
        system.Test.stopTest();
        
        
        List<Service_Event__c> events = [SELECT Id FROM Service_Event__c];
        system.assertEquals(1, events.size());
        system.assertEquals(results[0].status, 'SUCCESS');
        
    }    
    
    public static testMethod void test_GeneratePDF_error() {
        Contract contract = new Contract(); //this contract will fail validation - missingContractRequiredFields()
        
        List<generateOrderFormAsPDF.request> requests = new List<generateOrderFormAsPDF.request>(); //request from flow
        generateOrderFormAsPDF.request r = new generateOrderFormAsPDF.request();
        r.contract = null;
        requests.add(r);
        //Test.setMock(HttpCalloutMock.class, TestClassUtility.setStaticMock(400, 'ServiceEventPDFcreateResponseMock'));
        
        system.Test.startTest();
        
        List<generateOrderFormAsPDF.result> results = generateOrderFormAsPDF.getContractPDFs(requests);//to call generate PDF
        
        system.Test.stopTest();
        
        system.assertEquals(results[0].status, 'ERROR');
        system.assert(results[0].message.length() > 0);
        
    }
    
}