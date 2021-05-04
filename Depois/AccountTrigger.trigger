trigger AccountTrigger on Account (after insert) {
	  Id pfId =  Account.getSObjectType().getDescribe().getRecordTypeInfosByDeveloperName().get('PF').getRecordTypeId();
    AccountManagerSingleton.getInstance().addInMapAccount(Trigger.newMap);
    
    List<Case> listCase = new List<Case>();
    
    for(Account varAccount : Trigger.new) {
        if(varAccount.RecordTypeId == pfId) {
            Case newCase = new Case();
            newCase.AccountId = varAccount.Id;
            listCase.add(newCase);
        }
    }
    
    insert listCase;
}
