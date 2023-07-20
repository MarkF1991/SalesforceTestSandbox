@isTest
public class KnowledgeBaseAccordionTest {
	@isTest
	static void testGetList() {
		KnowledgeBase__c kbArticle = new KnowledgeBase__c();

		kbArticle.Category__c = 'test category';
		kbArticle.Description__c = 'test description';
		kbArticle.Type__c = 'FAQ';
		kbArticle.Name = 'test name';

		insert kbArticle;

		List<KnowledgeBase__c> listName = KnowledgeBaseAccordion.getList(kbArticle.Name, kbArticle.Type__c);
	}

	@isTest
	static void testCatchError() {
		try {
			List<KnowledgeBase__c> listName = KnowledgeBaseAccordion.getList('Error', 'FAQ');
		} catch (exception e) {
		}
	}
}