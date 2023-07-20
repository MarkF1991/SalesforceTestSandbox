/**
* @author Carolyn Hayward (micado@n4l.co.nz)
* @date 2022-12-16
* @description  invoked by flow to resend request to generate order form PDF
*
* CHANGE LOG
* **/

global class generateOrderFormAsPDF {
    @InvocableMethod(label='Get Order Form PDF' 
                     description='Callout to salesforce-sync-app to render contract Order Form as PDF' 
                     category='Contract')
    public static List<result> getContractPDFs(List<Request> requests) {
        List<result> results = new List<result>();
        for (Request request : requests) {
            results.add(getPDF(request));
        }
        return results;
    }
    
    public static result getPDF(Request request) {
        result r = new result();
        try {
            //get contract again to retrieve fields from related objects (e.g. Account.Name)
             Contract c = [SELECT  Id, Name, AccountId, Account.Name, Account.MoE_School_ID__c, ActivatedDate, Contract_Type__c, CustomerSignedDate, CustomerSignedId, CustomerSigned.Name, CustomerSigned.FirstName, CustomerSigned.Email, CustomerSignedTitle, MoE_Project_Manager__c, MoE_Project_Manager__r.Name, MoE_Project_Manager__r.Email, MoE_Signatory__c, MoE_Signatory__r.Name, MoE_Signatory__r.Email, Per_Pupil_Contribution__c, Annual_Contribution__c, Order_Total_Amount__c, Programme__c, Status, StatusCode, Accepted_N4L_Terms_and_Conditions__c, Accepted_N4LCharges_Terms_and_Conditions__c, Accepted_MoE_Terms_and_Conditions__c, N4L_Signatory_Name__c, N4L_Signatory_Email__c, MoE_Party_Name__c, MoE_Party_Email__c, School_Principal_Name__c, School_Principal_Email__c, OwnerId, Account.Owner.Name, Account.Owner.MobilePhone, CustomerSignedUser__c, Product__c, Educount_Rolls__c ,Account.School_Nominated_ICT_Provider__r.Name, Educount_Rolls_as_at__c
             FROM Contract WHERE Id = :request.contract.Id LIMIT 1];
            //Map<string, string> result = ContractController.getContract(request.contract.Id);
        
            //to call Platform Services API to asynchronously generate PDF
            ServiceEventContractController.GeneratePDF(c); 
        } catch (exception e) {
            r.status = 'ERROR';
            r.message = e.getMessage();
            return r;
        }
        r.status = 'SUCCESS';
        return r;
    }
    
    public class result {
        @InvocableVariable
        public String status;
        @InvocableVariable
        public String message;
        
    }    
    
    public class request{
        @InvocableVariable(label='Contract record' description='The contract record for the Order Form PDF generation' required=true)
        public Contract contract;    
    }
}