@isTest
public with sharing class HelperTest {
    
    static testMethod void test_sandboxURL_on_LightningPlatform() {
        String baseURL = 'n4l--test.cs152.my.salesforce.com';
        String instanceName = 'cs152';
        String result = Helper.sandboxSupportHubURL(baseURL, instanceName);
        system.assertEquals('https://test-n4lportal.cs152.force.com/schoolictsupport/s/', result);
    }

    static testMethod void test_sandboxURL_on_CommunityPage() {
        String baseURL = 'test-n4lportal.cs152.force.com'; //it has 'portal'
        String instanceName = 'cs152';
        String result = Helper.sandboxSupportHubURL(baseURL, instanceName);
        system.assertEquals('https://test-n4lportal.cs152.force.com/schoolictsupport/s/', result);
    }
    
    static testMethod void test_sandboxURL_on_LightningPlatform_enhancedDomains() {
        String baseURL = 'n4l--test.sandbox.my.salesforce.com';
        String instanceName = 'cs152';
        String result = Helper.sandboxSupportHubURL(baseURL, instanceName);
        system.assertEquals('https://n4l--test.sandbox.my.site.com/schoolictsupport/s/', result);
    }
    
    static testMethod void test_sandboxURL_on_CommunityPage_enhancedDomains() {
        String baseURL = 'n4l--test.sandbox.my.site.com'; //it has 'my.site'
        String instanceName = 'cs152';
        String result = Helper.sandboxSupportHubURL(baseURL, instanceName);
        system.assertEquals('https://n4l--test.sandbox.my.site.com/schoolictsupport/s/', result);
    }

    static testMethod void test_SupportHubURL(){
        String productionSupportHubURL = Label.Support_Hub_URL;
        
        if (Helper.isSandbox()){
            system.assertEquals(False, (productionSupportHubURL == Helper.supportHubURL()));
        } else {
            system.assertEquals(True, (productionSupportHubURL == Helper.supportHubURL()));
        }
    }

    static testMethod void test_SupportHubURL_true(){
        String url = Helper.supportHubURL();
        url = url.left(url.length()-2); //just to remove the "s/" at the End
        system.assertEquals(url, Helper.supportHubURL(true));
    }
    static testMethod void test_getRecordTypeId(){
        Id recordTypeId = Helper.getRecordTypeId(Schema.SObjectType.Case, 'Onboarding');
        system.assertEquals(True, (recordTypeId != null));
    }

    static testMethod void test_currency(){
        Decimal dec = 12345.45986;
        system.assertEquals('12,345.46', Helper.currency(dec));

        dec = 98765;
        system.assertEquals('98,765.00', Helper.currency(dec));
        
        dec = 98765.5;
        system.assertEquals('98,765.50', Helper.currency(dec));
    }
    
    static testMethod void test_getRandomNumber(){
        system.assertEquals(0, Helper.getRandomNumber(-1).length());
        system.assertEquals(0, Helper.getRandomNumber(0).length());
        system.assertEquals(1, Helper.getRandomNumber(1).length());
        system.assertEquals(10, Helper.getRandomNumber(10).length());
        system.assertEquals(15, Helper.getRandomNumber(15).length());
        system.assertEquals(20, Helper.getRandomNumber(20).length());
        system.assertEquals(30, Helper.getRandomNumber(30).length());
        system.assertEquals(61, Helper.getRandomNumber(61).length());
        system.assertEquals(255, Helper.getRandomNumber(255).length());
        
    }

    static testMethod void test_createLogFile(){
        //n4l
       // ContentWorkspace  Dfolder = new ContentWorkspace (name='System Admin Log Files');
       // insert Dfolder;
        //
        String csvContentString = 'number, name, title \n';
            //add content
            String csvLine = '"' + 1 
                            + '","' + 'John Smith'
                            + '","' + 'Principal'
                            + '"\n';
            csvContentString += csvLine.replace('null',' ');//add line  

            csvLine = '"' + 2 
                            + '","' + 'Jane Doe'
                            + '","' + 'ICT Lead'
                            + '"\n';
            csvContentString += csvLine.replace('null',' ');//add line  
        
            Test.startTest();
            //future method - create csv content ------------------------------------------------------------------------------
                Helper.createLogFile(
                    csvContentString, 
                    'SetupEntityAccessMaintenance Log ' + String.ValueOf(datetime.now()), 
                    '.csv', 
                    'System Admin Log Files');
            Test.stopTest();

        List<ContentVersion> contentVersions = [SELECT Id, ContentDocumentId FROM ContentVersion];
        System.assertEquals(1, contentVersions.size());
        
    }

    static testMethod void test_formatNZdatetime_and_date(){
        DateTime dt  = DateTime.newInstance(2020, 1, 31, 7, 8, 16);
        System.assertEquals('31/01/2020 07:08 AM', Helper.formatNZdatetime(dt));
        System.assertEquals('Friday 31 January at 7:08 AM', Helper.formatNZdatetimeWithStringMonth(dt));
        System.assertEquals('31/01/2020', Helper.formatNZdate(dt));

        dt  = DateTime.newInstance(2020, 10, 1, 7, 8, 16);
        System.assertEquals('01/10/2020 07:08 AM', Helper.formatNZdatetime(dt));

        Date myDate = date.newinstance(1960, 2, 7);
        System.assertEquals('07/02/1960', Helper.formatNZdate(myDate));

        dt  = DateTime.newInstance(2020, 10, 1, 21, 8, 16);
        System.assertEquals('01/10/2020 09:08 PM', Helper.formatNZdatetime(dt));
        System.assertEquals(date.newinstance(2020, 10, 1), Helper.getNZdate(dt));
    }

    static testMethod void test_getN4LSettings(){
        N4LSetting__mdt setting = Helper.getN4LSettings().get('Unit Testing')[0];

        System.assertEquals('gJzpBNJtCDMRnqF1DhabJJK73nHeF/U4LV78gi4shAM=', setting.cryptoKey__c);
        System.assertEquals('c3VwZXJzZWNyZXQ=', setting.secretKey__c);
        System.assertEquals('this_is_a_token_for_unit_test', setting.token__c);
    }

    static testMethod void test_getProgrammeNameMapping(){
        Programme_Name_Mapping__mdt programme = Helper.getProgrammeNameMapping().get('unitTest');
        System.assertEquals('Unit Test Programme', programme.Programme__c);
        System.assertEquals('UT', programme.key__c);
    }
    static testMethod void test_getProgrammeMapping(){
        String json = Helper.getProgrammeMapping();
        System.JSONParser parser = System.JSON.createParser(json);
        while (parser.nextToken() != System.JSONToken.END_OBJECT) {
			if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
				String text = parser.getText();
				if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
					if (text == 'unitTest') {
                        while (parser.nextToken() != System.JSONToken.END_OBJECT) {
                            if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
                                text = parser.getText();
                                if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
                                    if (text == 'DeveloperName') {
                                        System.assertEquals('unitTest', parser.getText());
                                    } else if (text == 'MasterLabel') {
                                        System.assertEquals('unitTest', parser.getText());
                                    } else if (text == 'Description__c') {
                                        System.assertNotEquals(null, parser.getText());
                                    } else if (text == 'Key__c') {
                                        System.assertEquals('UT', parser.getText());
                                    } else if (text == 'Programme__c') {
                                        System.assertEquals('Unit Test Programme', parser.getText());
                                    }
                                }
                            }
                        }
					}
				}
			}
		}
    }

    static testMethod void test_KeyFunctions(){
        system.assertEquals('', Helper.getStringValue(null));
        system.assertEquals('', Helper.getStringValue(''));
        system.assertEquals('This is a string', Helper.getStringValue('This is a string'));

        List<String> items = new List<String>{'First Item', 'Second Item', 'Third Item'};
        system.assertEquals('First Item-Second Item-Third Item', Helper.concatenateKey(items));
        system.assertEquals('', Helper.concatenateKey(null));
        system.assertEquals('', Helper.concatenateKey(new List<String>() ));
    }
    
    static testMethod void test_createAccountMap(){
        List<Account> accounts = new List<Account>();
        accounts.add(new Account(Name = 'School A', uuid__c = 'schoola'));
        accounts.add(new Account(Name = 'School B', uuid__c = 'schoolb'));
        accounts.add(new Account(Name = 'School C', uuid__c = 'schoolc'));
        Map<String, Account> result = helper.createAccountMap(accounts, 'uuid');
        system.assertEquals(3, result.size());
    }    
}