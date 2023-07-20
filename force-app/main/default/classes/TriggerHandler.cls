/**
 * TriggerHandler.cls
 * A pattern for dealing with execution of units
 * of work from triggers. It provides support for:
 * - bypassing units of work
 * - preventing/limiting recursion
 * - order of execution
 * - loop counting
 *
 * @author kevinohara80 https://github.com/kevinohara80/sfdc-trigger-framework
 * @author Logan Moore (Trineo)
 */
public virtual class TriggerHandler {

  // static map of handlername, times run() was invoked
  private static Map<String, LoopCount> loopCountMap;
  private static Set<String> bypassedHandlers;

  static {
    loopCountMap = new Map<String, LoopCount>();
    bypassedHandlers = new Set<String>();
  }

  public TriggerHandler() {

  }

  /***************************************
   * public methods
   ***************************************/

  // main method that will be called during execution
  public void run() {

    if(!validateRun()) return;

    addToLoopCount();

    // dispatch to the correct handler method
    if(Trigger.isBefore && Trigger.isInsert) {
      this.beforeInsert();
    } else if(Trigger.isBefore && Trigger.isUpdate) {
      this.beforeUpdate();
    } else if(Trigger.isBefore && Trigger.isDelete) {
      this.beforeDelete();
    } else if(Trigger.isAfter && Trigger.isInsert) {
      this.afterInsert();
    } else if(Trigger.isAfter && Trigger.isUpdate) {
      this.afterUpdate();
    } else if(Trigger.isAfter && Trigger.isDelete) {
      this.afterDelete();
    } else if(Trigger.isAfter && Trigger.isUndelete) {
      this.afterUndelete();
    }

  }

  public void setMaxLoopCount(Integer max) {
    String handlerName = getHandlerName();
    if(!TriggerHandler.loopCountMap.containsKey(handlerName)) {
      TriggerHandler.loopCountMap.put(handlerName, new LoopCount(max));
    } else {
      TriggerHandler.loopCountMap.get(handlerName).setMax(max);
    }
  }

  public void clearMaxLoopCount() {
    this.setMaxLoopCount(-1);
  }

  public static void bypass(String handlerName) {
    TriggerHandler.bypassedHandlers.add(handlerName);
  }

  public static void clearBypass(String handlerName) {
    TriggerHandler.bypassedHandlers.remove(handlerName);
  }

  public static Boolean isBypassed(String handlerName) {
    return TriggerHandler.bypassedHandlers.contains(handlerName);
  }

  public static void clearAllBypasses() {
    TriggerHandler.bypassedHandlers.clear();
  }

  /***************************************
   * private methods
   ***************************************/
  //n4l
  @TestVisible private void addToLoopCount() {
    String handlerName = getHandlerName();
    if(TriggerHandler.loopCountMap.containsKey(handlerName)) {
      Boolean exceeded = TriggerHandler.loopCountMap.get(handlerName).increment();
      if(exceeded) {
        Integer max = TriggerHandler.loopCountMap.get(handlerName).max;
        throw new TriggerHandlerException('Maximum loop count of ' + String.valueOf(max) + ' reached in ' + handlerName);
      }
    }
  }

  // make sure this trigger should continue to run
  //n4l
  @TestVisible private Boolean validateRun() {
      //n4l
    if(!Trigger.isExecuting && !Test.isRunningTest()) {
      throw new TriggerHandlerException('Trigger handler called outside of Trigger execution');
    }
    if(TriggerHandler.bypassedHandlers.contains(getHandlerName())&& !Test.isRunningTest()) {
      return false;
    }
    return true;
  }

  private String getHandlerName() {
    return String.valueOf(this).substring(0,String.valueOf(this).indexOf(':'));
  }

  /***************************************
   * context methods
   ***************************************/

  // context-specific methods for override
  @TestVisible protected virtual void beforeInsert(){}
  @TestVisible protected virtual void beforeUpdate(){}
  @TestVisible protected virtual void beforeDelete(){}
  @TestVisible protected virtual void afterInsert(){}
  @TestVisible protected virtual void afterUpdate(){}
  @TestVisible protected virtual void afterDelete(){}
  @TestVisible protected virtual void afterUndelete(){}

  /***************************************
   * inner classes
   ***************************************/

  // inner class for managing the loop count per handler
  // n4l 
  @TestVisible private class LoopCount {
    @TestVisible private Integer max;
    @TestVisible private Integer count;
    @TestVisible private Integer min=0;//n4l
    
    public LoopCount() {
      this.max = 5;
      this.count = 0;
    }

    public LoopCount(Integer max) {
      this.max = max;
      this.count = 0;
    }

    public Boolean increment() {
      this.count++;
      return this.exceeded();
    }

    public Boolean exceeded() {
      if(this.max < 0) return false;
      if(this.count > this.max) {
        return true;
      }
      return false;
    }

    public Integer getMax() {
      return this.max;
    }

    public Integer getCount() {
      return this.count;
    }

    public void setMax(Integer max) {
      this.max = max;
    }
      // n4l 
    public Integer getMim() {
      return this.min;
    }
   
    public void setMin(Integer min) {
      this.min = min;
    }
    public Boolean validateMin(Integer min,Integer max) {
      return this.min >this.max;
    }  
    public void addMax(Integer add) {
      this.max +=add;
    } 
    public void addMim(Integer add) {
      this.min +=add;
    }
    public void reduceMim(Integer reduce) {
      this.min -=reduce;
    }
    public void reduceMax(Integer reduce) {
      this.max -=reduce;
    }
    
      // n4l
       
  }

  // exception class
  public class TriggerHandlerException extends Exception {}

}