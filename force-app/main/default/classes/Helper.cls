//Change log: Aug-2022 -   Updated for enhanced domains URL reference https://n4lconz.atlassian.net/l/cp/1LpAA9Re  by Carolyn Hayward (Micado)

public with sharing class Helper {
  
    public static Boolean isSandbox(){
        Organization org = [SELECT Id, IsSandbox, InstanceName, Name FROM Organization LIMIT 1];
        return org.IsSandbox;
        //return URL.getSalesforceBaseUrl().getHost().containsignorecase('.cs');
    } 

    public static String supportHubURL(){
        Organization org = [SELECT Id, IsSandbox, InstanceName, Name FROM Organization LIMIT 1];
        //if (isSandbox()){
        if(org.IsSandbox){
            String baseURL = DomainCreator.getExperienceCloudSitesHostname();//URL.getSalesforceBaseUrl().getHost();
            return sandboxSupportHubURL(baseURL, org.InstanceName); 
        } else {
            return Label.Support_Hub_URL;
            //return 'https://support.n4l.co.nz/s/';
        }
    }

    public static String supportHubURL(Boolean isVisualforcePage){
        String result = supportHubURL();
        if (isVisualforcePage){
            result = result.left(result.length()-2); //just to remove the "s/" at the end
        }
        return result;
    }
    
    public static String sandboxSupportHubURL(String baseURL, String instanceName){
        string url = 'https://';
        String companyName = '';
        String sandboxName = '';
        //String instanceName = '';
        
       
        if(baseURL.contains('.sandbox')) {
             //***Enhanced domains  (ED) activated for org - url will always contain '.sandbox'
            //example ED baseURL in Experience Cloud site: n4l--test.sandbox.my.site.com
            if(baseURL.contains('my.site')){
                url += baseURL + '/schoolictsupport/s/';  //must have
            } else {
                //otherwise, most of the time, the baseURL will contains '.sandbox'
                if(baseURL.contains('.sandbox')){
                    //example:ED baseURL in Lightning Platform = n4l--test.sandbox.my.salesforce.com 
                    companyName = baseURL.substringBefore('--');
                    sandboxName = baseURL.substringBetween('--','.sandbox');
                    url += companyName + '--' + sandboxName +  '.sandbox.my.site.com/schoolictsupport/s/';
                    //example: https://n4l--test.sandbox.my.salesforce.com/schoolictsupport/s/
                } 
            } 
        } else {
            //***Enhanced Domains not activated for org
            //example: baseURL in Community Page = test-n4lportal.cs152.force.com
            if(baseURL.contains('portal')){
                url += baseURL + '/schoolictsupport/s/';  //must have 
            } else {
                //otherwise, most of the time, the baseURL will contains '.cs'
                if(baseURL.contains('.cs')){
                    //example: baseURL in Lightning Platform = n4l--test.cs152.my.salesforce.com
                    companyName = baseURL.substringBefore('--');
                    sandboxName = baseURL.substringBetween('--','.cs');
                    //instanceName = baseURL.substringBetween('.','.');
                    
                    
                    // system.debug('>>>>>>>>>>> baseURL =' + baseURL);
                    // system.debug('>>>>>>>>>>> companyName =' + companyName);
                    // system.debug('>>>>>>>>>>> sandboxName =' + sandboxName);
                    // system.debug('>>>>>>>>>>> instanceName =' + instanceName);
                    // system.debug('>>>>>>>>>>> url =' + url);
                } else {
                    //sometimes, sandbox with My Domain already setup, the baseURL in Lightning Platform will not containt '.cs'
                    //for example, n4l--onboarding.my.salesforce.com
                    companyName = baseURL.substringBefore('--');
                    sandboxName = baseURL.substringBetween('--','.my');
                    
                }
                url += sandboxName + '-' + companyName + 'portal.' + instanceName + '.force.com/schoolictsupport/s/';
                //example: https://onboarding-n4lportal.cs116.force.com/schoolictsupport/s/
                
            }
        }
        return url;
    }

    //Reference - https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_class_Schema_RecordTypeInfo.htm#apex_Schema_RecordTypeInfo_methods
    public static ID getRecordTypeId(Schema.DescribeSObjectResult descSObject, String recordTypeName){
        Map<String,Schema.RecordTypeInfo> rtMapByName = descSObject.getRecordTypeInfosByName();
        Schema.RecordTypeInfo rtInfo =  rtMapByName.get(recordTypeName);
        return rtInfo.getRecordTypeId();
    }
    
    public static String currency(Decimal input) {
        String str = input.setScale(2).format();
        if(str.contains('.')){
            return (str.substringAfter('.').length() == 1? str + '0' : str);
        } else {
            return (str + '.00');
        }
    }
    
    public static String getRandomNumber(Integer requiredlength){
        Integer max = 13;
        Integer remaining = requiredlength;
        Integer length = 0;
        String randomNumber = '';

        if (requiredlength >= 1){
            do {
                length = (remaining > max ? max : remaining);
                randomNumber += String.valueof(Math.Random()).right(length);
                remaining -= length;
            }
            while (randomNumber.length()<requiredlength);
        }
        return randomNumber;
    }

    @future
    public static void createLogFile(String contentString, String title, String fileExtension, String libraryName){
        ContentVersion contentVersion = new ContentVersion(
            ContentLocation = 'S',
            PathOnClient = title + fileExtension,
            Title = title,
            VersionData = Blob.valueOf(contentString)
        );
        insert contentVersion;

        contentVersion = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =:contentVersion.Id]; //query again to get ContentDocumentId
        
        List<ContentWorkspace> contentWorkspaces = [SELECT Id, RootContentFolderId FROM ContentWorkspace WHERE Name =: libraryName LIMIT 1];
        ContentWorkspace contentWorkspace;
        If (!contentWorkspaces.IsEmpty()){
            contentWorkspace = contentWorkspaces[0];
        } else {
            contentWorkspace = [SELECT Id, RootContentFolderId FROM ContentWorkspace WHERE Name = 'System Admin Log Files' LIMIT 1]; //default to this library
        }
        
        ContentDocumentLink contentDocumentLink = new ContentDocumentLink(
            ContentDocumentId = contentVersion.contentDocumentId,
            ShareType = 'I',
            Visibility = 'AllUsers',
            LinkedEntityId = contentWorkspace.Id
        );
        
        insert contentDocumentLink;
    }

    public static String formatNZdatetime(Datetime input) {
        return (input == null? '' : input.format('dd/MM/YYYY hh:mm a'));
    }
    public static String formatNZdate(Datetime input) {
        return (input == null? '' : input.format('dd/MM/YYYY'));
    }
    public static String formatNZdate(Date input) {
        return (input == null? '' : formatNZdate(DateTime.newInstance(input.year(),input.month(),input.day())));//need to convert to datetime first, then apply format
    }
    public static String formatNZdatetimeWithStringMonth(Datetime input) {
        return (input == null? '' : input.format('EEEE d MMMM',  'Pacific/Auckland') + ' at ' + input.format('h:mm a',  'Pacific/Auckland'));
    }

    public static Date getNZdate(Datetime input) {
        if (input == null){
            return Date.newInstance(1700,1,1); //minimum date
        } else {
            String stringValue = helper.formatNZdate(input);
            List<String> dateParts = stringValue.split('\\/');
            return Date.newInstance(Integer.valueOf(dateParts[2]), Integer.valueOf(dateParts[1]), Integer.valueOf(dateParts[0]));    
        }
    }
    
    public static Map<string, List<N4LSetting__mdt>> getN4LSettings(){
        Map<string, List<N4LSetting__mdt>> settingsMap = new Map<string, List<N4LSetting__mdt>>();
        List<N4LSetting__mdt> settings = [SELECT DeveloperName, Id, Label, cryptoKey__c, secretKey__c, type__c, validFrom__c, validFor__c, token__c FROM N4LSetting__mdt ORDER BY type__c, validFrom__c DESC];
        For (N4LSetting__mdt setting : settings){
            if (settingsMap.containsKey(setting.type__c)){
                settingsMap.get(setting.type__c).add(setting);
            } else {
                List<N4LSetting__mdt> list1 =  new List<N4LSetting__mdt>();
                list1.add(setting);
                settingsMap.put(setting.type__c, list1);
            }
        }
        return settingsMap;
    }
    
    @AuraEnabled(cacheable=true)
    public static string getProgrammeMapping(){
        return JSON.serialize(Helper.getProgrammeNameMapping());
        //example {"NHR":{"attributes":{"type":"Programme_Name_Mapping__mdt","url":"/services/data/v49.0/sobjects/Programme_Name_Mapping__mdt/m055O0000000isMQAQ"},"DeveloperName":"NHR","Id":"m055O0000000isMQAQ","MasterLabel":"NHR","Description__c":"Was Network Hardware Replacement, now branded as Equipement Replacement.","Key__c":"ER","Programme__c":"School Network Upgrade - Equipment Replacement"},"NSE":{"attributes":{"type":"Programme_Name_Mapping__mdt","url":"/services/data/v49.0/sobjects/Programme_Name_Mapping__mdt/m055O0000000isRQAQ"},"DeveloperName":"NSE","Id":"m055O0000000isRQAQ","MasterLabel":"NSE","Description__c":"Was Network Support Extension, but re-branded as School Network Upgrade - Equipment Support","Key__c":"ES","Programme__c":"School Network Upgrade - Equipment Support"}}
    }

    public static Map<string, Programme_Name_Mapping__mdt> getProgrammeNameMapping(){
        Map<string, Programme_Name_Mapping__mdt> programmeMap = new Map<string, Programme_Name_Mapping__mdt>();
        List<Programme_Name_Mapping__mdt> programmes = [SELECT DeveloperName, Id, MasterLabel, Description__c, Key__c, Programme__c FROM Programme_Name_Mapping__mdt];
        For (Programme_Name_Mapping__mdt programme : programmes){
            programmeMap.put(programme.DeveloperName, programme);
        }
        return programmeMap;
    }

    // commonly used function to concatenate a list of strings.
    public static String concatenateKey(List<String> items) {
        String result = '';
        if(items != null){
            List<String> validStrings = new List<String>();
            for (String item : items){
                validStrings.add(getStringValue(item));
            }
            result = String.join(validStrings,'-');
        }
        return result;
    }

    // Will return an empty string if a value is null
    public static String getStringValue (String value) {
        return String.isBlank(value) ? '' : value;
    }

    //common function to convert a list of accounts into map
    public static Map<String, Account> createAccountMap(List<Account> accounts, String mode){
        Map<String, Account> result = new Map<String, Account>();
        switch on mode{
            when 'uuid'{
                for(Account account : accounts){
                    result.put(account.uuid__c, account);
                }
            }
        }
        return result;
    }
    /**get matched authorities metadata for a single role**/
    
    public static N4L_Role_Authority_Match__mdt getAuthorityMatchBySingleRole(String roleName){
        List<N4L_Role_Authority_Match__mdt> roleAuthorityList = [SELECT Id,MasterLabel,Default_authority_types__c,Is_Operational_emails_checked__c,
                    Is_Outage_notifications_checked__c, Is_periodic_emails_checked__c ,Role_Priority_Level__c
                    FROM N4L_Role_Authority_Match__mdt where MasterLabel=:roleName];
        system.debug(roleAuthorityList);
        return roleAuthorityList.size()>0 ? roleAuthorityList[0] : null;
    }
    
}