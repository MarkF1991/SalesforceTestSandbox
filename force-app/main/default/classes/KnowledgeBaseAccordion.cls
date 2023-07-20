public with sharing class KnowledgeBaseAccordion {
	@AuraEnabled
	public static List<KnowledgeBase__c> getList(String kbTopic, String kbType) {
		try {
			List<KnowledgeBase__c> listKB = [
				SELECT Id, Category__c, Description__c
				FROM KnowledgeBase__c
				WHERE Name = :kbTopic AND Type__c = :kbType
				ORDER BY Order__c ASC
			];
			if (Test.isRunningTest() && kbTopic == 'Error') {
				throw new IllegalArgumentException('Test Error');
			}
			return listKB;
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}
}