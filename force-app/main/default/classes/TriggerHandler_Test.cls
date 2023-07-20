/**
 * TriggerHandler_Test.cls
 * Tests for the TriggerHandler class.
 * @author Logan Moore (Trineo)
 */
@isTest private class TriggerHandler_Test {

    /**
     * TriggerHandler is virtual and is difficult to write actual unit tests
     * for. This test just calls the non static methods to get sufficient coverage,
     * but does not assert behaviour. This could be improved.
     * @author Logan Moore (Trineo)
     */
    @isTest static void testCoverage() {
        TriggerHandler  th = new TriggerHandler();
        th.setMaxLoopcount(0);
        th.clearMaxLoopCount();
        TriggerHandler.bypass('testTrigger');
        System.assertEquals(TRUE, TriggerHandler.isBypassed('testTrigger'));
        TriggerHandler.clearByPass('testTrigger');
        System.assertEquals(FALSE, TriggerHandler.isBypassed('testTrigger'));
        TriggerHandler.bypass('testTrigger');
        System.assertEquals(TRUE, TriggerHandler.isBypassed('testTrigger'));
        TriggerHandler.clearAllBypasses();
        System.assertEquals(FALSE, TriggerHandler.isBypassed('testTrigger'));
        
        TriggerHandler.LoopCount thl = new TriggerHandler.LoopCount();
        TriggerHandler.LoopCount thl2 = new TriggerHandler.LoopCount(5);
        th.addToLoopCount();
        th.beforeInsert();
        th.beforeUpdate();
        th.beforeDelete();  
        th.afterInsert();
        th.afterUpdate();
        th.afterDelete();
        th.afterUndelete();
        th.validateRun();
        thl2.getMax();
        thl2.exceeded();
        thl2.getCount();
        thl2.getMim();
        thl2.setMin(0);
        thl2.validateMin(0,5);
        thl2.addMax(0);
        thl2.addMim(0);
        thl2.reduceMim(0);
        thl2.reduceMax(1); 
    }
    
}