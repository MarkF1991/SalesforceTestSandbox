/**
 * @Date               : March 25, 2021
 * @Description        : apex handler class for related school ict provider trigger
 * @Author             : Heidi Tang (heitang@deloitte.com)
**/
public with sharing class N4LRelatedICTTriggerHandler {

    public static void onAfterInsert(List<Related_School_ICTProvider__c> newList) {
        checkOnlyOnePrimaryICTProvider(newList);
        updateRelatedSchool(newList);
    }

    public static void onAfterUpdate(List<Related_School_ICTProvider__c> newList,Map<Id,Related_School_ICTProvider__c> oldListMap) {
        checkOnlyOnePrimaryICTProvider(newList);
        updateRelatedSchool(newList);
    }

    public static void onAfterDelete(List<Related_School_ICTProvider__c> oldList) {
        updateRelatedSchool(oldList);
    }

    public static void onAfterUnDelete(List<Related_School_ICTProvider__c> newList) {
        updateRelatedSchool(newList);
    }

    /** 
     * @Date: March 29, 2021
     * @Author: Heidi Tang (heitang@deloitte.com)
     * @Description: Method that blocks user from creating another primary ict provider in a school
     * @Params:
     * List<Related_School_ICTProvider__c> ictProviderList - list of ict providers to check
    **/
    private static void checkOnlyOnePrimaryICTProvider(List<Related_School_ICTProvider__c> ictProviderList) {
        Map<Id,List<Related_School_ICTProvider__c>> schoolICTProviderRelation = new Map<Id,List<Related_School_ICTProvider__c>>();
        Map<Id,Related_School_ICTProvider__c> schoolICTProviderRelationSingleMap = new Map<Id,Related_School_ICTProvider__c>();

        // check if records are of type primary
        for(Related_School_ICTProvider__c ictProvider : ictProviderList) {
            if(ictProvider.School__c != null 
                && ictProvider.Relationship__c.toLowerCase() == N4LStringConstants.ICTPROVIDER_RELATION_PRIMARY.toLowerCase()
                && ictProvider.Status__c == N4LStringConstants.ICTPROVIDER_STATUS_CURRENT) {
                if(!schoolICTProviderRelation.containsKey(ictProvider.School__c)) {
                    schoolICTProviderRelation.put(ictProvider.School__c,new List<Related_School_ICTProvider__c>());
                }
                
                schoolICTProviderRelation.get(ictProvider.School__c).add(ictProvider);                
            }
        }

        // throw error if more than 1 primary relationship
        for(String key : schoolICTProviderRelation.keySet()) {
            if(schoolICTProviderRelation.get(key).size()>1) {
                for(Related_School_ICTProvider__c relationsOnMap : schoolICTProviderRelation.get(key)) {
                    relationsOnMap.addError(System.Label.Screen_ICTOnePrimary);
                }
            } else {
                schoolICTProviderRelationSingleMap.put(key,schoolICTProviderRelation.get(key)[0]);
            }
        }

        List<Related_School_ICTProvider__c> existingICTProviders = [SELECT Id,School__c FROM Related_School_ICTProvider__c 
                                                                    WHERE School__c IN :schoolICTProviderRelationSingleMap.keySet()
                                                                    AND Relationship__c = :N4LStringConstants.ICTPROVIDER_RELATION_PRIMARY
                                                                    AND Status__c = :N4LStringConstants.ICTPROVIDER_STATUS_CURRENT
                                                                    AND Id NOT IN :schoolICTProviderRelationSingleMap.values()];

        // throw error if 1 primary relationship already exist in an account
        for(Related_School_ICTProvider__c existingICTProvider : existingICTProviders) {
            if(schoolICTProviderRelationSingleMap.containsKey(existingICTProvider.School__c)) {
                schoolICTProviderRelationSingleMap.get(existingICTProvider.School__c).addError(System.Label.Screen_ICTOnePrimary);
            }
        }
    }

    /** 
     * @Date: March 30, 2021
     * @Author: Heidi Tang (heitang@deloitte.com)
     * @Description: Method that updates related schools has external ict checkbox and nominated ict provider value
     * @Params:
     * List<Related_School_ICTProvider__c> ictProviderList - list of ict providers to check
    **/
    private static void updateRelatedSchool(List<Related_School_ICTProvider__c> ictProviderList) {
        Map<Id,List<Related_School_ICTProvider__c>> schoolICTProviderRelation = new Map<Id,List<Related_School_ICTProvider__c>>();

        // check if records are of type primary, if not set has external provider to false and nomnated ict provider to null
        for(Related_School_ICTProvider__c ictProvider : ictProviderList) {
            if(ictProvider.School__c != null) {
                if(!schoolICTProviderRelation.containsKey(ictProvider.School__c)) {
                    schoolICTProviderRelation.put(ictProvider.School__c,new List<Related_School_ICTProvider__c>());
                }
                
                schoolICTProviderRelation.get(ictProvider.School__c).add(ictProvider);                
            }
        }

        List<Account> acctList = [SELECT Id,Has_External_ICT_Provider__c,School_Nominated_ICT_Provider__c,
                                    (SELECT Id FROM Related_School_ICT_Providers__r 
                                        WHERE Relationship__c = :N4LStringConstants.ICTPROVIDER_RELATION_PRIMARY 
                                        AND Status__c = :N4LStringConstants.ICTPROVIDER_STATUS_CURRENT
                                    )
                                    FROM Account WHERE Id IN :schoolICTProviderRelation.keySet()];

        if(!acctList.isEmpty()) {

            for(Account acct : acctList) {
                if(acct.Related_School_ICT_Providers__r.isEmpty()) {
                    acct.Has_External_ICT_Provider__c = false;
                    acct.School_Nominated_ICT_Provider__c = null;
                }
            }

            update acctList;
        }
    }    
}