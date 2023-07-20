/**
 * a simple trigger on object simplesurvey__Survey__c after insert go update 
 * Survey_Completed__c in case object by assigning system.now which indecates
 * the survey from simple survey app has been completed.
*/
trigger TriggerOnSimpleSurvey on simplesurvey__Survey__c ( after insert )
{
      set<id> caseidSet = new set<id>();
for ( simplesurvey__Survey__c ss : trigger.new )
      {

            caseidSet.add ( ss.simplesurvey__Case__c );
      }
      if ( caseidSet.size() >0 )
      {
            SimpleSurveyHelpMethods.updateCaseSurveyCompleted ( caseidSet );
      }
}