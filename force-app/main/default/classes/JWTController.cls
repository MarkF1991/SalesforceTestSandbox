/**
* @author Ben Soh 
* @date 2019
* @description methods to decrypt and decode JWT. Started with request_authorisation routinng to Filtering Portal  
*
* CHANGE LOG
* 2020 added routing to MOU form (which is now called Order Form) for NHR (or ER) project
* 2021 added routing for school contact update campaign - confirm or update operations
**/
public without sharing class JWTController {
  
    //for internal Apex calls
    Public Static String issueJWT(string type, Map<String, Object> claimsMap, Boolean isEncrypted){
        //JWT jwt = new JWT('RS256'); //too hard to make it work in unit test. Could not generate/find certificate during unit test
        JWT jwt = new JWT('HS256', type); //so use HS256 instead, passing in type for JWT() constructor to get settings from Custom Metadata Types
        jwt.claims = claimsMap;
        String token = jwt.issue(isEncrypted);
        return token;
    }
    

    //for internal Apex calls
    public static JWT decodeJWT(string type, string input, Boolean isEncrypted){
        JWT result = new JWT('HS256', type, input, isEncrypted);
        return result;
    }
    
    //for LWC
    @AuraEnabled(cacheable=false)
    public static  Map<String, String> decodeJWTintoMap(string type, string input, Boolean isEncrypted){
        //Lesson learnt: must return Map<String, String> to LWC. Map<String, Object> will not work for LWC. Map must use Primitive—Boolean, Date, DateTime, Decimal, Double, Integer, Long, and String.
        //https://developer.salesforce.com/docs/component-library/documentation/lwc/lwc.apex
        Long rightNow = (dateTime.now().getTime()/1000)+1; 
        
        //JWT jwt = new JWT('RS256', input, isEncrypted); //too hard to make it work in unit test. Could not generate/find certificate during unit test
        JWT jwt = new JWT('HS256', type, input, isEncrypted);//so use HS256 instead,

        Map<String, String> result = new  Map<String, String>();
        result.put('verified', String.valueOf(jwt.verified));
        result.put('expired', String.valueOf(jwt.expired));
        result.put('now', String.valueOf(rightNow));

        result.put('body', jwt.jsonBody);

        return result;
    } 

    @AuraEnabled(cacheable=false)
    public static String authenticate(string userid){
        //Default settings
        Boolean isEncrypted = false;
        //Integer validFor = 5; // only valid for 5 seconds

        JWT jwt = new JWT('HS256', 'School Reporting');
        //jwt.privateKey = jwt.getSecretKey('c3VwZXJzZWNyZXQ='); //commented out as it is defined in Custom Metadata Types in JWT() constructor 
        //jwt.validFor = validFor; //commented out as it is defined in Custom Metadata Types in JWT() constructor 

        //return a list accessible accounts by user id
        List<Account> accounts = AccountController.getAccessibleSchools(userid);
        //prepare map for claims
        Map<String, List<String>> myMap = new Map<String, List<String>>();

        List<String> schoolIds = new List<String>();
        for (Account account : accounts){
            if(account.uuid__c != null) {
                schoolIds.add(account.uuid__c);
            }
        }
        myMap.put('allowed', schoolIds);

        jwt.claims = myMap;

        String token = jwt.issue(isEncrypted);
        return token;
    }

    @AuraEnabled(cacheable=false)
    public static String request_authorisation(string productName, string token){
        MethodResponse res = request_authorisation_action(productName, token, null);
        return res.getJSONstring(); 
    }

    @AuraEnabled(cacheable=false)
    public static String request_authorisation_with_credential(string productName, string token, id userId){
        MethodResponse res = request_authorisation_action(productName, token, userId);
        return res.getJSONstring(); 
    }

    public static MethodResponse request_authorisation_action(string productName, string token, id userId){
        MethodResponse res = new MethodResponse();
        
        //mapping URL parameter to Case.Product__c, and Metadata Type
        Map<String, String> productTypes = new Map<String, String>();
        productTypes.put('filtering-portal', 'Filtering Portal');
        productTypes.put('school-reporting', 'School Reporting');
        productTypes.put('mou', 'MOU');
        productTypes.put('school-contacts-update', 'School Contacts Update');
        productTypes.put('invite-signup', 'Invite-SignUp');
        

        //validate input: productName
        String type='';
        if (productTypes.containsKey(productName)){
            type = productTypes.get(productName);   
        } else {
            res.setStatus(400);
            res.setResult('request_authorisation', 'Invalid Product Name');
            return res;
        }

        //verify token and check expiry
        Boolean isEncrypted = true;
        JWT jwt = JWTController.decodeJWT(type, token, isEncrypted); 

        if (!jwt.verified){
            res.setStatus(401);
            res.setResult('request_authorisation', 'Unverified Token');
            return res;
        }
        if (jwt.expired){
            res.setStatus(401);
            res.setResult('request_authorisation', 'Token Expired');
            return res;
        }

        //this is acting like a gate keeper > directing process.
        Map<String, Object> claimsMap = jwt.claims;
        // if(type=='Filtering Portal') {
        //     res = OnboardingController.Filtering_Portal_Request_Approved_or_Declined(claimsMap);
        // }
        // if(type=='School Reporting') {
        //     //TODO: res = OnboardingController.School_Reporting_Request_Approved_or_Declined(claimsMap);
        // }
        // if(type=='MOU') {
        //     system.debug('>>>>>>>>> before getContractByToken claimsMap:' + JSON.serialize(claimsMap));
        //     system.debug('>>>>>>>>> before getContractByToken userId:' + JSON.serialize(userId));
        //     res = ContractController.getContractByToken(claimsMap, userId); //return results based on ContractController.getContract()
        // }

        switch on type{
            when 'Filtering Portal'{
                res = OnboardingController.Filtering_Portal_Request_Approved_or_Declined(claimsMap);
            }
            when 'School Reporting'{
                //TODO: res = OnboardingController.School_Reporting_Request_Approved_or_Declined(claimsMap);
            }
            when 'MOU' {
                //system.debug('>>>>>>>>> before getContractByToken claimsMap:' + JSON.serialize(claimsMap));
                //system.debug('>>>>>>>>> before getContractByToken userId:' + JSON.serialize(userId));
                res = ContractController.getContractByToken(claimsMap, userId); //return results based on ContractController.getContract()   
            }
            when 'School Contacts Update'{
                res = SupportHubUserSetupController.SchoolContactsUpdate_Confirm_or_Update(claimsMap);
            }
            when 'Invite-SignUp'{
                res = SupportHubUserSetupController.RespondedToCreateUserByInvitation(claimsMap);
            }
        }

        return res;
    }
    
    

   
}