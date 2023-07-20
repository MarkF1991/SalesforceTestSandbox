@isTest
public class SupportHubVerifyEmailControllerTest {
    @TestSetup
    
    private static void setup(){
        Account schoolAccount = TestClassUtility.createAccount('Baradene College',  'School');
        schoolAccount.uuid__c = 'schoola';
        schoolAccount.MoE_School_ID__c = '200';
        schoolAccount.Email_Domain__c = 'invalid-domain.com'; //for filtering portal access, the contact and user's email must have the same domain.
        insert schoolAccount;

        //there is a process/trigger on account that automatically create a principal contact at the time account record is created
        Contact principalContact = new Contact();
        List<Contact> contacts = [SELECT id, name, email, Business_Role__c, Current_Principal_Of_This_School__c FROM Contact WHERE AccountId =: schoolAccount.id and Current_Principal_Of_This_School__c = true];
        if (contacts.size()==1){
            //Contact principalContact = contacts[0];
            principalContact = contacts[0];
            principalContact.FirstName = 'FirstName1';
            principalContact.LastName = 'LastName1';
            principalContact.Email = 'email1@invalid-domain.com';
            update principalContact;
        } else {
            //create contacts in the school
            //Contact principalContact = TestClassUtility.createContact(schoolAccount.Id, 'FirstName1', 'LastName1', 'email1@invalid-domain.com', '02711111111', 'Principal', True);
            principalContact = TestClassUtility.createContact(schoolAccount.Id, 'FirstName1', 'LastName1', 'email1@invalid-domain.com', '02711111111', 'Principal', True);
            insert principalContact;    
        }


        List<Contact> newContacts = new List<Contact>();
        newContacts.add(TestClassUtility.createContact(schoolAccount.Id, 'FirstName2', 'LastName2', 'email2@invalid-domain.com', '02722222222', 'ICT Leader', False));
        newContacts.add(TestClassUtility.createContact(schoolAccount.Id, 'FirstName3', 'LastName3', 'email3@invalid-domain.com', '02733333333', 'External ICT', False));
        newContacts.add(TestClassUtility.createContact(schoolAccount.Id, 'FirstName4', 'LastName4', 'email4@invalid-domain.com', '02744444444', 'External ICT', False));
        

        Contact exPrincipalContact = TestClassUtility.createContact(schoolAccount.Id, 'FirstName5', 'LastName5', 'email5@invalid-domain.com', '02755555555', 'Principal', False);

        newContacts.add(exPrincipalContact);
        insert newContacts;
        List<Campaign> newCampaigns = new List<Campaign>();
        newCampaigns.add(TestClassUtility.createCampaign('Filtering Portal (Pilot)', '', 'Filtering Portal', 'Onboarding', 'In Progress', 'Generic Campaign'));
        newCampaigns.add(TestClassUtility.createCampaign('Identity Awareness (Pilot)', '', 'Internet Connection', 'Onboarding', 'In Progress', 'Generic Campaign'));
        newCampaigns.add(TestClassUtility.createCampaign('School Reporting (Pilot)', '', 'School Reporting', 'Onboarding', 'In Progress', 'Generic Campaign'));
        newCampaigns.add(TestClassUtility.createCampaign('NHR (Pilot)', Helper.getProgrammeNameMapping().get('NHR').Programme__c, 'Managed Network To The Classroom', 'Onboarding', 'In Progress', 'Generic Campaign'));
        newCampaigns.add(TestClassUtility.createCampaign('NSE (Pilot)', Helper.getProgrammeNameMapping().get('NSE').Programme__c, 'Internet Connection', 'Onboarding', 'In Progress', 'Generic Campaign'));

        insert newCampaigns;
        
    }
    
   
    
        
    static testMethod void generalTest(){
        String demojwt1 ='XrdmboBBn9kmEo0EoqBCLwm65unTds_t_jFa3aItG0EZxhH05PgiMfNiaID_SnTzrVUHD7i8mzy09K6vNYSowsBJ3nb99x0leILsXlDb9P44vHEARi5ozTWv6VPQTLttpYSHED2mFtnuNhbgQX7kFPsIO89CVw0kuoP1hDqdfNZZFGvFo5dVYxpr3VOtsjg57dPnbIi5VMqr2e86lkTXc97AeIpykYoOPszBa-apgS0c0btSBDR0bn_33yYOshnr';
        String demojwt2 ='1871418192';
        String type='School Contacts Update';
        //create account, campaign, campaignAccount - for the campaignAccountContact
        Account account = [SELECT Id, Name FROM Account WHERE uuid__c = 'schoola'];
        Campaign campaign = [SELECT id, name, Programme__c, product__c, type, status, RecordTypeId FROM Campaign WHERE name = 'NHR (Pilot)'];
        Contact contact = [SELECT id, name, email, FirstName, LastName, AccountId, Business_Role__c FROM Contact WHERE email =: 'email2@invalid-domain.com'];
        Campaign_Account__c campaignAccount = TestClassUtility.createCampaignAccount(campaign, account);
        insert campaignAccount;
        Campaign_Account_Contact__c campaignAccountContact = TestClassUtility.createCampaignAccountContact(campaign, contact, campaignAccount);
        insert campaignAccountContact;
        campaignAccountContact = [SELECT Id, Campaign__c, Contact__c, Campaign_Account__r.Account__c  FROM Campaign_Account_Contact__c WHERE Id =: campaignAccountContact.Id];
        MethodResponse testResponse = CampaignController.createToken(campaignAccountContact, type);
        system.assertEquals(201, testResponse.statuscode);
        system.debug('account debug :'+account);
        system.debug('campaign debug :'+campaign);
        system.debug('contact debug :'+contact);
        system.debug('campaignAccount debug :'+campaignAccount);
        system.debug('campaignAccountContact debug :'+campaignAccountContact);
        Token__c token = testResponse.token;
        token.JWT1__c = demojwt1;
        token.JWT2__c = demojwt2;
        update token;
        system.debug('token object debug :'+token);
        system.debug('token debug :'+token.JWT1__c);
        PageReference pageRef = Page.SupportHubVerifyEmail;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('t',demojwt1);
        SupportHubVerifyEmailController shusc = new SupportHubVerifyEmailController();
        shusc.initializeVariables();
        shusc.noVerificationCode = true;
        shusc.messageOnPage ='test message on page';
        SupportHubVerifyEmailController.ErrorFlags testerrors = shusc.errors;
        testerrors.termsNotAccepted = true;
        testerrors.verificationCodeErrors ='test verification code error';
        testerrors.verificationCodeHasError = false;
        system.assertNotEquals(null, testerrors);
        SupportHubVerifyEmailController.Verification testver = shusc.verification;
        testver.code = demojwt2;
        shusc.testRes.setStatus(200);
        system.assertNotEquals(null, testver);
        shusc.submit();
        token.IsClosed__c = true;
        update token;
        shusc.testRes.token=token;
        shusc.submit();
        token.IsClosed__c = false;
        update token;
        shusc.testRes.token=token;
        shusc.submit();
        testver.code = 'test code';
        shusc.submit();
        shusc.testRes.setStatus(400);
        shusc.submit();
    }
    
}