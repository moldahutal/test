/*-------------------------------------------------------------------------------------------------------------------------------------------------------
     Author:        Manuel Ochoa
     Company:       Accenture Technology Center - Tecnilógica
     Description:   TEST Class for BI_LEX_CreateMultipleSubOppControl class
                    
     Test Class:    
     History:
     
     <Date>             <Author>                <Description>
     2020-01-17         Manuel Ochoa            First Version
--------------------------------------------------------------------------------------------------------------------------------------------------------*/
@isTest
public class BI_LEX_CreateMultipleSubOpp_TEST {

    public static User testUser;
    public static Account accHolding;
    public static Account accCC;
    public static Account accLE;
    public static Opportunity testOptyCentralized;
    public static Opportunity testOptyGlobal;
    public static Opportunity testOptyLocal;
    public static NE__Map__c mp;
    public static String strOrderId;

    public static List<String> selectedCatItemsList;
    public static Map <String,String> productNamesMap;
    public static List<String> catalogIDLIST;

     /* ********************************************
    ***********************************************
      TEST Data creation  -- START  
    ***********************************************
    ***********************************************/
    
    //@testSetup
    public static void setupData() {
        testUser = createUser();
        System.runAs(testUser){
            BI_MigrationHelper.skipAllTriggers();

            Map<String,Id> mapStrIdRT = new Map<String,Id>();
            for(RecordType rt:[SELECT Id,DeveloperName,Name FROM RecordType WHERE SObjectType = 'Account' OR SObjectType = 'Opportunity']){
                mapStrIdRT.put(rt.Name,rt.Id);
            }

            accHolding = new Account(RecordTypeId = mapStrIdRT.get('1.Holding'),
                                    Name = 'test_multiOpp',
                                    TGS_Region__c = '2|Europe',
                                    BI_Country__c ='Spain',
                                    BI_Ambito__c = 'Público',
                                    CurrencyIsoCode = 'EUR');
            insert accHolding;

            accCC = new Account(RecordTypeId = mapStrIdRT.get('2.Customer Country'),
                                ParentId = accHolding.Id,
                                Name = 'test_multiOpp_CC',
                                TGS_Region__c = '2|Europe',
                                BI_Country__c ='Spain',
                                BI_Ambito__c = 'Público',
                                CurrencyIsoCode = 'EUR');
            insert accCC;

            accLE = new Account(RecordTypeId = mapStrIdRT.get('3.Legal Entity'),
                                Name = 'test LE',
                                ParentId = accCC.Id,
                                BI_Activo__c = Label.BI_Si,
                                BI_Country__c = 'Spain',
                                BI_Segment__c = 'Empresas',
                                BI_Subsector__c = 'test', 
                                BI_Sector__c = 'test', 
                                BI_Subsegment_local__c = 'Top 1',
                                BI_Subsegment_Regional__c = 'test',
                                BI_Territory__c = 'test'
                                );
            insert accLE;

            testOptyGlobal = new Opportunity(Name = 'testOptyGlobal',
                            RecordTypeId = mapStrIdRT.get('Agrupación'),
                            BI_O4_Opportunity_Type__c = 'Global Distributed',
                            StageName = Label.BI_F5DefSolucion,
                            AccountId = accHolding.Id,
                            CloseDate = Date.today(),
                            Probability = 50,
                            BI_Country__c = 'Spain');
            insert testOptyGlobal;
        
            testOptyCentralized = new Opportunity(Name = 'testOptyCentralized',
                                            RecordTypeId = mapStrIdRT.get('Agrupación'),
                                            BI_O4_Opportunity_Type__c = 'Centralized',
                                            StageName = Label.BI_F5DefSolucion,
                                            AccountId = accHolding.Id,
                                            BI_O4_Service_Lines__c = '',
                                            BI_Fecha_de_vigencia__c= null,
                                            BI_O4_Paises__c = '',                                            
                                            BI_O4_Countries_EMEA__c = '',
                                            BI_O4_Countries_America__c = '',
                                            BI_O4_Countries_Rest_of_the_world__c = '',                                            
                                            CloseDate = Date.today(),
                                            Probability = 50,                                            
                                            BI_Country__c = 'Spain');
            insert testOptyCentralized;

            testOptyLocal = new Opportunity(Name = 'testOptyLocal',
                                RecordTypeId = mapStrIdRT.get('Agrupación'),
                                BI_O4_Opportunity_Type__c = 'Local Distributed',
                                StageName = Label.BI_F5DefSolucion,
                                AccountId = accLE.Id,
                                CloseDate = Date.today(),
                                Probability = 50,
                                BI_Country__c = 'Spain');
            insert testOptyLocal;

            BI_MigrationHelper.cleanSkippedTriggers();
        }
    }
    
    public static User createUser(){
        BI_MigrationHelper.skipAllTriggers();
        User testUser = new User(LastName = 'test user 1', 
                                Username = 'test.user.1@example.com', 
                                Email = 'amador.caceres.rubio.sa@everis.com', 
                                CommunityNickname = 'testUser',
                                Alias = 'testu1', 
                                TimeZoneSidKey = 'Europe/Paris', 
                                LocaleSidKey = 'es_ES', 
                                EmailEncodingKey = 'ISO-8859-1', 
                                ProfileId = [SELECT Id FROM profile WHERE Name = 'BI_O4_TGS_Standard_LEX' LIMIT 1].Id, 
                                LanguageLocaleKey = 'es',
                                BI_Permisos__c = 'Ejecutivo de Cliente');
        insert testUser;
		insert new PermissionSetAssignment(AssigneeId = testUser.id, PermissionSetId = [SELECT Id FROM PermissionSet WHERE Name = 'BI_General'].Id);
        insert new PermissionSetAssignment(AssigneeId = testUser.id, PermissionSetId = [SELECT Id FROM PermissionSet WHERE Name = 'BI_O4_TGS_Ejecutivo_de_Cliente'].Id);
        insert new PermissionSetAssignment(AssigneeId = testUser.id, PermissionSetId = [SELECT Id FROM PermissionSet WHERE Name = 'BI_O4_Oportunidades'].Id);
        BI_MigrationHelper.cleanSkippedTriggers();
        return testUser;
    }
    
    public static void createCatalogAndProducts(){
        BI_MigrationHelper.skipAllTriggers();
        // products insertion
        RecordType RTProdStandard = [SELECT Id FROM RecordType WHERE (SobjectType = 'NE__Product__c' OR SobjectType = 'Product__c') AND Name = 'Standard' LIMIT 1];        
        List<NE__Product__c> lstProducts = new List<NE__Product__c>();
        NE__Product__c prod1 = new NE__Product__c(Name='Test Product 1', RecordTypeId=RTProdStandard.Id);
        lstProducts.addAll(new List<NE__Product__c>{prod1});
        insert lstProducts;

        // Family property insertion
        List<NE__DynamicPropertyDefinition__c> lstProps = new List<NE__DynamicPropertyDefinition__c>();
        NE__DynamicPropertyDefinition__c prop1   =   new NE__DynamicPropertyDefinition__c(name = 'TestPropertyString',NE__Type__c ='String');
        lstProps.addAll(new List<NE__DynamicPropertyDefinition__c>{prop1});
        insert lstProps;

        // families insertion
        List<NE__Family__c> lstFamilies = new List<NE__Family__c>();
        NE__Family__c familyProd1    =   new NE__Family__c(name = 'Test Family Prod1');        
        lstFamilies.addAll(new List<NE__Family__c>{familyProd1});
        insert lstFamilies;

        // product family and properties
        List<NE__ProductFamily__c> lstProdFamily = new List<NE__ProductFamily__c>();
        NE__ProductFamily__c prodFamilyProd1 =   new NE__ProductFamily__c(NE__ProdId__c = prod1.id, NE__FamilyId__c = familyProd1.id,NE__Sequence__c=1);        
        lstProdFamily.addAll(new List<NE__ProductFamily__c>{prodFamilyProd1});
        insert lstProdFamily;
            
        List<NE__ProductFamilyProperty__c> lstProdFamilyProp = new List<NE__ProductFamilyProperty__c>();
        NE__ProductFamilyProperty__c pfp1 = new NE__ProductFamilyProperty__c(NE__FamilyId__c=familyProd1.Id, NE__PropId__c=prop1.Id,NE__Required__c='Yes',NE__Sequence__c=1);        
        lstProdFamilyProp.addAll(new List<NE__ProductFamilyProperty__c>{pfp1});
        insert lstProdFamilyProp;

        // catalog header and catalog
        NE__Catalog_Header__c catHead = new NE__Catalog_Header__c(Name='Catalog Header',
                                                                    NE__Name__C='Catalog Header');
        insert catHead;
                
        NE__Catalog__c  cat = new NE__Catalog__c(Name='TGS Commercial',
                                                NE__Catalog_Header__c=catHead.Id, 
                                                NE__StartDate__c=Datetime.now(), 
                                                NE__Active__c = true);
        insert cat;
        catalogIDLIST = new List<String>();
        catalogIDLIST.add(cat.Id);

        // Catalog category, items and related data
        NE__Catalog_Category__c catCat = new NE__Catalog_Category__c(Name='Voz Fija', 
                                                                    NE__CatalogId__c=cat.Id);
        insert catCat;

        List<NE__Catalog_Item__c> lstCatItems = new  List<NE__Catalog_Item__c>();
        // simple product     
        NE__Catalog_Item__c catItem1 = new NE__Catalog_Item__c(NE__Active__c=true,NE__Type__c='Enumerated',
                                                            NE__Catalog_Id__c=cat.Id, NE__ProductId__c=prod1.Id, NE__Catalog_Category_Name__c=catCat.Id,
                                                                NE__Start_Date__c=Datetime.now(), NE__Base_OneTime_Fee__c=200.00, NE__BaseRecurringCharge__c=20.00, 
                                                            NE__Recurring_Charge_Frequency__c='Monthly');
        NE__Catalog_Item__c catItem2 = new NE__Catalog_Item__c(NE__Active__c=true,NE__Type__c='Enumerated',
                                                            NE__Catalog_Id__c=cat.Id, NE__ProductId__c=prod1.Id, NE__Catalog_Category_Name__c=catCat.Id,
                                                                NE__Start_Date__c=Datetime.now(), NE__Base_OneTime_Fee__c=200.00, NE__BaseRecurringCharge__c=20.00, 
                                                            NE__Recurring_Charge_Frequency__c='Monthly');                    
        
        lstCatItems.addAll(new List<NE__Catalog_Item__c>{catItem1,catItem2});
        insert lstCatItems;

        selectedCatItemsList = new  List<String>();
        productNamesMap = new Map <String,String>();
        selectedCatItemsList.add(lstCatItems[0].Id);
        selectedCatItemsList.add(lstCatItems[1].Id);
        productNamesMap.put(lstCatItems[0].Id,prod1.name);
        productNamesMap.put(lstCatItems[1].Id,prod1.name);

        NE__Item_Header__c itemHead = new  NE__Item_Header__c(Name='Item Header',
                                                                NE__Catalog__c=cat.id,
                                                                NE__Catalog_Item__c=catItem1.id
                                                            );
        insert itemHead;
        BI_MigrationHelper.cleanSkippedTriggers();
    }

     /* ********************************************
    ***********************************************
      TEST Data creation  -- END 
    ***********************************************
    ***********************************************/

    //----------------------------------------------------------------------------------------------------------------------------------------------------------
    //Tests for method alloAccessComponent

    @isTest 
    static void testAlloAccessComponentOptyCentralized(){

        system.debug('ENTERING testAlloAccessComponentCustomUser');		
        
        setupData();
        BI_LEX_CreateMultipleSubOppControl.wrapperHelper response = new BI_LEX_CreateMultipleSubOppControl.wrapperHelper();        
        
        Test.startTest();
        System.runAs(testUser){
            response = BI_LEX_CreateMultipleSubOppControl.allowAccessComponent(testOptyCentralized.Id);
        }
        Test.stopTest();

        System.debug(response);
        System.assertEquals(null, response.errorMessage);
        System.assertEquals(null, response.errorList);
    }

    @isTest 
    static void testAlloAccessComponentOptyGlobal(){

        system.debug('ENTERING testAlloAccessComponentGlobal');		
        
        setupData();
        BI_LEX_CreateMultipleSubOppControl.wrapperHelper response = new BI_LEX_CreateMultipleSubOppControl.wrapperHelper();
        
        Test.startTest();
        System.runAs(testUser){
            response = BI_LEX_CreateMultipleSubOppControl.allowAccessComponent(testOptyGlobal.Id);
        }
        Test.stopTest();

        System.debug(response);
        System.assertEquals(null, response.errorMessage);
        System.assertEquals(null, response.errorList);
    }

    @isTest 
    static void testAlloAccessComponentNoValidOpty(){

        system.debug('ENTERING testAlloAccessComponentGlobal');
        setupData();
        
        testOptyGlobal.StageName = 'F1 - Cancelled | Suspended';
        System.runAs(testUser){
            update testOptyGlobal;
        }       
        
        BI_LEX_CreateMultipleSubOppControl.wrapperHelper response = new BI_LEX_CreateMultipleSubOppControl.wrapperHelper();
        
        Test.startTest();
        System.runAs(testUser){
            response = BI_LEX_CreateMultipleSubOppControl.allowAccessComponent(testOptyGlobal.Id);
        }
        Test.stopTest();

        System.debug(response);
        System.assertEquals(Label.BI_LEX_CantCreateSubOppF1F2, response.errorMessage);
    }

    @isTest 
    static void testAlloAccessComponentInvalidUser(){

        system.debug('ENTERING testAlloAccessComponentInvalidUser');		
        
        setupData();
        BI_LEX_CreateMultipleSubOppControl.wrapperHelper response = new BI_LEX_CreateMultipleSubOppControl.wrapperHelper();
        
        Test.startTest();
            response = BI_LEX_CreateMultipleSubOppControl.allowAccessComponent(testOptyGlobal.Id);
        Test.stopTest();

        System.debug(response);
        System.assertEquals(Label.BI_LEX_NoPermissionsForAction, response.errorMessage);
    }
    
    //----------------------------------------------------------------------------------------------------------------------------------------------------------
    //Tests for method getInitialInformation    

    @isTest 
    static void testGetInitialInformationOptyCentralized(){
        system.debug('ENTERING testGetInitialInformationOptyCentralized');
        setupData();

        BI_LEX_CreateMultipleSubOppControl.wrapperHelper response = new BI_LEX_CreateMultipleSubOppControl.wrapperHelper();

        Test.startTest();
            response = BI_LEX_CreateMultipleSubOppControl.getInitialInformation(testOptyCentralized.Id);
        Test.stopTest();

        System.assertEquals(testOptyCentralized.Id, response.currentOpp.Id);
        System.assertEquals(testOptyCentralized.name, response.currentOpp.name); 
    }

    @isTest 
    static void testGetInitialInformationOptyGlobal(){
        system.debug('ENTERING testGetInitialInformationOptyGlobal');
        setupData();

        BI_LEX_CreateMultipleSubOppControl.wrapperHelper response = new BI_LEX_CreateMultipleSubOppControl.wrapperHelper();

        Test.startTest();
            response = BI_LEX_CreateMultipleSubOppControl.getInitialInformation(testOptyGlobal.Id);
        Test.stopTest();

        System.assertEquals(testOptyGlobal.Id, response.currentOpp.Id);
        System.assertEquals(testOptyGlobal.name, response.currentOpp.name); 
    }

    @isTest 
    static void testGetInitialInformationOptyLocal(){
        system.debug('ENTERING testGetInitialInformationOptyLocal');
        setupData();

        BI_LEX_CreateMultipleSubOppControl.wrapperHelper response = new BI_LEX_CreateMultipleSubOppControl.wrapperHelper();

        Test.startTest();
            response = BI_LEX_CreateMultipleSubOppControl.getInitialInformation(testOptyLocal.Id);
        Test.stopTest();

        System.assertEquals(testOptyLocal.Id, response.currentOpp.Id);
        System.assertEquals(testOptyLocal.name, response.currentOpp.name); 
    }    
    
    @isTest 
    static void testGetInitialInformationWithCatalog(){
        system.debug('ENTERING testGetInitialInformationWithCatalog');
        setupData();
        System.runAs(testUser){
            createCatalogAndProducts();
        }

        BI_LEX_CreateMultipleSubOppControl.wrapperHelper response = new BI_LEX_CreateMultipleSubOppControl.wrapperHelper();

        Test.startTest();
            response = BI_LEX_CreateMultipleSubOppControl.getInitialInformation(testOptyGlobal.Id);
        Test.stopTest();

        System.assertEquals(testOptyGlobal.Id, response.currentOpp.Id);
        System.assertEquals(testOptyGlobal.Name, response.currentOpp.Name);
    }

    @isTest 
    static void testGetInitialInformationNoValidOpty(){
        system.debug('ENTERING testGetInitialInformationNoValidOpty');
        setupData();

        BI_LEX_CreateMultipleSubOppControl.wrapperHelper response = new BI_LEX_CreateMultipleSubOppControl.wrapperHelper();

        testOptyGlobal.BI_O4_Opportunity_Type__c='';
        System.runAs(testUser){ 
            update testOptyGlobal;  
        }

        Test.startTest();
            response = BI_LEX_CreateMultipleSubOppControl.getInitialInformation(testOptyGlobal.Id);
        Test.stopTest();

        System.assertEquals(Label.BI_O4_Opportunity_Type_Mandatory, response.errorMessage);
        
    }

    //----------------------------------------------------------------------------------------------------------------------------------------------------------
    //Tests for method validateData

    @isTest 
    static void testValidateDataTrue(){
        system.debug('ENTERING testValidateDataTrue');
        setupData();

        Boolean response;

        Test.startTest();
            response = BI_LEX_CreateMultipleSubOppControl.validateData(testOptyCentralized);
        Test.stopTest();

        System.assertEquals(true, response);
    }

    @isTest 
    static void testValidateDataFalse(){
        system.debug('ENTERING testValidateDataFalse');
        setupData();

        testOptyCentralized.StageName = Label.BI_F1ClosedLost;
        testOptyCentralized.BI_O4_Contract_Term_Months__c = 0;        

        Boolean response;

        Test.startTest();
            response = BI_LEX_CreateMultipleSubOppControl.validateData(testOptyCentralized);
        Test.stopTest();

        System.assertEquals(false, response);
    }
    
    //----------------------------------------------------------------------------------------------------------------------------------------------------------
    //Tests for method saveSubopportunities
    @isTest
    static void testSaveSubopportunitiesCentralized(){

        system.debug('ENTERING testSaveSubopportunitiesCentralized');
        
        setupData();
        System.runAs(testUser){
            createCatalogAndProducts();
        }

        BI_LEX_CreateMultipleSubOppControl.wrapperHelper response = new BI_LEX_CreateMultipleSubOppControl.wrapperHelper();  
        
        List<String> countryLIST = new List<String>(); 
        countryLIST.add('Angola');
        Map<String,Boolean> countryMultipleSLinesMAP = new Map<String,Boolean>();
        countryMultipleSLinesMAP.put('Angola', true);
        Map<String,Boolean> countryRenewalMAP = new Map<String,Boolean>();
        countryRenewalMAP.put('Angola', false);

		List<String> customerLIST = new List<String>();
        Map<String,Account> accountCountryMAP = new Map<String,Account>();		
        Boolean multisite = false;		
        Map<String,String> countrySitesMAP = new Map<String,String>();

        test.startTest();
        System.runAs(testUser){            
            response = BI_LEX_CreateMultipleSubOppControl.saveSubopportunities(testOptyCentralized,
                                                                                selectedCatItemsList,
                                                                                productNamesMap,
                                                                                countryLIST,
                                                                                customerLIST,
                                                                                accountCountryMAP,
                                                                                accHolding.Id,
                                                                                countryMultipleSLinesMAP,
                                                                                countryRenewalMAP,
                                                                                countrySitesMAP);
        }
        test.stopTest();

        System.assertEquals(2, response.toRecord);
       
        /*
        //Method to get a Error into try and go to catch
        Map<String,Account> accountCountryMAP_Error;
        BI_LEX_CreateMultipleSubOppControl.saveSubopportunities(Opp,selectedbusinesslinesLIST,countryLIST,customerLIST,accountCountryMAP_Error,
                                                                holding,countryMultipleSLinesMAP,multisite,serviceLineSET,countryRenewalMAP,
                                                               countrySitesMAP,serviceLineIdSET);*/
    }
    
    @isTest
    static void testSaveSubopportunitiesGlobal(){

        system.debug('ENTERING testSaveSubopportunitiesGlobal');
        
        setupData();
        System.runAs(testUser){
            createCatalogAndProducts();
        }

        BI_LEX_CreateMultipleSubOppControl.wrapperHelper response = new BI_LEX_CreateMultipleSubOppControl.wrapperHelper();  
        
        List<String> countryLIST = new List<String>(); 
        countryLIST.add('Angola');
        countryLIST.add('Spain');
        Map<String,Boolean> countryMultipleSLinesMAP = new Map<String,Boolean>();
        countryMultipleSLinesMAP.put('Angola', false);
        countryMultipleSLinesMAP.put('Spain', true);
        Map<String,Boolean> countryRenewalMAP = new Map<String,Boolean>();
        countryRenewalMAP.put('Angola', true);
        countryRenewalMAP.put('Spain', true);

		List<String> customerLIST = new List<String>();
        Map<String,Account> accountCountryMAP = new Map<String,Account>();		
        Boolean multisite = false;		
        Map<String,String> countrySitesMAP = new Map<String,String>();
        
        accountCountryMAP.put(accHolding.Id, accHolding);
        countryMultipleSLinesMAP.put(accHolding.Id, true);  
        countryRenewalMAP.put(accHolding.Id, true);

        test.startTest();
        System.runAs(testUser){           
            response = BI_LEX_CreateMultipleSubOppControl.saveSubopportunities(testOptyGlobal,
                                                                                selectedCatItemsList,
                                                                                productNamesMap,
                                                                                countryLIST,
                                                                                customerLIST,
                                                                                accountCountryMAP,
                                                                                accHolding.Id,
                                                                                countryMultipleSLinesMAP,
                                                                                countryRenewalMAP,
                                                                                countrySitesMAP);
        }
        test.stopTest();

        System.assertEquals(3, response.toRecord);
    }

     @isTest
    static void testSaveSubopportunitiesLocal(){

        system.debug('ENTERING testSaveSubopportunitiesGlobal');
        
        setupData();
        System.runAs(testUser){
            createCatalogAndProducts();
        }

        BI_LEX_CreateMultipleSubOppControl.wrapperHelper response = new BI_LEX_CreateMultipleSubOppControl.wrapperHelper();  
        
        List<String> countryLIST = new List<String>(); 
        countryLIST.add('Angola');
        Map<String,Boolean> countryMultipleSLinesMAP = new Map<String,Boolean>();
        countryMultipleSLinesMAP.put('Angola', true);
        Map<String,Boolean> countryRenewalMAP = new Map<String,Boolean>();
        countryRenewalMAP.put('Angola', false);        

		List<String> customerLIST = new List<String>();
        Map<String,Account> accountCountryMAP = new Map<String,Account>();		
        Boolean multisite = false;		
        Map<String,String> countrySitesMAP = new Map<String,String>();

        //testOptyGlobal.BI_O4_Opportunity_Type__c='Local Distributed';
        customerLIST.add(accCC.Id);
        customerLIST.add(accHolding.Id);
        accountCountryMAP.put(accCC.Id, accCC);
        accountCountryMAP.put(accHolding.Id, accHolding);
        countryMultipleSLinesMAP.put(accCC.Id, true);
        countryMultipleSLinesMAP.put(accHolding.Id, false);  
        countryRenewalMAP.put(accCC.Id, true);
        countryRenewalMAP.put(accHolding.Id, true);

        test.startTest();
        System.runAs(testUser){            
            response = BI_LEX_CreateMultipleSubOppControl.saveSubopportunities(testOptyLocal,
                                                                                selectedCatItemsList,
                                                                                productNamesMap,
                                                                                countryLIST,
                                                                                customerLIST,
                                                                                accountCountryMAP,
                                                                                accHolding.Id,
                                                                                countryMultipleSLinesMAP,
                                                                                countryRenewalMAP,
                                                                                countrySitesMAP);
        }
        test.stopTest();

        System.assertEquals(3, response.toRecord);
    }

     @isTest
    static void testSaveSubopportunitiesException(){

        system.debug('ENTERING testSaveSubopportunitiesException');
        
        setupData();
        System.runAs(testUser){
            createCatalogAndProducts();
        }

        BI_LEX_CreateMultipleSubOppControl.wrapperHelper response = new BI_LEX_CreateMultipleSubOppControl.wrapperHelper();  
        
        List<String> countryLIST = new List<String>(); 
        countryLIST.add('Angola');
        // map intentionally not initialized
        Map<String,Boolean> countryMultipleSLinesMAP;
        Map<String,Boolean> countryRenewalMAP = new Map<String,Boolean>();
        countryRenewalMAP.put('Angola', false);

		List<String> customerLIST = new List<String>();
        Map<String,Account> accountCountryMAP = new Map<String,Account>();		
        Boolean multisite = false;		
        Map<String,String> countrySitesMAP = new Map<String,String>();

        test.startTest();
        System.runAs(testUser){            
            response = BI_LEX_CreateMultipleSubOppControl.saveSubopportunities(testOptyCentralized,
                                                                                selectedCatItemsList,
                                                                                productNamesMap,
                                                                                countryLIST,
                                                                                customerLIST,
                                                                                accountCountryMAP,
                                                                                accHolding.Id,
                                                                                countryMultipleSLinesMAP,
                                                                                countryRenewalMAP,
                                                                                countrySitesMAP);
        }
        test.stopTest();

        System.assert(response.errorMessage!=null);        
    }

    @isTest
    static void testSaveSubopportunitiesNotValid(){

        system.debug('ENTERING testSaveSubopportunitiesNotValid');
        
        setupData();
        System.runAs(testUser){
            createCatalogAndProducts();
        }

        BI_LEX_CreateMultipleSubOppControl.wrapperHelper response = new BI_LEX_CreateMultipleSubOppControl.wrapperHelper();  
        
        List<String> countryLIST = new List<String>(); 
        countryLIST.add('Angola');
        Map<String,Boolean> countryMultipleSLinesMAP = new Map<String,Boolean>();
        countryMultipleSLinesMAP.put('Angola', true);
        Map<String,Boolean> countryRenewalMAP = new Map<String,Boolean>();
        countryRenewalMAP.put('Angola', false);

		List<String> customerLIST = new List<String>();
        Map<String,Account> accountCountryMAP = new Map<String,Account>();		
        Boolean multisite = false;		
        Map<String,String> countrySitesMAP = new Map<String,String>();

        testOptyCentralized.StageName = Label.BI_F1ClosedLost;
        testOptyCentralized.BI_O4_Contract_Term_Months__c = 0;

        test.startTest();
        System.runAs(testUser){            
            response = BI_LEX_CreateMultipleSubOppControl.saveSubopportunities(testOptyCentralized,
                                                                                selectedCatItemsList,
                                                                                productNamesMap,
                                                                                countryLIST,
                                                                                customerLIST,
                                                                                accountCountryMAP,
                                                                                accHolding.Id,
                                                                                countryMultipleSLinesMAP,
                                                                                countryRenewalMAP,
                                                                                countrySitesMAP);
        }
        test.stopTest();

        System.assertEquals(Label.BI_O4_ContractTermError, response.errorMessage);
       
        /*
        //Method to get a Error into try and go to catch
        Map<String,Account> accountCountryMAP_Error;
        BI_LEX_CreateMultipleSubOppControl.saveSubopportunities(Opp,selectedbusinesslinesLIST,countryLIST,customerLIST,accountCountryMAP_Error,
                                                                holding,countryMultipleSLinesMAP,multisite,serviceLineSET,countryRenewalMAP,
                                                               countrySitesMAP,serviceLineIdSET);*/
    }

    //----------------------------------------------------------------------------------------------------------------------------------------------------------
    //Test to Constructor
    @isTest
    static void testConstructor(){ 

        system.debug('ENTERING testConstructor');


        BI_LEX_CreateMultipleSubOppControl.wrapperHelper wrapperHelper = new BI_LEX_CreateMultipleSubOppControl.wrapperHelper();
        BI_LEX_CreateMultipleSubOppControl.wrapperHelperOptions wrapperHelperOptions = new BI_LEX_CreateMultipleSubOppControl.wrapperHelperOptions('test', 'hipertest');
    }   
    
    
    //------------------------------------------------------------------------------------------------------------------------------------------------
    //Test to "saveAllSubOpportunities" 
    @isTest
    static void testSaveAllSubOpportunities(){ 

        system.debug('ENTERING testSaveAllSubOpportunities');       

        setupData();
        System.runAs(testUser){
            createCatalogAndProducts();
        }

        BI_LEX_CreateMultipleSubOppControl.wrapperHelper response = new BI_LEX_CreateMultipleSubOppControl.wrapperHelper();  
        
        List<String> countryLIST = new List<String>(); 
        countryLIST.add('Angola');
        Map<String,Boolean> countryMultipleSLinesMAP = new Map<String,Boolean>();
        countryMultipleSLinesMAP.put('Angola', true);
        Map<String,Boolean> countryRenewalMAP = new Map<String,Boolean>();
        countryRenewalMAP.put('Angola', false);

		List<String> customerLIST = new List<String>();
        Map<String,Account> accountCountryMAP = new Map<String,Account>();		
        Boolean multisite = false;		
        Map<String,String> countrySitesMAP = new Map<String,String>();

        testOptyCentralized.BI_O4_Service_Lines__c = '2;' + testOptyCentralized.BI_O4_Service_Lines__c;
       
        System.runAs(testUser){            
            response = BI_LEX_CreateMultipleSubOppControl.saveSubopportunities(testOptyCentralized,
                                                                                selectedCatItemsList,
                                                                                productNamesMap,
                                                                                countryLIST,
                                                                                customerLIST,
                                                                                accountCountryMAP,
                                                                                accHolding.Id,
                                                                                countryMultipleSLinesMAP,
                                                                                countryRenewalMAP,
                                                                                countrySitesMAP);
        }
        
        List<String> errorList = new List<String>();
        
        List<String> countriesLIST = new List<String>();
        countriesLIST.add('Angola');

        test.startTest();
        System.runAs(testUser){ 
        response = BI_LEX_CreateMultipleSubOppControl.saveAllSubOpportunities(response.insertsuboppLIST,
                                                                            errorList, 
                                                                            testOptyCentralized,
                                                                            multisite,
                                                                            selectedCatItemsList, 
                                                                            catalogIDLIST,
                                                                            countriesLIST);
        }
        test.stopTest();

        System.assert(response.errorList.isEmpty());
    }

    @isTest
    static void testSaveAllSubOpportunitiesMultisite(){  

        system.debug('ENTERING testSaveAllSubOpportunitiesMultisite');         

        setupData();
        System.runAs(testUser){
            createCatalogAndProducts();
        }

        BI_LEX_CreateMultipleSubOppControl.wrapperHelper response = new BI_LEX_CreateMultipleSubOppControl.wrapperHelper();  
        
        List<String> countryLIST = new List<String>(); 
        countryLIST.add('Angola');
        Map<String,Boolean> countryMultipleSLinesMAP = new Map<String,Boolean>();
        countryMultipleSLinesMAP.put('Angola', true);
        Map<String,Boolean> countryRenewalMAP = new Map<String,Boolean>();
        countryRenewalMAP.put('Angola', false);

		List<String> customerLIST = new List<String>();
        Map<String,Account> accountCountryMAP = new Map<String,Account>();		
        Boolean multisite = true;		
        Map<String,String> countrySitesMAP = new Map<String,String>();

        testOptyCentralized.BI_O4_Service_Lines__c = '2;' + testOptyCentralized.BI_O4_Service_Lines__c;
       
        System.runAs(testUser){            
            response = BI_LEX_CreateMultipleSubOppControl.saveSubopportunities(testOptyCentralized,
                                                                                selectedCatItemsList,
                                                                                productNamesMap,
                                                                                countryLIST,
                                                                                customerLIST,
                                                                                accountCountryMAP,
                                                                                accHolding.Id,
                                                                                countryMultipleSLinesMAP,
                                                                                countryRenewalMAP,
                                                                                countrySitesMAP);
        }
        
        List<String> errorList = new List<String>();

        List<String> countriesLIST = new List<String>();
        countriesLIST.add('Angola');

        test.startTest();
        System.runAs(testUser){ 
        response = BI_LEX_CreateMultipleSubOppControl.saveAllSubOpportunities(response.insertsuboppLIST,
                                                                            errorList, 
                                                                            testOptyCentralized,
                                                                            multisite,
                                                                            selectedCatItemsList, 
                                                                            catalogIDLIST,
                                                                            countriesLIST);
        }
        test.stopTest();
        
        System.assert(response.errorList.isEmpty());
    }

    @isTest
    static void testSaveAllSubOpportunitiesNoServiceLines(){ 

        system.debug('ENTERING testSaveAllSubOpportunitiesNoServiceLines');       

        setupData();
        System.runAs(testUser){
            createCatalogAndProducts();
        }

        BI_LEX_CreateMultipleSubOppControl.wrapperHelper response = new BI_LEX_CreateMultipleSubOppControl.wrapperHelper();  
        
        List<String> countryLIST = new List<String>(); 
        countryLIST.add('Angola');
        Map<String,Boolean> countryMultipleSLinesMAP = new Map<String,Boolean>();
        countryMultipleSLinesMAP.put('Angola', true);
        Map<String,Boolean> countryRenewalMAP = new Map<String,Boolean>();
        countryRenewalMAP.put('Angola', false);

		List<String> customerLIST = new List<String>();
        Map<String,Account> accountCountryMAP = new Map<String,Account>();		
        Boolean multisite = true;		
        Map<String,String> countrySitesMAP = new Map<String,String>();

        testOptyCentralized.BI_O4_Service_Lines__c = null;
        List<String> auxList = new List<String>();
        auxList.add('2');
        auxList.add(selectedCatItemsList[0]);
       
        System.runAs(testUser){            
            response = BI_LEX_CreateMultipleSubOppControl.saveSubopportunities(testOptyCentralized,
                                                                                selectedCatItemsList,
                                                                                productNamesMap,
                                                                                countryLIST,
                                                                                customerLIST,
                                                                                accountCountryMAP,
                                                                                accHolding.Id,
                                                                                countryMultipleSLinesMAP,
                                                                                countryRenewalMAP,
                                                                                countrySitesMAP);
        }
        
        List<String> errorList = new List<String>();

        List<String> countriesLIST = new List<String>();
        countriesLIST.add('Angola');

        test.startTest();
        System.runAs(testUser){ 
        response = BI_LEX_CreateMultipleSubOppControl.saveAllSubOpportunities(response.insertsuboppLIST,
                                                                            errorList, 
                                                                            testOptyCentralized,
                                                                            multisite,
                                                                            auxList, 
                                                                            catalogIDLIST,
                                                                            countriesLIST);
        }
        test.stopTest();
        
        System.assert(response.errorList.isEmpty());
    }

    @isTest
    static void testSaveAllSubOpportunitiesException(){ 

        system.debug('ENTERING testSaveAllSubOpportunitiesException');       

        setupData();
        System.runAs(testUser){
            createCatalogAndProducts();
        }

        BI_LEX_CreateMultipleSubOppControl.wrapperHelper response = new BI_LEX_CreateMultipleSubOppControl.wrapperHelper();  
        
        List<String> errorList = new List<String>();
        Boolean multisite = false;
        List<String> countriesLIST = new List<String>();
        countriesLIST.add('Angola');
        List<String> serviceLineSaveSubOppLIST = new List<String>();
        List<Opportunity> lstOpty = new List<Opportunity>();
        lstOpty.add(testOptyCentralized);

        test.startTest();
        System.runAs(testUser){ 
        response = BI_LEX_CreateMultipleSubOppControl.saveAllSubOpportunities(lstOpty,
                                                                            errorList, 
                                                                            testOptyCentralized,
                                                                            multisite,
                                                                            selectedCatItemsList, 
                                                                            catalogIDLIST,
                                                                            countriesLIST); 
        }
        test.stopTest();
        
        System.assert(!response.errorList.isEmpty());
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------
    //Test to "checkUserProfileAndPermission" 
    @isTest
    static void tesCheckUserProfileAndPermission(){
        system.debug('ENTERING tesCheckUserProfileAndPermission');       

        setupData();

        Boolean result;

        test.startTest();
        System.runAs(testUser){
            result = BI_LEX_CreateMultipleSubOppControl.checkUserProfileAndPermission();
        }
        test.stopTest();

        System.assert(result);
    }
}