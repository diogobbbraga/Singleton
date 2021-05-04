trigger CaseTrigger on Case (before insert) {
	Id pfId =  Account.getSObjectType().getDescribe().getRecordTypeInfosByDeveloperName().get('PF').getRecordTypeId();
    List<Id> listAccountIds = new List<Id>();
     
    for(Case varCase : Trigger.new) {
        listAccountIds.add(varCase.AccountId);
    }
    
    List<Account> listAccount = [SELECT Id,
                                 RecordTypeId
                                 FROM Account
                                 WHERE Id IN :listAccountIds];
    
    Map<Id, Account> mapAccount = new Map<Id, Account>(listAccount);
    
    for(Case varCase : Trigger.new) {
        if(mapAccount.get(varCase.AccountId).RecordTypeId == pfId) {
            // Instruções aqui
        }
    }
}
