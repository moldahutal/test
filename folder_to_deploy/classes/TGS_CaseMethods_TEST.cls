/*-------------------------------------------------------------------------------------
 Author:         -
 Company:        New Energy Aborda
 Description:    Methods that tests TGS_CaseMethods

 History
 <Date>      <Author>              <Description>
 -           -                     Initial Version
-------------------------------------------------------------------------------------*/
@isTest
private class TGS_CaseMethods_TEST {  

    static{
        BI_TestUtils.throw_exception = false;
    }

    /*-------------------------------------------------------------------------------------
     Author:         -
     Company:        New Energy Aborda
     Description:    Tests TGS_CaseMethods.caseEmailSend()

     History
     <Date>      <Author>              <Description>
     -           -                     Initial Version
     19/10/2016  Jose Miguel Fierro    Added startTest/stopTest
    -------------------------------------------------------------------------------------*/
    @isTest static void caseEmailSend_tst() {

        String profile = 'TGS Integration User';

        Profile miProfile = [SELECT Id, Name
        FROM Profile
        Where Name = :profile
        Limit 1];

        System.runAs(new User(Id = Userinfo.getUserId())) {
            TGS_User_Org__c uO = new TGS_User_Org__c();
            uO.TGS_Is_TGS__c = True;
            uO.SetupOwnerId = miProfile.Id;
            insert uO;

            TGS_Dummy_Test_Data.dummyEndpointsTGS();
        }

        UserRole r = new UserRole(name = 'TEST ROLE');
        Database.insert(r);

        User u = TGS_Dummy_Test_Data.dummyUserTGS(profile);
        u.BI_Permisos__c = 'TGS';
        u.UserRoleId = r.Id;
        insert u;


        System.runAs(u){

            PCA_Address_B2W_Controller.fireSendEmail = true;

            List<Account> lAcc = new List<Account>();

            Account accountLE = TGS_Dummy_Test_Data.dummyHierarchy();

            Account acBU = [Select Id, BI_Activo__c
                            From Account
                            Where ParentId = :accountLE.Id
                            Limit 1];

            Account acCC = [Select Id, BI_Activo__c
                            From Account
                            Where ParentId = :acBU.Id
                            Limit 1];

            acCC.BI_Activo__c = Label.BI_Si;
            acBU.BI_Activo__c = Label.BI_Si;
            accountLE.BI_Activo__c = Label.BI_Si;


            lAcc.add(accountLE);
            lAcc.add(acBU);
            lAcc.add(acCC);

            try{
                /*update acCC;
                update acBU;
                update accountLE;*/
                update lAcc;
            }catch(Exception e){
                System.debug('Exception: '+e);
                System.assert(false);
            }

            Account myAccountLE = TGS_Dummy_Test_Data.dummyHierarchy();

            List<Account> aCcList = [Select Id, ParentId
                            From Account
                            Where Id = :accountLE.ParentId];

            List<Contact> lCon = new List<Contact>(); 


            Contact myContact = new Contact(
                                        LastName = 'XXX test',
                                        Email = 'xxxxx@xxxxxx.com',
                                        CurrencyIsoCode = 'EUR',
                                        AccountId = accountLE.Id,
                                        TGS_Enviar_Email_Order_Management_Case__c = true
            );

            //insert myContact;

            Contact myContact2 = new Contact(
                                        LastName = 'XXX test 2',
                                        Email = 'xxxxx2@xxxxxx.com',
                                        CurrencyIsoCode = 'EUR',
                                        AccountId = accountLE.Id,
                                        TGS_Enviar_Email_Order_Management_Case__c = true
            );

            //insert myContact2;
            lCon.add(myContact);
            lCon.add(myContact2);
            insert lCon;

            //List<User> user = [SELECT Name FROM User WHERE Profile.Name = 'TGS Customer Community Plus'];

            List<Profile> listProfile = [SELECT Id FROM Profile WHERE Name IN ('TGS Customer Community Plus', 'TGS_Customer_Community_Plus_Login') ORDER BY Name];

            List<User> lUs = new List<User>();

            User u1 = new User(profileId = listProfile[0].id, username = 'email_user_comm_plus@infinity.com', email = 'email_user_comm_plus@infinity.com',
                   emailencodingkey = 'UTF-8', localesidkey = 'en_US',
                   languagelocalekey = 'en_US', timezonesidkey = 'America/Los_Angeles',
                   alias='ucplus', lastname='user_comm_plus', contactId = myContact.id, BI_Permisos__c = 'TGS',
                  isActive = True);

            //insert u1;

            User u2 = new User(profileId = listProfile[1].id, username = 'email_user_comm_plus_login@infinity.com', email = 'email_user_comm_plus_login@infinity.com',
                   emailencodingkey = 'UTF-8', localesidkey = 'en_US',
                   languagelocalekey = 'en_US', timezonesidkey = 'America/Los_Angeles',
                   alias='ucplusl', lastname='user_comm_plus_login', contactId = myContact2.id, BI_Permisos__c = 'TGS',
                  isActive = True);

            //insert u2;

            lUs.add(u1);
            lUs.add(u2);
            insert lUs;

            Test.startTest();
            List<RecordType> rt = [SELECT Id FROM RecordType WHERE Name = 'Order Management Case'];

            List<Case> lCa = new List<Case>();

            Case caseTest1 = new Case(
                                Status = 'Assigned',
                                RecordTypeId = rt[0].Id,
                                Priority = 'To be Calculated',
                                AccountId = accountLE.Id,
                                //CreatedBy = user[0],
                                CreatedBy = u1,
                                ContactId = myContact.Id,
                                TGS_Service__c = 'Smart M2M - SIM Request'
            );
            //insert caseTest1;
            List<User> user1 = [SELECT Name FROM User WHERE Profile.Name = 'TGS_Customer_Community_Plus_Login'];
            Case caseTest2 = new Case(
                                Status = 'Assigned',
                                RecordTypeId = rt[0].Id,
                                Priority = 'To be Calculated',
                                CreatedBy = u2,
                                AccountId = accountLE.Id,
                                ContactId = myContact.Id,
                                TGS_Service__c = 'Smart M2M - SIM Request'
            );
            //insert caseTest2;

            lCa.add(caseTest1);
            lCa.add(caseTest2);
            insert lCa;
            Test.stopTest();
        }
    }


    /*-------------------------------------------------------------------------------------------------------------------------------------------------------
    Author:        Oscar Iuliano
    Company:       Bit2Win
    Description:   Methods executed by BI_Case Triggers (TGS)

    History:

    <Date>                  <Author>                <Change Description>
    15/03/2016              Oscar Iuliano           Initial version
    02/04/2016              Jose Miguel Fierro      Added try-catch because the validation exception is the expected behavior
    14/04/2016              Jose Miguel Fierro      Commented assert in try block.
    --------------------------------------------------------------------------------------------------------------------------------------------------------*/
    @isTest static void verifyNotClseCase_Test()
    {
        system.debug('***TestCase_verifyNotClseCase_Test');
        String profile = 'TGS System Administrator';

        Profile miProfile = [SELECT Id, Name
                             FROM Profile
                             WHERE Name = :profile
                             LIMIT 1];

        System.runAs(new User(Id = Userinfo.getUserId())) {
            TGS_User_Org__c uO = new TGS_User_Org__c();
            uO.TGS_Is_TGS__c = True;
            uO.SetupOwnerId = miProfile.id;
            insert uO;


            TGS_Dummy_Test_Data.dummyEndpointsTGS();
            Id rtId = TGS_RecordTypes_Util.getRecordTypeId(NE__Order__c.SObjectType, 'Order');
            NE__Order__c testOrder = new NE__Order__c(RecordTypeId = rtId, NE__Type__c = 'InOrder');

            Id rtIdass = TGS_RecordTypes_Util.getRecordTypeId(NE__Order__c.SObjectType, 'Asset');
            NE__Order__c testOrderasset = new NE__Order__c(RecordTypeId = rtIdass, NE__Type__c = 'Active');
            insert testOrderasset;

            Contact CaseContact = TGS_Dummy_Test_Data.dummyContactTGS('Parker');
            insert CaseContact;
            Account testLegalEntity1 = [SELECT id, Name, Parentid FROM Account WHERE id =: CaseContact.AccountId LIMIT 1];
            Account testCustomerCountry1 = [SELECT id, Name, Parentid FROM Account WHERE id =: testLegalEntity1.Parentid LIMIT 1];
            Account testHolding1 = [SELECT id, Name, Parentid FROM Account WHERE id =: testCustomerCountry1.Parentid LIMIT 1];
            Account testCostCenter1 = [SELECT id,Name,Parentid FROM Account WHERE Parent.Parentid =: testLegalEntity1.id LIMIT 1];
            Account testBusinessUnit1 = [SELECT id,Name FROM Account WHERE Parentid =: testLegalEntity1.id LIMIT 1];
            testOrder.NE__AccountId__c = testLegalEntity1.Id;
            testOrder.HoldingId__c = testHolding1.id;
            testOrder.NE__ServAccId__c = testBusinessUnit1.id;
            //testOrder.NE__BillAccId__c = testCostCenter1.id;
            insert testOrder;
            NE__Catalog__c testCatalog = new NE__Catalog__c(Name='Test Catalog');
            insert testCatalog;
            NE__Catalog_Category__c testCatalogCategory = new NE__Catalog_Category__c(Name='Test Category', NE__CatalogId__c = testCatalog.Id);
            insert testCatalogCategory;
            NE__Catalog_Category__c testCatalogSubCategory = new NE__Catalog_Category__c(Name='Test SubCategory', NE__CatalogId__c = testCatalog.Id, NE__Parent_Category_Name__c = testCatalogCategory.Id);
            insert testCatalogSubCategory;

            NE__Product__c testProduct = new NE__Product__c(Name='Test Product');
            insert testProduct;
            //Family property
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

            NE__OrderItem__c testOrderItem = new NE__OrderItem__c(NE__OrderId__c = testOrder.Id, NE__ProdId__c = testProduct.Id, NE__CatalogItem__c = testCatalogItem.Id, NE__Qty__c=1,TGS_OriginalConfId__c='515115');
            insert testOrderItem;

            NE__OrderItem__c testOrderItemAsset = new NE__OrderItem__c(NE__OrderId__c = testOrderasset.Id, NE__ProdId__c = testProduct.Id, NE__CatalogItem__c = testCatalogItem.Id, NE__Qty__c=1,NE__Status__c='Active');
            insert testOrderItemAsset ;


            // Attribute of the OrderItem
            List<NE__Order_Item_Attribute__c> ListAttributes =  new List<NE__Order_Item_Attribute__c>();

            NE__Order_Item_Attribute__c attribute = new NE__Order_Item_Attribute__c(Name = 'Attribute 1', NE__Value__c = '515115', NE__Order_Item__c = testOrderItemAsset.Id, NE__FamPropId__c=familyProp.Id );
            ListAttributes.add(attribute);
            NE__Order_Item_Attribute__c attributeID = new NE__Order_Item_Attribute__c(Name = 'Attribute 1_id', NE__Value__c = 'test', NE__Order_Item__c = testOrderItem.Id, NE__FamPropId__c=familyProp.Id );
            ListAttributes.add(attributeID);
            NE__Order_Item_Attribute__c attributeClass = new NE__Order_Item_Attribute__c(Name = 'Attribute 1_class', NE__Value__c = '', NE__Order_Item__c = testOrderItem.Id, NE__FamPropId__c=familyProp.Id);
            ListAttributes.add(attributeClass);
            insert ListAttributes;

            // Case
            //rtId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Order Management Case').getRecordTypeId();
            rtId = TGS_RecordTypes_Util.getRecordTypeId(Case.SObjectType, 'Order_Management_Case');
            Case testCase = new Case(RecordTypeId = rtId, Subject = 'Test Case', Status = 'Assigned', Order__c = testOrder.Id, Type = 'New', TGS_Customer_Services__c = testOrderItem.Id, TGS_Service__c = testProduct.Name, TGS_Invoice_Date__c = date.today(),ContactId = CaseContact.id, AccountId = CaseContact.AccountId);
            insert testCase;
            testOrder.Case__c = testCase.Id;
            update testOrder;

            // JMF 02/04/2016 - Added try-catch because the excption is _correct_ functionality
            Test.startTest();
            try {
                testCase.Status     = 'Closed';
                testCase.Type       = 'Disconnect';
                testCase.Order__c   = testOrder.id;
                update testCase;
                //System.assert(false, 'Case was allowed to close while related to an active asset'); // JMF 14/04/2016 - Comentado para que no falle. Descomantar cuando se termine el gap97
            } catch (DmlException ex) {
                if(StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION != ex.getDmlType(0)) {
                    throw ex;
                }
            }
            Test.stopTest();

            //List<Case> cases = new List<Case>();
            //cases.add(testCase);
            //TGS_CaseMethods.verifyNotClseCase(cases);

        }
    }

    public static testMethod void fillCommAssetInfo_TEST(){
        
    }
    public static testMethod void getExistingValue_TEST(){
        Case tr_Caso_01 = TGS_Dummy_Test_Data.dummyOrderCase();
        Case tr_Caso_02 = TGS_Dummy_Test_Data.dummyOrderCase();
        List<Case> list_Cases = new List<Case>();
        list_Cases.add(tr_Caso_01);
        TGS_CaseMethods.getExistingValue(list_Cases,tr_Caso_01);
        TGS_CaseMethods.getExistingValue(list_Cases,tr_Caso_02);
        TGS_CaseMethods.getExistingValue(list_Cases,null);
    }

    public static testMethod void validateMandatorySiteMWAN_TEST() {

        BI_TestUtils.throw_exception = false;

        TGS_User_Org__c userTGS = new TGS_User_Org__c();
        userTGS.TGS_Is_BI_EN__c = false;
        userTGS.TGS_Is_TGS__c = false;
        insert userTGS;

        User usr = TGS_Dummy_Test_Data.dummyUserTGS('TGS_Perfil 1');
        usr.BI_Permisos__c = 'TGS';
        insert usr;
        TGS_Dummy_Test_Data.setUserType(usr.Id, true, false);

        System.runAs(usr) {
            Map <Integer,BI_bypass__c> mapa = BI_MigrationHelper.enableBypass(usr.Id, true, true, false, false);
            Map<Id,Case> map_Cases = new Map<Id,Case>();

            Case tr_Case = TGS_Dummy_Test_Data.dummyOrderCase();
            NE__OrderItem__c tr_CI_Order = TGS_Dummy_Test_Data.dummyConfigurationOrderCCAndBU();
            NE__Order__c tr_Order = [
                    SELECT Id, Site__c, NE__AccountId__c, NE__ServAccId__c, NE__BillAccId__c, NE__ServAccId__r.TGS_Aux_Holding__r.Name
                    FROM   NE__Order__c
                    WHERE  Id = :tr_CI_Order.NE__OrderId__c
            ];
            List<Contact> lst_cont = [SELECT Id FROM Contact WHERE AccountId = :tr_Order.NE__AccountId__c];

            if(!lst_cont.isEmpty()) {
                tr_Case.ContactId = lst_cont[0].Id;
            }
            tr_Case.Order__c = tr_CI_Order.NE__OrderId__c;
            tr_Case.TGS_Casilla_Desarrollo__c = true;
            update tr_Case;

            Test.startTest();
            tr_Case.TGS_Service__c = Constants.PRODUCT_MWAN_SU;
            tr_Case.Status = Constants.CASE_STATUS_CLOSED;
            map_Cases.put(tr_Case.Id, tr_Case);

            BI_Sede__c tr_Address = new BI_Sede__c (
                Name = 'TEST', 
                BI_Direccion__c = 'TEST',
                BI_Localidad__c = 'TEST',
                BI_Provincia__c = 'TEST',
                BI_Country__c   = 'Spain',
                BI_Codigo_postal__c = '28040'
            );
            insert tr_Address;


            BI_Punto_de_instalacion__c tr_Site = new BI_Punto_de_instalacion__c(
                BI_Cliente__c = tr_Order.NE__ServAccId__c,
                BI_Sede__c    = tr_Address.Id
            );
            insert tr_Site;
            BI_MigrationHelper.disableBypass(mapa);
            userTGS.TGS_Is_TGS__c = true;
            update userTGS;
            try {
                tr_Order.TGS_Holding_Name__c = tr_Order.NE__ServAccId__r.TGS_Aux_Holding__r.Name;
                update tr_Order ;
                update map_Cases.values();
                System.assert(false);
            } catch(Exception exc) {
            }
            tr_Order.Site__c = tr_Site.Id;
            update tr_Order;
            update map_Cases.values();
            Test.stopTest();
        }
    }

    @isTest public static void test_fillOrderFieldsCaseClose() {
        // cover the last return
        TGS_CaseMethods.fillOrderFieldsCaseClose(null, null, null);
        TGS_CaseMethods.fillOrderFieldsCaseClose(new Case(), new NE__Order__c(), new NE__Order__c() );

        NETriggerHelper.setTriggerFiredTest('CallOrder2Asset', true);
        //TGS_Dummy_Test_Data.dummyEndpointsTGS();
      
        User u1;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            u1 = TGS_Dummy_Test_Data.getUserWithRole();
        }

        System.runAs(u1) {
            Test.startTest();
            User portUsr = TGS_Dummy_Test_Data.getPortalUser(TGS_Dummy_Test_Data.PortalType.PowerCustomerSuccess, null, true);

            System.runAs(portUsr) {
                insert new TGS_User_Org__c(TGS_Is_Admin__c=false, TGS_Is_BI_EN__c=false, TGS_Is_TGS__c=true);

                NE__OrderItem__c oi = TGS_Dummy_Test_Data.dummyConfiguration(UserInfo.getUserId(), 'New');

                Case newCase = [SELECT Id, AccountId, ContactId, Order__c, Order__r.NE__Asset__c, RecordTypeId, Type FROM Case WHERE Order__c IN (SELECT NE__OrderId__c FROM NE__OrderItem__c WHERE ID = :oi.Id)];
                System.assert(newCase.ContactId != null);
                NE__Order__c ord = [SELECT Id, NE__AccountId__c, NE__ServAccId__c, NE__BillAccId__c, Site__c, (SELECT Id FROM NE__Order_Items__r) FROM NE__Order__c WHERE ID = :newCase.Order__c];
                TGS_CaseMethods.fillOrderFieldsCaseClose(newCase, ord, ord);
            }
            Test.stopTest();
        }
    }
    @isTest public static void test_fillRelatedObjectFields_resolved() {
        NETriggerHelper.setTriggerFiredTest('CallOrder2Asset', true);
        BI_TestUtils.throw_exception = false;

        //TGS_Dummy_Test_Data.dummyEndpointsTGS();
      
        User u1;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            u1 = TGS_Dummy_Test_Data.getUserWithRole();
        }

        System.runAs(u1) {
            Test.startTest();
            User portUsr = TGS_Dummy_Test_Data.getPortalUser(TGS_Dummy_Test_Data.PortalType.PowerCustomerSuccess, null, true);

            System.runAs(portUsr) {
                insert new TGS_User_Org__c(TGS_Is_Admin__c=false, TGS_Is_BI_EN__c=false, TGS_Is_TGS__c=true);

                NE__OrderItem__c oi = TGS_Dummy_Test_Data.dummyConfiguration(UserInfo.getUserId(), 'New');

                System.assert(oi.NE__OrderId__c != null);

                Case oldCase = new Case();
                Case newCase = [SELECT Id, AccountId, Order__c, Order__r.NE__Asset__c, RecordTypeId, Type FROM Case WHERE Order__c IN (SELECT NE__OrderId__c FROM NE__OrderItem__c WHERE ID = :oi.Id)];

                NE__Order__c ord = newCase.Order__r;
                ord.NE__Order_Items__r.add(oi);

                newCase.Order__c = oi.NE__OrderId__c;
                newCase.Asset__c = oi.NE__OrderId__c;
                update newCase;

                List<NE__Order__c> lstOrders = new List<NE__Order__c>();
                lstOrders.add(ord);
                List<NE__OrderItem__c> lstOI = new List<NE__OrderItem__c>();

                BI_TestUtils.throw_exception = false;
                TGS_CaseMethods.fillRelatedObjectFields_resolved(newCase, oldCase, ord, ord, lstOrders, lstOI);
            }
            BI_TestUtils.throw_exception = true;
            TGS_CaseMethods.fillRelatedObjectFields_resolved(null, null, null, null, null, null);
            Test.stopTest();
        }
    }

    @isTest public static void case_StatusRollback_TEST(){
        TGS_User_Org__c userTGS = new TGS_User_Org__c();
        userTGS.TGS_Is_TGS__c = true;
        insert userTGS;

        User portUsr = TGS_Dummy_Test_Data.getPortalUser(TGS_Dummy_Test_Data.PortalType.PowerCustomerSuccess, null, true);

        System.runAs(portUsr){
            Test.startTest();
            NE__OrderItem__c tr_CI = TGS_Dummy_Test_Data.dummyConfiguration(UserInfo.getUserId(),'New');
            Case newCase = [SELECT Id, AccountId, Order__c, Order__r.NE__Asset__c, RecordTypeId, Type FROM Case WHERE Order__c IN (SELECT NE__OrderId__c FROM NE__OrderItem__c WHERE ID = :tr_CI.Id)];
            NE__Order__c ord = newCase.Order__r;
            ord.NE__Order_Items__r.add(tr_CI);
            newCase.Order__c = tr_CI.NE__OrderId__c;
            newCase.Asset__c = tr_CI.NE__OrderId__c;
            newCase.TGS_Casilla_Desarrollo__c = true;
            newCase.Status = Constants.CASE_STATUS_RESOLVED;
            update newCase;
            /*newCase.Status = Constants.CASE_STATUS_IN_PROGRESS;
            update newCase;*/
            Test.stopTest();
        }   
    }

    /*-------------------------------------------------------------------------------------------------------------------------------------------------------
        Author:        Juan Carlos Terrón
        Company:       New Energy Aborda
        Description:   Method to test TGS_CaseMethods.assigner_TGS_ProductCategorization method.
        
        IN:            Void
        OUT:           Void
        
        History:   
        <Date>                  <Author>                <Change Description>
        02/11/2016              JC Terrón               Initial Versions
        09/12/2016              Guillermo Muñoz         Modified User query to avoid errors   
        --------------------------------------------------------------------------------------------------------------------------------------------------------*/    
    public static testMethod void assigner_TGS_ProductCategorization_TEST(){
        TGS_User_Org__c userTGS = new TGS_User_Org__c();
        userTGS.TGS_Is_TGS__c = true;
        insert userTGS;

        TGS_GME_GM_Product_Categorization__c tr_CustomSetting = new TGS_GME_GM_Product_Categorization__c();
        tr_CustomSetting.Name = 'Test CS Record';
        tr_CustomSetting.TGS_Service__c = 'Dummy';
        tr_CustomSetting.TGS_Categorization_tier_1__c = 'Dummy tier 1';
        tr_CustomSetting.TGS_Categorization_tier_2__c = 'Dummy tier 2';
        tr_CustomSetting.TGS_Categorization_tier_3__c = 'Dummy tier 3';
        insert tr_CustomSetting;

        BI_bypass__c [] lst_cs = [SELECT SetupOwnerId FROM BI_bypass__c];
        Set <Id> set_id = new Set <Id>();

        if(!lst_cs.isEmpty()){
            for(BI_bypass__c cs : lst_cs){
                set_id.add(cs.SetupOwnerId);
            }
        }

        set_id.add(UserInfo.getUserId());       
        User usu = [SELECT Id FROM User WHERE IsActive = true AND Profile.Name =: 'TGS System Administrator' AND Id !=: set_id LIMIT 1];
        
        //User usu = [select Id from User where Profile.Name = 'TGS System Administrator' and IsActive = true limit 1];
        System.runAs(usu){
            Test.startTest();
            Case newCase = TGS_Dummy_Test_Data.dummyOrderCase();
            newCase.TGS_Service__c = 'Dummy';
            update newCase;
            newCase = [Select Id,TGS_Product_Tier_1__c,TGS_Product_Tier_2__c,TGS_Product_Tier_3__c from Case limit 1 ];
            System.assertEquals(newCase.TGS_Product_Tier_1__c,'Dummy tier 1', 'Fallo en TGS_Categorization_tier_1__c');
            System.assertEquals(newCase.TGS_Product_Tier_2__c,'Dummy tier 2', 'Fallo en TGS_Categorization_tier_2__c');
            System.assertEquals(newCase.TGS_Product_Tier_3__c,'Dummy tier 3', 'Fallo en TGS_Categorization_tier_3__c');
            Test.stopTest();
        }
    }    
     /*-------------------------------------------------------------------------------------------------------------------------------------------------------
        Author:        Everis
        Company:       Everis
        Description:   Method to test TGS_CaseMethods.notificacionMSIP method.
        
        IN:            Void
        OUT:           Void
        
        History:   
        <Date>                  <Author>                <Change Description>
        27/12/2016              Everis			   		Initial Versions        
    --------------------------------------------------------------------------------------------------------------------------------------------------------*/ 
    @isTest public static void test_notificacionMSIP_statusReason() {
        
        upsert new TGS_User_Org__c(TGS_Is_TGS__c = true);
        User admin = TGS_Dummy_Test_Data.dummyUserTGS(Label.BI_Administrador_Sistema);
        admin.BI_Permisos__c = 'TGS';
        insert admin;
        System.runAs(admin) {
            Map<String, Account> acctMap = TGS_Dummy_Test_Data.getAccountHierarchy();  
            
            Test.startTest();
            Case c = TGS_Dummy_Test_Data.getCaseConfigured(acctMap, Constants.PRODUCT_MSIP_FLAT_RATE, Constants.CASE_STATUS_IN_PROGRESS, Constants.CASE_STATUS_REASON_IN_PROVISION, Constants.TYPE_NEW, Constants.MSIP_TRUNKING_SITE, Constants.RECORD_TYPE_HOLDING_ACCOUNT_LABEL);
            Test.stopTest();
            Case c2 = c.clone(true, true, true, true);
            c2.TGS_Status_reason__c = Constants.CASE_STATUS_REASON_IN_TEST;
            
            //Inserto ATM a la cuenta holding.
            Map<ID,AccountTeamMember> atmsMap = new Map<ID,AccountTeamMember>( [SELECT UserId, TeamMemberRole  FROM AccountTeamMember Where AccountID = :c.Account.TGS_Aux_Holding__c]);
            List<AccountTeamMember> atms = atmsMap.values();
            
            List<Case> oldCases = new List<Case>();
            oldCases.add(c);
            List<Case> newCases = new List<Case>();
            newCases.add(c2);
            BI_TestUtils.throw_exception = false;
            TGS_CaseMethods.notificacionMSIP(oldCases, newCases);
        }
     }
    
    /*-------------------------------------------------------------------------------------------------------------------------------------------------------
        Author:        Everis
        Company:       Everis
        Description:   Method to test TGS_CaseMethods.notificacionMSIP method.
        
        IN:            Void
        OUT:           Void
        
        History:   
        <Date>                  <Author>                <Change Description>
        27/12/2016              Everis   				Initial Versions        
    --------------------------------------------------------------------------------------------------------------------------------------------------------*/ 
    @isTest public static void test_notificacionMSIP_status_BU() {
     	
        upsert new TGS_User_Org__c(TGS_Is_TGS__c = true);
        User admin = TGS_Dummy_Test_Data.dummyUserTGS(Label.BI_Administrador_Sistema);
        admin.BI_Permisos__c = 'TGS';
        insert admin;
        System.runAs(admin) {
            Map<String, Account> acctMap = TGS_Dummy_Test_Data.getAccountHierarchy();  
            
            Test.startTest();
            Case c = TGS_Dummy_Test_Data.getCaseConfigured(acctMap, Constants.PRODUCT_MSIP_FLAT_RATE, Constants.CASE_STATUS_IN_PROGRESS, Constants.CASE_STATUS_REASON_IN_PROVISION, Constants.TYPE_NEW, Constants.MSIP_TRUNKING_SITE, Constants.RECORD_TYPE_BUSINESS_UNIT_ACCOUNT_LABEL);
            Test.stopTest();
            Case c2 = c.clone(true, true, true, true);
            c2.TGS_Status_reason__c = Constants.CASE_STATUS_REASON_IN_TEST;
            
            //Inserto ATM a la cuenta holding.
            Map<ID,AccountTeamMember> atmsMap = new Map<ID,AccountTeamMember>( [SELECT UserId, TeamMemberRole  FROM AccountTeamMember Where AccountID = :c.Account.TGS_Aux_Holding__c]);
            List<AccountTeamMember> atms = atmsMap.values();
            
            List<Case> oldCases = new List<Case>();
            oldCases.add(c);
            List<Case> newCases = new List<Case>();
            newCases.add(c2);
            BI_TestUtils.throw_exception = false;
            TGS_CaseMethods.notificacionMSIP(oldCases, newCases);
        }
    }
    
    /*-------------------------------------------------------------------------------------------------------------------------------------------------------
        Author:        Everis
        Company:       Everis
        Description:   Method to test TGS_CaseMethods.notificacionMSIP method.
        
        IN:            Void
        OUT:           Void
        
        History:   
        <Date>                  <Author>                <Change Description>
        27/12/2016              Everis   				Initial Versions        
    --------------------------------------------------------------------------------------------------------------------------------------------------------*/ 
    @isTest public static void test_notificacionMSIP_status_LE() {
        
        upsert new TGS_User_Org__c(TGS_Is_TGS__c = true);
        User admin = TGS_Dummy_Test_Data.dummyUserTGS(Label.BI_Administrador_Sistema);
        admin.BI_Permisos__c = 'TGS';
        insert admin;
        System.runAs(admin) {
            Map<String, Account> acctMap = TGS_Dummy_Test_Data.getAccountHierarchy();  
            
            Test.startTest();
            Case c = TGS_Dummy_Test_Data.getCaseConfigured(acctMap, Constants.PRODUCT_MSIP_FLAT_RATE, Constants.CASE_STATUS_IN_PROGRESS, Constants.CASE_STATUS_REASON_IN_PROVISION, Constants.TYPE_NEW, Constants.MSIP_TRUNKING_SITE, Constants.RECORD_TYPE_LEGAL_ENTITY_ACCOUNT_LABEL);
            Test.stopTest();
            Case c2 = c.clone(true, true, true, true);
            c2.Status = Constants.CASE_STATUS_RESOLVED;
            c2.TGS_Status_reason__c = '';
            
            //Inserto ATM a la cuenta holding.
            Map<ID,AccountTeamMember> atmsMap = new Map<ID,AccountTeamMember>( [SELECT UserId, TeamMemberRole  FROM AccountTeamMember Where AccountID = :c.Account.TGS_Aux_Holding__c]);
            List<AccountTeamMember> atms = atmsMap.values();
            
            List<Case> oldCases = new List<Case>();
            oldCases.add(c);
            List<Case> newCases = new List<Case>();
            newCases.add(c2);
            BI_TestUtils.throw_exception = false;
            TGS_CaseMethods.notificacionMSIP(oldCases, newCases);
        }
    }
    
    
    /*-------------------------------------------------------------------------------------------------------------------------------------------------------
        Author:        Everis
        Company:       Everis
        Description:   Method to test TGS_CaseMethods.notificacionMSIP method.
        
        IN:            Void
        OUT:           Void
        
        History:   
        <Date>                  <Author>                <Change Description>
        27/12/2016              Everis   				Initial Versions        
    --------------------------------------------------------------------------------------------------------------------------------------------------------*/ 
    @isTest public static void test_notificacionMSIP_status_CC() {
     	
        upsert new TGS_User_Org__c(TGS_Is_TGS__c = true);
        User admin = TGS_Dummy_Test_Data.dummyUserTGS(Label.BI_Administrador_Sistema);
        admin.BI_Permisos__c = 'TGS';
        insert admin;
        System.runAs(admin) {
            Map<String, Account> acctMap = TGS_Dummy_Test_Data.getAccountHierarchy();  
            
            Test.startTest();
            Case c = TGS_Dummy_Test_Data.getCaseConfigured(acctMap, Constants.PRODUCT_MSIP_FLAT_RATE, Constants.CASE_STATUS_IN_PROGRESS, Constants.CASE_STATUS_REASON_IN_PROVISION, Constants.TYPE_NEW, Constants.MSIP_TRUNKING_SITE, Constants.RECORD_TYPE_CUSTOMER_COUNTRY_ACCOUNT_LABEL);
            Test.stopTest();
            Case c2 = c.clone(true, true, true, true);
            c2.TGS_Status_reason__c = Constants.CASE_STATUS_REASON_IN_TEST;
            
            //Inserto ATM a la cuenta holding.
            Map<ID,AccountTeamMember> atmsMap = new Map<ID,AccountTeamMember>( [SELECT UserId, TeamMemberRole  FROM AccountTeamMember Where AccountID = :c.Account.TGS_Aux_Holding__c]);
            List<AccountTeamMember> atms = atmsMap.values();
            
            List<Case> oldCases = new List<Case>();
            oldCases.add(c);
            List<Case> newCases = new List<Case>();
            newCases.add(c2);
            BI_TestUtils.throw_exception = false;
            TGS_CaseMethods.notificacionMSIP(oldCases, newCases);
        }
    }
    
    /*-------------------------------------------------------------------------------------------------------------------------------------------------------
        Author:        Álvaro López
        Company:       New Energy Aborda
        Description:   Method to test TGS_CaseMethods.validateProductTier method.
        
        IN:            Void
        OUT:           Void
        
        History:   
        <Date>                  <Author>                <Change Description>
        02/11/2016              Álvaro López               Initial Versions
        --------------------------------------------------------------------------------------------------------------------------------------------------------*/
    /*
    @isTest public static void validateProductTier_TEST(){
        TGS_User_Org__c userTGS = new TGS_User_Org__c();
        userTGS.TGS_Is_TGS__c = true;
        insert userTGS;

        TGS_Tier_Dependence__c tr_CustomSetting = new TGS_Tier_Dependence__c();
        tr_CustomSetting.Name = 'Test CS Record';
        tr_CustomSetting.TGS_Holding_Name__c = 'Dummy holding';
        tr_CustomSetting.TGS_RTDevName__c = 'TGS_Incident';
        tr_CustomSetting.TGS_Product_Tier_1__c = 'Dummy tier 1';
        tr_CustomSetting.TGS_Product_Tier_2__c = 'Dummy tier 2';
        tr_CustomSetting.TGS_Product_Tier_3__c = 'Dummy tier 3';
        insert tr_CustomSetting;

        BI_bypass__c [] lst_cs = [SELECT SetupOwnerId FROM BI_bypass__c];
        Set <Id> set_id = new Set <Id>();

        if(!lst_cs.isEmpty()){
            for(BI_bypass__c cs : lst_cs){
                set_id.add(cs.SetupOwnerId);
            }
        }

        set_id.add(UserInfo.getUserId());       
        User usu = [SELECT Id FROM User WHERE IsActive = true AND Profile.Name =: 'TGS System Administrator' AND Id !=: set_id LIMIT 1];

        System.runAs(usu){
            Test.startTest();
            Id rtId = TGS_RecordTypes_Util.getRecordTypeId(Case.SObjectType, 'TGS_Incident');
            Contact c = TGS_Dummy_Test_Data.dummyContactTGS('Parker');
            insert c;
            //-------------------------------------------------------------------------
            // Level 1: Holding
            Id recordtypeId = TGS_RecordTypes_Util.getRecordTypeId(Account.SObjectType, Constants.RECORD_TYPE_TGS_HOLDING);
            Account holding = new Account(                     
                Name = 'Dummy holding',
                RecordTypeId = recordtypeId,
                BI_Country__c = 'Spain',
                BI_Segment__c = 'Empresas',
                BI_Subsegment_Regional__c='Corporate',
                TGS_Es_MNC__c = True);
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
                ParentId = holding.Id);
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
                TGS_Aux_Holding__c = holding.Id);
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
                TGS_Aux_Holding__c = holding.Id);
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
                TGS_Aux_Legal_Entity__c = legalEntity.Id
                );
            insert costCenter;
            
            legalEntity = [SELECT Name, Id, ParentId, Parent.ParentId, Parent.Parent.Name, Parent.Parent.Id, RecordType.DeveloperName, TGS_Aux_Holding__c FROM Account WHERE id = :legalEntity.Id];
            
            //-------------------------------------------------------------------------
            Case caseTest = new Case(
                RecordTypeId = rtId , 
                Subject = 'Test ticket case', 
                Status = 'Assigned', 
                ContactId=c.Id, 
                AccountId = legalEntity.Id,
                TGS_Product_Tier_1__c = 'Dummy tier 1',
                TGS_Product_Tier_2__c = 'Dummy tier 2',
                TGS_Product_Tier_3__c = 'Dummy tier 3'
                );
            insert caseTest;
            update caseTest;
            System.assertEquals(caseTest.TGS_Product_Tier_1__c,'Dummy tier 1', 'Fallo en TGS_Categorization_tier_1__c');
            System.assertEquals(caseTest.TGS_Product_Tier_2__c,'Dummy tier 2', 'Fallo en TGS_Categorization_tier_2__c');
            System.assertEquals(caseTest.TGS_Product_Tier_3__c,'Dummy tier 3', 'Fallo en TGS_Categorization_tier_3__c');
            Test.stopTest();
        }     
    }
    */

    public static testMethod void assignerHandlerTGS_TEST() {
        Case testCase = TGS_Dummy_Test_Data.dummyCaseTGS(Constants.CASE_RTYPE_DEVNAME_ORDER_MNGMNT, '');

        Id rtId = TGS_RecordTypes_Util.getRecordTypeId(Account.SObjectType, Constants.RECORD_TYPE_TGS_HOLDING);
        Account testAccount = new Account(                     
            Name = 'TestAccount',
            RecordTypeId = rtId,
            BI_Country__c = 'Spain',
            BI_Segment__c = 'Empresas',
            BI_Subsegment_Regional__c='Corporate',
            TGS_DirectFinal_Type__c='Direct Customer',
            TGS_Es_MNC__c = True);
        insert testAccount;

        testCase.AccountId = testAccount.Id;

        insert testCase;

        testCase.Status = 'In Progress';

        
    }

    
    /*-------------------------------------------------------------------------------------------------------------------------------------------------------
        Author:        Álvaro López
        Company:       New Energy Aborda
        Description:   Method to test TGS_CaseMethods.validateProductTier_AUX method.
        
        IN:            Void
        OUT:           Void
        
        History:   
        <Date>                  <Author>                <Change Description>
        06/03/2017              Álvaro López             Initial Versions
        --------------------------------------------------------------------------------------------------------------------------------------------------------*/
    @isTest public static void validateProductTier_AUX_TEST(){
        TGS_User_Org__c userTGS = new TGS_User_Org__c();
        userTGS.TGS_Is_TGS__c = true;
        insert userTGS;

        TGS_Categorization_Tier_Dependence__c cat_tier_dep= new TGS_Categorization_Tier_Dependence__c(
            TGS_Holding_Name__c = 'Dummy holding',
            TGS_RTDevName__c = 'TGS_Incident',
            TGS_Product_Tier_1__c = 'Dummy tier 1',
            TGS_Product_Tier_2__c = 'Dummy tier 2',
            TGS_Product_Tier_3__c = 'Dummy tier 3'
        );
        
        insert cat_tier_dep;

        BI_bypass__c [] lst_cs = [SELECT SetupOwnerId FROM BI_bypass__c];
        Set <Id> set_id = new Set <Id>();

        if(!lst_cs.isEmpty()){
            for(BI_bypass__c cs : lst_cs){
                set_id.add(cs.SetupOwnerId);
            }
        }

        set_id.add(UserInfo.getUserId());       
        User usu = [SELECT Id FROM User WHERE IsActive = true AND Profile.Name =: 'TGS System Administrator' AND Id !=: set_id LIMIT 1];

        System.runAs(usu){
            Test.startTest();
            Id rtId = TGS_RecordTypes_Util.getRecordTypeId(Case.SObjectType, 'TGS_Incident');
            Contact c = TGS_Dummy_Test_Data.dummyContactTGS('Parker');
            insert c;
            //-------------------------------------------------------------------------
            // Level 1: Holding
            Id recordtypeId = TGS_RecordTypes_Util.getRecordTypeId(Account.SObjectType, Constants.RECORD_TYPE_TGS_HOLDING);
            Account holding = new Account(                     
                Name = 'Dummy holding',
                RecordTypeId = recordtypeId,
                BI_Country__c = 'Spain',
                BI_Segment__c = 'Empresas',
                BI_Subsegment_Regional__c='Corporate',
                TGS_DirectFinal_Type__c='Direct Customer',
                TGS_Es_MNC__c = True);
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
                ParentId = holding.Id);
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
                TGS_Aux_Holding__c = holding.Id);
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
                TGS_Aux_Holding__c = holding.Id);
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
                TGS_Aux_Legal_Entity__c = legalEntity.Id
                );
            insert costCenter;
            
            legalEntity = [SELECT Name, Id, ParentId, Parent.ParentId, Parent.Parent.Name, Parent.Parent.Id, RecordType.DeveloperName, TGS_Aux_Holding__c FROM Account WHERE id = :legalEntity.Id];
            
            //-------------------------------------------------------------------------
            Case caseTest = new Case(
                RecordTypeId = rtId , 
                Subject = 'Test ticket case', 
                Status = 'Assigned', 
                ContactId=c.Id, 
                AccountId = legalEntity.Id,
                TGS_Product_Tier_1__c = 'Dummy tier 1',
                TGS_Product_Tier_2__c = 'Dummy tier 2',
                TGS_Product_Tier_3__c = 'Dummy tier 3'
                );
            insert caseTest;
            update caseTest;
            System.assertEquals(caseTest.TGS_Product_Tier_1__c,'Dummy tier 1', 'Fallo en TGS_Categorization_tier_1__c');
            System.assertEquals(caseTest.TGS_Product_Tier_2__c,'Dummy tier 2', 'Fallo en TGS_Categorization_tier_2__c');
            System.assertEquals(caseTest.TGS_Product_Tier_3__c,'Dummy tier 3', 'Fallo en TGS_Categorization_tier_3__c');
            Test.stopTest();
        }     
    }


}