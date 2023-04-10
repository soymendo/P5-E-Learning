trigger UpdateUnirUserHistory on Unit_User_History__c (after update) {
    if(Trigger.isAfter){
        UpdateUnirUserHistoryHelper.UpdateUnirUserHistory(Trigger.new);
    }
}