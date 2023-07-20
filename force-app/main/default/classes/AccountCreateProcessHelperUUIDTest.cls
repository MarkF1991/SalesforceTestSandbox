@isTest
public class AccountCreateProcessHelperUUIDTest {

    // static testMethod void accountUUIDTest1(){
    //     account tacc = TestClassUtility.createAccount('testaccount01','School');
    //     Test.startTest();
    //     insert tacc;
    //     Test.stopTest();
        
    //      system.assertNOTEquals(null,[select id,uuid__c from account where id=: tacc.id].uuid__c); 
    // }

    // static testMethod void accountUUIDformatTest1(){
    //     account tacc = TestClassUtility.createAccount('testaccount01','School');
    //     Test.startTest();
    //     insert tacc;
    //     Test.stopTest();
        
    //      system.assertNOTEquals(null,[select id,uuid__c from account where id=: tacc.id].uuid__c); 
    //     string uuidtest = UUIDGenerator.Version4UUIDGenerator('test string');
    //     set<String> keyset = new set<String>{'a','b','9','8'};
    //     system.assertEquals('4',uuidtest.substring(14,15));
    //     system.assertEquals(true,keyset.contains( uuidtest.substring(19,20)));
    // }

    static testMethod void test_updateAccountUUID() {
        Account account = TestClassUtility.createAccount('testaccount01','School');
        insert account;

        //before process builder is deployed and activated, inserting account record only does not automatically update the uuid.
        //therefore, test the @invocable apex method seperately.
        List<Account> accounts = new List<Account>();
        accounts.add(account);
        AccountCreateProcessHelper.updateAccountUUID(accounts);
        system.assertNOTEquals(null,[select id,uuid__c from account where id=: account.id].uuid__c); 
    } 

    static testMethod void test_UUID_format() {
        //test uuid
        string uuidtest = UUIDGenerator.Version4UUIDGenerator('test string');
        set<String> keyset = new set<String>{'a','b','9','8'};
        system.assertEquals('4',uuidtest.substring(14,15));
        system.assertEquals(true,keyset.contains( uuidtest.substring(19,20)));
    }
}