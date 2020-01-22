//@isTest 
public without sharing class TGS_Dummy_Test_Data {


    ///// Used in getPortalUser method    
    public enum PortalType { CSPLiteUser, PowerPartner, PowerCustomerSuccess, CustomerSuccess } 
    
    /**
    * @author José González, José Vicente Fernández, Jose Leonardo Lopez Manrique 
    * @date 06/06/2015
    * @description          Return a standard junction object Entitlement preparing the relationship with Account.
    *               
    *                       The Entitlement returned must be inserted by the developer on his own code.
    *
    * @param  name          A String with Name that will be assigned to the Entitlement.
    * @param  accountName   A String with the Account Name to be assigned to the Entitlement.
    * @return               new Entitlement with parameters options.
    */
    ///// Returns a Portal User with contact and full-account hierarchy; normal use should
    // work with userWithRole = null and doInsert = true

    //09/02/2017        Gawron, Julian              Adding Random Name
    public static User getPortalUser(PortalType portalType, User userWithRole, Boolean doInsert) {
        // Make sure the running user has a role otherwise an exception 
        // will be thrown.        
        if(userWithRole == null) {             
            userWithRole = getUserWithRole();
            System.assert(userWithRole.userRoleId != null, 
                          'This test requires the target org to have at least one UserRole created. Please create a user role in this organization and try again.');
        }
        

        Account a;
        Contact c;
        // An user with userRole is needed in the runAs() for the CWP user creation 
        System.runAs(userWithRole) {
            a = TGS_Dummy_Test_data.dummyHierarchy();
            //Database.insert(a);   Originally in the method; not neccesary since dummyHierachy() does the insert call      
            c = new Contact(AccountId = a.id,
                            lastname = 'lastname',
                            Email = 'contactTest@telefonica.com',
                            BI_Activo__c = true,
                            BI_Country__c = a.BI_Country__c
                            );
            Database.insert(c);

        }
        
        // Get any profile for the given type.
        Profile p = [SELECT Id 
                       FROM Profile 
                      WHERE UserType = :portalType.name() AND Name='TGS Customer Community Plus'
                      LIMIT 1];   
        String nombre = BI_DataLoad.generateRandomString(4); //JEG
        String testemail = 'puse'+ nombre +'@amamama.com';   //JEG
        User pu = new User(profileId = p.id, username = testemail, email = testemail, 
                           emailencodingkey = 'UTF-8', localesidkey = 'en_US', 
                           languagelocalekey = 'en_US', timezonesidkey = 'America/Los_Angeles', 
                           //alias='cspu', lastname='lastname', contactId = c.id, BI_Permisos__c = 'Empresas Platino',
                           alias='cspu' + nombre, lastname='lastname', contactId = c.id, BI_Permisos__c = 'TGS',
                          isActive = True);
        
        
        System.debug('PortalUser (dentro del dummie)' + pu);
        if(doInsert) {
            Database.insert(pu);
            // Start JMF 02/04/2016
            System.runAs(userWithRole) {
                addUsersToPortalGroup(new List<Id>{ pu.Id });
            }
            // End JMF 02/04/2016
            return [SELECT ProfileId, UserName, Email, EmailEncodingKey, LocalesIdKey, 
                       LanguageLocaleKey , TimeZonesIdKey, Alias, LastName, BI_Permisos__c, isActive,
                       ContactId, Contact.Id, Contact.Name, Contact.AccountId, 
                       Contact.Account.Id, Contact.Account.Name, Contact.Account.ParentId
                FROM User WHERE Id = : pu.Id LIMIT 1];
        } else {
            return pu;
        }
    }            
    
    /*
     *  @author Jose Miguel Fierro
     *  @date 03/03/2016
     *  @description          Returns a Portal User associated with a given account
     */
    public static User getPortalUserFromAccount(PortalType portalType, User userWRole, Account acco, Boolean doInsert) {
        User ret;
        String userFirstName = 'TestingFN';
        String userLastName = 'TestingLN';
        String userEmail = 'fnu@test.com';
        
        if(userWRole == null) {
            userWRole = getUserWithRole();
            System.assert(userWRole.UserRoleId != null,
                          'This test requires the target org to have at least one UserRole created. Please create a user role in this organization and try again.');
        }
        Contact c;
        System.runAs(userWRole) {
            c = new Contact(AccountId = acco.Id,
                            FirstName = userFirstName,
                            Lastname = userLastName,
                            Email = userEmail,
                            BI_Activo__c = true);
            insert c;
        }
        Profile prof = [SELECT Id FROM Profile WHERE UserType = :portalType.name() AND Name='TGS Customer Community Plus' LIMIT 1];
        
        ret = new User(ProfileId=prof.id, UserName=userEmail, Email=userEmail, LastName=userLastName, FirstName=userFirstName, ContactId=c.id,
                       EmailEncodingKey='UTF-8', LocalesIdKey='en_US', LanguageLocaleKey='en_US', TimezonesIdKey='America/Los_Angeles',
                       Alias='cspu', BI_Permisos__c = 'TGS', isActive = True);
        
        if(doInsert) {
            insert ret;
            // Start JMF 02/04/2016
            System.runAs(userWRole) {
                addUsersToPortalGroup(new List<Id>{ ret.Id });
            }
            // End JMF 02/04/2016
            return [SELECT Id, UserName, Email, FirstName, LastName, ContactId, Contact.Id, Contact.Name,
                        Contact.AccountId, Contact.Account.Id, Contact.Account.Name, Contact.Account.ParentId,
                        ProfileId,  EmailEncodingKey, LocalesIdKey, LanguageLocaleKey, TimeZonesIdKey, Alias, BI_Permisos__c, isActive
                FROM User WHERE Id = :ret.Id];
        }
        return ret;
    }
    
    /*
     * @author Jose Miguel Fierro
     * @date 03/03/2016
     * @description          Generate a user with a role for creating Portal Users
     *               
     * @return               User reference
     */
    public static User getUserWithRole(){
        if(UserInfo.getUserRoleId() == null) {
            UserRole r = new UserRole(Name = 'TEST ROLE');
            insert r;
            
           User u;
           Profile p = [Select Id From Profile Where Name='System Administrator' OR Name='Administrador del sistema'];
           u =  new User(Alias = 'hasrole', Email='userwithrole@roletest1.com', UserRoleId = r.id, LocalesIdKey='en_US', EmailEncodingKey='UTF-8',
                                    Lastname='Testing', LanguageLocaleKey='en_US', ProfileId = p.Id, TimezonesIdKey='America/Los_Angeles',
                                    UserName='userwithrole@testorg.com', BI_Permisos__c = 'TGS', isActive = true);
                insert u;
            System.runAs(new User(Id = UserInfo.getUserId())) {
				
                addUsersToPortalGroup(new List<Id>{ u.Id });
            }
            return u;
        } else {
            return new User(Id = UserInfo.getUserId(), UserRoleId = UserInfo.getUserRoleId());
        }
    }

    /**
     * @author Jose Miguel Fierro
     * @date 02/04/2016
     * @description          Adds users or groups to the portal users group. Requires runAs
     */
    public static void addUsersToPortalGroup(List<Id> lstURG) {
        List<Group> lstGrp = [SELECT Id FROM Group WHERE DeveloperName = 'TGS_Portal_users' LIMIT 1]; // 02/04/2016 - Real groups are visible in tests
        System.assertNotEquals(0, lstGrp.size(), 'The Group \'TGS_Portal_users\' cannot be found.');

        List<GroupMember> lgm = new List<GroupMember>();
        for(Id urg : lstURG) {
            lgm.add(new GroupMember(GroupId = lstGrp[0].Id, UserOrGroupId = urg));
        }
        insert lgm;
    }

    /**
     * @author Jose Miguel Fierro
     * @date 02/04/2016
     * @description         Grants a portal user or group visibility over a list of accounts
     */
    public static void addAccountShare(List<Id> lstURG, List<Account> lstAccs) {
        List<AccountShare> lstAccSh = new List<AccountShare>();
        for(Id urg : lstURG) {
            for(Account acc : lstAccs) {
                lstAccSh.add(new AccountShare(UserOrGroupId = urg, AccountId = acc.Id, AccountAccessLevel='Edit',
                            OpportunityAccessLevel = 'Read', CaseAccessLevel = 'Edit'));
            }
        }
        insert lstAccSh;
    }
    
    /**
    * @author José Vicente Fernández 
    * @date 06/06/2015
    * @description          Creates an owner and an account's hierarchy.
    *                       Only returns Legal Entity Account reference, but owner
    *                       and accounts can be referenced throught user reference
    *               
    * @return               Legal Entity Account reference
    */
    public static Account dummyHierarchy() {
        //Id rtId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Constants.RECORD_TYPE_HOLDING_ACCOUNT_LABEL).getRecordTypeId();
        // Level 1: Holding
        //Id rtId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Label.TGS_Holding).getRecordTypeId();
        List<Account> lstAccs = new List<Account>();
        Id rtId = TGS_RecordTypes_Util.getRecordTypeId(Account.SObjectType, Constants.RECORD_TYPE_TGS_HOLDING);
        Account holding = new Account(                     
            Name = 'Account Test Name - ' + Label.TGS_Holding + String.valueOf(Math.random()),
            RecordTypeId = rtId,
            BI_Country__c = 'Spain',
            BI_Segment__c = 'Empresas',
            BI_Subsegment_Regional__c='Corporate',
            TGS_Es_MNC__c = True,
            BI_No_Identificador_fiscal__c = 'a123'+ String.valueOf(Math.random()), //JEG
            BI_Tipo_de_identificador_fiscal__c = 'DNI', //JEG
            TGS_DirectFinal_Type__c = 'Direct Customer' //OGB
            );
        insert holding;
        lstAccs.add(holding);
        
        // Level 2: Customer Country
        //rtId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Label.TGS_Customer_Country).getRecordTypeId();
        rtId = TGS_RecordTypes_Util.getRecordTypeId(Account.SObjectType, Constants.RECORD_TYPE_TGS_CUSTOMER_COUNTRY);
        Account customerCountry = new Account(                     
            Name = 'Account Test Name - ' + Label.TGS_Customer_Country + String.valueOf(Math.random()),
            RecordTypeId = rtId,
            BI_Country__c = 'Spain', // JMF 19/10/2016 - Add Country
            BI_Segment__c = 'Empresas',
            BI_Subsegment_Regional__c='Corporate',
            TGS_Es_MNC__c = True,
            TGS_Aux_Holding__c = holding.Id,
            ParentId = holding.Id,
            BI_No_Identificador_fiscal__c = 'a124'+ String.valueOf(Math.random()), //JEG
            BI_Tipo_de_identificador_fiscal__c = 'DNI',
            TGS_DirectFinal_Type__c = 'Direct Customer' //JEG
            );
        insert customerCountry;
        lstAccs.add(customerCountry);
        
        // Level 3: Legal Entity
        //rtId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Label.TGS_Legal_Entity).getRecordTypeId();
        rtId = TGS_RecordTypes_Util.getRecordTypeId(Account.SObjectType, Constants.RECORD_TYPE_TGS_LEGAL_ENTITY);
        Account legalEntity = new Account(                     
            Name = 'Account Test Name - ' + Label.TGS_Legal_Entity + String.valueOf(Math.random()),
            RecordTypeId = rtId,
            ParentId = customerCountry.Id,
            BI_Country__c = 'Spain',
            BI_Segment__c = 'Empresas',
            BI_Subsegment_Regional__c='Corporate',
            TGS_Es_MNC__c = True,
            TGS_Aux_Holding__c = holding.Id,
            BI_No_Identificador_fiscal__c = 'a125'+ String.valueOf(Math.random()), //JEG
            BI_Tipo_de_identificador_fiscal__c = 'DNI',
            TGS_DirectFinal_Type__c = 'Direct Customer' //JEG
            );
        insert legalEntity;
        lstAccs.add(legalEntity);
        
        // Level 4: Business Unit
        //rtId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Label.TGS_Business_Unit).getRecordTypeId();
        rtId = TGS_RecordTypes_Util.getRecordTypeId(Account.SObjectType, Constants.RECORD_TYPE_TGS_BUSINESS_UNIT);
        Account businessUnit = new Account(                     
            Name = 'Account Test Name - ' + Label.TGS_Business_Unit + String.valueOf(Math.random()),
            RecordTypeId = rtId,
            ParentId = legalEntity.Id,
            BI_Segment__c = 'Empresas',
            BI_Subsegment_Regional__c='Corporate',
            TGS_Es_MNC__c = True,
            TGS_Aux_Holding__c = holding.Id,
            BI_No_Identificador_fiscal__c = 'a126'+ String.valueOf(Math.random()), //JEG
            BI_Tipo_de_identificador_fiscal__c = 'DNI',
            TGS_DirectFinal_Type__c = 'Direct Customer' //JEG
            );
        insert businessUnit;
        lstAccs.add(businessUnit);

        // Level 5: Cost Center
        //rtId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Label.TGS_Cost_Center).getRecordTypeId();
        //24/10/2016 JCT Added related accounts fields.Lines 263-265.
        rtId = TGS_RecordTypes_Util.getRecordTypeId(Account.SObjectType, Constants.RECORD_TYPE_TGS_COST_CENTER);
        Account costCenter = new Account(                     
            Name = 'Account Test Name - ' + Label.TGS_Cost_Center + String.valueOf(Math.random()),
            RecordTypeId = rtId,
            ParentId = businessUnit.Id,
            BI_Segment__c = 'Empresas',
            BI_Subsegment_Regional__c='Corporate',
            TGS_Es_MNC__c = True,
            TGS_Aux_Holding__c = holding.Id,
            TGS_Aux_Business_Unit__c = businessUnit.Id,
            TGS_Aux_Customer_Country__c = customerCountry.Id,
            TGS_Aux_Legal_Entity__c = legalEntity.Id,
            BI_No_Identificador_fiscal__c = 'a127'+ String.valueOf(Math.random()), //JEG
            BI_Tipo_de_identificador_fiscal__c = 'DNI',
            TGS_DirectFinal_Type__c = 'Direct Customer' //JEG
            );
        insert costCenter;
        lstAccs.add(costCenter);
        
        //legalEntity = [SELECT Name, Id, ParentId, Parent.ParentId, Parent.Parent.ParentId, RecordType.DeveloperName, TGS_Aux_Holding__c FROM Account WHERE id = :legalEntity.Id];
        legalEntity = [SELECT Name, Id, ParentId, Parent.ParentId, Parent.Parent.Name, Parent.Parent.Id, RecordType.DeveloperName, TGS_Aux_Holding__c, BI_Country__c FROM Account WHERE id = :legalEntity.Id];
        //System.debug('### 0: ' + legalEntity.Parent.Parent.ParentId);
        System.debug('### 1: ' + legalEntity.Parent.ParentId);
        System.debug('### 2: ' + legalEntity.ParentId);

        // Start JMF 02/04/2016 - Portal Users need to see Accounts in heirarchy
        List<Group> lstGrp = [SELECT Id FROM Group WHERE DeveloperName IN ('TGS_Portal_users')];
        List<Id> lstAccShIds = new List<Id>();
        lstAccShIds.addAll(new Map<Id, Group>(lstGrp).keySet());
        addAccountShare(lstAccShIds, lstAccs);
        // End JMF

        return legalEntity;
    }  


    /**
    * @author Marta Laliena
    * @date 06/06/2015
    * @description          Return a contact asociated to the indicated account.
    *
    * @param  accountId     An Id with the identification number of an account
    * @return               new contact associated to the account
    */
    public static Contact dummyContact(Id accountId){
        String nRandom = String.valueOf((Integer)(Math.random()*100));
        String mailName = 'telefonicaTest'+nRandom+'@tefonica.com';
        Contact contactTest = new Contact(LastName = 'contactTest',
                                          AccountId = accountId,
                                          Email = mailName
                                          /*
                                          Fax = '123456789',
                                          Phone = '123456789',
                                          MobilePhone = '123456789',
                                          BI_Id_del_contacto__c = 'test1',
                                          BI_Paises_ref__c = account1.BI_Pais_ref__c,
                                          BI_Activo__c = true,
                                          MailingCity = 'city1',
                                          BI_Tipo_de_documento__c = 'Otros',
                                          BI_Numero_de_documento__c = '1',
                                          TGS_Default_Cost_Center__c = account1.Id */
                                    );
        insert contactTest;
        return contactTest;
    }
        
    
    /*
    public static TGS_Portal_User_Configuration_Product__c dummyPortalUserConfigurationVisibility(String contactId) {
        //  Creates portal user configuration, portal user
        //    configuration product and commercial product 
        //    Returns portal user configuration product reference
        //    and need a contact (related to user)
        
        
     // Commercial Product 
        NE__Product__c productTest = new NE__Product__c(Name='Test Product');
        insert productTest;

     // Portal User Configuration 
        TGS_Portal_User_Configuration__c portalUserConfigTest = new TGS_Portal_User_Configuration__c(Contact__c = contactId);
        insert portalUserConfigTest;
        
     // Portal User Configuration Product 
        TGS_Portal_User_Configuration_Product__c portalUserConfigProductTest = 
                                new TGS_Portal_User_Configuration_Product__c(Portal_User_Configuration__c = portalUserConfigTest.Id,
                                                                             Commercial_Product__c = productTest.Id
                                                                            );
        insert portalUserConfigProductTest;
    
        return portalUserConfigProductTest;
    }
    */
    
    
    /**
    * @author Marta Laliena
    * @date 06/06/2015
    * @description          Return a Case of type "Incident" and status "Assigned".
    *
    * @return               new Incident Case
    */
    public static Case dummyTicketCase() {
        //Id rtId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Incident').getRecordTypeId();
        Id rtId = TGS_RecordTypes_Util.getRecordTypeId(Case.SObjectType, 'TGS_Incident');
         Contact c = TGS_Dummy_Test_Data.dummyContactTGS('Parker');
        insert c;
        Case caseTest = new Case(RecordTypeId = rtId , Subject = 'Test ticket case', Status = 'Assigned', ContactId=c.Id, TGS_Service__c = '1234567');
        insert caseTest;       
        return caseTest;
    }
    
    /**
    * @author Marta Laliena
    * @date 06/06/2015
    * @description          Return a Case of type "Order Management Case" and status "Assigned".
    *               
    * @return               new Order Management Case
    */
    public static Case dummyOrderCase() {
        //Id rtId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Order Management Case').getRecordTypeId();
        Id rtId = TGS_RecordTypes_Util.getRecordTypeId(Case.SObjectType, 'Order_Management_Case');
        Case testCaseOrder = new Case(RecordTypeId = rtId , Subject = 'Test order case', Status = 'Assigned', TGS_Acceptance_Date__c = System.today());
        insert testCaseOrder;
        return testCaseOrder;
    }
    
    /**
    * @author Marta Laliena
    * @date 06/06/2015
    * @description          Return a TGS_Work_Info__c asociated to the given case.
    *                       Attachments are created and asociated to the created TGS_Work_Info__c.
    *
    * @param  caseId        An Id with identification number of a case.
    * @return               new TGS_Work_Info__c with attachments and asociated to the given case.
    */
    public static TGS_Work_Info__c dummyWorkInfo(Id caseId) {
        TGS_Work_Info__c workInfoTest = new TGS_Work_Info__c(TGS_Case__c = caseId , TGS_Description__c = 'Test workinfo description', TGS_Public__c = false);
        insert workInfoTest;
        List<Attachment> listAtt = new List<Attachment>();
        Attachment attachmentTest = new Attachment(Name = 'Test Attachment', Body = Blob.valueOf('Test Body Attachment'), Description = 'Test Description Attachment', ParentId = workInfoTest.Id);
        listAtt.add(attachmentTest);
        Attachment attachmentTest2 = new Attachment(Name = 'Test Attachment2', Body = Blob.valueOf('Test Body Attachment'), Description = 'Test Description Attachment', ParentId = workInfoTest.Id);
        listAtt.add(attachmentTest2);
        Attachment attachmentTest3 = new Attachment(Name = 'Test Attachment3', Body = Blob.valueOf('Test Body Attachment'), Description = 'Test Description Attachment', ParentId = workInfoTest.Id);
        listAtt.add(attachmentTest3);
        insert listAtt;
        return workInfoTest;
    }
        
    /**
    * @author Marta Laliena
    * @date 06/06/2015
    * @description          Return a TGS_Work_Info__c asociated to a created case.
    *                       Attachments are created and asociated to the created TGS_Work_Info__c.
    *
    * @return               new TGS_Work_Info__c with attachments and asociated to a new case.
    */
    public static Case dummyCaseWithAttachments() {
        //Id rtId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Incident').getRecordTypeId();
        Id rtId = TGS_RecordTypes_Util.getRecordTypeId(Case.SObjectType, 'TGS_Incident');
        Contact c = TGS_Dummy_Test_Data.dummyContactTGS('Parker');
        insert c;
        Case caseTest = new Case(RecordTypeId = rtId , Subject = 'Test case subject', Status = 'Assigned', ContactId=c.Id);
        insert caseTest;
        TGS_Work_Info__c workInfoTest = new TGS_Work_Info__c(TGS_Case__c = caseTest.Id , TGS_Description__c = 'Test workinfo description', TGS_Public__c = true);
        insert workInfoTest;
        List<Attachment> listAtt = new List<Attachment>();
        Attachment attachmentTest = new Attachment(Name = 'Test Attachment', Body = Blob.valueOf('Test Body Attachment'), Description = 'Test Description Attachment', ParentId = workInfoTest.Id);
        listAtt.add(attachmentTest);
        Attachment attachmentTest2 = new Attachment(Name = 'Test Attachment2', Body = Blob.valueOf('Test Body Attachment'), Description = 'Test Description Attachment', ParentId = workInfoTest.Id);
        listAtt.add(attachmentTest2);
        Attachment attachmentTest3 = new Attachment(Name = 'Test Attachment3', Body = Blob.valueOf('Test Body Attachment'), Description = 'Test Description Attachment', ParentId = workInfoTest.Id);
        listAtt.add(attachmentTest3);
        insert listAtt;
        return caseTest;
    }
    
    /**
    * @author Marta Laliena
    * @date 06/06/2015
    * @description          Return an order.
    *
    * @return               new Order.
    */
    public static NE__Order__c dummyOrder() {
        //Id rtId = Schema.SObjectType.NE__Order__c.getRecordTypeInfosByName().get('Order').getRecordTypeId();
        Id rtId = TGS_RecordTypes_Util.getRecordTypeId(NE__Order__c.SObjectType, 'Order');
        NE__Order__c testOrder = new NE__Order__c(RecordTypeId = rtId);
        insert testOrder;
        return testOrder;
    }
    
    /*public static NE__Catalog_Item__c dummyCatalogItem() {
        NE__Catalog__c testCatalog = new NE__Catalog__c(Name='Test Catalog');
        insert testCatalog;
        NE__Catalog_Category__c testCatalogCategory = new NE__Catalog_Category__c(Name='Test Category', NE__CatalogId__c = testCatalog.Id);
        insert testCatalogCategory;
        NE__Product__c testProduct = new NE__Product__c(Name='Test Product');
        insert testProduct;
        NE__Catalog_Item__c testCatalogItem = new NE__Catalog_Item__c(NE__Catalog_Category_Name__c = testCatalogCategory.Id, NE__Catalog_Id__c = testCatalog.Id, NE__ProductId__c = testProduct.Id );
        insert testCatalogItem;
        return testCatalogItem;
    }*/
    
    /**
    * @author Marta Laliena
    * @date 06/06/2015
    * @description          Return a catalog item asociatted with a created product.
    *                       A catalog is created, as well as a category and subcategory.
    *                       The catalog item is placed the subcategory of the catalog.
    *
    * @return               new NE__Catalog_Item__c asociatted with a product and placed in a subcategory of a catalog.
    */
    public static NE__Catalog_Item__c dummyCatalogItem() {
        NE__Catalog__c testCatalog = new NE__Catalog__c(Name='Test Catalog');
        insert testCatalog;
        NE__Catalog_Category__c testCatalogCategory = new NE__Catalog_Category__c(Name='Test Category', NE__CatalogId__c = testCatalog.Id);
        insert testCatalogCategory;
        NE__Catalog_Category__c testCatalogSubCategory = new NE__Catalog_Category__c(Name='Test SubCategory', NE__CatalogId__c = testCatalog.Id, NE__Parent_Category_Name__c = testCatalogCategory.Id);
        insert testCatalogSubCategory;
        NE__Product__c testProduct = new NE__Product__c(Name='Test Product');
        insert testProduct;
        NE__Catalog_Item__c testCatalogItem = new NE__Catalog_Item__c(NE__Catalog_Category_Name__c = testCatalogSubCategory.Id, NE__Catalog_Id__c = testCatalog.Id, NE__ProductId__c = testProduct.Id );
        insert testCatalogItem;
        return testCatalogItem;
    }
    
    /**
    * @author Marta Laliena
    * @date 06/06/2015
    * @description          Return order item of a catalog item, that is created and associated to a product.
    *                       A catalog with its category and subcategory are created, and is where the catalog item is placed.
    *               
    * @return               new NE__OrderItem__c of a catalog item.
    */
    public static NE__OrderItem__c dummyOrderItem() {
        //Id rtId = Schema.SObjectType.NE__Order__c.getRecordTypeInfosByName().get('Order').getRecordTypeId();
        Id rtId = TGS_RecordTypes_Util.getRecordTypeId(NE__Order__c.SObjectType, 'Order');
        NE__Order__c testOrder = new NE__Order__c(RecordTypeId = rtId);
        insert testOrder;
        NE__Catalog__c testCatalog = new NE__Catalog__c(Name='Test Catalog');
        insert testCatalog;
        NE__Catalog_Category__c testCatalogCategory = new NE__Catalog_Category__c(Name='Test Category', NE__CatalogId__c = testCatalog.Id);
        insert testCatalogCategory;
        NE__Catalog_Category__c testCatalogSubCategory = new NE__Catalog_Category__c(Name='Test SubCategory', NE__CatalogId__c = testCatalog.Id, NE__Parent_Category_Name__c = testCatalogCategory.Id);
        insert testCatalogSubCategory;
        NE__Product__c testProduct = new NE__Product__c(Name='Test Product');
        insert testProduct;
        NE__Catalog_Item__c testCatalogItem = new NE__Catalog_Item__c(NE__Catalog_Category_Name__c = testCatalogSubCategory.Id, NE__Catalog_Id__c = testCatalog.Id, NE__ProductId__c = testProduct.Id );
        insert testCatalogItem;
        //ACR 03/12/2019 - Recoger RT con Schema
        String idRt = Schema.SObjectType.NE__OrderItem__c.getRecordTypeInfosByDeveloperName().get('StanStandarddard').getRecordTypeId();
        NE__OrderItem__c testOrderItem = new NE__OrderItem__c(REcordTypeId=idRt,NE__OrderId__c = testOrder.Id, NE__ProdId__c = testProduct.Id, NE__CatalogItem__c = testCatalogItem.Id, NE__Qty__c=1);
        insert testOrderItem;
        return testOrderItem;
    }

     /**
    * @author Marta Laliena
    * @date 06/06/2015
    * @description          Return a order item with attributes and an order. The catalog hierarchy is created,
    *                       as well as a catalog item that is associated to a product. The product
    *                       has a family that contains attributes.
    * 
    * @return               new NE__OrderItem__c with attributes and an order.
    */
    public static NE__OrderItem__c dummyConfigurationOrder() {
        //Id rtId = Schema.SObjectType.NE__Order__c.getRecordTypeInfosByName().get('Order').getRecordTypeId();
        Id rtId = TGS_RecordTypes_Util.getRecordTypeId(NE__Order__c.SObjectType, 'Order');
        NE__Order__c testOrder = new NE__Order__c(RecordTypeId = rtId, NE__Type__c = 'Asset');
        insert testOrder;
        NE__Catalog__c testCatalog = new NE__Catalog__c(Name='Test Catalog');
        insert testCatalog;
        NE__Catalog_Category__c testCatalogCategory = new NE__Catalog_Category__c(Name='Test Category', NE__CatalogId__c = testCatalog.Id);
        insert testCatalogCategory;
        NE__Catalog_Category__c testCatalogSubCategory = new NE__Catalog_Category__c(Name='Test SubCategory', NE__CatalogId__c = testCatalog.Id, NE__Parent_Category_Name__c = testCatalogCategory.Id);
        insert testCatalogSubCategory;
        
        NE__Product__c testProduct = new NE__Product__c(Name='Test Product');
        insert testProduct;
     /* Family property*/
        NE__Family__c family = new NE__Family__c(Name = 'Product Family');
        insert family;
        Id recordtypelookup = TGS_RecordTypes_Util.getRecordTypeId(NE__DynamicPropertyDefinition__c.SObjectType, 'Dynamic_Lookup');
        NE__DynamicPropertyDefinition__c property = new NE__DynamicPropertyDefinition__c(Name = 'Attribute 1', NE__Type__c = 'Dynamic Lookup', NE__Show_As__c = 'Lookup', RecordTypeId= recordtypelookup);
        insert property;
        System.debug(property.RecordTypeId);
        NE__ProductFamilyProperty__c familyProp = new NE__ProductFamilyProperty__c(NE__FamilyId__c = family.Id, NE__PropId__c = property.Id, NE__Required__c = 'No', TGS_Is_key_attribute__c = true);
        insert familyProp;
        NE__ProductFamily__c productFamily = new NE__ProductFamily__c(NE__ProdId__c = testProduct.Id, NE__FamilyId__c = family.Id);
        insert productFamily;
        
        NE__Catalog_Item__c testCatalogItem = new NE__Catalog_Item__c(NE__Type__c = 'Product', NE__Catalog_Category_Name__c = testCatalogSubCategory.Id, NE__Catalog_Id__c = testCatalog.Id, NE__ProductId__c = testProduct.Id );
        insert testCatalogItem;
        //ACR 03/12/2019 - Recoger RT con Schema
		String idRt = Schema.SObjectType.NE__OrderItem__c.getRecordTypeInfosByDeveloperName().get('StanStandarddard').getRecordTypeId();
        NE__OrderItem__c testOrderItem = new NE__OrderItem__c(RecordTypeId=idRt,NE__OrderId__c = testOrder.Id, NE__ProdId__c = testProduct.Id, NE__CatalogItem__c = testCatalogItem.Id, NE__Qty__c=1);
        insert testOrderItem;
     /* Attribute of the OrderItem*/
        List<NE__Order_Item_Attribute__c> ListAttributes =  new List<NE__Order_Item_Attribute__c>();
        
        NE__Order_Item_Attribute__c attribute = new NE__Order_Item_Attribute__c(Name = 'Attribute 1', NE__Value__c = 'test', NE__Order_Item__c = testOrderItem.Id, NE__FamPropId__c=familyProp.Id );
        ListAttributes.add(attribute);
        NE__Order_Item_Attribute__c attributeID = new NE__Order_Item_Attribute__c(Name = 'Attribute 1_id', NE__Value__c = 'test', NE__Order_Item__c = testOrderItem.Id, NE__FamPropId__c=familyProp.Id );
        ListAttributes.add(attributeID);
        NE__Order_Item_Attribute__c attributeClass = new NE__Order_Item_Attribute__c(Name = 'Attribute 1_class', NE__Value__c = '', NE__Order_Item__c = testOrderItem.Id, NE__FamPropId__c=familyProp.Id );
        ListAttributes.add(attributeClass);
        insert ListAttributes;
     
      /* Case*/ 
        //rtId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Order Management Case').getRecordTypeId();
        rtId = TGS_RecordTypes_Util.getRecordTypeId(Case.SObjectType, 'Order_Management_Case');
        Contact CaseContact = TGS_Dummy_Test_Data.dummyContactTGS('Parker');
        insert CaseContact;
        Case testCase = new Case(RecordTypeId = rtId, Subject = 'Test Case', Status = 'Assigned', Order__c = testOrder.Id, Type = 'New', TGS_Customer_Services__c = testOrderItem.Id, TGS_Invoice_Date__c = date.today(),ContactId = CaseContact.id, AccountId = CaseContact.AccountId);
        insert testCase;
        testOrder.Case__c = testCase.Id;
        update testOrder;
        return testOrderItem;
    }
    
    /*---------------------------------------------*/
    public static NE__OrderItem__c dummyConfiguration() {
        Id rtId = Schema.SObjectType.NE__Order__c.getRecordTypeInfosByName().get('Order').getRecordTypeId();
        NE__Order__c testOrder = new NE__Order__c(RecordTypeId = rtId);
        System.debug('#|@# rtId: ' + rtId);
        System.debug('#|@# testOrder: ' + testOrder);
        
        insert testOrder;
        NE__Catalog__c testCatalog = new NE__Catalog__c(Name='Test Catalog');
        insert testCatalog;
        NE__Catalog_Category__c testCatalogCategory = new NE__Catalog_Category__c(Name='Test Category', NE__CatalogId__c = testCatalog.Id);
        insert testCatalogCategory;
        NE__Catalog_Category__c testCatalogSubCategory = new NE__Catalog_Category__c(Name='Test SubCategory', NE__CatalogId__c = testCatalog.Id, NE__Parent_Category_Name__c = testCatalogCategory.Id);
        insert testCatalogSubCategory;
        NE__Product__c testProduct = new NE__Product__c(Name='Test Product');
        insert testProduct;

        /* Family property*/
        NE__Family__c family = new NE__Family__c(Name = 'Product Family');
        insert family;
        NE__DynamicPropertyDefinition__c property = new NE__DynamicPropertyDefinition__c(Name = 'Attribute 1', NE__Type__c = 'String');
        insert property;
        NE__ProductFamilyProperty__c familyProp = new NE__ProductFamilyProperty__c(NE__FamilyId__c = family.Id, NE__PropId__c = property.Id, NE__Required__c = 'No', TGS_Is_key_attribute__c = true);
        insert familyProp;
        NE__ProductFamily__c productFamily = new NE__ProductFamily__c(NE__ProdId__c = testProduct.Id, NE__FamilyId__c = family.Id);
        insert productFamily;
        
        NE__Catalog_Item__c testCatalogItem = new NE__Catalog_Item__c(NE__Type__c = 'Product', NE__Catalog_Category_Name__c = testCatalogSubCategory.Id, NE__Catalog_Id__c = testCatalog.Id, NE__ProductId__c = testProduct.Id,NE__Technical_Behaviour__c='Technical Behaviour');
        insert testCatalogItem;
        //ACR 03/12/2019 - Recoger RT con Schema
		String idRt = Schema.SObjectType.NE__OrderItem__c.getRecordTypeInfosByDeveloperName().get('StanStandarddard').getRecordTypeId();
        NE__OrderItem__c testOrderItem = new NE__OrderItem__c(RecordTypeId=idRt,NE__OrderId__c = testOrder.Id, NE__ProdId__c = testProduct.Id, NE__CatalogItem__c = testCatalogItem.Id, NE__Qty__c=1);
        insert testOrderItem;

        /* Attribute of the OrderItem*/
        NE__Order_Item_Attribute__c attribute = new NE__Order_Item_Attribute__c(Name = 'Attribute 1', NE__Value__c = 'test', NE__Order_Item__c = testOrderItem.Id);
        insert attribute;

        /* Case */
        rtId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Incident').getRecordTypeId();
        Contact CaseContact = TGS_Dummy_Test_Data.dummyContactTGS('Parker');
        insert CaseContact;


         // Level 1: Holding
            Id recordtypeId = TGS_RecordTypes_Util.getRecordTypeId(Account.SObjectType, Constants.RECORD_TYPE_TGS_HOLDING);
            Account holding = new Account(                     
                Name = 'Dummy holding',
                RecordTypeId = recordtypeId,
                BI_Country__c = 'Spain',
                BI_Segment__c = 'Empresas',
                BI_Subsegment_Regional__c='Corporate',
                TGS_Es_MNC__c = True,
                TGS_DirectFinal_Type__c = 'Direct Customer');
            insert holding;
            
            // Level 2: Customer Country
            recordtypeId = TGS_RecordTypes_Util.getRecordTypeId(Account.SObjectType, Constants.RECORD_TYPE_TGS_CUSTOMER_COUNTRY);
            Account customerCountry = new Account(                     
                Name = 'Account Test Name - ' + Label.TGS_Customer_Country + String.valueOf(Math.random()),
                RecordTypeId = recordtypeId,
                BI_Country__c = 'Spain', // JMF 19/10/2016 - Add Country
                BI_Segment__c = 'Empresas',
                BI_Subsegment_Regional__c='Corporate',
                TGS_Es_MNC__c = True,
                TGS_Aux_Holding__c = holding.Id,
                ParentId = holding.Id,
                TGS_DirectFinal_Type__c = 'Direct Customer');
            insert customerCountry;
            
            // Level 3: Legal Entity
            recordtypeId = TGS_RecordTypes_Util.getRecordTypeId(Account.SObjectType, Constants.RECORD_TYPE_TGS_LEGAL_ENTITY);
            Account legalEntity = new Account(                     
                Name = 'Account Test Name - ' + Label.TGS_Legal_Entity + String.valueOf(Math.random()),
                RecordTypeId = recordtypeId,
                ParentId = customerCountry.Id,
                BI_Country__c = 'Spain',
                BI_Segment__c = 'Empresas',
                BI_Subsegment_Regional__c='Corporate',
                TGS_Es_MNC__c = True,
                TGS_Aux_Holding__c = holding.Id,
                TGS_DirectFinal_Type__c = 'Direct Customer');
            insert legalEntity;
            
            // Level 4: Business Unit
            recordtypeId = TGS_RecordTypes_Util.getRecordTypeId(Account.SObjectType, Constants.RECORD_TYPE_TGS_BUSINESS_UNIT);
            Account businessUnit = new Account(                     
                Name = 'Account Test Name - ' + Label.TGS_Business_Unit + String.valueOf(Math.random()),
                RecordTypeId = recordtypeId,
                ParentId = legalEntity.Id,
                BI_Segment__c = 'Empresas',
                BI_Subsegment_Regional__c='Corporate',
                TGS_Es_MNC__c = True,
                TGS_Aux_Holding__c = holding.Id,
                TGS_DirectFinal_Type__c = 'Direct Customer');
            insert businessUnit;

            // Level 5: Cost Center
            recordtypeId = TGS_RecordTypes_Util.getRecordTypeId(Account.SObjectType, Constants.RECORD_TYPE_TGS_COST_CENTER);
            Account costCenter = new Account(                     
                Name = 'Account Test Name - ' + Label.TGS_Cost_Center + String.valueOf(Math.random()),
                RecordTypeId = recordtypeId,
                ParentId = businessUnit.Id,
                BI_Segment__c = 'Empresas',
                BI_Subsegment_Regional__c='Corporate',
                TGS_Es_MNC__c = True,
                TGS_Aux_Holding__c = holding.Id,
                TGS_Aux_Business_Unit__c = businessUnit.Id,
                TGS_Aux_Customer_Country__c = customerCountry.Id,
                TGS_Aux_Legal_Entity__c = legalEntity.Id,
                TGS_DirectFinal_Type__c = 'Direct Customer'
                );
            insert costCenter;

            TGS_Tier_Dependence__c tr_CustomSetting3 = new TGS_Tier_Dependence__c();
            tr_CustomSetting3.Name = 'Test CS Record3';
            tr_CustomSetting3.TGS_Holding_Name__c = 'Dummy holding';
            tr_CustomSetting3.TGS_RTDevName__c = 'TGS_Incident';
            tr_CustomSetting3.TGS_Product_Tier_1__c = 'Dummy tier 1';
            tr_CustomSetting3.TGS_Product_Tier_2__c = 'Dummy tier 2';
            tr_CustomSetting3.TGS_Product_Tier_3__c = 'Dummy tier 3';
            insert tr_CustomSetting3;


        Case testCase = new Case(RecordTypeId = rtId, Subject = 'Test Case', Status = 'Assigned', TGS_Status_reason__c='', Order__c = testOrder.Id, ContactId = CaseContact.Id, Type='New', TGS_Service__c = testProduct.Name, AccountId = legalEntity.Id, TGS_Product_Tier_1__c = 'Dummy tier 1',
                                TGS_Product_Tier_2__c = 'Dummy tier 2',
                                TGS_Product_Tier_3__c = 'Dummy tier 3'); 
        insert testCase;

        Account accountLE = TGS_Dummy_Test_Data.dummyHierarchy();
        // Start JMF 01/04/2016
        List<Account> lstAccs = [SELECT Id, Name, HoldingId__c, RecordType.Name, Parent.Id, Parent.Name FROM Account WHERE Parent.ParentId = :accountLE.Id];
        System.assertNotEquals(0, lstAccs.size(), 'No Cost Centers were created for the legal entity');
        Account accountCC = lstAccs[0];
        Account accountBU = lstAccs[0].Parent;
        // End JMF 01/04/2016

        testOrder.Case__c = testCase.Id;
        testOrder.HoldingId__c = accountCC.HoldingId__c;
        testOrder.NE__AccountId__c = accountLE.Id;
        // Start JMF 01/04/2016
        testOrder.NE__ServAccId__c = accountBU.Id;
        testOrder.NE__BillAccId__c = accountCC.Id;
        testOrder.Cost_Center__c = accountCC.Id;
        // End JMF 01/04/2016
        //System.assert(accountCC.RecordType.Name.contains('Cost Center'));
        update testOrder;
        return testOrderItem;
    }
/*---------------------------------------------*/
    public static NE__OrderItem__c dummyConfigurationOrderLookup() {
        //Id rtId = Schema.SObjectType.NE__Order__c.getRecordTypeInfosByName().get('Order').getRecordTypeId();
        Id rtId = TGS_RecordTypes_Util.getRecordTypeId(NE__Order__c.SObjectType, 'Order');
        
        NE__Order__c testOrder = new NE__Order__c(RecordTypeId = rtId, NE__Type__c = 'Asset');
        insert testOrder;
        NE__Catalog__c testCatalog = new NE__Catalog__c(Name='Test Catalog');
        insert testCatalog;
        NE__Catalog_Category__c testCatalogCategory = new NE__Catalog_Category__c(Name='Test Category', NE__CatalogId__c = testCatalog.Id);
        insert testCatalogCategory;
        NE__Catalog_Category__c testCatalogSubCategory = new NE__Catalog_Category__c(Name='Test SubCategory', NE__CatalogId__c = testCatalog.Id, NE__Parent_Category_Name__c = testCatalogCategory.Id);
        insert testCatalogSubCategory;
        
        NE__Product__c testProduct = new NE__Product__c(Name='Test Product');
        insert testProduct;
     /* Family property*/
        NE__Family__c family = new NE__Family__c(Name = 'Product Family');
        insert family;
        Id recordtypelookup = TGS_RecordTypes_Util.getRecordTypeId(NE__DynamicPropertyDefinition__c.SObjectType, 'Dynamic_Lookup'); 
        System.debug('$$$$'+recordtypelookup );
        NE__DynamicPropertyDefinition__c property = new NE__DynamicPropertyDefinition__c(NE__Type__c = 'Dynamic Lookup', Name = 'Attribute 1', RecordTypeId=recordtypelookup);
        insert property;
        
        NE__DynamicPropertyDefinition__c propertyID = new NE__DynamicPropertyDefinition__c(Name = 'Attribute 1_id', NE__Type__c = 'String');
        insert propertyID;    
            
        NE__DynamicPropertyDefinition__c propertyClass = new NE__DynamicPropertyDefinition__c(Name = 'Attribute 1_class', NE__Type__c = 'String');
        insert propertyClass;    
            
        NE__ProductFamilyProperty__c familyProp = new NE__ProductFamilyProperty__c(NE__FamilyId__c = family.Id, NE__PropId__c = property.Id, NE__Required__c = 'No', TGS_Is_key_attribute__c = true, NE__Dynamic_Lookup__c = '');
        insert familyProp;
        NE__ProductFamilyProperty__c familyPropClass = new NE__ProductFamilyProperty__c(NE__FamilyId__c = family.Id, NE__PropId__c = propertyClass.Id, NE__Required__c = 'No', TGS_Is_key_attribute__c = true);
        insert familyPropClass;
        NE__ProductFamilyProperty__c familyPropID = new NE__ProductFamilyProperty__c(NE__FamilyId__c = family.Id, NE__PropId__c = propertyID.Id, NE__Required__c = 'No', TGS_Is_key_attribute__c = true);
        insert familyPropID;   
            
        NE__ProductFamily__c productFamily = new NE__ProductFamily__c(NE__ProdId__c = testProduct.Id, NE__FamilyId__c = family.Id);
        insert productFamily;
        
        NE__Catalog_Item__c testCatalogItem = new NE__Catalog_Item__c(NE__Type__c = 'Product', NE__Catalog_Category_Name__c = testCatalogSubCategory.Id, NE__Catalog_Id__c = testCatalog.Id, NE__ProductId__c = testProduct.Id );
        insert testCatalogItem;
        // FAR 10/03/2016
        //ACR 03/12/2019 - Recoger RT con Schema
		String idRt = Schema.SObjectType.NE__OrderItem__c.getRecordTypeInfosByDeveloperName().get('StanStandarddard').getRecordTypeId();
        //NE__OrderItem__c testOrderItem = new NE__OrderItem__c(NE__OrderId__c = testOrder.Id, NE__ProdId__c = testProduct.Id, NE__CatalogItem__c = testCatalogItem.Id, NE__Qty__c = 1);
        NE__OrderItem__c testOrderItem = new NE__OrderItem__c(RecordTypeId=idRt,NE__OrderId__c = testOrder.Id, NE__ProdId__c = testProduct.Id, NE__CatalogItem__c = testCatalogItem.Id, NE__Qty__c = 1, Integration_Id__c = 'dummyIntegrationId');
        insert testOrderItem;
     /* Attribute of the OrderItem*/
        List<NE__Order_Item_Attribute__c> ListAttributes =  new List<NE__Order_Item_Attribute__c>();
        
        NE__Order_Item_Attribute__c attribute = new NE__Order_Item_Attribute__c(Name = 'Attribute 1', NE__Value__c = 'test', NE__Order_Item__c = testOrderItem.Id, NE__FamPropId__c=familyProp.Id );
        ListAttributes.add(attribute);
        NE__Order_Item_Attribute__c attributeID = new NE__Order_Item_Attribute__c(Name = 'Attribute 1_id', NE__Value__c = 'test', NE__Order_Item__c = testOrderItem.Id, NE__FamPropId__c=familyProp.Id );
        ListAttributes.add(attributeID);
        NE__Order_Item_Attribute__c attributeClass = new NE__Order_Item_Attribute__c(Name = 'Attribute 1_class', NE__Value__c = '', NE__Order_Item__c = testOrderItem.Id, NE__FamPropId__c=familyProp.Id );
        ListAttributes.add(attributeClass);
        // FAR 10/03/2016
        NE__Order_Item_Attribute__c attributeIntegrationId = new NE__Order_Item_Attribute__c(Name = 'Integration_id', NE__Value__c = 'dummyIntegrationId', NE__Order_Item__c = testOrderItem.Id, NE__FamPropId__c=familyProp.Id );
        ListAttributes.add(attributeIntegrationId);
        
        insert ListAttributes;
     
      /* Case*/ 
        //rtId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Order Management Case').getRecordTypeId();
        rtId = TGS_RecordTypes_Util.getRecordTypeId(Case.SObjectType, 'Order_Management_Case');
        Contact CaseContact = TGS_Dummy_Test_Data.dummyContactTGS('Parker');
        insert CaseContact;
         System.debug('$$$$$$$542');   
        Case testCase = new Case(RecordTypeId = rtId, Subject = 'Test Case', Status = 'Assigned',TGS_Status_reason__c='', Order__c = testOrder.Id, Type = 'New', TGS_Customer_Services__c = testOrderItem.Id, TGS_Invoice_Date__c = date.today(),ContactId = CaseContact.id, AccountId = CaseContact.AccountId, TGS_Service__c = testProduct.Name);
        insert testCase;
               
        testOrder.Case__c = testCase.Id;
        update testOrder;
        
        // FAR 10/03/2016
        testCase.Status = Constants.CASE_STATUS_CANCELLED;
        update testCase;
        // END FAR
        
        testCase.Status = Constants.CASE_STATUS_IN_PROGRESS;   
        testCase.Type = Constants.TYPE_CHANGE;
        Constants.firstRunLookup = true;
        update testCase;   
        
        return testOrderItem;
    }
    
    /*---------------------------*/
    
    public static NE__OrderItem__c dummyConfigurationOrderCCAndBU() {
        //Id rtId = Schema.SObjectType.NE__Order__c.getRecordTypeInfosByName().get('Order').getRecordTypeId();
        Id rtId = TGS_RecordTypes_Util.getRecordTypeId(NE__Order__c.SObjectType, 'Order');
        NE__Order__c testOrder = new NE__Order__c(RecordTypeId = rtId, NE__Type__c = 'InOrder');
        Contact CaseContact = TGS_Dummy_Test_Data.dummyContactTGS('Parker');
        insert CaseContact;

        Account testLegalEntity1 = [SELECT id, Name, Parentid FROM Account WHERE id =: CaseContact.AccountId LIMIT 1];
        Account testCostCenter1 = [SELECT id,Name,Parentid, HoldingId__c FROM Account WHERE Parent.Parentid =: testLegalEntity1.id LIMIT 1];
        Account testBusinessUnit1 = [SELECT id,Name FROM Account WHERE Parentid =: testLegalEntity1.id LIMIT 1];
        testOrder.HoldingId__c = testCostCenter1.HoldingId__c;
        testOrder.NE__AccountId__c = testLegalEntity1.Id;
        testOrder.NE__ServAccId__c = testBusinessUnit1.id;
        testOrder.NE__BillAccId__c = testCostCenter1.id;
        insert testOrder;

        NE__Catalog__c testCatalog = new NE__Catalog__c(Name='Test Catalog');
        insert testCatalog;
        NE__Catalog_Category__c testCatalogCategory = new NE__Catalog_Category__c(Name='Test Category', NE__CatalogId__c = testCatalog.Id);
        insert testCatalogCategory;
        NE__Catalog_Category__c testCatalogSubCategory = new NE__Catalog_Category__c(Name='Test SubCategory', NE__CatalogId__c = testCatalog.Id, NE__Parent_Category_Name__c = testCatalogCategory.Id);
        insert testCatalogSubCategory;
        
        NE__Product__c testProduct = new NE__Product__c(Name='Test Product');
        insert testProduct;
     /* Family property*/
        NE__Family__c family = new NE__Family__c(Name = 'Product Family');
        insert family;
        NE__DynamicPropertyDefinition__c property = new NE__DynamicPropertyDefinition__c(Name = 'Attribute 1', NE__Type__c = 'String');
        insert property;
        System.debug(property.RecordTypeId);
        NE__ProductFamilyProperty__c familyProp = new NE__ProductFamilyProperty__c(NE__FamilyId__c = family.Id, NE__PropId__c = property.Id, NE__Required__c = 'No', TGS_Is_key_attribute__c = true);
        insert familyProp;
        NE__ProductFamily__c productFamily = new NE__ProductFamily__c(NE__ProdId__c = testProduct.Id, NE__FamilyId__c = family.Id);
        insert productFamily;
        
        NE__Catalog_Item__c testCatalogItem = new NE__Catalog_Item__c(NE__Type__c = 'Product', NE__Catalog_Category_Name__c = testCatalogSubCategory.Id, NE__Catalog_Id__c = testCatalog.Id, NE__ProductId__c = testProduct.Id );
        insert testCatalogItem;
        //ACR 03/12/2019 - Recoger RT con Schema
		String idRt = Schema.SObjectType.NE__OrderItem__c.getRecordTypeInfosByDeveloperName().get('StanStandarddard').getRecordTypeId();
        NE__OrderItem__c testOrderItem = new NE__OrderItem__c(RecordTypeId=idRt,NE__OrderId__c = testOrder.Id, NE__ProdId__c = testProduct.Id, NE__CatalogItem__c = testCatalogItem.Id, NE__Qty__c=1);
        insert testOrderItem;
     /* Attribute of the OrderItem*/
        List<NE__Order_Item_Attribute__c> ListAttributes =  new List<NE__Order_Item_Attribute__c>();
        
        NE__Order_Item_Attribute__c attribute = new NE__Order_Item_Attribute__c(Name = 'Attribute 1', NE__Value__c = 'test', NE__Order_Item__c = testOrderItem.Id, NE__FamPropId__c=familyProp.Id );
        ListAttributes.add(attribute);
        NE__Order_Item_Attribute__c attributeID = new NE__Order_Item_Attribute__c(Name = 'Attribute 1_id', NE__Value__c = 'test', NE__Order_Item__c = testOrderItem.Id, NE__FamPropId__c=familyProp.Id );
        ListAttributes.add(attributeID);
        NE__Order_Item_Attribute__c attributeClass = new NE__Order_Item_Attribute__c(Name = 'Attribute 1_class', NE__Value__c = '', NE__Order_Item__c = testOrderItem.Id, NE__FamPropId__c=familyProp.Id );
        ListAttributes.add(attributeClass);
        insert ListAttributes;
     
      /* Case*/ 
        //rtId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Order Management Case').getRecordTypeId();
        rtId = TGS_RecordTypes_Util.getRecordTypeId(Case.SObjectType, 'Order_Management_Case');
        Case testCase = new Case(RecordTypeId = rtId, Subject = 'Test Case', Status = 'Assigned', Order__c = testOrder.Id, Type = 'New', TGS_Customer_Services__c = testOrderItem.Id, TGS_Service__c = testProduct.Name, TGS_Invoice_Date__c = date.today(),ContactId = CaseContact.id, AccountId = CaseContact.AccountId);
        insert testCase;
        testOrder.Case__c = testCase.Id;
        update testOrder;
        return testOrderItem;
    }
    
    
     /**
    * @author Marta Laliena
    * @date 06/06/2015
    * @description          Return a order item with attributes and an order. The catalog hierarchy is created,
    *                       as well as a catalog item that is associated to a product. The product
    *                       has a family that contains attributes.
    * 
    * @return               new NE__OrderItem__c with attributes and an order.
    */
    public static NE__OrderItem__c dummyConfiguration(Id userId) {
        return dummyConfiguration(userId, null);
    }

    // JMF 27/10/2016 - Separate methods to allow setting ordertype explicitly
    public static NE__OrderItem__c dummyConfiguration(Id userId, String orderType) {
        User user = TGS_Portal_Utils.getUser(userId);  
        //Id rtId = Schema.SObjectType.NE__Order__c.getRecordTypeInfosByName().get('Order').getRecordTypeId();
        Id rtId = TGS_RecordTypes_Util.getRecordTypeId(NE__Order__c.SObjectType, 'Order');
        
        NE__Catalog__c testCatalog = new NE__Catalog__c(Name='Test Catalog');
        insert testCatalog;

        NE__Catalog_Category__c testCatalogCategory = new NE__Catalog_Category__c(
            Name = 'Test Category',
            NE__CatalogId__c = testCatalog.Id
        );
        insert testCatalogCategory;

        NE__Catalog_Category__c testCatalogSubCategory = new NE__Catalog_Category__c(
            Name = 'Test SubCategory',
            NE__CatalogId__c = testCatalog.Id,
            NE__Parent_Category_Name__c = testCatalogCategory.Id
        );
        insert testCatalogSubCategory;

        NE__Product__c testProduct = new NE__Product__c(Name='Test Product');
        insert testProduct;

        /* Family property*/
        NE__Family__c family = new NE__Family__c(Name = 'Product Family');
        insert family;
        NE__DynamicPropertyDefinition__c property = new NE__DynamicPropertyDefinition__c(Name = 'Attribute 1', NE__Type__c = 'String');
        insert property;
        NE__ProductFamilyProperty__c familyProp = new NE__ProductFamilyProperty__c(
            NE__FamilyId__c = family.Id,
            NE__PropId__c = property.Id,
            NE__Required__c = 'No',
            TGS_Is_key_attribute__c = true
        );
        insert familyProp;
        NE__ProductFamily__c productFamily = new NE__ProductFamily__c(
            NE__ProdId__c = testProduct.Id,
            NE__FamilyId__c = family.Id
        );
        insert productFamily;
        
        NE__Catalog_Item__c testCatalogItem = new NE__Catalog_Item__c(
            NE__Type__c = 'Product',
            NE__Catalog_Category_Name__c = testCatalogSubCategory.Id,
            NE__Catalog_Id__c = testCatalog.Id,
            NE__ProductId__c = testProduct.Id
        );
        insert testCatalogItem;
        
        NE__Asset__c commAsset = new NE__Asset__c(
            NE__ServAccId__c = user.Contact.AccountId,
            NE__BillAccId__c = user.Contact.AccountId,
            TGS_RFB_date__c=date.today(),
            TGS_RFS_date__c=date.today(),
            TGS_Billing_end_date__c=date.today()
        );
        insert commAsset;

        // JMF 27/10/2016 - Insert order with Commertial Asset
        NE__Order__c ord = new NE__Order__c(
            RecordTypeId = rtId,
            NE__CatalogId__c = testCatalog.Id,
            NE__Asset__c = commAsset.Id,
            NE__Configuration_Type__c = orderType,
            NE__AccountId__c = user.Contact.AccountId
        );
        insert ord;
        //ACR 03/12/2019 - Recoger RT con Schema
		String idRt = Schema.SObjectType.NE__OrderItem__c.getRecordTypeInfosByDeveloperName().get('StanStandarddard').getRecordTypeId();
        NE__OrderItem__c ci = new NE__OrderItem__c(
            NE__Account__c = user.Contact.AccountId,
            NE__Billing_Account_Asset_Item__c = TGS_Portal_Utils.getLevel5(userId, 0)[0].Id,
            NE__Service_Account_Asset_Item__c = TGS_Portal_Utils.getLevel3(userId, 0)[0].Id,
            NE__OrderId__c = ord.Id,
            NE__ProdId__c = testProduct.Id,
            NE__CatalogItem__c = testCatalogItem.Id,
			recordTypeId=idRt,
            NE__Qty__c=1
        );
        insert ci;
        /* Attribute of the OrderItem*/
        NE__Order_Item_Attribute__c cia = new NE__Order_Item_Attribute__c(
            Name = 'Attribute 1',
            NE__Value__c = 'test',
            NE__Order_Item__c = ci.Id
        );
        insert cia;


        /* Case */
        if(orderType == null) {
            rtId = TGS_RecordTypes_Util.getRecordTypeId(Case.SObjectType, 'Order_Management_Case');
            
            // If there is an order type, code will create the case for you
            Case testCase = new Case(
                AccountId = user.Contact.AccountId,
                RecordTypeId = rtId,
                Subject = 'Test Case',
                Status = 'Assigned',
                Order__c = ord.Id,
                TGS_Customer_Services__c = ci.Id,
                TGS_Invoice_Date__c = Date.today(),
                TGS_Service__c = testProduct.Name, //New value needed JEG 29/11/2016
                Type='New'
            );
            insert testCase;

            ord.Case__c = testCase.Id;
            update ord;
        }
        return ci;
    }

    /*Álvaro López 23/04/2017*/
    public static NE__OrderItem__c dummyConfigurationInProgressInProv(Id userId, String orderType) {
        User user = TGS_Portal_Utils.getUser(userId);  
        //Id rtId = Schema.SObjectType.NE__Order__c.getRecordTypeInfosByName().get('Order').getRecordTypeId();
        Id rtId = TGS_RecordTypes_Util.getRecordTypeId(NE__Order__c.SObjectType, 'Order');
        
        NE__Catalog__c testCatalog = new NE__Catalog__c(Name='Test Catalog');
        insert testCatalog;

        NE__Catalog_Category__c testCatalogCategory = new NE__Catalog_Category__c(
            Name = 'Test Category',
            NE__CatalogId__c = testCatalog.Id
        );
        insert testCatalogCategory;

        NE__Catalog_Category__c testCatalogSubCategory = new NE__Catalog_Category__c(
            Name = 'Test SubCategory',
            NE__CatalogId__c = testCatalog.Id,
            NE__Parent_Category_Name__c = testCatalogCategory.Id
        );
        insert testCatalogSubCategory;

        NE__Product__c testProduct = new NE__Product__c(Name='Test Product');
        insert testProduct;

        /* Family property*/
        NE__Family__c family = new NE__Family__c(Name = 'Product Family');
        insert family;
        NE__DynamicPropertyDefinition__c property = new NE__DynamicPropertyDefinition__c(Name = 'Attribute 1', NE__Type__c = 'String');
        insert property;
        NE__ProductFamilyProperty__c familyProp = new NE__ProductFamilyProperty__c(
            NE__FamilyId__c = family.Id,
            NE__PropId__c = property.Id,
            NE__Required__c = 'No',
            TGS_Is_key_attribute__c = true
        );
        insert familyProp;
        NE__ProductFamily__c productFamily = new NE__ProductFamily__c(
            NE__ProdId__c = testProduct.Id,
            NE__FamilyId__c = family.Id
        );
        insert productFamily;
        
        NE__Catalog_Item__c testCatalogItem = new NE__Catalog_Item__c(
            NE__Type__c = 'Product',
            NE__Catalog_Category_Name__c = testCatalogSubCategory.Id,
            NE__Catalog_Id__c = testCatalog.Id,
            NE__ProductId__c = testProduct.Id
        );
        insert testCatalogItem;
        
        NE__Asset__c commAsset = new NE__Asset__c(
            NE__ServAccId__c = user.Contact.AccountId,
            NE__BillAccId__c = user.Contact.AccountId,
            TGS_RFB_date__c=date.today(),
            TGS_RFS_date__c=date.today(),
            TGS_Billing_end_date__c=date.today()
        );
        insert commAsset;

        // JMF 27/10/2016 - Insert order with Commertial Asset
        NE__Order__c ord = new NE__Order__c(
            RecordTypeId = rtId,
            NE__CatalogId__c = testCatalog.Id,
            NE__Asset__c = commAsset.Id,
            NE__Configuration_Type__c = orderType,
            NE__AccountId__c = user.Contact.AccountId
        );
        insert ord;
        //ACR 03/12/2019 - Recoger RT con Schema
		String idRt = Schema.SObjectType.NE__OrderItem__c.getRecordTypeInfosByDeveloperName().get('StanStandarddard').getRecordTypeId();
        NE__OrderItem__c ci = new NE__OrderItem__c(
            NE__Account__c = user.Contact.AccountId,
			RecordTypeId= idRt,
            NE__Billing_Account_Asset_Item__c = TGS_Portal_Utils.getLevel5(userId, 0)[0].Id,
            NE__Service_Account_Asset_Item__c = TGS_Portal_Utils.getLevel3(userId, 0)[0].Id,
            NE__OrderId__c = ord.Id,
            NE__ProdId__c = testProduct.Id,
            NE__CatalogItem__c = testCatalogItem.Id,
            NE__Qty__c=1
        );
        insert ci;
        /* Attribute of the OrderItem*/
        NE__Order_Item_Attribute__c cia = new NE__Order_Item_Attribute__c(
            Name = 'Attribute 1',
            NE__Value__c = 'test',
            NE__Order_Item__c = ci.Id
        );
        insert cia;


        /* Case */
        if(orderType == null) {
            rtId = TGS_RecordTypes_Util.getRecordTypeId(Case.SObjectType, 'Order_Management_Case');
            
            // If there is an order type, code will create the case for you
            Case testCase = new Case(
                AccountId = user.Contact.AccountId,
                RecordTypeId = rtId,
                Subject = 'Test Case',
                Status = 'In Progress',
                TGS_Status_Reason__c = 'In Provision',
                TGS_Casilla_Desarrollo__c = true,
                Order__c = ord.Id,
                TGS_Customer_Services__c = ci.Id,
                TGS_Invoice_Date__c = Date.today(),
                TGS_Service__c = testProduct.Name, //New value needed JEG 29/11/2016
                Type= orderType
            );
            insert testCase;

            ord.Case__c = testCase.Id;
            update ord;
        }
        return ci;
    }
    
    /**
    * @author Marta Laliena
    * @date 06/06/2015
    * @description          Return a order item with attributes, an order and an asset. The catalog hierarchy is created,
    *                       as well as a catalog item that is associated to a product. The product
    *                       has a family that contains attributes.
    *
    * @return               new NE__OrderItem__c with attributes, an order and an asset.
    */
    public static NE__OrderItem__c dummyConfigurationAsset() {
        Account acc = dummyHierarchy();
        //Id rtId = Schema.SObjectType.NE__Order__c.getRecordTypeInfosByName().get('Order').getRecordTypeId();
        Id rtId = TGS_RecordTypes_Util.getRecordTypeId(NE__Order__c.SObjectType, 'Order');
        NE__Order__c testOrder = new NE__Order__c(RecordTypeId = rtId);
        insert testOrder;
        //Id rtIdA = Schema.SObjectType.NE__Order__c.getRecordTypeInfosByName().get('Asset').getRecordTypeId();
        Id rtIdA = TGS_RecordTypes_Util.getRecordTypeId(NE__Order__c.SObjectType, 'Asset');
        NE__Order__c testOrderAsset = new NE__Order__c(RecordTypeId = rtIdA);
        insert testOrderAsset;
        NE__Catalog__c testCatalog = new NE__Catalog__c(Name='Test Catalog');
        insert testCatalog;
        NE__Catalog_Category__c testCatalogCategory = new NE__Catalog_Category__c(Name='Test Category', NE__CatalogId__c = testCatalog.Id);
        insert testCatalogCategory;
        NE__Catalog_Category__c testCatalogSubCategory = new NE__Catalog_Category__c(Name='Test SubCategory', NE__CatalogId__c = testCatalog.Id, NE__Parent_Category_Name__c = testCatalogCategory.Id);
        insert testCatalogSubCategory;
        NE__Product__c testProduct = new NE__Product__c(Name='Test Product');
        insert testProduct;
        /* Family property*/
        NE__Family__c family = new NE__Family__c(Name = 'Product Family');
        insert family;
        Id recordtypelookup = TGS_RecordTypes_Util.getRecordTypeId(NE__DynamicPropertyDefinition__c.SObjectType, 'Dynamic_Lookup');
        NE__DynamicPropertyDefinition__c property = new NE__DynamicPropertyDefinition__c(Name = 'Attribute 1', NE__Type__c = 'Dynamic Lookup', NE__Show_As__c = 'Lookup', RecordTypeId= recordtypelookup);
        insert property;
        System.debug(property.RecordTypeId);
        NE__ProductFamilyProperty__c familyProp = new NE__ProductFamilyProperty__c(NE__FamilyId__c = family.Id, NE__PropId__c = property.Id, NE__Required__c = 'No', TGS_Is_key_attribute__c = true);
        insert familyProp;
        NE__ProductFamily__c productFamily = new NE__ProductFamily__c(NE__ProdId__c = testProduct.Id, NE__FamilyId__c = family.Id);
        insert productFamily; 
        NE__Catalog_Item__c testCatalogItem = new NE__Catalog_Item__c(NE__Type__c = 'Product', NE__Catalog_Category_Name__c = testCatalogSubCategory.Id, NE__Catalog_Id__c = testCatalog.Id, NE__ProductId__c = testProduct.Id );
        insert testCatalogItem;
        //ACR 03/12/2019 - Recoger RT con Schema
		String idRt = Schema.SObjectType.NE__OrderItem__c.getRecordTypeInfosByDeveloperName().get('StanStandarddard').getRecordTypeId();
        NE__OrderItem__c testOrderItem = new NE__OrderItem__c(RecordTypeId=idRt,NE__OrderId__c = testOrder.Id, NE__ProdId__c = testProduct.Id, NE__CatalogItem__c = testCatalogItem.Id, NE__Qty__c=1);
        insert testOrderItem;
        NE__OrderItem__c testOrderItemAsset = new NE__OrderItem__c(RecordTypeId=idRt,NE__OrderId__c = testOrderAsset.Id, NE__ProdId__c = testProduct.Id, NE__CatalogItem__c = testCatalogItem.Id, NE__Qty__c=1 );
        insert testOrderItemAsset;

        //rtId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Order Management Case').getRecordTypeId();
        rtId = TGS_RecordTypes_Util.getRecordTypeId(Case.SObjectType, 'Order_Management_Case');
        Contact CaseContact = TGS_Dummy_Test_Data.dummyContactTGS('Parker');
        insert CaseContact;
        Case testCase = new Case(RecordTypeId = rtId, Subject = 'Test Case', Status = 'Assigned', Order__c = testOrder.Id, Type = 'New', TGS_Customer_Services__c = testOrderItem.Id, TGS_Invoice_Date__c = date.today(),ContactId = CaseContact.id, AccountId = CaseContact.AccountId);
        insert testCase;
        testOrder.Case__c = testCase.Id;
        update testOrder;
        testOrderAsset.Case__c = testCase.Id;
        update testOrderAsset;

        return testOrderItemAsset;
    }
    
    /**
    * @author Marta Laliena
    * @date 06/06/2015
    * @description          Return a standard junction object Entitlement preparing the relationship with Account.
    *
    * @return               new product associated with a family of attr.
    */
    public static NE__Product__c dummyCommercialProduct() {
        NE__Family__c family = new NE__Family__c();
        insert family;
        NE__Product__c product = new NE__Product__c(Name='Test Product');
        insert product;
        NE__ProductFamily__c productFamily = new NE__ProductFamily__c(NE__ProdId__c = product.Id, NE__FamilyId__c = family.Id);
        insert productFamily;
        NE__DynamicPropertyDefinition__c definition = new NE__DynamicPropertyDefinition__c();
        insert definition;
        NE__ProductFamilyProperty__c familyProperty = new NE__ProductFamilyProperty__c(NE__FamilyId__c = family.Id,  NE__PropId__c = definition.Id);
        insert familyProperty;
        return product;
    }
        
    /**
    * @author Marta Laliena
    * @date 06/06/2015
    * @description          Creates a full catalog with a category, subcategories, catalog items, products,
    *                       families of attributes, order items and order items' attributes for the category
    *                       'Enterprise Managed Mobility'.
    *                       A portal user configuration is created to give visibility to the contact given.
    *               
    * @param  accountId     A Id with the identification number of an account.
    * @param  contactId     A Id with the identification number of a contact.
    */
    public static void createDummyConfigurationEnterpriseManagedMobility(Id accountId, Id contactId) {
        List<RecordType> listRecordTypes = [SELECT Id, Name FROM RecordType WHERE Name LIKE 'Asset'];
        if(listRecordTypes.size()>0){
            // Start JMF 01/04/2016
            Id rtAccCC = TGS_RecordTypes_Util.getRecordTypeId(Account.SObjectType, Constants.RECORD_TYPE_COST_CENTER_ACCOUNT);
            Id rtAccBU = TGS_RecordTypes_Util.getRecordTypeId(Account.SObjectType, Constants.RECORD_TYPE_BUSINESS_UNIT_ACCOUNT);
            List<Account> lstAccCC = [SELECT Id, Name FROM Account WHERE RecordTypeId = :rtAccCC AND (ParentId = :accountId OR Parent.ParentId = :accountId OR TGS_Aux_Holding__c = :accountId)];
            List<Account> lstAccBU = [SELECT Id, Name FROM Account WHERE RecordTypeId = :rtAccBU AND (Id = :accountId OR ParentId = :accountId)];
            System.assertNotEquals(0, lstAccCC.size(), 'No Cost Centers were created for the dummy hierarchy');
            System.assertNotEquals(0, lstAccBU.size(), 'No Business Units were created for the dummy hierarchy');
            // End JMF 01/04/2016
            NE__Order__c testOrder = new NE__Order__c(RecordTypeId = listRecordTypes[0].Id, NE__BillAccId__c = lstAccCC[0].Id, NE__AccountId__c = accountId, NE__ServAccId__c = lstAccBU[0].Id);
            insert testOrder;
         /* Catalog */
            NE__Catalog__c testCatalog = new NE__Catalog__c(Name='TGSOL Catalog');
            insert testCatalog;
         /* Category */
            NE__Catalog_Category__c testCategory = new NE__Catalog_Category__c(Name='Enterprise Managed Mobility', NE__CatalogId__c = testCatalog.Id);
            insert testCategory;
         /* Subcategory 1 */
            NE__Catalog_Category__c testSubCategory = new NE__Catalog_Category__c(Name='Universal WIFI', NE__CatalogId__c = testCatalog.Id, NE__Parent_Category_Name__c = testCategory.Id);
            insert testSubCategory;
         /* Subcategory 2 */
            NE__Catalog_Category__c testSubCategory2 = new NE__Catalog_Category__c(Name='Secure Mobile Device, Apps and Content Management', NE__CatalogId__c = testCatalog.Id, NE__Parent_Category_Name__c = testCategory.Id);
            insert testSubCategory2;
            
         /* Product 1 */
            NE__Product__c testProduct = new NE__Product__c(Name='Universal WIFI',TGS_CWP_Tier_1__c=testCategory.Name,TGS_CWP_Tier_2__c=testCategory.Name);
            insert testProduct;
         /* Family property */
            NE__Family__c family = new NE__Family__c(Name = 'WIFI Family');
            insert family;
            NE__DynamicPropertyDefinition__c property = new NE__DynamicPropertyDefinition__c(Name = 'Domain', NE__Type__c = 'String');
            insert property;
            NE__ProductFamilyProperty__c familyProp = new NE__ProductFamilyProperty__c(NE__FamilyId__c = family.Id, NE__PropId__c = property.Id, NE__Required__c = 'No', TGS_Is_key_attribute__c = true);
            insert familyProp;
            property = new NE__DynamicPropertyDefinition__c(Name = 'Set-up Fee', NE__Type__c = 'Number');
            insert property;
            familyProp = new NE__ProductFamilyProperty__c(NE__FamilyId__c = family.Id, NE__PropId__c = property.Id, NE__Required__c = 'No', TGS_Is_key_attribute__c = true);
            insert familyProp;
            property = new NE__DynamicPropertyDefinition__c(Name = 'Service Modality', NE__Type__c = 'Enumerated');
            insert property;
            NE__PropertyDomain__c domain = new NE__PropertyDomain__c(Name = 'Premier Monthly Rate', NE__PropId__c = property.Id);
            insert domain;
            domain = new NE__PropertyDomain__c(Name = 'Connect Monthly Rate', NE__PropId__c = property.Id);
            insert domain;            
            familyProp = new NE__ProductFamilyProperty__c(NE__FamilyId__c = family.Id, NE__PropId__c = property.Id, NE__Required__c = 'No', TGS_Is_key_attribute__c = true);
            insert familyProp;
            NE__ProductFamily__c productFamily = new NE__ProductFamily__c(NE__ProdId__c = testProduct.Id, NE__FamilyId__c = family.Id);
            insert productFamily;
            //ACR 03/12/2019 - Recoger RT con Schema
            String idRt = Schema.SObjectType.NE__OrderItem__c.getRecordTypeInfosByDeveloperName().get('StanStandarddard').getRecordTypeId();
         /* OrderItem */
            NE__OrderItem__c testOrderItem = new NE__OrderItem__c(RecordTypeId=idRt,NE__OrderId__c = testOrder.Id, NE__ProdId__c = testProduct.Id, NE__Qty__c=1, NE__Account__c = accountId, NE__Billing_Account_Asset_Item__c = TGS_Portal_Utils.getLevel5(accountId, 1)[0].Id, NE__Service_Account_Asset_Item__c = TGS_Portal_Utils.getLevel3(accountId, 1)[0].Id, TGS_Service_Status__c = 'Deployed', NE__Status__c = 'In Progress');            
            insert testOrderItem;
         /* Attributes of the OrderItem*/
            NE__Order_Item_Attribute__c attribute = new NE__Order_Item_Attribute__c(Name = 'Domain', NE__Value__c = 'test', NE__Order_Item__c = testOrderItem.Id);
            insert attribute;
            attribute = new NE__Order_Item_Attribute__c(Name = 'Service Modality', NE__Value__c = 'Premier Monthly Rate', NE__Order_Item__c = testOrderItem.Id);
            insert attribute;
            
         /* Catalog Item */
            NE__Catalog_Item__c testCatalogItem = new NE__Catalog_Item__c(NE__Catalog_Category_Name__c = testSubCategory.Id, NE__Catalog_Id__c = testCatalog.Id, NE__ProductId__c = testProduct.Id, NE__Technical_Behaviour__c='Order Management Case' );
            insert testCatalogItem;
         /* Portal User Configuration */
            TGS_Portal_User_Configuration__c portalUserConfigTest = new TGS_Portal_User_Configuration__c(Contact__c = contactId);
            insert portalUserConfigTest;
         /* Portal User Configuration Product */
            TGS_Portal_User_Configuration_Product__c portalUserConfigProductTest = 
                                new TGS_Portal_User_Configuration_Product__c(Portal_User_Configuration__c = portalUserConfigTest.Id, Commercial_Product__c = testProduct.Id );
            insert portalUserConfigProductTest;
            
         /* Product 2*/
            testOrder = new NE__Order__c(RecordTypeId = listRecordTypes[0].Id);
            insert testOrder;
            testProduct = new NE__Product__c(Name='Secure Mobile Device, Apps and Content Management');
            insert testProduct;
         /* Family property */
            family = new NE__Family__c(Name = 'SMDM Management Family');
            insert family;
            property = new NE__DynamicPropertyDefinition__c(Name = 'Device Serial Number', NE__Type__c = 'String');
            insert property;
            familyProp = new NE__ProductFamilyProperty__c(NE__FamilyId__c = family.Id, NE__PropId__c = property.Id, NE__Required__c = 'No', TGS_Is_key_attribute__c = true);
            insert familyProp;
            productFamily = new NE__ProductFamily__c(NE__ProdId__c = testProduct.Id, NE__FamilyId__c = family.Id);
            insert productFamily;
            
          /* OrderItem */
            testOrderItem = new NE__OrderItem__c(RecordTypeId=idRT,NE__OrderId__c = testOrder.Id, NE__ProdId__c = testProduct.Id, NE__Qty__c=1, NE__Account__c = accountId, NE__Billing_Account_Asset_Item__c = TGS_Portal_Utils.getLevel5(accountId, 1)[0].Id, NE__Service_Account_Asset_Item__c = TGS_Portal_Utils.getLevel3(accountId, 1)[0].Id, TGS_Service_Status__c = 'Deployed', NE__Status__c = 'In Progress');
            insert testOrderItem;
         /* Attributes of the OrderItem*/
            attribute = new NE__Order_Item_Attribute__c(Name = 'Device Serial Number', NE__Value__c = '000', NE__Order_Item__c = testOrderItem.Id);
            insert attribute;
         /* Case */
            //Id rtId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Order Management Case').getRecordTypeId();
            Id rtId = TGS_RecordTypes_Util.getRecordTypeId(Case.SObjectType, 'Order_Management_Case');
            Case testCase = new Case(RecordTypeId = rtId, Subject = 'Test Case', Status = 'Assigned', Order__c = testOrder.Id);
            insert testCase;
            testOrder.Case__c = testCase.Id;
            update testOrder;
            
         /* Catalog Item for product 2 */
            testCatalogItem = new NE__Catalog_Item__c(NE__Type__c = 'Product', NE__Catalog_Category_Name__c = testSubCategory2.Id, NE__Catalog_Id__c = testCatalog.Id, NE__ProductId__c = testProduct.Id );
            insert testCatalogItem;
         /* Portal User Configuration Product */
            portalUserConfigProductTest = 
                                new TGS_Portal_User_Configuration_Product__c(Portal_User_Configuration__c = portalUserConfigTest.Id,
                                                                             Commercial_Product__c = testProduct.Id );
            insert portalUserConfigProductTest;
        }      
    } 
    
    /**
    * @author Marta Laliena
    * @date 15/06/2015
    * @description          Creates a full catalog with a category, subcategories, catalog item, product, family of 
    *                       attributes, order item and order item's attributes for the product 'Threat Detection'
    *                       A portal user configuration is created to give visibility to the contact given.
    *               
    * @param  accountId     A Id with the identification number of an account.
    * @param  contactId     A Id with the identification number of a contact.
    */
    public static void createDummyConfigurationSecurityServices(Id accountId, Id contactId) {
        List<RecordType> listRecordTypes = [SELECT Id, Name FROM RecordType WHERE Name LIKE 'Asset'];
        if(listRecordTypes.size()>0){
            // Start JMF 01/04/2016
            Id rtAccCC = TGS_RecordTypes_Util.getRecordTypeId(Account.SObjectType, Constants.RECORD_TYPE_COST_CENTER_ACCOUNT);
            Id rtAccBU = TGS_RecordTypes_Util.getRecordTypeId(Account.SObjectType, Constants.RECORD_TYPE_BUSINESS_UNIT_ACCOUNT);
            List<Account> lstAccCC = [SELECT Id, Name FROM Account WHERE RecordTypeId = :rtAccCC AND (ParentId = :accountId OR Parent.ParentId = :accountId OR TGS_Aux_Holding__c = :accountId)];
            List<Account> lstAccBU = [SELECT Id, Name FROM Account WHERE RecordTypeId = :rtAccBU AND (Id = :accountId OR ParentId = :accountId)];
            System.assertNotEquals(0, lstAccCC.size(), 'No Cost Centers were created for the dummy hierarchy');
            System.assertNotEquals(0, lstAccBU.size(), 'No Business Units were created for the dummy hierarchy');
            // End JMF 01/04/2016
            Map<String,Map<String,String>>initStringStringMap = new Map<String,Map<String,String>>{'one' => new Map<String, String>{'a'=>'b', 'c'=> 'd'}, 'two' =>new Map<String, String> {'e'=>'f', 'g'=> 'h'} };
            NE__Order__c testOrder = new NE__Order__c(RecordTypeId = listRecordTypes[0].Id, NE__AccountId__c=accountId, NE__ServAccId__c = lstAccBU[0].Id, NE__BillAccId__c = lstAccCC[0].Id);
            insert testOrder;
         /* Catalog and categories */
            NE__Catalog__c testCatalog = new NE__Catalog__c(Name='TGSOL Catalog');
            insert testCatalog;
            NE__Catalog_Category__c testCategory = new NE__Catalog_Category__c(Name='Security Services', NE__CatalogId__c = testCatalog.Id);
            insert testCategory;
            NE__Catalog_Category__c testSubCategory = new NE__Catalog_Category__c(Name='Cyber Security', NE__CatalogId__c = testCatalog.Id, NE__Parent_Category_Name__c = testCategory.Id);
            insert testSubCategory;
         /* Product */
            NE__Product__c testProduct = new NE__Product__c(Name='Threat Detection');
            insert testProduct;
            NE__Family__c family = new NE__Family__c(Name = 'Cyber Security Family');
            insert family;
            NE__DynamicPropertyDefinition__c property = new NE__DynamicPropertyDefinition__c(Name = 'Description', NE__Type__c = 'String');
            insert property;
            NE__ProductFamilyProperty__c familyProp = new NE__ProductFamilyProperty__c(NE__FamilyId__c = family.Id, NE__PropId__c = property.Id, NE__Required__c = 'No', TGS_Is_key_attribute__c = true);
            insert familyProp;
            NE__ProductFamily__c productFamily = new NE__ProductFamily__c(NE__ProdId__c = testProduct.Id, NE__FamilyId__c = family.Id);
            insert productFamily;
         /* Order item */
         //ACR 03/12/2019 - Recoger RT con Schema
		 String idRt = Schema.SObjectType.NE__OrderItem__c.getRecordTypeInfosByDeveloperName().get('StanStandarddard').getRecordTypeId();
            NE__OrderItem__c testOrderItem = new NE__OrderItem__c(RecordTypeId=idRt,NE__OrderId__c = testOrder.Id, NE__ProdId__c = testProduct.Id, NE__Qty__c=1, NE__Account__c = accountId, TGS_Service_Status__c = 'Deployed', NE__Status__c = 'In Progress');            
            insert testOrderItem;
            NE__Order_Item_Attribute__c attribute = new NE__Order_Item_Attribute__c(Name = 'Description', NE__Value__c = 'test', NE__Order_Item__c = testOrderItem.Id);
            insert attribute;
         /* Case */
            //Id rtId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Order Management Case').getRecordTypeId();
            Id rtId = TGS_RecordTypes_Util.getRecordTypeId(Case.SObjectType, 'Order_Management_Case');
            Case testCase = new Case(RecordTypeId = rtId, Subject = 'Test Case', Status = 'Assigned', Order__c = testOrder.Id);
            insert testCase;
            testOrder.Case__c = testCase.Id;
            update testOrder;
         /* Catalog Item */
            NE__Catalog_Item__c testCatalogItem = new NE__Catalog_Item__c(NE__Catalog_Category_Name__c = testSubCategory.Id, NE__Catalog_Id__c = testCatalog.Id, NE__ProductId__c = testProduct.Id );
            insert testCatalogItem;
         /* Portal User Configuration */
            TGS_Portal_User_Configuration__c portalUserConfigTest = new TGS_Portal_User_Configuration__c(Contact__c = contactId);
            insert portalUserConfigTest;
         /* Portal User Configuration Product */
            TGS_Portal_User_Configuration_Product__c portalUserConfigProductTest = 
                                new TGS_Portal_User_Configuration_Product__c(Portal_User_Configuration__c = portalUserConfigTest.Id, Commercial_Product__c = testProduct.Id );
            insert portalUserConfigProductTest;
        }      
    }
   
    /**
    * @author Marta Laliena
    * @date 06/06/2015
    * @description          Return a punto instalación associated to the business unit account given.
    *
    * @param  clientId      A String with identification number of a business unit account.
    * @return               new punto de instalación associted to the contact given.
    */
    public static BI_Punto_de_instalacion__c dummyPuntoInstalacion(Id clientId){
        Account acc = [SELECT RecordType.DeveloperName, TGS_Aux_Holding__c FROM Account WHERE Id = :clientId LIMIT 1];
        if(acc.RecordType.DeveloperName.equals(Constants.RECORD_TYPE_TGS_BUSINESS_UNIT)){
            BI_Sede__c sede = new BI_Sede__c(Name = 'Test sede', BI_Codigo_postal__c = '12345', BI_Direccion__c = 'Direccion', BI_Localidad__c = 'Localidad', BI_Provincia__c = 'Provincia', TGS_Available_Accounts__c = acc.TGS_Aux_Holding__c);
            insert sede;
            BI_Punto_de_instalacion__c site = new BI_Punto_de_instalacion__c(Name = 'Test site', BI_Cliente__c = clientId, BI_Sede__c = sede.Id);
            TGS_SitesIntegration.inFutureContextSite = true;
            insert site;
            TGS_SitesIntegration.inFutureContextSite = false;
            System.debug('return site');
            
            return site;
        }
        else{
            return null;
        }
    }        

    /**
    * @author Marta Laliena
    * @date 06/06/2015
    * @description          Creates a full configuration for a complex product that has a subproduct.
    *                       A portal user configuration is created to give visibility to the contact given.
    *               
    * @param  accountId     A Id with the identification number of an account.
    * @param  contactId     A Id with the identification number of a contact.
    * @return               new order item of the complex product created.
    */
    public static NE__OrderItem__c createDummyConfigurationComplexProduct(Id accountId, Id contactId) {
        NE__OrderItem__c testOrderItem;    
        List<RecordType> listRecordTypes = [SELECT Id, Name FROM RecordType WHERE Name LIKE 'Asset'];
        if(listRecordTypes.size()>0){
            // Start JMF 01/04/2016
            Id rtAccCC = TGS_RecordTypes_Util.getRecordTypeId(Account.SObjectType, Constants.RECORD_TYPE_COST_CENTER_ACCOUNT);
            Id rtAccBU = TGS_RecordTypes_Util.getRecordTypeId(Account.SObjectType, Constants.RECORD_TYPE_BUSINESS_UNIT_ACCOUNT);
            List<Account> lstAccCC = [SELECT Id, Name FROM Account WHERE RecordTypeId = :rtAccCC AND (ParentId = :accountId OR Parent.ParentId = :accountId OR TGS_Aux_Holding__c = :accountId)];
            List<Account> lstAccBU = [SELECT Id, Name FROM Account WHERE RecordTypeId = :rtAccBU AND (Id = :accountId OR ParentId = :accountId)];
            System.assertNotEquals(0, lstAccCC.size(), 'No Cost Centers were created for the dummy hierarchy');
            System.assertNotEquals(0, lstAccBU.size(), 'No Business Units were created for the dummy hierarchy');
            // End JMF 01/04/2016
          /*Asset*/
            NE__Asset__c commAsset = new NE__Asset__c(NE__ServAccId__c = accountId, NE__BillAccId__c = accountId,TGS_RFB_date__c=date.today(),TGS_RFS_date__c=date.today(),TGS_Billing_end_date__c=date.today());
            insert commAsset;
            NE__Order__c testOrder = new NE__Order__c(RecordTypeId = listRecordTypes[0].Id, NE__Asset__c= commAsset.Id, NE__AccountId__c = accountId, NE__ServAccId__c = accountId, NE__BillAccId__c = lstAccCC[0].Id);
            insert testOrder;
         /* Catalog */
            NE__Catalog__c testCatalog = new NE__Catalog__c(Name='Catalog');
            insert testCatalog;
         /* Category */
            NE__Catalog_Category__c testCategory = new NE__Catalog_Category__c(Name='Category', NE__CatalogId__c = testCatalog.Id);
            insert testCategory;
            
         /* Subcategory 1 */
            NE__Catalog_Category__c testSubCategory = new NE__Catalog_Category__c(Name='Subcategory', NE__CatalogId__c = testCatalog.Id, NE__Parent_Category_Name__c = testCategory.Id);
            insert testSubCategory;
            
         /* Product */
            NE__Product__c testProduct = new NE__Product__c(Name='Complex product', TGS_CWP_Tier_1__c='Enterprise Managed Mobility',TGS_CWP_Tier_2__c='Universal Wifi');
            insert testProduct;
            
         /* Catalog Item complex product */
            NE__Catalog_Item__c testCatalogItemComplex = new NE__Catalog_Item__c(NE__Catalog_Category_Name__c = testSubCategory.Id, NE__Catalog_Id__c = testCatalog.Id, NE__ProductId__c = testProduct.Id, NE__Technical_Behaviour__c = 'Service not available for e-Ordering; Service with pre-approved changes' );
            insert testCatalogItemComplex;
         /* Catalog Item root */
            NE__Catalog_Item__c testCatalogItemRoot = new NE__Catalog_Item__c(NE__Catalog_Category_Name__c = testSubCategory.Id, NE__Catalog_Id__c = testCatalog.Id, NE__Parent_Catalog_Item__c = testCatalogItemComplex.Id, NE__ProductId__c = testProduct.Id, NE__Type__c = 'Product', NE__Technical_Behaviour__c = 'Service not available for e-Ordering; Service with pre-approved changes');
            insert testCatalogItemRoot;
                    
         /* Subproduct */
            NE__Product__c testsubProduct = new NE__Product__c(Name='Subproduct');
            insert testSubProduct;
         /* Family property*/
            NE__Family__c family = new NE__Family__c(Name = 'subProduct Family');
            insert family;
           
            NE__DynamicPropertyDefinition__c property = new NE__DynamicPropertyDefinition__c(Name = 'Attribute 1', NE__Type__c = 'String');
            insert property;
            
            NE__ProductFamilyProperty__c familyProp = new NE__ProductFamilyProperty__c(NE__FamilyId__c = family.Id, NE__PropId__c = property.Id, NE__Required__c = 'No', TGS_Is_key_attribute__c = true);
            insert familyProp;
            NE__ProductFamily__c productFamily = new NE__ProductFamily__c(NE__ProdId__c = testsubProduct.Id, NE__FamilyId__c = family.Id);
            insert productFamily;
            
         /* Catalog Item subproduct */
            NE__Catalog_Item__c testCatalogItemSub = new NE__Catalog_Item__c(NE__Root_Catalog_Item__c = testCatalogItemRoot.Id, NE__Parent_Catalog_Item__c = testCatalogItemRoot.Id, NE__Catalog_Id__c = testCatalog.Id, NE__ProductId__c = testSubproduct.Id, NE__Technical_Behaviour__c = 'Service not available for e-Ordering; Service with pre-approved changes' );
            insert testCatalogItemSub;
        
         /* Portal User Configuration */
            TGS_Portal_User_Configuration__c portalUserConfigTest = new TGS_Portal_User_Configuration__c(Contact__c = contactId);
            insert portalUserConfigTest;
         /* Portal User Configuration Product */
            TGS_Portal_User_Configuration_Product__c portalUserConfigProductTest = 
                                new TGS_Portal_User_Configuration_Product__c(Portal_User_Configuration__c = portalUserConfigTest.Id, Commercial_Product__c = testProduct.Id );
            insert portalUserConfigProductTest;
            portalUserConfigProductTest = 
                                new TGS_Portal_User_Configuration_Product__c(Portal_User_Configuration__c = portalUserConfigTest.Id, Commercial_Product__c = testsubProduct.Id );
            insert portalUserConfigProductTest;
        
         /* OrderItem */
         //ACR 03/12/2019 - Recoger RT con Schema
		 String idRt = Schema.SObjectType.NE__OrderItem__c.getRecordTypeInfosByDeveloperName().get('StanStandarddard').getRecordTypeId();
            testOrderItem = new NE__OrderItem__c(RecordTypeId=idRt,NE__OrderId__c = testOrder.Id, NE__ProdId__c = testProduct.Id, NE__Qty__c=1, NE__Account__c = accountId, TGS_Service_Status__c = 'Deployed', NE__Status__c = 'In Progress',NE__Service_Account_Asset_Item__c= accountId,NE__Billing_Account_Asset_Item__c= accountId, NE__CatalogItem__c=testCatalogItemComplex.Id);
            insert testOrderItem;
            NE__OrderItem__c testOrderSubItem = new NE__OrderItem__c(RecordTypeId=idRt,NE__OrderId__c = testOrder.Id, NE__ProdId__c = testSubProduct.Id, NE__Qty__c=1, NE__Account__c = accountId, TGS_Service_Status__c = 'Deployed', NE__Status__c = 'In Progress',NE__Service_Account_Asset_Item__c= accountId,NE__Billing_Account_Asset_Item__c= accountId, NE__Parent_Order_Item__c = testOrderItem.Id);
            insert testOrderSubItem;
         /* Attributes of the OrderSubItem */
            NE__Order_Item_Attribute__c attribute = new NE__Order_Item_Attribute__c(Name = 'AttributeName1', NE__Value__c = '000', NE__Order_Item__c = testOrderSubItem.Id);
            insert attribute;
         /* Case */
            //Id rtId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Order Management Case').getRecordTypeId();
            Id rtId = TGS_RecordTypes_Util.getRecordTypeId(Case.SObjectType, 'Order_Management_Case');
            Date RFBDate = Date.newInstance(2015, 12, 11);
            Case testCase = new Case(RecordTypeId = rtId, Subject = 'Test Case', Status = 'Assigned', Order__c = testOrder.Id, TGS_RFB_date__c = RFBDate, TGS_RFS_date__c = RFBDate);
            insert testCase;
            testOrder.Case__c = testCase.Id;
            update testOrder;
        }
        return testOrderItem;
    }
    
    
    
    /**
    * @author Unknow
    * @date 06/06/2015
    * @description                 Creation of a given number of accounts and associated to a given number of contacts.
    *               
    * @param  numAccts             An integer with the number of accounts to create.
    * @param  numContactsPerAcct   An integer with the number of contacts to associate to each account.
    */
    public static void createTestRecords(Integer numAccts, Integer numContactsPerAcct) {
        List<Account> accts = new List<Account>();
        
        for(Integer i=0;i<numAccts;i++) {
            Account a = new Account(Name='TestAccount' + i, BI_Segment__c = 'Empresas', BI_Subsegment_Regional__c='Corporate');
            accts.add(a);
        }
        insert accts;
        
        List<Contact> cons = new List<Contact>();
        for (Integer j=0;j<numAccts;j++) {
            Account acct = accts[j];            
            // For each account just inserted, add contacts
            for (Integer k=numContactsPerAcct*j;k<numContactsPerAcct*(j+1);k++) {
                cons.add(new Contact(firstname='Test'+k,
                                     lastname='Test'+k,
                                     AccountId=acct.Id));
            }
        }
        // Insert all contacts for all accounts
        insert cons;
    }
    

    /**
    * @author Miguel Angel Galindo, Marta García
    * @date 23/03/2015
    * @description          Returns a standard Saleforce User with the profile assigned.
    *
    *                       The User returned must be inserted by the developer on his own code.
    *
    * @param  profileName   A String with the Profile name that we want assign to the user
    * @return               User with the profile Name assigned on the parameter 
    */   
    public static User dummyUserTGS(String profileName){
        Profile p = [Select Id From Profile Where Name=:profileName];
            
        String nRandom = String.valueOf((Integer)(Math.random()*100));
        String mailName = 'telefonicaTest'+nRandom+'@tefonica.com';
        
        User user = new User(
            username = mailName,
            lastname='Testing',
            CommunityNickname = 'telefonicaTest' + nRandom,
            alias = 'aliasT'+nRandom,
            email = mailName,
            emailencodingkey='UTF-8',
            timezonesidkey='America/Los_Angeles',
            languagelocalekey='en_US', 
            localesidkey='en_US',
            profileid = p.Id,
            isActive = true
        );

        return user;
           
    }
    
    /**
    * @author Miguel Angel Galindo, Marta García
    * @date 23/03/2015
    * @description  Returns a Junction Object Permission Set Assignment with the 
    *               relationship between the User and the Permission Set from the parameters.
    *
    *               The Permission Set Assignment returned must be inserted by 
    *               the developer on his own code.
    *
    * @param  User              A User that will be assigned the Permission Set.
    * @param  permissionSetName A String with the Permission Set Name that will be assigned to the user.
    * @return                   Junction object PermissionSetAssignment with the 
    *                           relationship between the User and the Permission Set 
    */
    public static PermissionSetAssignment setPermissionToUser(User user, String permissionSetName){
        PermissionSet permissionSet = [SELECT Id From PermissionSet Where Name = :permissionSetName];
        PermissionSetAssignment psa = new PermissionSetAssignment(PermissionSetId = permissionSet.Id, AssigneeId =user.Id);
        return psa;
    }
    
    /**
    * @author Miguel Angel Galindo
    * @date 24/03/2015
    * @description  Returns a Case object with the record type, Acting as and Status Reason Set on the parameters
    *               Initial Status is Assigned, and subject is 'Test ticket case'.
    *               The Case returned must be inserted by the developer on his own code.
    *
    * @param  recordTypeDeveloperName   A String with the Record type DeveloperName that will be assigned to the new case.
    * @param  actingAs                  A String with Acting as Name that will be assigned to the user. The options are 'Authorized User', 'On Behalf' or 'Support Agent'.
    * @return                           new Case with parameters options.
    */
    public static Case dummyCaseTGS(String recordTypeDeveloperName, String actingAs){
        //Id rtId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId();
        Id rtId = TGS_RecordTypes_Util.getRecordTypeId(Case.SObjectType, recordTypeDeveloperName);
        Case caseTest = new Case(
            RecordTypeId = rtId,
            Subject = 'Test ticket case',
            Status = 'Assigned'
            //TGS_Acting_as__c = actingAs   Eliminacion Acting As
            );
        
        return caseTest;
    }
    
    /**
    * @author Miguel Angel Galindo
    * @date 24/03/2015
    * @description  Returns a Contact object with the Last Name set on the parameters
    *               The Account field is required on Contact, and is assigned the Legal Entity Account returnet by the method dummyHierarchy().
    *               The Contact returned must be inserted by the developer on his own code.
    *
    * @param  lastName  A String with last Name that will be assigned to the Contact.
    * @return           new Contact with parameters options.
    */
    public static Contact dummyContactTGS(String lastName){
        Account acLe = TGS_Dummy_Test_Data.dummyHierarchy();
        Contact contactTest = new Contact(LastName = lastName,
                                          AccountId = acLe.Id,
                                          Email = 'dummy@test.com',
                                          TGS_Enviar_Email_Order_Management_Case__c=false,
                                          TGS_Enviar_Email_Billing_Inquiry__c = false,
                                          TGS_Enviar_Email_Change__c = false,
                                          TGS_Enviar_Email_Complaint__c = false,
                                          TGS_Enviar_Email_Incident__c = false,
                                          TGS_Enviar_Email_Query__c = false
                                        );
        
        return contactTest;
    }
    
    /**
    * @author Miguel Angel Galindo
    * @date 24/03/2015
    * @description  Return a standard junction object Entitlement preparing the relationship with Account.
    *               
    *               The Entitlement returned must be inserted by the developer on his own code.
    *
    * @param  name          A String with Name that will be assigned to the Entitlement.
    * @param  accountName   A String with the Account Name to be assigned to the Entitlement.
    * @return               new Entitlement with parameters options.
    */
    public static Entitlement dummyEntitlementTGS(String name, Id accountId){
        Entitlement entitlement = new Entitlement();
        entitlement.AccountId = accountId;
        entitlement.Name = name;
        
        return entitlement;
    }

    //09/02/2017            Gawron, Julián E.           Adding if isEmpty()
    public static void dummyEndpointsTGS(){
      if(!TGS_Endpoints__c.getAll().isEmpty()){
          System.debug('No estaba vacío');
      }else{
        List<TGS_Endpoints__c> endpoints = new List<TGS_Endpoints__c>();
        TGS_Endpoints__c endpoint1 = new TGS_Endpoints__c(Name = 'rod_ticketing', TGS_endpoint__c= 'test');  
        TGS_Endpoints__c endpoint2 = new TGS_Endpoints__c(Name = 'rod_attAST', TGS_endpoint__c= 'test');  
        
        endpoints.add(endpoint1);
        endpoints.add(endpoint2);
        insert endpoints;
      } 
    }
    
    /**
     * @author Jose Miguel Fierro
     * @date 03/04/2016
     * @description  Sets the given user or profile's User Org setting
     *
     * @param  tgs    Does this U/P belong to TGS?
     * @param  bien   Does this U/P belong to BIEN?
     * @return        Created User Org custom setting
     */
    public static TGS_User_Org__c setUserType(Id uRp, Boolean tgs, Boolean bien) {
        TGS_User_Org__c uo = new TGS_User_Org__c(TGS_Is_TGS__c = tgs, TGS_Is_BI_EN__c = bien, SetupOwnerId=uRp);
        insert uo;
        return uo;
    }





    /*-------------------------------------------------------------------------------------------------------------------------------------------------------
     Author:        Gawron, Julian
     Company:       Accenture
     Description:   Create random strings
     adapted from http://salesforce.stackexchange.com/questions/43823/how-do-i-generate-a-random-string
     
     History: 
     
     <Date>                <Author>                          <Change Description>
     23/11/2016            Gawron, Julián                     Initial version
    --------------------------------------------------------------------------------------------------------------------------------------------------------*/
    public static String generateRandomString(Integer len) {
     
        final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
        String randStr = '';
        while (randStr.length() < len) {
           Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
           randStr += chars.substring(idx, idx+1);
        }
        return randStr; 
    }
    
     
    /*------------------------------------------------------------
    Author:         Everis 
    Company:        Everis
    Description:    Crea una jerarquía de cuentas para crear un Order.
    
	History
    <Date>          <Author>        <Change Description>
    16/03/2017      Everis        	Initial Version
    ------------------------------------------------------------*/
    public static Map<String, account> getAccountHierarchy() {
        List<Account> accounts = new List<Account>();
        //Creo un Account H
        Account acctH = new Account(name = 'testHolding', TGS_Es_MNC__c=true);
        String recordT = Constants.RECORD_TYPE_HOLDING_ACCOUNT_LABEL;
        RecordType rt = [select Id,name from RecordType where Name =: recordT and SobjectType = 'Account' limit 1];
        acctH.RecordType = rt;
        acctH.RecordTypeId = rt.Id;
        accounts.add(acctH);
                
        //Creo un Account Customer Country
        Account acctCC = new Account(name = 'testCustomerCountry', TGS_Es_MNC__c=true, parentId = acctH.id);
        recordT = Constants.RECORD_TYPE_CUSTOMER_COUNTRY_ACCOUNT_LABEL;
        rt = [select Id,name from RecordType where Name =: recordT and SobjectType = 'Account' limit 1];
        acctCC.RecordType = rt;
        acctCC.RecordTypeId = rt.Id;
        accounts.add(acctCC);
        insert accounts;
        acctCC.TGS_Aux_Holding__c = acctH.Id;
        acctCC.TGS_Aux_Holding__r = acctH;
        update acctCC;
               
        //Creo un Account LE
        Account acctLE = new Account(name = 'test', TGS_Es_MNC__c=true, parentID=acctCC.id);
        recordT = Constants.RECORD_TYPE_LEGAL_ENTITY_ACCOUNT_LABEL;
        rt = [select Id,name from RecordType where Name =: recordT and SobjectType = 'Account' limit 1];
        acctLE.RecordType = rt;
        acctLE.RecordTypeId = rt.Id;
        acctLE.TGS_Aux_Holding__c = acctH.Id;
        acctLE.TGS_Aux_Holding__r = acctH;
        insert acctLE;
                
        //Creo un Account BU
        Account acctBU = new Account(name = 'test', TGS_Es_MNC__c=true, parentID=acctLE.id);
        recordT = Constants.RECORD_TYPE_BUSINESS_UNIT_ACCOUNT_LABEL;
        rt = [select Id,name from RecordType where Name =: recordT and SobjectType = 'Account' limit 1];
        acctBU.RecordType = rt;
        acctBU.RecordTypeId = rt.Id;
        acctBU.TGS_Aux_Holding__c = acctH.id;
        acctBU.TGS_Aux_Holding__r = acctH;
        insert acctBU;
        
        //Creo un Account CC
        Account acctCCenter = new Account(name = 'testCC2', TGS_Es_MNC__c=true,parentID=acctBU.id);
        recordT = Constants.RECORD_TYPE_COST_CENTER_ACCOUNT_LABEL;
        rt = [select Id,name from RecordType where Name =: recordT and SobjectType = 'Account' limit 1];
        acctCCenter.RecordType = rt;
        acctCCenter.RecordTypeId = rt.Id;
        acctCCenter.TGS_Aux_Holding__c = acctH.id;
        acctCCenter.TGS_Aux_Holding__r = acctH;
        insert acctCCenter;
        
        Map<String, account> accountMap = new Map<String,Account>();
        accountMap.put(Constants.RECORD_TYPE_HOLDING_ACCOUNT_LABEL, acctH);
        accountMap.put(Constants.RECORD_TYPE_CUSTOMER_COUNTRY_ACCOUNT_LABEL, acctCC);
        accountMap.put(Constants.RECORD_TYPE_LEGAL_ENTITY_ACCOUNT_LABEL, acctLE);
        accountMap.put(Constants.RECORD_TYPE_BUSINESS_UNIT_ACCOUNT_LABEL, acctBU);
        accountMap.put(Constants.RECORD_TYPE_COST_CENTER_ACCOUNT_LABEL, acctCCenter);
        return accountMap;
        
    }
    
    /*------------------------------------------------------------
    Author:         Everis 
    Company:        Everis
    Description:    Crea un caso y le asocia un producto, todo con los datos pasados por parámetros. Por último crea un Order item y devuelve el CASO.
    
	History
    <Date>          <Author>        <Change Description>
    08/02/2017      Everis        	Initial Version
    03/12/2019      Amador Cáceres  Añadir Administrador de sistema a Query
    ------------------------------------------------------------*/
    public static Case getCaseConfigured(Map<String, Account> accountMap, String Servicio, String caseStatus, String caseStatusReason, String caseType, String Product, String caseAccount) {
        
        Account acctH = accountMap.get(Constants.RECORD_TYPE_HOLDING_ACCOUNT_LABEL);
        
        //Inserto ATM a la cuenta holding.
        //ACR 03/12/2019 - Añadir Administrador a la query para recoger solos usuarios administradores
        User u = [select id from User where isActive=true  AND (Profile.Name = 'System administrator' OR Profile.Name='Administrador del sistema') Limit 1];
        String teamRole = Constants.ROLE_GPM;
        AccountTeamMember atm = new AccountTeamMember(UserId=u.id, TeamMemberRole=teamRole, AccountID= acctH.id);
        insert atm;
        
        NE__Order__c order = new NE__Order__c();
        order.NE__AccountId__c = accountMap.get(Constants.RECORD_TYPE_LEGAL_ENTITY_ACCOUNT_LABEL).id;
        order.HoldingId__c = accountMap.get(Constants.RECORD_TYPE_HOLDING_ACCOUNT_LABEL).id;
        order.NE__ServAccId__c = accountMap.get(Constants.RECORD_TYPE_BUSINESS_UNIT_ACCOUNT_LABEL).id;
        order.NE__ServAccId__r = accountMap.get(Constants.RECORD_TYPE_BUSINESS_UNIT_ACCOUNT_LABEL);
        order.NE__BillAccId__c = accountMap.get(Constants.RECORD_TYPE_COST_CENTER_ACCOUNT_LABEL).id;
        order.NE__BillAccId__r = accountMap.get(Constants.RECORD_TYPE_COST_CENTER_ACCOUNT_LABEL);
        insert order;
        
        NE__Product__c prod = new NE__Product__c(name='ProductoPrueba', TGS_CWP_Tier_2__c=Constants.MSIP_TRUNKING_SITE);
		insert prod;
        //Creo un OrderItem
        NE__OrderItem__c oi = new NE__OrderItem__c(NE__Qty__c = 1);
        oi.NE__OrderId__c = order.ID;
        oi.NE__ProdId__c = prod.ID;
        oi.NE__Status__c = Constants.CONFIGURATION_STATUS_ACTIVE;
        //ACR 03/12/2019 - Recoger RT con Schema
		String idRt = Schema.SObjectType.NE__OrderItem__c.getRecordTypeInfosByDeveloperName().get('StanStandarddard').getRecordTypeId();
		oi.RecordTypeId=idRt;
        insert oi;
        
        Contact CaseContact = TGS_Dummy_Test_Data.dummyContactTGS('Parker');
        CaseContact.AccountId = accountMap.get(caseAccount).id; 
        CaseContact.Account = accountMap.get(caseAccount); 
        insert CaseContact;
        ID rtId = TGS_RecordTypes_Util.getRecordTypeId(Case.SObjectType, 'Order_Management_Case');
        Account caseAcct =  accountMap.get(Constants.RECORD_TYPE_HOLDING_ACCOUNT_LABEL);
        Case testCase = new Case(RecordTypeId = rtId, Subject = 'Test Case', Status = caseStatus, TGS_Status_reason__c = caseStatusReason, Order__c = order.Id, Type = caseType, TGS_Customer_Services__c = oi.Id, TGS_Service__c = Servicio, TGS_Invoice_Date__c = date.today(),ContactId = CaseContact.id, AccountId = CaseContact.AccountId);
        testCase.Account = CaseContact.Account;
        insert testCase; 
        
        order.Case__c = testCase.id;
        order.Case__r = testCase;
        update order;
        
        return testCase;
    }

    /*-------------------------------------------------------------------------------------------------------------------------------------------------------
    Author:        Guillermo Muñoz
    Company:       Accenture - New Energy Aborda
    Description:   Method that create an Account hierachy with contacts and sites associated
    
    History:
    
    <Date>            <Author>              <Description>
    27/09/2017        Guillermo Muñoz       Initial version
    --------------------------------------------------------------------------------------------------------------------------------------------------------*/
    public static void insertFullStackData(){

        List <Account> lst_holding = new List <Account>();
        List <Account> lst_custCountry = new List <Account>();
        List <Account> lst_legalEntity = new List <Account>();

        for(Integer i = 0; i < 2; i++){

            Account oHolding = new Account();
            oHolding.RecordTypeId = TGS_RecordTypes_Util.getRecordTypeId(Account.SObjectType, Constants.RECORD_TYPE_TGS_HOLDING);
            oHolding.Name = 'Test Holding ' + i;
            oHolding.Fax = '916755532';
            oHolding.Phone = '654337899';
            oHolding.NumberOfEmployees = 467; 
            oHolding.BI_No_Identificador_fiscal__c = 'Holding' + i; 
            oHolding.AnnualRevenue = 2897600;
            oHolding.BI_Country__c = 'Spain';  
            oHolding.BI_Tipo_de_identificador_fiscal__c = 'NIF';
            oHolding.Website = 'test@accenture.com';
            oHolding.BI_Inicio_actividad_del_cliente__c = Date.today();
            oHolding.Rating = 'Cold';
            oHolding.BI_Riesgo__c = '1 - Sin problema';
            oHolding.BI_Activo__c = 'Sí';
            oHolding.BI_Denominacion_comercial__c = 'Test';
            oHolding.TGS_Account_Mnemonic__c = 'Test';
            oHolding.TGS_Account_Category__c = 'Corporate';
            oHolding.TGS_Es_MNC__c = true;
            oHolding.TGS_Account_Leading_MNC_Unit__c = 'SPAIN';
            oHolding.SAP_ID__c = 'E34622';
            oHolding.TGS_Invoice_Language__c = false;
            oHolding.TGS_DirectFinal_Type__c = 'Direct Customer';
            lst_holding.add(oHolding);
        }
        insert lst_holding;

        Account parentHolding = lst_holding[0];

        for(Integer i = 0; i < 2; i++){

            Account oCustCountry = new Account();
            oCustCountry.RecordTypeId = TGS_RecordTypes_Util.getRecordTypeId(Account.SObjectType, Constants.RECORD_TYPE_TGS_CUSTOMER_COUNTRY);
            oCustCountry.Name = 'Test Customer Country ' + i;
            oCustCountry.Fax = '916755532';
            oCustCountry.Phone = '654337899';
            oCustCountry.NumberOfEmployees = 467; 
            oCustCountry.BI_No_Identificador_fiscal__c = 'CusttCountry' + i;
            oCustCountry.AnnualRevenue = 2897600;
            oCustCountry.BI_Country__c = 'Spain';  
            oCustCountry.BI_Tipo_de_identificador_fiscal__c = 'NIF';
            oCustCountry.Website = 'test@accenture.com';
            oCustCountry.BI_Inicio_actividad_del_cliente__c = Date.today();
            oCustCountry.Rating = 'Cold';
            oCustCountry.BI_Riesgo__c = '1 - Sin problema';
            oCustCountry.BI_Activo__c = 'Sí';
            oCustCountry.BI_Denominacion_comercial__c = 'Test';
            oCustCountry.TGS_Account_Mnemonic__c = 'Test';
            oCustCountry.TGS_Account_Category__c = 'Corporate';
            oCustCountry.TGS_Es_MNC__c = true;
            oCustCountry.TGS_Account_Leading_MNC_Unit__c = 'SPAIN';
            oCustCountry.SAP_ID__c = 'E34622';
            oCustCountry.TGS_Invoice_Language__c = false;
            oCustCountry.TGS_Aux_Holding__c = parentHolding.Id;
            oCustCountry.ParentId = parentHolding.Id;
            oCustCountry.TGS_DirectFinal_Type__c = 'Direct Customer';
            lst_custCountry.add(oCustCountry);
        }
        insert lst_custCountry;

        for(Integer i = 0; i < 2; i++){
            
            Account oLegalEntity = new Account();
            oLegalEntity.RecordTypeId = TGS_RecordTypes_Util.getRecordTypeId(Account.SObjectType, Constants.RECORD_TYPE_TGS_LEGAL_ENTITY);
            oLegalEntity.Name = 'Test Legal Entity ' + i;
            oLegalEntity.Fax = '916755532';
            oLegalEntity.Phone = '654337899';
            oLegalEntity.NumberOfEmployees = 467; 
            oLegalEntity.BI_No_Identificador_fiscal__c = 'LegalEntity' + i;
            oLegalEntity.AnnualRevenue = 2897600;
            oLegalEntity.BI_Country__c = 'Spain';  
            oLegalEntity.BI_Tipo_de_identificador_fiscal__c = 'NIF';
            oLegalEntity.Website = 'test@accenture.com';
            oLegalEntity.BI_Inicio_actividad_del_cliente__c = Date.today();
            oLegalEntity.Rating = 'Cold';
            oLegalEntity.BI_Riesgo__c = '1 - Sin problema';
            oLegalEntity.BI_Activo__c = 'Sí';
            oLegalEntity.BI_Denominacion_comercial__c = 'Test';
            oLegalEntity.TGS_Account_Mnemonic__c = 'Test';
            oLegalEntity.TGS_Account_Category__c = 'Corporate';
            oLegalEntity.TGS_Es_MNC__c = true;
            oLegalEntity.TGS_Account_Leading_MNC_Unit__c = 'SPAIN';
            oLegalEntity.SAP_ID__c = 'E34622';
            oLegalEntity.TGS_Invoice_Language__c = false;
            oLegalEntity.TGS_Aux_Holding__c = parentHolding.Id;
            oLegalEntity.ParentId = lst_custCountry[i].Id;
            oLegalEntity.TGS_DirectFinal_Type__c = 'Direct Customer';
            lst_legalEntity.add(oLegalEntity);
        }
        insert lst_legalEntity;

        List <Contact> lst_con = new List <Contact>();

        for(Integer i = 0; i < 2; i++){

            for(Integer j = 0; j < 2; j++){
                
                Contact oContact1 = new Contact();
                oContact1.AccountId = lst_holding[i].id;
                oContact1.BI_Country__c = lst_holding[i].BI_Country__c;
                oContact1.BirthDate = Date.valueof('2016-02-08');
                oContact1.TGS_Language__c = 'ES';
                oContact1.Email = 'test@test.com';
                oContact1.Phone = '976123456';
                oContact1.Fax = '976654321';
                oContact1.Department = 'TEST DEPARMENT';
                oContact1.FirstName = 'FIRST_NAME';
                oContact1.LastName = 'LAST_NAME';
                oContact1.Salutation = 'Mr';
                oContact1.BI_Genero__c = 'Masculino';
                oContact1.Bi_Activo__c = true;
                lst_con.add(oContact1);

                Contact oContact2 = new Contact();
                oContact2.AccountId = lst_custCountry[i].id;
                oContact2.BI_Country__c = lst_custCountry[i].BI_Country__c;
                oContact2.BirthDate = Date.valueof('2016-02-08');
                oContact2.TGS_Language__c = 'ES';
                oContact2.Email = 'test@test.com';
                oContact2.Phone = '976123456';
                oContact2.Fax = '976654321';
                oContact2.Department = 'TEST DEPARMENT';
                oContact2.FirstName = 'FIRST_NAME';
                oContact2.LastName = 'LAST_NAME';
                oContact2.Salutation = 'Mr';
                oContact2.BI_Genero__c = 'Masculino';
                oContact2.Bi_Activo__c = true;
                lst_con.add(oContact2);

                Contact oContact3 = new Contact();
                oContact3.AccountId = lst_legalEntity[i].id;
                oContact3.BI_Country__c = lst_legalEntity[i].BI_Country__c;
                oContact3.BirthDate = Date.valueof('2016-02-08');
                oContact3.TGS_Language__c = 'ES';
                oContact3.Email = 'test@test.com';
                oContact3.Phone = '976123456';
                oContact3.Fax = '976654321';
                oContact3.Department = 'TEST DEPARMENT';
                oContact3.FirstName = 'FIRST_NAME';
                oContact3.LastName = 'LAST_NAME';
                oContact3.Salutation = 'Mr';
                oContact3.BI_Genero__c = 'Masculino';
                oContact3.Bi_Activo__c = true;
                lst_con.add(oContact3);
            }
        }
        insert lst_con;

        List <BI_Sede__c> lst_sede = new List <BI_sede__c>();

        for(Integer i = 0; i < 12; i++){

            BI_Sede__c sede = new BI_Sede__c();
            sede.Name = 'UpdateSitesTest';
            sede.BI_Direccion__c = 'UpdateSitesTest';
            sede.BI_Numero__c = '1';
            sede.BI_Country__c = 'Spain';
            sede.BI_Provincia__c = 'Zaragoza';
            sede.BI_Localidad__c = 'Zaragoza';
            sede.BI_Piso__c = '5';
            sede.BI_Apartamento__c = 'A';
            sede.BI_Codigo_postal__c = '50006';
            lst_sede.add(sede);
        }
        insert lst_sede;

        List <BI_Punto_de_instalacion__c> lst_puntInst = new List <BI_Punto_de_instalacion__c>();

        Integer cont = 0;

        for(Integer i = 0; i < 2; i++){

            for(Integer j = 0; j < 2; j++){

                BI_Punto_de_instalacion__c puntInst1 = new BI_Punto_de_instalacion__c();
                puntInst1.BI_Sede__c = lst_sede[cont++].Id;
                puntInst1.BI_Cliente__c = lst_holding[i].Id;
                lst_puntInst.add(puntInst1);

                BI_Punto_de_instalacion__c puntInst2 = new BI_Punto_de_instalacion__c();
                puntInst2.BI_Sede__c = lst_sede[cont++].Id;
                puntInst2.BI_Cliente__c = lst_custCountry[i].Id;
                lst_puntInst.add(puntInst2);

                BI_Punto_de_instalacion__c puntInst3 = new BI_Punto_de_instalacion__c();
                puntInst3.BI_Sede__c = lst_sede[cont++].Id;
                puntInst3.BI_Cliente__c = lst_legalEntity[i].Id;
                lst_puntInst.add(puntInst3);
            }
        }
        insert lst_puntInst;
    }
}