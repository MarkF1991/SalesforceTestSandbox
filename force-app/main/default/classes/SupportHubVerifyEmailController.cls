/**
* @author Ben Soh 
* @date 2021-02-25
* @description Controller for the SupportHubVerifyEmail page
*
* CHANGE LOG
**/
public without sharing class SupportHubVerifyEmailController {
    //Declare and initialize containers.
    
    public Boolean noVerificationCode {get;set;}
    public String messageOnPage {get;set;}
    public MethodResponse testRes = new MethodResponse();//temp var for test purpose
    public SupportHubVerifyEmailController() {
       
    }
    
    public string getDisplayMessageonPage(){
        string messageOnPage;
        //TODO: get Map<string, Support_Hub_User_Creation_Mapping__mdt> userCreationMap =  SupportHubUserNotificationController.getUserCreationMapping('origin');
        //to retrive string value from Message_on_Verify_Email_Page__c from custom metadata Support_Hub_User_Creation_Mapping__mdt 
        //then display the message on Visualforce Page
        String urlToken = System.currentPageReference().getParameters().get('t');
        MethodResponse res1 = SupportHubUserSetupController.getTokenRecord(urlToken, 'Verification Code');
        //a token record is returned from the res above
        Token__c token = res1.token;
        Contact contact = [SELECT id, UserOrigin__c FROM Contact WHERE id =: token.approver__c];

        Map<string, Support_Hub_User_Creation_Mapping__mdt> userCreationMap = SupportHubUserNotificationController.getUserCreationMapping('origin');

        if(contact.UserOrigin__c != null){
        Support_Hub_User_Creation_Mapping__mdt mapping = userCreationMap.get(contact.userOrigin__c);
        messageOnPage = mapping.Message_on_Verify_Email_Page__c;
        }else{
        Support_Hub_User_Creation_Mapping__mdt mapping = userCreationMap.get(token.userOrigin__c); 
        messageOnPage = mapping.Message_on_Verify_Email_Page__c;   
        }
        return messageOnPage;       
    } 

    public ErrorFlags errors {
        get {
            if (errors == null) {
                errors = new ErrorFlags();
            }
            return errors;
        }
        set;
    }

    public Verification verification {
        get {
            if (verification == null) {
                verification = new Verification();
            }
            return verification;
        }
        set;
    }

    public void initializeVariables() {
        verification = null;
        errors = null;
    }

    public class Verification {

        public String code {get;set;}

    }
    
   
    public class ErrorFlags {

        public String verificationCodeErrors {get;set;}
        public Boolean termsNotAccepted {get;set;}
        public Boolean verificationCodeHasError {get;set;}
    }

    public PageReference submit() {
        PageReference pageRef = ApexPages.currentPage();

        // Clear the errors, we need to re-evaluate them
        errors = null;

        try {

            
            // String p = System.currentPageReference().getParameters().get('p');
            String urlToken = System.currentPageReference().getParameters().get('t');
            String startURL = System.currentPageReference().getParameters().get('startURL');
            
            MethodResponse res1 = Test.isRunningTest()? testRes : SupportHubUserSetupController.getTokenRecord(urlToken, 'Verification Code');
            if(res1.statuscode == 200){
                
                //a token record is returned from the res above
                Token__c token = res1.token;

                if(token.IsClosed__c){
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Sorry, the session has already ended.'));
                    return null;
                }
                
                //match verification code from user input against the stored verification code in Token__c record
                if(this.verification.code == token.JWT2__c){
                    this.errors.verificationCodeHasError = false;

                    //generate another urlToken with shorter expiry for the next page
                    MethodResponse res2 = SupportHubUserSetupController.setPasswordToken_actions(token.Approver__c, token.Parent__c, token.UserOrigin__c); //passing contactId
                    urlToken = res2.token.JWT1__c;//get a new token with shorter expiry for user to provide and confirm password in order to create user

                    //navigate to the next page, with url parameter
                    //create the second part of url for LWC in request-authorisation page to navigate to
                    String pageRef_url = (Helper.isSandbox() ? '/schoolictsupport/' : '/') + 'supporthubsetpassword?t='  + urlToken + (startURL == null ? '' : '&startUrl=' + startURL);
                    // String pageRef_url = '';
                    // if(Helper.isSandbox()){
                    //     pageRef_url = '/schoolictsupport/supporthubsetpassword?t=' + urlToken + '&startUrl=/schoolictsupport/s/manage-contacts';
                    // } else {
                    //     //this is production
                    //     pageRef_url = '/supporthubsetpassword?t=' + urlToken + '&startUrl=/s/manage-contacts';
                    // }
                    
                    MethodResponse res3 = TokenController.closeToken(token.id, 'Responded');

                    //redirect
                    pageRef = new PageReference(pageRef_url);
                    pageRef.setRedirect(true);
                    

                } else {
                    errors.verificationCodeHasError = true;
                    errors.verificationCodeErrors = Label.Support_Hub_Verify_Email_Error_Verifying_Code;
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Support_Hub_Verify_Email_Error_Verifying_Code));
                    return null;
                }
                
            } else {
                errors.verificationCodeHasError = true;
                errors.verificationCodeErrors = res1.results.get('error');
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, res1.results.get('error')));
                return null;
                
            }

        }
        catch (Exception ex) {

            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Unexpected error occurred during email address verification'));
            return null;
            
        }
        return pageRef;
       
    }

    


}