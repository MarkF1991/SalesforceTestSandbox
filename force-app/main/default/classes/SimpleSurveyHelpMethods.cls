public without sharing class SimpleSurveyHelpMethods
{

      @future
      public static void updateCaseSurveyCompleted ( set<id> ids )
      {

            List<Case> Cases = [Select Id, Survey_Completed__c From Case Where Id in :ids];
            List<Case> updateCases = new List<Case>();
            if ( Cases != null && Cases .size() > 0 )
            {
            for ( case c : Cases )
                        {
                              c.Survey_Completed__c = System.now();
                              updateCases .add ( c );
                        }

            }
            update ( updateCases );
      } 
}