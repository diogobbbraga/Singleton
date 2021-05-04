trigger CaseTrigger on Case (before insert) {
	  Id pfId =  Account.getSObjectType().getDescribe().getRecordTypeInfosByDeveloperName().get('PF').getRecordTypeId();
    List<Id> listAccountIds = new List<Id>();
     
    for(Case varCase : Trigger.new) {
        listAccountIds.add(varCase.AccountId);
    }
    
    AccountSingletonDAO varAccountSingletonDAO = AccountSingletonDAO.getInstance();
    varAccountSingletonDAO.buildMapAccount(listAccountIds);
    
    for(Case varCase : Trigger.new) {
        if(varAccountSingletonDAO.getAccount(varCase.AccountId).RecordTypeId == pfId) {
            // instruções aqui
        }
    }
}
