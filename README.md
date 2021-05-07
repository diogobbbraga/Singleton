# Singleton - Padrão de projeto Apex

Fala desenvolvedores Salesforce! Hoje o assunto que venho falar com você é o padrão de projeto Singleton, esse que é o mais famoso dos padrões. Alguns até dizem que é um anti-padrão, eles argumentam que fere o princípio Single Responsibility do SOLID, ou que variáveis com acesso global não estão aderentes às boas práticas, também já ouvi dizerem que é porque ele mascara arquiteturas ruins, de qualquer forma é sempre bom conhecermos para podermos opinar com mais propriedade

      “Com grandes poderes vêm grandes responsabilidades”, Ben Parker
      
# O Problema

Você precisa que a execução do código tenha uma, e apenas uma instância de uma determinada classe.
Isso pode ocorrer em alguns cenários:
Para minimizar o processamento de criar novas instâncias;
Para reaproveitar dados do banco, diminuindo as interações com a base; ou
Pata ter um armazenador de dados que será utilizado em diversas classes;

# Solução

Implementar um Singleton em apex é bem simples, você precisa seguir somente esses três passos:

1° Crie um construtor privado

2° Crie uma variável estática onde o tipo é a própria classe e o acesso é privado

3° Crie o método getInstance onde verifica se a variável estática da classe é nula, caso seja, instancia e retorna, caso não seja, somente retorna a instância já existente.

    public class BasicSingleton {
        private static BasicSingleton instance = null;

        private BasicSingleton() { }

        public static BasicSingleton getInstance() {
            if(instance == null) {
                instance = new BasicSingleton();
            }
            return instance;
        }
    }


# Aplicação prática
Imagine as seguintes regras de negócio: 

Sempre que você cria uma conta do tipo PF um caso deve ser criado para essa conta;
Sempre que um caso é criado você precisa verificar se a conta associada é do tipo PF, se for, executa uma série de instruções.
Vamos ver primeiro como o código ficaria sem o uso do Singleton.

Nota: Neste exemplo por motivos didáticos não seguiremos todas as boas práticas de arquitetura, para que possamos fazer o entendimento do Singleton isoladamente.

Trigger da conta

    trigger AccountTrigger on Account (after insert) {
      Id pfId =  Account.getSObjectType().getDescribe().getRecordTypeInfosByDeveloperName().get('PF').getRecordTypeId();

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

Trigger do caso

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
    
    
Podemos ver que utilizamos um SELECT para buscar os dados das contas no banco, porém quando a trigger de caso é disparada pela trigger de conta nós já temos essas informações dentro do nosso processo, logo podemos otimizar o nosso código passando essas informações de uma trigger para a outra, e é aqui onde podemos usar o Singleton, ele vai nos ajudar a orquestrar essas informações.

Primeiro vamos criar uma classe onde podemos recuperar os dados de conta, para fazermos a otimização vamos utilizar os registros que já temos no processo e buscar somente os que não temos no banco, dessa forma:

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

Agora precisamos adicionar essa otimização nas triggers, primeiro vamos fazer a trigger armazenar esses dados no Singleton

    trigger AccountTrigger on Account (after insert) {
        Id pfId =  Account.getSObjectType().getDescribe().getRecordTypeInfosByDeveloperName().get('PF').getRecordTypeId();
        AccountSingletonDAO.getInstance().addInMapAccount(Trigger.newMap);

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
    
Agora temos que recuperar esses dados do nosso Singleton para a trigger de caso

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
    
# Alternativa de solução

Uma alternativa ao Singleton é o padrão MonoState, que ao contrário do Singleton não temos apenas uma instância única e sim múltiplas instâncias compartilhando as mesmas variáveis, no próximo artigo trago mais detalhes e exemplos para vermos juntos.
