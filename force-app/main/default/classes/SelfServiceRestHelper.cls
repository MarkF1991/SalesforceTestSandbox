public class SelfServiceRestHelper {
    
    public static User CreateSSuserAccount(String JsonBody) {
        User u = new User();
        userPassword userPwd = new userPassword();
        userAccount userAcct = new userAccount();
        removeACR removeUserAcr = new removeACR();
        
        removeUserAcr = (removeACR)System.JSON.deserialize(JsonBody, removeACR.class);
        userAcct = (userAccount)System.JSON.deserialize(JsonBody, userAccount.class);
        userPwd = (userPassword)System.JSON.deserialize(JsonBody, userPassword.class);
        u = (User)System.JSON.deserialize(JsonBody, User.class);

        String contactId = u.ContactId;

        // just until emails are sorted
        //if (String.isBlank(contactId)) {
        //    Account school = [SELECT Id, Name FROM Account WHERE Id =: userAcct.accountIds[0] ];
        //    Contact pocContact = new Contact();
        //    pocContact = TestClassUtility.createContact(school.Id, u.FirstName, u.LastName, u.Email, '02711111111', 'ICT Leader', False);
        //    insert pocContact;
        //    contactId = pocContact.Id;
        // }
        
        List<String> userAccts = New List<String>(userAcct.accountIds);
        system.debug('!*#@&^#%@UserAccts: '+userAccts);
        
        //SS-1238 Create Account Contact Relationship(ACR)
        For(string usrAcctId : userAccts){
            List<AccountContactRelation> acrs = [SELECT Id, AccountId, ContactId FROM AccountContactRelation 
                                                 WHERE AccountId =: usrAcctId AND ContactId =: contactId];
            If(acrs.size() == 0){
                AccountContactRelation acr = New AccountContactRelation();
                acr.AccountId = usrAcctId;
                acr.ContactId = contactId;
                insert acr;
            }else{
                //do nothing
            }
        } 
        
        //SS-1238 Remove Account Contact Relationship(ACR) If needed
        List<String> removeUserAcrs = New List<String>(removeUserAcr.removeACRs);
        if(removeUserAcrs.size() > 0){
            For(string removeAcr : removeUserAcrs){
                AccountContactRelation acr = [SELECT Id, AccountId, ContactId FROM AccountContactRelation 
                                              WHERE AccountId =: removeAcr AND ContactId =: contactId];
                
                delete acr;
            }
        }
        
        //SS-1238 update contact before create user
        Contact updatedContact = [SELECT Id, FirstName, LastName, Email FROM Contact WHERE Id =: contactId];
        updatedContact.FirstName = u.FirstName;
        updatedContact.LastName = u.LastName;
        updatedContact.Email = u.Email;
        update updatedContact;
        
        //find the profile for user
        
        Profile userProfile = [SELECT Id, Name FROM Profile WHERE Name =: label.Support_Hub_Signup_user_profile];
        
        //Check if the user already gets the account
        List<User> existingUser = [SELECT Id, Email, Name FROM User WHERE Email =: u.Email];
        User userCreate = null;
        
        if(existingUser.size() == 0){
            //Create SH user account
            userCreate = new User(firstname = u.FirstName,
                                  lastName = u.LastName,
                                  Alias = u.Alias,
                                  email = u.Email,
                                  Username = u.Username,
                                  IsActive = True,
                                  ContactId = contactId,         
                                  ProfileId = userProfile.Id,
                                  TimeZoneSidKey = 'Pacific/Auckland',
                                  LocaleSidKey = 'en_NZ',
                                  EmailEncodingKey = 'UTF-8',   
                                  LanguageLocaleKey = 'en_US'
                                 );
            insert userCreate;
            
            System.setPassword(userCreate.Id, userPwd.pwd);
        }else{
            //do nothing if user account already exist in SF
        }
        
        return userCreate;
    }
    
    
    
    
    Public class userPassword {
        public String pwd;
    } 
    
    Public class userAccount {
        public List<String> accountIds;
    } 
    
    Public class removeACR {
        public List<String> removeACRs; //This is also account Id
    } 
}