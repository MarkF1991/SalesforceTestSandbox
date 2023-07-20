public with sharing class ContractController {
    @AuraEnabled(cacheable=true)
    public static Map<String,String> getContract(id contractId) {
        Map<String,String> result = New Map<String,String>();
        MethodResponse res = new MethodResponse();
        
        List<Contract> contracts = [SELECT Id, Name, AccountId, Account.Name, Related_Case__c, Related_Case__r.id, ContractNumber, Account.MoE_School_ID__c, ActivatedDate, Contract_Type__c, Order_Total_at_Time_of_Invite__c, CustomerSignedDate, CustomerSignedId, CustomerSigned.Name, CustomerSigned.FirstName, CustomerSigned.Email, CustomerSignedTitle, MoE_Project_Manager__c, MoE_Project_Manager__r.Name, MoE_Project_Manager__r.Email, MoE_Signatory__c, MoE_Signatory__r.Name, MoE_Signatory__r.Email, Per_Pupil_Contribution__c, Annual_Contribution__c, Order_Total_Amount__c, Programme__c, Status, StatusCode, Accepted_N4L_Terms_and_Conditions__c, Accepted_N4LCharges_Terms_and_Conditions__c, Accepted_MoE_Terms_and_Conditions__c, N4L_Signatory_Name__c, N4L_Signatory_Email__c, MoE_Party_Name__c, MoE_Party_Email__c, School_Principal_Name__c, School_Principal_Email__c, OwnerId, Account.Owner.Name, Account.Owner.MobilePhone, CustomerSignedUser__c, Product__c, Educount_Rolls__c ,Account.School_Nominated_ICT_Provider__r.Name, Educount_Rolls_as_at__c FROM Contract WHERE id =: contractId];
        
        //error
        if(contracts.isEmpty()){
            if (String.isNotBlank(contractId)){
                res.setStatus(404);
                res.setResult('error', 'Could not find a Contract record with id = ' + contractId);   
            } else {
                res.setStatus(400);
                res.setResult('error', 'Missing contractId');    
            }
            result.put('response', res.getJSONstring());
            return result;
        }
        
        //successful
        Contract contract = contracts[0];
        res.setStatus(200);
        result.put('response', res.getJSONstring());
        result.put('contract', JSON.serialize(contract));
        
        //get principal
        Map<string, List<Contact>> roleBasedContacts = ContactController.getRoleBaseContacts(contract.AccountId);
        Contact principal =  roleBasedContacts.get('Principal').get(0); //get principal of the school
        result.put('principal', JSON.serialize(principal));
        
        return result;
    }
    
    @AuraEnabled() //using cacheable=true will cause error LIMIT_USAGE_FOR_NS   Number of DML statements: 1 out of 0 ******* CLOSE TO LIMIT
    public static Map<String,String> updateContract(Map<string, object> fieldsMap ) {
        Map<String,String> result = New Map<String,String>();
        MethodResponse res = new MethodResponse();
        
        system.debug('>>>>> fieldsMap = ' + JSON.serializePretty(fieldsMap));
        Contract contract = new Contract();
        String action = String.valueOf(fieldsMap.get('action'));
        if(action == 'Update_Customer_Signatory'){
            contract.Id = String.valueOf(fieldsMap.get('id'));
            contract.CustomerSignedId = String.valueOf(fieldsMap.get('CustomerSignedId'));
            contract.OwnerId = String.valueOf(fieldsMap.get('OwnerId'));
            contract.CustomerSignedTitle = String.valueOf(fieldsMap.get('CustomerSignedTitle'));
            
            // system.debug('>>>>>>>>>>> String.valueOf(fieldsMap.get(OwnerId) = ' + String.valueOf(fieldsMap.get('OwnerId')));
            // system.debug('>>>>>>>>>> contract.OwnerId = ' + contract.OwnerId);
            // system.debug('>>>>>>>>>>!!! contract.CustomerSignedTitle = ' + contract.CustomerSignedTitle);
        }
        
        if(action == 'Update_Signed_Or_Declined'){
            contract.Id = String.valueOf(fieldsMap.get('id'));
            contract.Status = String.valueOf(fieldsMap.get('status'));
            contract.Accepted_MoE_Terms_and_Conditions__c = Boolean.valueOf(fieldsMap.get('acceptedTsandCs1'));
            contract.Accepted_N4LCharges_Terms_and_Conditions__c = Boolean.valueOf(fieldsMap.get('acceptedTsandCs2'));
            contract.Accepted_N4L_Terms_and_Conditions__c = Boolean.valueOf(fieldsMap.get('acceptedTsandCs3'));
            contract.School_Principal_Name__c = String.valueOf(fieldsMap.get('principalname'));
            contract.School_Principal_Email__c = String.valueOf(fieldsMap.get('principalemail'));
            
            contract.CustomerSignedUser__c = String.valueOf(fieldsMap.get('customerUserId'));
            contract.CustomerSignedDate = date.today();
            contract.StartDate = date.today();
        }
        
        if(action == 'Update_Status_Only'){
            contract.Id = String.valueOf(fieldsMap.get('id'));
            contract.Status = String.valueOf(fieldsMap.get('status'));
        }
        
        try {
            update contract;     
            // system.debug('>>>>> update contact = ' + JSON.serializePretty(contract));
            result = getContract(contract.Id); //return the same JSON structure as getContract() above
            
            //send confirmation email
            if(action == 'Update_Signed_Or_Declined'){
                confirm_ContractSigned_actions(result);
            }
            
        } catch (System.Exception ex) {
            res.setStatus(400);
            res.setResult('error', ex.getMessage());
            res.setResult('log', 'ContractController.updateContract Exception' );
            
            result.put('response', res.getJSONstring());
        }
        
        return result;
        
    }
    
    @AuraEnabled() //LWC MOUContractSignatory will call this method to send email
    public static string inviteToSignContract(String type, ID recordId){
        MethodResponse res = invite_signatory_actions(type, recordId);
        return res.getJSONstring(); 
    }
    
    public static MethodResponse invite_signatory_actions(String type, ID recordId){
        //type = 'MOU Contract'
        MethodResponse res = new MethodResponse();
        String JSONContent = '';
        JSONParser parser = null;
        
        try {
            // ---------------------------- get Contract record ----------------------------
            Map<String,String> mapContract = getContract(recordId);
            //part 1a: get response from getContract()
            JSONContent = mapContract.get('response'); //stringResponse is a json.serialized string
            parser = JSON.createParser(JSONContent);
            parser.nextToken();// Make calls to nextToken() to point to the second start object marker.
            // Retrieve the Contact object from the JSON string.
            MethodResponse res1a = (MethodResponse)parser.readValueAs(MethodResponse.class);
            if (res1a.statusCode >= 400) return res1a; //stop and return the res with error message
            
            //part 1b: success in part 1a, now get contract record from getContract()
            JSONContent = mapContract.get('contract'); //stringResponse is a json.serialized string
            parser = JSON.createParser(JSONContent);
            parser.nextToken();// Make calls to nextToken() to point to the second start object marker.
            // Retrieve the Contact object from the JSON string.
            Contract contract = (Contract)parser.readValueAs(Contract.class);
            
            
            
            
            // ---------------------------- create ContractSignatoryInvite Token ----------------------------
            MethodResponse res2 = create_ContractSignatoryInvite_Token(contract, type);
            if (res2.statusCode >= 400) return res2; //stop and return the caseResponse with error message
            res.setResult('log', 'OnboardingController.invite_signatory_actions created token. Next step: Token__c token = res2.token' );
            Token__c token = res2.token;
            res.setResult('log', 'OnboardingController.invite_signatory_actions assigned token' );
            res.results.putAll(res2.results); //append results in res2 to res.
            
            
            // ---------------------------- generate encrypted JWT ----------------------------
            Map<String, String> inviteTokens =  generateJWTToken(token, type);
            res.setResult('log', 'ContractController.invite_signatory_actions successfully ran generateJWTToken()' );
            token.JWT1__c = inviteTokens.get('inviteToken'); 
            update token; //save JWT1
            
            //query token one more time with the full and extended details like Account__r.Name
            MethodResponse res3 = TokenController.getToken(token.id);
            if (res3.statusCode >= 400) return res3;
            token = res3.token; //res1 return token as dto
            
            // ---------------------------- send ContractSignatoryInvite email to Contract Designated Signatory ----------------------------
            MethodResponse res4;
            System.debug('>>>>Educount_Rolls__c'+contract.Educount_Rolls__c);
            
            //add condition  contract.status isn't Cancelled. To facilitate reprice / variation contract (CH Micado 29-6-2023) MNTC-1690
            if(contract.Status != 'Activated' && contract.Status != 'Cancelled' && contract.Educount_Rolls__c != null && contract.Educount_Rolls__c > 0 ){
                res4 = send_ContractSignatoryInvite_Email(token, contract);
                
                //find out the related contract completion task, MNTC-1665
                Case relatedCase;
                //task is only updated if the contract is not a 'reprice' contract. (CH Micado 29-6-2023) MNTC-1689
                if(contract.Contract_Type__c != 'Reprice'){
                                        if(contract.Contract_Type__c == 'Variation'){
                        relatedCase = [SELECT Id, ER_Lite__c, Contract__c FROM Case WHERE Id =: contract.Related_Case__r.id];
                        system.debug('caseVariation'+relatedCase);
                    }
                    else if(contract.Contract_Type__c == 'Master'){
                        relatedCase = [SELECT Id, ER_Lite__c, Contract__c FROM Case WHERE Contract__c =: contract.Id];
                        system.debug('caseNonVariation'+relatedCase);
                    }
                    
                    Task contractCompletionTask = [SELECT id, subject, status, whatId FROM Task WHERE whatId =: relatedCase.Id AND subject like '%Contract Completion'];
                    If(contractCompletionTask.Status == 'In Progress'){
                        contractCompletionTask.Status = 'Waiting on someone else';
                        update contractCompletionTask;
                    }
                }
            }
            if (res4.statusCode >= 400) return res4; //stop and return the caseResponse with error message
            res.setResult('log', 'ContractController.invite_signatory_actions successfully ran send_PermissionRequired_Email()' );
            res.results.putAll(res4.results); //append results in res3 to res.
            
            res.setStatus(200);
            return res;
            
        } catch (Exception e) {
            system.debug('EXCEPTION:: ' + e.getMessage());
            res.setStatus(400);
            res.setResult('error', e.getMessage());
            res.setResult('log', 'ContractController.invite_signatory_actions exception' );
            return res;
        }
    }
    
    
    Public Static MethodResponse create_ContractSignatoryInvite_Token(Contract contract, String type){
        MethodResponse res = new MethodResponse();
        
        try {
            Token__c token = new Token__c(
                RecordId__c = String.valueOf(contract.Id),
                Account__c = contract.AccountId,
                Requester__c = null,
                Approver__c = contract.CustomerSignedId, //designated signatory contact id
                Type__c = type,
                Status__c = 'Invited',
                IsClosed__c = false,
                //ITR1397 - add userorigin
                UserOrigin__c = 'N4L Invitation - Contract Signatory' 
            );
            insert token;
            
            //return response
            res.setStatus(201);
            res.setResult('success', 'Created ContractSignatoryInvite Token : ' + token.Id);  
            res.token = token; //return dto
            return res;
        } catch (Exception e) {
            res.setStatus(400);
            res.setResult('error', e.getMessage());
            res.setResult('log', 'ContractController.ContractSignatoryInvite exception' );
            return res;
        }
    }

    //ITR-1397 create a token for user account creation
    public static MethodResponse createToken(Contact contact, String type, String userOrigin){
        MethodResponse res = new MethodResponse();
   
        try {
            Token__c token = new Token__c(
                RecordId__c = String.valueOf(contact.Id),
                Account__c = contact.AccountId, //account Id
                Requester__c = null,
                Approver__c = contact.Id, //contact Id,
                Type__c = type,
                Status__c = 'Invited',
                IsClosed__c = false,
                Parent__c = null,
                UserOrigin__c = userOrigin //'N4L Invitation - Contract Signatory'
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
            return res;
        }
    }
    
    Public Static Map<String, String> generateJWTToken(Token__c token, String type){
        Boolean isEncrypted = true;
        Map<String, String> claimsMap = new Map<String, String>();
        claimsMap.put('tokenId', token.Id);
        
        String inviteToken = JWTController.issueJWT(type, claimsMap, isEncrypted);
        
        Map<String, String> result = new Map<String, String>();
        result.put('inviteToken', inviteToken);
        
        return result;
    }
    
    public static MethodResponse send_ContractSignatoryInvite_Email (Token__c token, Contract contract){
        MethodResponse res = new MethodResponse();
        try{
            
            //toAddresses
            List<String> toAddresses = new List<String>();
            if(token.Approver__c != null && String.isNotBlank(token.Approver__r.Email)) toAddresses.add(token.Approver__r.Email); //add designated contact's email to address
            
            //ccAddresses - no cc required, but leave it as empty list
            List<String> ccAddresses = new List<String>();
            
            //get Email Template Name based on MetaData - Email Template Mapping
            //String masterLabel = ('mou designated signatory invitation').toLowerCase();

            //Er Lite changes 
            //Get case details 
            //Update 30/6/23 Reprice contracts are related to the case via related_case__c field. (CH Micado)
            Case sourceCase;
            if(contract.Contract_Type__c == 'Variation' || contract.Contract_Type__c == 'Reprice'){
                sourceCase = [SELECT Id, ER_Lite__c, Contract__c, Account.name FROM Case WHERE Id =: contract.Related_Case__r.id];
                system.debug('caseVariation'+sourceCase);
            }
            else if(contract.Contract_Type__c != 'Variation'){
                sourceCase = [SELECT Id, ER_Lite__c, Contract__c, Account.name FROM Case WHERE Contract__c =: contract.Id];
                system.debug('caseNonVariation'+sourceCase);
            }

            String masterLabel;
            if(sourceCase.ER_Lite__c == false && contract.Contract_Type__c != 'Variation'){
                masterLabel = String.valueOf(contract.Programme__c).toLowerCase() + ' order form invitation email';
            }
            else if(sourceCase.ER_Lite__c == true && contract.Contract_Type__c != 'Variation'){
                masterLabel = String.valueOf(contract.Programme__c).toLowerCase() + ' er lite order form invitation email';
            }
            else if(sourceCase.ER_Lite__c == true && contract.Contract_Type__c == 'Variation'){
                masterLabel = String.valueOf(contract.Programme__c).toLowerCase() + ' phase 2 order form invitation email';
            }
        
            MethodResponse res2 = EmailController.getEmailTemplateByMasterLabel(masterLabel);
            if(res2.statusCode >= 400) return res2;
            EmailTemplate emailTemplate = res2.emailTemplate; //dto in res
            OrgWideEmailAddress orgWideEmailAddress = res2.orgWideEmailAddress; //dto in res

            //MNTC-1665 Add logic to update case contract updation task to Waiting on Someone Else
            if(contract.Contract_Type__c == 'Variation'){
                Task contractUpdationTask = [SELECT Id, status, WhatId, Type FROM Task WHERE WhatId =: sourceCase.Id AND Type = 'Contract Updation - Phase 2'];
                contractUpdationTask.status = 'Waiting on someone else';

                update contractUpdationTask;
            }

            String inviteHyperlink='';
            String inviteAndCreateUserAcctHyperlink='';
            String htmlBody = emailTemplate.HtmlValue;
          
            //ITR1397 Add logic to assign the link base on whether user has account
            List<User> checkUsers = [SELECT Id FROM User WHERE Username = :contract.CustomerSigned.Email];
            Contact contact = [SELECT Id, Name FROM Contact WHERE Id =: contract.CustomerSignedId LIMIT 1];

            if (!checkUsers.isEmpty()){
                inviteHyperlink = Helper.supportHubURL() + 'mou?t=' + token.JWT1__c + '&p=mou';
                htmlBody = htmlBody.replace('[inviteHyperlink]', inviteHyperlink); 
            }else{        
                inviteAndCreateUserAcctHyperlink = createUser_actions_for_sign_theorder(token, 'N4L Invitation - Contract Signatory');
                htmlBody = htmlBody.replace('[inviteHyperlink]', inviteAndCreateUserAcctHyperlink); 
            }
            
            
            htmlBody = htmlBody.replace('{!Contact.FirstName}', token.Approver__r.FirstName); //when replacing htmlbody this way, the normal Salesforce merge field in email template way would not work
            //htmlBody = htmlBody.replace('[schoolName]', token.Account__r.Name); //relate to case's school name
            htmlBody = htmlBody.replace('{!Contract.Account}', contract.Account.Name);
            htmlBody = htmlBody.replace('{!Case.Account}', sourceCase.Account.Name);

            String plainBody = emailTemplate.Body;
            plainBody = plainBody.replace('[inviteHyperlink]', inviteHyperlink); 
            plainBody = plainBody.replace('{!Contact.FirstName}', token.Approver__r.FirstName); //when replacing htmlbody this way, the normal Salesforce merge field in email template way would not work
            plainBody = plainBody.replace('{!Case.Account}', sourceCase.Account.Name);

            //plainBody = plainBody.replace('[schoolName]', token.Account__r.Name); //relate to case's school name
            
            EmailController.sendEmail2(token.Approver__c, token.Account__c, emailTemplate, toAddresses, ccAddresses, htmlBody, plainBody, orgWideEmailAddress);    
            res.setStatus(200);
            res.setResult('success', 'Sent ' + emailTemplate.Name +' Email to ' + string.join(toAddresses,','));  
            return res;
            
        } catch (System.Exception ex) {
            res.setStatus(400);
            res.setResult('error', ex.getMessage());
            res.setResult('log', 'ContractController.send_ContractSignatoryInvite_Email Exception' );
            return res;
        }
    }
    
    public static void confirm_ContractSigned_actions(Map<String,String> result){
        //result comes from  getContract() when contract is updated. now extract the contract record from the result
        Contract contract = (Contract) JSON.deserialize(result.get('contract'), Contract.class);
        ServiceEventContractController.GeneratePDF(contract); //to call Platform Services API to asynchronously generate PDF and complete subsequent workflows

        
    }
    
    
    
    //------ process Token when it returns ---------------
    public static MethodResponse getContractByToken(Map<String, Object> claimsMap, Id userId){
        MethodResponse res = new MethodResponse();
        try{
            //for unit testing only: in order to make sure that @AuraEnabled JWTController._request_authorisation_with_credential() can call this method.
            if (claimsMap.containsKey('unitTestEscaped')  && Boolean.valueOf(claimsMap.get('unitTestEscaped'))) {
                res.setStatus(200);
                return res;
                //return 'Unit Test Escaped successfully';
            }
            
            //the rest of the code will be tested in OnboardingControllerTest.cls
            Id tokenId = String.valueOf(claimsMap.get('tokenId')); 
            
            MethodResponse res1 = TokenController.getToken(tokenId);
            if (res1.statusCode >= 400) return res1;
            Token__c token = res1.token; //res1 return token as dto
            
            // if (String.isNotBlank(token.RecordId__c) && String.isNotBlank(token.Approver__c)){
            //     //compare to make sure that contactId of the logged in user matches token.Approver__c
            //     if (contactId != token.Approver__c){
            //         //not match, then prevent user from signing the contract
            //         res.setStatus(401);
            //         res.setResult('error', 'your credential is unauthorised to sign this MOU.');    
            //         return res;
            //     }
            // }
            
            MethodResponse res2 = TokenController.closeToken(token.id, 'Responded');
            if (res2.statusCode >= 400) return res2;
            
            if (String.isBlank(token.RecordId__c)){
                res.setStatus(400);
                res.setResult('error', 'missing token.RecordId__c.');    
                return res;
            }
            
            Contract contract = [SELECT Id, OwnerId FROM Contract WHERE Id=:token.RecordId__c LIMIT 1];
            System.debug('>>>>>>>>>> token.RecordId__c = ' + token.RecordId__c);
            System.debug('>>>>>>>>>> OwnerId = ' + contract.OwnerId);
            System.debug('>>>>>>>>>> userId = ' + userId);
            //compare to make sure that userId of the logged in user matches Contract.OwnerId
            if (userId != contract.OwnerId){
                system.debug('>>>>>>>>userId != contract.OwnerId');
                //not match, then prevent user from signing the contract
                res.setStatus(401);
                res.setResult('error', 'your credential is unauthorised to sign this MOU.');        
                return res;
            }
            
            //successful
            system.debug('>>>>>>>>userId == contract.OwnerId Successful!!!');
            res.setStatus(200);
            //both res.results and getContract return the same structure Map<String, String>
            res.results = getContract(contract.Id);
            return res;
            
        } catch (System.Exception ex) {
            res.setStatus(400);
            res.setResult('error', ex.getMessage());
            res.setResult('log', 'ContractController.getContractByToken Exception' );
            return res;
        }
    }

            //ITR-1397 main method for Contract Authorised Signatory who does not have user account
            public static string createUser_actions_for_sign_theorder(Token__c token, String userOrigin){
                MethodResponse res = new MethodResponse();
                try{
                    String type='Invite-SignUp';
            
                        // ------------------------ generate encrypted JWT ----------------------------
                        Map<String, String> responseTokens = SupportHubInviteSignupController.generateResponseTokens(token, type);
                        token.JWT1__c = responseTokens.get('respondToken'); 
                        token.UserOrigin__c = userOrigin;
                        token.type__c = type;
                        update token; //save JWT1 and 2
                        MethodResponse res2 = TokenController.getToken(token.id);
                        token = res2.token;
                        
                        // ---------------------------- generate the link ----------------------------
                        string hyperlink = Helper.supportHubURL() + 'request-authorisation?p=invite-signup&t=' + token.JWT1__c;
                        res.setStatus(200);
                        return hyperlink;
                        
                }catch (Exception e) {
                    res.setStatus(400);
                    res.setResult('error', e.getMessage());
                    return 'Error'+e;
                }
            }

            //ITR-1397 update contact userOrigin before send order form to user
            @AuraEnabled
            public static MethodResponse contact_userOrign_update(Id recordId){
                MethodResponse res = New MethodResponse();
                
                Contract contract = [SELECT Id, CustomerSignedId FROM Contract WHERE Id =: recordId];
                Contact contact = [SELECT Id, UserOrigin__c FROM Contact WHERE Id =: contract.CustomerSignedId];
                contact.UserOrigin__c = 'N4L Invitation - Contract Signatory';
                update contact;
                res.setStatus(200);

                return res;

            }

}