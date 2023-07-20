@isTest
public class SupportHubUserSetupControllerTest {
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
        //newCampaigns.add(TestClassUtility.createCampaign('Filtering Portal (Pilot)', '', 'Filtering Portal', 'Onboarding', 'In Progress', 'Generic Campaign'));
        //newCampaigns.add(TestClassUtility.createCampaign('Identity Awareness (Pilot)', '', 'Identity Awareness', 'Onboarding', 'In Progress', 'Generic Campaign'));
        //newCampaigns.add(TestClassUtility.createCampaign('School Reporting (Pilot)', '', 'School Reporting', 'Onboarding', 'In Progress', 'Generic Campaign'));
        //newCampaigns.add(TestClassUtility.createCampaign('NHR (Pilot)', Helper.getProgrammeNameMapping().get('NHR').Programme__c, 'Managed Network To The Classroom', 'Onboarding', 'In Progress', 'Generic Campaign'));
        //newCampaigns.add(TestClassUtility.createCampaign('NSE (Pilot)', Helper.getProgrammeNameMapping().get('NSE').Programme__c, 'Managed Network Extension', 'Onboarding', 'In Progress', 'Generic Campaign'));
        //due to product__c picklist value change:
        newCampaigns.add(TestClassUtility.createCampaign('NHR (Pilot)', Helper.getProgrammeNameMapping().get('NHR').Programme__c, 'Support Hub', 'Onboarding', 'In Progress', 'Generic Campaign'));
        insert newCampaigns;
        
    }
    static testMethod void getTokenTest(){
        String demojwt1 ='XrdmboBBn9kmEo0EoqBCLwm65unTds_t_jFa3aItG0EZxhH05PgiMfNiaID_SnTzrVUHD7i8mzy09K6vNYSowsBJ3nb99x0leILsXlDb9P44vHEARi5ozTWv6VPQTLttpYSHED2mFtnuNhbgQX7kFPsIO89CVw0kuoP1hDqdfNZZFGvFo5dVYxpr3VOtsjg57dPnbIi5VMqr2e86lkTXc97AeIpykYoOPszBa-apgS0c0btSBDR0bn_33yYOshnr';
        String demojwt2 ='1871418192';
        String type='Verification Code';
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
        system.debug('@@!!!campaignAccountContact'+testResponse); 
        system.assertEquals(201, testResponse.statuscode);
        SupportHubUserSetupController shusc = new SupportHubUserSetupController();
        Boolean isEncrypted = true;
        //String type = 'Verification Code';
        SupportHubUserSetupController.testJWT = JWTController.decodeJWT(type, demojwt1, isEncrypted);  
        system.debug('testJWT JWT=:'+SupportHubUserSetupController.testJWT); 
        SupportHubUserSetupController.testJWT.verified = true;
        SupportHubUserSetupController.testJWT.expired = false;
        SupportHubUserSetupController.getTokenRecord(demojwt1, Type);
        SupportHubUserSetupController.testJWT.verified = false;
        SupportHubUserSetupController.testJWT.expired = true;
        SupportHubUserSetupController.getTokenRecord(demojwt1, Type);
        
    }
    static testMethod void schoolContactUpdateTest(){
        String demojwt1 ='XrdmboBBn9kmEo0EoqBCLwm65unTds_t_jFa3aItG0EZxhH05PgiMfNiaID_SnTzrVUHD7i8mzy09K6vNYSowsBJ3nb99x0leILsXlDb9P44vHEARi5ozTWv6VPQTLttpYSHED2mFtnuNhbgQX7kFPsIO89CVw0kuoP1hDqdfNZZFGvFo5dVYxpr3VOtsjg57dPnbIi5VMqr2e86lkTXc97AeIpykYoOPszBa-apgS0c0btSBDR0bn_33yYOshnr';
        String demojwt2 ='1871418192';
        String type='Verification Code';
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
        system.debug('@@!!!campaignAccountContact'+testResponse); 
        system.assertEquals(201, testResponse.statuscode);
        Token__c token = testResponse.token;
        token.JWT1__c = demojwt1;
        token.JWT2__c = demojwt2;
        token.Approver__c = contact.id;
        update token;
        SupportHubUserSetupController shusc = new SupportHubUserSetupController();
        SupportHubUserSetupController.testRes = testResponse;
        SupportHubUserSetupController.testRes.setStatus(200);
        Boolean isEncrypted = true;
        Map<String, Object> claimsMap = new Map<String, Object>();
        claimsMap.put('response', 'confirmed');
        //claimsMap.put('attribute2', 'value2');
        //claimsMap.put('attribute3', 'value3');
        SupportHubUserSetupController.SchoolContactsUpdate_Confirm_or_Update(claimsMap);
        token.isclosed__c=true;
        SupportHubUserSetupController.SchoolContactsUpdate_Confirm_or_Update(claimsMap);
        SupportHubUserSetupController.testRes.setStatus(600);
        SupportHubUserSetupController.SchoolContactsUpdate_Confirm_or_Update(claimsMap);
        claimsMap.put('response', 'updated');
        SupportHubUserSetupController.testRes.setStatus(200);
        SupportHubUserSetupController.SchoolContactsUpdate_Confirm_or_Update(claimsMap);
        token.isclosed__c=false;
        SupportHubUserSetupController.SchoolContactsUpdate_Confirm_or_Update(claimsMap);
        contact tempc = TestClassUtility.createContact(account.id, 'test01first', 'test01last', 'n4ltest01n4l@n4l.co.nz', '6492777777');
        insert tempc;
        token.Approver__c = tempc.id;
        update token;
        SupportHubUserSetupController.SchoolContactsUpdate_Confirm_or_Update(claimsMap);
        claimsMap.put('response', 'delegated');
        SupportHubUserSetupController.SchoolContactsUpdate_Confirm_or_Update(claimsMap);
    }
    static testMethod void setPasswordToken_actionsTest(){
        String demojwt1 ='XrdmboBBn9kmEo0EoqBCLwm65unTds_t_jFa3aItG0EZxhH05PgiMfNiaID_SnTzrVUHD7i8mzy09K6vNYSowsBJ3nb99x0leILsXlDb9P44vHEARi5ozTWv6VPQTLttpYSHED2mFtnuNhbgQX7kFPsIO89CVw0kuoP1hDqdfNZZFGvFo5dVYxpr3VOtsjg57dPnbIi5VMqr2e86lkTXc97AeIpykYoOPszBa-apgS0c0btSBDR0bn_33yYOshnr';
        String demojwt2 ='1871418192';
        String type='Verification Code';
        //create account, campaign, campaignAccount - for the campaignAccountContact
        Account account = [SELECT Id, Name FROM Account WHERE uuid__c = 'schoola'];
        Campaign campaign = [SELECT id, name, Programme__c, product__c, type, status, RecordTypeId FROM Campaign WHERE name = 'NHR (Pilot)'];
        Contact contact = [SELECT id, name, email, FirstName, LastName, AccountId, Business_Role__c FROM Contact WHERE email =: 'email2@invalid-domain.com'];
        contact.FirstName ='TestTokenFirst';
        contact.LastName ='TestTokenLast'; 
        update contact;
        Campaign_Account__c campaignAccount = TestClassUtility.createCampaignAccount(campaign, account);
        insert campaignAccount;
        Campaign_Account_Contact__c campaignAccountContact = TestClassUtility.createCampaignAccountContact(campaign, contact, campaignAccount);
        insert campaignAccountContact;
        campaignAccountContact = [SELECT Id, Campaign__c, Contact__c, Campaign_Account__r.Account__c  FROM Campaign_Account_Contact__c WHERE Id =: campaignAccountContact.Id];
        MethodResponse testResponse = CampaignController.createToken(campaignAccountContact, type);
        system.debug('@@!!!campaignAccountContact'+testResponse); 
        system.assertEquals(201, testResponse.statuscode);
        //Token__c token = testResponse.token;
        Token__c token = [select id,name,JWT1__c,JWT2__c,Approver__c,Approver__r.firstname,Approver__r.email,account__c from token__c where id=:testResponse.token.id];
        token.JWT1__c = demojwt1;
        token.JWT2__c = demojwt2;
        token.Approver__c = contact.id;
        token.approver__r.firstName='Tes F N';
        token.approver__r.email='testapprover01@n4l.co.nz';
        update token.approver__r;
        update token;
        SupportHubUserSetupController.testRes = testResponse;
        SupportHubUserSetupController.testRes.token=token;
        SupportHubUserSetupController.setPasswordToken_actions(contact.id,token.id,'test userOrigin');
        SupportHubUserSetupController.testRes.setStatus(200);
        SupportHubUserSetupController.create_SetPassword_Token(contact,type,token.id,'test userOrigin');
        SupportHubUserSetupController.testRes = testResponse;
        EmailTemplate testet = new EmailTemplate();
        testet.isActive = true;
        testet.Name = 'test Name';
        testet.HtmlValue ='{!Contact.FirstName}[hyperlink]';
        testet.Body = '{!Contact.FirstName}[hyperlink]';
        SupportHubUserSetupController.testRes.emailTemplate = testet;
        SupportHubUserSetupController.send_SchoolContactConfirmed_Email(token);
        token.Approver__c = null;
        update token;
        SupportHubUserSetupController.send_SchoolContactConfirmed_Email(token);
        SupportHubUserSetupController.InviteToCreateCustomerUser(contact.Id, true);
        SupportHubUserSetupController.InviteToCreateCustomerUser(null, true);
        SupportHubUserSetupController.InviteToCreateUser_email_actions(contact);
        contact tempc = TestClassUtility.createContact(account.id, 'test02first', 'test02last', 'n4ltest02n4l@n4l.co.nz', '6493777777');
        insert tempc;
        SupportHubUserSetupController.InviteToCreateCustomerUser(tempc.id, true);
        SupportHubUserSetupController.testRes.setStatus(500);
        SupportHubUserSetupController.InviteToCreateCustomerUser(contact.Id, true);
         SupportHubUserSetupController.testRes.token = null;
        SupportHubUserSetupController.setPasswordToken_actions(null,null,null);
    }
    
    static testMethod void send_InviteToCreateUser_EmailTest(){
        String demojwt1 ='XrdmboBBn9kmEo0EoqBCLwm65unTds_t_jFa3aItG0EZxhH05PgiMfNiaID_SnTzrVUHD7i8mzy09K6vNYSowsBJ3nb99x0leILsXlDb9P44vHEARi5ozTWv6VPQTLttpYSHED2mFtnuNhbgQX7kFPsIO89CVw0kuoP1hDqdfNZZFGvFo5dVYxpr3VOtsjg57dPnbIi5VMqr2e86lkTXc97AeIpykYoOPszBa-apgS0c0btSBDR0bn_33yYOshnr';
        String demojwt2 ='1871418192';
        String type='Verification Code';
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
        system.debug('@@!!!campaignAccountContact'+testResponse); 
        system.assertEquals(201, testResponse.statuscode);
        Token__c token = testResponse.token;
        token.JWT1__c = demojwt1;
        token.JWT2__c = demojwt2;
        token.Approver__c = contact.id;
        update token;
        SupportHubUserSetupController.testRes = testResponse;
        SupportHubUserSetupController.send_InviteToCreateUser_Email(contact,token);
        SupportHubUserSetupController.testRes.setStatus(200);
        EmailTemplate testet = new EmailTemplate();
        testet.isActive = true;
        testet.Name = 'test Name';
        testet.HtmlValue ='{!Contact.FirstName}[hyperlink]';
        testet.Body = '{!Contact.FirstName}[hyperlink]';
        SupportHubUserSetupController.testRes.emailTemplate = testet;
        SupportHubUserSetupController.send_InviteToCreateUser_Email(contact,token);
        Map<String, Object> claimsMap = new Map<String, Object>();
        claimsMap.put('response', 'confirmed');
        claimsMap.put('tokenId', token.id);
        SupportHubUserSetupController.RespondedToCreateUserByInvitation(claimsMap);
        token.IsClosed__c = true;
        SupportHubUserSetupController.RespondedToCreateUserByInvitation(claimsMap);
        contact tempc = TestClassUtility.createContact(account.id, 'test03first', 'test03last', 'n4ltest03n4l@n4l.co.nz', '6494777777');
        insert tempc;
        SupportHubUserSetupController.testRes.token.Approver__c = tempc.id;
        system.debug('debug in test for approver id:'+tempc.id);
        SupportHubUserSetupController.testRes.token.IsClosed__c = false;
        SupportHubUserSetupController.testRes.setStatus(200);
        SupportHubUserSetupController.RespondedToCreateUserByInvitation(claimsMap);
        
    }
}