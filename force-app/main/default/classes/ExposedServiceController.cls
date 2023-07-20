public class ExposedServiceController {
//Queuable Apex
    // public class CampaignEmailQueue implements Queueable {
       
    //     Private List<Campaign_Account_Contact__c> CampaignAccountContacts;
    //     Private String partialURL;

    //     public CampaignEmailQueue(List<Campaign_Account_Contact__c> CampaignAccountContacts, String partialURL){
    //         this.CampaignAccountContacts = CampaignAccountContacts;  
    //         this.partialURL = partialURL;
    //     }
    //     public void execute(QueueableContext context) {
    
    //         for(Campaign_Account_Contact__c CampaignAccountContact : CampaignAccountContacts){
    //             //Send email 
    //             campaign_email_actions(CampaignAccountContact, partialURL);
    //         }
    //     }
    // }

    //@AuraEnabled() //LWC will call this method to send email
    // public static string campaign_email(Campaign_Account_Contact__c CampaignAccountContact, String partialURL){
    //     MethodResponse res = campaign_email_actions(CampaignAccountContact, partialURL );
    //
    //       return res.getJSONstring(); 
    //   }

    @AuraEnabled
    public static Map<String,String> sendCampaignEmail (Id campaignId, String mode) {
        Map<String,String> result = new Map<String,String>();
        MethodResponse res = new MethodResponse();
        
        //TODO: 
        Id batchJobId = Database.executeBatch(new ExposedServiceContactsBatch(campaignId), 5);
        
        res.setStatus(200);
        result.put('response', res.getJSONstring());

        return result;
    }

    @AuraEnabled
    public static Map<String,String> getCampaignAccounts (Id campaignId, String input) {
        Map<String,String> result = new Map<String,String>();
        MethodResponse res = new MethodResponse();

        //existing Campaign Account
        List<Campaign_Account__c> existingCampaignAccounts = [SELECT Id, Campaign__c, Account__c, Name, Campaign__r.Name, Account__r.Name FROM Campaign_Account__c WHERE Campaign__c =: CampaignId];

        Set<Id> existingAccountIds = new Set<Id>();

        for(Campaign_Account__c campaignAccount : existingCampaignAccounts){
            existingAccountIds.add(campaignAccount.Account__c);
        }
        System.debug('existingAccountIds: '+ existingAccountIds);
        //moeExternalId
        Set<String> moeExternalIds = new Set<String>();

        if(String.isBlank(input)){
            res.setStatus(400);
            result.put('response', res.getJSONstring());

            return result;
           
        }

        //loop through 
        for(String moeExternalId : input.split(',')){
            moeExternalIds.add(moeExternalId);
        }

        List<Account> accounts = [SELECT Id, name, MoE_External_ID__c FROM Account WHERE MoE_External_ID__c IN: moeExternalIds];
        List<Campaign_Account__c> campaignAccounts = new List<Campaign_Account__c>();
        Campaign campaign = [SELECT Id, name FROM Campaign WHERE Id =: campaignId];
        System.debug('accounts: '+ accounts);
        if(!accounts.isEmpty()){
            for(Account account : accounts){
                if(!existingAccountIds.contains(account.Id)){
                    campaignAccounts.add(new Campaign_Account__c (Campaign__c = campaignId, Account__c = account.Id));
                }      
            }
            insert campaignAccounts;
        }
      
        campaignAccounts = [SELECT Id, Campaign__c, Campaign__r.Name, Name, Account__c, Account__r.Name, Account__r.MoE_External_ID__c FROM Campaign_Account__c WHERE Campaign__c =: CampaignId];
        System.debug('campaignAccounts: '+ campaignAccounts);
        res.setStatus(200);
        result.put('response', res.getJSONstring());
        result.put('campaignAccounts', JSON.serialize(campaignAccounts));


        return result;
    }
    
    @AuraEnabled
    //Get getCampaignAccountContacts
    public static Map<string,string> getCampaignAccountContacts (Id campaignId){
        Map<String,String> result = new Map<String,String>();
        MethodResponse res = new MethodResponse();

        Campaign campaign = [SELECT id, name, Email_Targetted_Roles__c FROM Campaign WHERE id =: campaignId];

        //existing Campaign Account
        List<Campaign_Account__c> campaignAccounts = [SELECT Id, Campaign__c, Account__c FROM Campaign_Account__c WHERE Campaign__c =: campaign.id];
        
        //accountId, campaignAccount
        Map<String, Campaign_Account__c> campaignAccountsMap = new Map<String, Campaign_Account__c>();

        for(Campaign_Account__c campaignAccount : campaignAccounts){
            campaignAccountsMap.put(campaignAccount.Account__c, campaignAccount);
  
        }
        //Roles in Email Targeted Roles
        List<String> sendToRolesList = campaign.Email_Targetted_Roles__c.split(';');
        List<AccountContactRelation> accountContactRelations =[SELECT Id, accountId, contactId, Roles, isActive FROM AccountContactRelation WHERE accountId IN: campaignAccountsMap.keyset() ORDER BY Role_Sorting__c];
        system.debug('@@##!!ACR:'+accountContactRelations);
       
        //create Campaign_Account_Contact__c
        List<Campaign_Account_Contact__c> CampaignAccountContacts = new List<Campaign_Account_Contact__c>();

        for(AccountContactRelation accountContactRelation : accountContactRelations){
            if(accountContactRelation.roles != null && accountContactRelation.isActive == true){
            for(string roles : sendToRolesList){
                if(accountContactRelation.roles.contains(roles)==true){
            CampaignAccountContacts.add(new Campaign_Account_Contact__c(Campaign__c = campaign.Id, Account__c = campaignAccountsMap.get(accountContactRelation.accountId).account__c, Contact__c = accountContactRelation.contactId, 
            Campaign_Account__c = campaignAccountsMap.get(accountContactRelation.accountId).id, 
            External_Id__c = String.valueof(campaign.Id) + String.valueof(campaignAccountsMap.get(accountContactRelation.accountId).account__c) + String.valueof(accountContactRelation.contactId)));
                     break;
                }
            }
            }
        }
        upsert CampaignAccountContacts External_Id__c;
        

        CampaignAccountContacts = [SELECT Campaign__c, Account__c, Contact__c, Campaign_Account__c, External_Id__c FROM Campaign_Account_Contact__c WHERE Campaign__c =: campaign.Id];

        if(CampaignAccountContacts.size()<1){
            res.setStatus(400);
            result.put('response', res.getJSONstring());

            return result;
           
        }
        
        res.setStatus(200);
        result.put('response', res.getJSONstring());
        result.put('campaignAccountContacts', JSON.serialize(CampaignAccountContacts));


        return result;
    }

    //main method for sending email
    public static MethodResponse campaign_email_actions(Campaign_Account_Contact__c CampaignAccountContact, String partialURL,Boolean isDelegate){
        MethodResponse res = new MethodResponse();
        try{
            String type='School Contacts Update'; 

            //create Token
                MethodResponse res1= createToken(CampaignAccountContact, type);
                if (res1.statusCode >= 400) return res1; //stop and return with error message
                res.setResult('log', 'OnboardingController.request_access_actions created token. Next step: Token__c token = res1.token' );
                Token__c token = res1.token;
                res.setResult('log', 'createToken assigned token');
                res.results.putAll(res1.results); //append results in res1 to res.
    
                // ------------------------ generate encrypted JWT ----------------------------
                 Map<String, String> responseTokens = generateResponseTokens(token, type);
                 res.setResult('log', 'generateResponseTokens successfully ran generateResponseTokens()' );
                token.JWT1__c = responseTokens.get('confirmToken'); 
                token.JWT2__c = responseTokens.get('updateToken'); 
                //delegate
                token.JWT3__c = responseTokens.get('delegateToken'); 
                update token; //save JWT1 and 2
                token  = [SELECT id, Account__c, Type__c, Approver__c, IsClosed__c, JWT1__c, JWT2__c,JWT3__c FROM Token__c WHERE id =: token.id LIMIT 1];
                
                // ---------------------------- send email to principal ----------------------------
                MethodResponse res2 = send_CampaignAccount_Email(campaignAccountContact.campaign__c, token, partialURL,isDelegate);
                if (res2.statusCode >= 400) return res2; //stop and return the caseResponse with error message
                res.setResult('log', 'send_CampaignAccount_Email successfully ran' );
                res.results.putAll(res2.results); //append results in res3 to res.

                res.setStatus(200);
                return res;
                
        }catch (Exception e) {
            res.setStatus(400);
            res.setResult('error', e.getMessage());
            res.setResult('log', 'ExposedServiceController.campaign_email_actions exception' );
            return res;
        }

        

    }
   
    public static MethodResponse createToken(Campaign_Account_Contact__c CampaignAccountContact, String type){
        MethodResponse res = new MethodResponse();
   
        try {
            Token__c token = new Token__c(
                RecordId__c = String.valueOf(CampaignAccountContact.Campaign_Account__r.Account__c),
                Account__c = CampaignAccountContact.Campaign_Account__r.Account__c, //account Id
                Approver__c = CampaignAccountContact.Contact__c, //contact Id,
                Type__c = type,
                IsClosed__c = false,
                UserOrigin__c = 'N4L Invitation - School Contacts Update Campaign'
            );
            insert token;
            
            //return response
            res.setStatus(201);
            res.setResult('success', 'Generate Token : ' + token.Id);  
            res.token = token; //return dto
            return res;
        } catch (Exception e) {
            res.setStatus(400);
            res.setResult('error', e.getStackTraceString());
            res.setResult('log', 'ExposedServiceController.createToken exception' );
            return res;
        }

    }

    Public Static Map<String, String> generateResponseTokens(Token__c token, String type){
        Boolean isEncrypted = true;
        Map<String, String> claimsMap = new Map<String, String>();
        claimsMap.put('tokenId', token.Id);
        claimsMap.put('response', 'confirmed');
        String confirmToken = JWTController.issueJWT(type, claimsMap, isEncrypted);
        claimsMap.remove('response');
        claimsMap.put('response', 'updated');
        String updateToken = JWTController.issueJWT(type, claimsMap, isEncrypted);
        //delegate
        claimsMap.put('response', 'delegate');
        String delegateToken = JWTController.issueJWT(type, claimsMap, isEncrypted);
        Map<String, String> result = new Map<String, String>();
        result.put('confirmToken', confirmToken);
        result.put('updateToken', updateToken);
        result.put('delegateToken',delegateToken);
        return result;
    }

    public static MethodResponse send_CampaignAccount_Email (Id campaignId, Token__c token, String partialURL,Boolean isDelegate){
        MethodResponse res = new MethodResponse();
        //Custom Label 
        //List<string> keyContactUpdatesList = Label.N4L_Business_Contacts.split(';');

        // Get list of business contact roles
        List<N4L_Business_Contact_Role__mdt> businessRoles = [SELECT ID, MasterLabel 
        FROM N4L_Business_Contact_Role__mdt ORDER BY Id];

        List<String> businessRolesList = new List<String>();
        List<String> roleSet = new List<String>();
        for(N4L_Business_Contact_Role__mdt businessRole : businessRoles) {
            businessRolesList.add(businessRole.MasterLabel);
            roleSet.add('\''+ businessRole.MasterLabel + '\'');
        }

        //Contact
        Contact contact = [SELECT id, name, Contact.Firstname, email FROM Contact WHERE id =: token.Approver__c];
        List<AccountContactRelation> accountContactRelationList = new List<AccountContactRelation>();
        /** replaced by below query string to support multiple picklist value.
        accountContactRelationList = [SELECT 
        Id,
        AccountId,
        Contact.Name,
        Roles, 
        Contact.Email
        FROM AccountContactRelation
        WHERE AccountId =:token.Account__c 
        AND Roles In:businessRolesList 
        AND isActive = True
        ]; **/
        String acrQueryString = 'SELECT Id,AccountId,Contact.Name,Roles,Role_Sorting__c, Contact.Email FROM AccountContactRelation '+
                                'WHERE AccountId = \''+token.Account__c+'\' AND isActive = True AND Roles INCLUDES ( ' +
                                 String.join(roleSet, ',')+' ) ORDER BY Role_Sorting__c' ;
        accountContactRelationList = (List<AccountContactRelation>) Database.query(acrQueryString);
        Campaign campaign = [SELECT id, name, Email_Template_Name__c FROM Campaign WHERE id =: campaignId]; 

        //ExposedService
        List<Scheduled_Event__c> ScheduledEventList = New List<Scheduled_Event__c>();
        String SEQueryString = 'SELECT Id, IP_Str__c, Port__c, Product__c, Status__c, School_Name__c, SourceIP__c, SourceMAC__c, Date__c FROM Scheduled_Event__c '+
                                'WHERE School_Name__c = \''+token.Account__c+'\' ' ;
        ScheduledEventList = (List<Scheduled_Event__c>) Database.query(SEQueryString);
        system.debug('>>>>>@@@ScheduledEventList'+ScheduledEventList);

        try{           
            //toAddresses
            List<String> toAddresses = new List<String>();
            if(contact != null && String.isNotBlank(contact.Email)) toAddresses.add(contact.Email); //add campaign contact's email to address
            
            //ccAddresses - no cc required, but leave it as empty list
            List<String> ccAddresses = new List<String>();
            
            //delegate 2021 06 09
              AccountContactRelation actContactRelation = [SELECT Id, ContactId, AccountId, account.Name, Roles FROM AccountContactRelation WHERE ContactId =: contact.Id AND AccountId =: token.Account__c Limit 1];
            
            //get Email Template Name based on MetaData - Email Template Mapping
            //String masterLabel = ('school key contact confirmation').toLowerCase();
            String currentEmailTemplate;
  
                currentEmailTemplate = (campaign.Email_Template_Name__c).toLowerCase();
      
            system.debug('@@**#&$^currentEmailTemplate'+currentEmailTemplate);
            String masterLabel = isDelegate? 'school key contact delegate': currentEmailTemplate;
            MethodResponse res2 = EmailController.getEmailTemplateByMasterLabel(masterLabel);
             if(res2.statusCode >= 400) return res2;
            EmailTemplate emailTemplate = res2.emailTemplate; //dto in res
            OrgWideEmailAddress orgWideEmailAddress = res2.orgWideEmailAddress; //dto in res
            
            String confirmHyperlink = partialURL + 'request-authorisation?p=school-contacts-update&t=' + token.JWT1__c;
            String updateHyperlink = partialURL + 'request-authorisation?p=school-contacts-update&t=' + token.JWT2__c;
            String delegateHyperlink;

                        //delegate 2021 06 09
            if(actContactRelation.Roles!=null && actContactRelation.Roles.contains('Principal')){
                delegateHyperlink = partialURL + 'request-authorisation?p=school-contacts-update&t=' + token.JWT3__c +'&camid='+campaign.id+'&accid='+token.account__c;
            }
            
             //Email Template
            String htmlBody = emailTemplate.HtmlValue;         
            String plainBody = emailTemplate.Body;
            String htmltableScopeofWork = '';

            //----------------------------------------------------------------ExposedService Table Start-------------------------------------------------------------------------------------------------------
            For (Scheduled_Event__c scheduledEvent : ScheduledEventList){
                htmltableScopeofWork += '<tr style="vertical-align:top">';
                htmltableScopeofWork += '<td style="width: 180px; text-align: middle;"><span>' + Helper.getStringValue(scheduledEvent.SourceIP__c) + '</span></td>';
                htmltableScopeofWork += '<td style="width: 160px; text-align: middle;"><span>' + Helper.getStringValue(scheduledEvent.SourceMAC__c) + '</span></td>';
                htmltableScopeofWork += '<td style="width: 160px; text-align: middle;"><span>' + Helper.getStringValue(string.valueOf(scheduledEvent.Date__c)) + '</span></td>';
                htmltableScopeofWork += '</tr>';

                system.debug('>>>>@@@@@@scheduledEvent:'+scheduledEvent+'>>>>>!!!!Port:'+scheduledEvent.Port__c);
            }           

            //----------------------------------------------------------------ExposedService Table End----------------------------------------------------------------------------------------------------------
            htmlBody = htmlBody.replace('[htmltableScopeofWork]', nullCheck(htmltableScopeofWork)); 
            htmlBody = htmlBody.replace('[confirmHyperlink]', nullCheck(confirmHyperlink)); 
            htmlBody = htmlBody.replace('[updateHyperlink]', nullCheck(updateHyperlink)); 

            htmlBody = htmlBody.replace('[delegateHyperlink]', nullCheck(delegateHyperlink));  
            htmlBody = htmlBody.replace('{!Contact.FirstName}', nullCheck(contact.FirstName)); //when replacing htmlbody this way, the normal Salesforce merge field in email template way would not work
            htmlBody = htmlBody.replace('{!Account.Name}', nullCheck(actContactRelation.account.name));

            plainBody = plainBody.replace('[htmltableScopeofWork]', nullCheck(htmltableScopeofWork)); 
            plainBody = plainBody.replace('[confirmHyperlink]', nullCheck(confirmHyperlink)); 
            plainBody = plainBody.replace('[updateHyperlink]', nullCheck(updateHyperlink));


            EmailController.sendEmail2(token.Approver__c, token.Account__c, emailTemplate, toAddresses, ccAddresses, htmlBody, plainBody, orgWideEmailAddress);    
            res.setStatus(200);
            res.setResult('success', 'Sent ' + emailTemplate.Name +' Email to ' + string.join(toAddresses,','));  
            return res;
            
        } catch (System.Exception ex) {
            res.setStatus(400);
            res.setResult('error', ex.getMessage());
            res.setResult('log', 'Email Exception' );
            return res;
        }
    }
     
    public static String nullCheck(String input){
        return (String.IsBlank(input) ? '' : input ); //return '' if input is null.
    }

}