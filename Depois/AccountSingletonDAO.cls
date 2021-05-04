public class AccountSingletonDAO {
    
    private static AccountSingletonDAO instance = null;
    
    private Map<Id, Account> mapAccount = new Map<Id, Account>();

    private AccountSingletonDAO() { }
    
    public static AccountSingletonDAO getInstance() {
        if(instance == null) {
            instance = new AccountSingletonDAO();
        }
        return instance;
    }
    
    public void buildMapAccount(List<Id> listAccountIds) {
        Set<Id> setDontContains = new Set<Id>();
        for(Id accountId : listAccountIds) {
            if(!mapAccount.containsKey(accountId)) {
                setDontContains.add(accountId);
            }
        }
        
        if(!setDontContains.isEmpty()) {
            mapAccount.putAll([SELECT Id, 
                               RecordTypeId 
                               FROM Account 
                               WHERE Id IN : listAccountIds]);
        }
    }
    
    public void addInMapAccount(Map<Id, Account> mapAccount) {
        this.mapAccount.putAll(mapAccount);
    }
    
    public void addInMapAccount(List<Account> listAccount) {
        this.mapAccount.putAll(listAccount);
    }
    
    public Account getAccount(Id accountId) {
        return this.mapAccount.get(accountId);
    }
}
