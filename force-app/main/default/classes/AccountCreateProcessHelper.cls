/**
* @author n4lsalesforce@gmail.com
* @date 2020-09-08
* @description 	to generate UUID v4
*
* CHANGE LOG
**/
public class AccountCreateProcessHelper {
 // for process builder :AccountUUIDProcess    
 @InvocableMethod (label='Update Account UUID' description='generate a UUID when account is created.' category='Account')
    public static void updateAccountUUID (List<Account> accs) {
        account newacc = new account();
        newacc.id=accs[0].id;
        newacc.Name=accs[0].name;
        newacc.uuid__c =UUIDGenerator.GenerateAccountUUID(string.valueOf(newacc.id));
        update newacc;
    } 
}