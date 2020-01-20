public with sharing class TGS_CaseMethods {
    /*-------------------------------------------------------------------------------------------------------------------------------------------------------
    Author:      Miguel Cabrera
    Company:     Aborda
    Description: Methods executed by BI_Case Triggers (TGS)
    Test Class:  TGS_CaseMethods_TEST

    History:

    <Date>       <Author>              <Change Description>
    23/02/2016   Miguel Cabrera        Initial version
    15/03/2016   Oscar Iuliano         add verifyNotClseCase
    ??/10/2016   Jose Miguel Fierro    Initialize constants before any other methods
    20/10/2016   Jose Miguel Fierro    Integrated Order2AssetAfterUpdate.trigger
    02/11/2016   Juan Carlos Terrón    Added assigner_TGS_ProductCategorization method.
    01/11/2016   Juan Carlos Terrón    Added several changes on case_Status_Rollback method, all are described on the header.
    01/12/2016   everis                Added notificacionMSIP method.
    13/12/2016   Alvaro López          Added validateProductTier method.
    08/03/2017   Jose Miguel Fierro    Added getOrderCompleted and setOrderRevised methods
    21/04/2017   Mariano García        Cambio condición selección de cuenta
    16/05/2017   Cristina Rodriguez    Created method fillBillingInfo. Refactor BI_Case.trigger
    15/01/2018   Álvaro López          Changed condition for disconnect cases in fillBillingInfo
    14/01/2020   Daniel Córdoba        Validation categories customer Infinity with Dummy and not equal generic product
    --------------------------------------------------------------------------------------------------------------------------------------------------------*/
    //INI - everis - 13/12/2016 – DSS218 – condición de parada
    public Static boolean firstRunNotification = true;
    //FIN - everis - 13/12/2016 – DSS218 – condición de parada
    static {
        String.isNotBlank(Constants.RECORD_TYPE_ORDER);

        TGS_RecordTypes_Util.loadRecordTypes(new Schema.SObjectType[] {Case.SObjectType, NE__Order__c.SObjectType, Account.SObjectType});
    }

    /*-------------------------------------------------------------------------------------------------------------------------------------------------------
     Author:      Miguel Cabrera
     Company:     Aborda
     Description: Method that sends an email when a case is updated

     History:

     <Date>       <Author>               <Change Description>
     23/02/2016   Miguel Cabrera         Initial version
    --------------------------------------------------------------------------------------------------------------------------------------------------------*/
    public static void caseEmailSend(List<Case> news)
    {
        try{

            List<Id> cases = new List<Id>();
            for(Case item: news){
                cases.add(item.Id);
            }

            List<Case> casesToSend = [SELECT Id, RecordType.Name, TGS_Has_Contact__c, TGS_On_Behalf__c, Contact.TGS_Enviar_Email_Order_Management_Case__c, Contact.Email, Contact.Id FROM Case WHERE Id in :cases AND Status = 'Assigned' AND RecordType.Name = 'Order Management Case' AND TGS_Has_Contact__c = true AND Contact.TGS_Enviar_Email_Order_Management_Case__c = true];

            List<EmailTemplate> templates = [Select Id, Name, HTMLValue, Subject from EmailTemplate where DeveloperName IN ('TGS_1_1_Case_Creation', 'TGS_1_2_Case_Creation_On_Behalf') Order By DeveloperName];


            if(!templates.isEmpty() && !casesToSend.isEmpty())
            {
                List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
                for(Case item: casesToSend)
                {
                    if(item.Contact.Email != null)
                    {
                        String[] toaddress = new String[]{};
                        toaddress.add(item.Contact.Email);
                        Messaging.SingleEmailMessage singleMail = new Messaging.SingleEmailMessage();

                        if(!item.TGS_On_Behalf__c) //NO On behalf
                        {
                            singleMail.setTemplateId(templates[0].Id);
                        } else { //On Behalf

                            singleMail.setTemplateId(templates[1].Id);
                        }

                        singleMail.saveAsActivity = false;
                        singleMail.setToAddresses(toaddress);
                        singleMail.setTargetObjectId(item.Contact.Id);
                        singleMail.setWhatId(item.Id);
                        emails.add(singleMail);
                    }
                }
                Messaging.sendEmail(emails);
            }

        }catch(Exception e){
        }
    }

    /*-------------------------------------------------------------------------------------------------------------------------------------------------------
     Author:      Oscar Iuliano
     Company:     New Energy Aborda
     Description: Used to not close the case, if the father is Active

     History:

     <Date>       <Author>              <Change Description>
     21/03/2016   Oscar Iuliano         Initial version
    --------------------------------------------------------------------------------------------------------------------------------------------------------*/
    public static void verifyNotClseCase(List<Case> news)
    { //Used to not close the case, if the father is Active
        try
        {
                //String IdAsset     = '';
                Boolean isError = false;
                String idError = '';
                List<Case> nameCase = new List<Case>();
                List<String> idConfItemError = new List<String>();

                for (Case a : news)
                {
                    if (a.Status== 'Closed' && a.Type=='Disconnect')
                    {
                     // IdAsset = a.Order__c;
                        nameCase.add(a);
                    }

                }

                if (nameCase!=null && nameCase.size()>0)
                {
                        List<Id> assetId    = new List<Id>();

                        for(Case tmpCase: nameCase)
                        {
                            assetId.add(tmpCase.Order__c);
                        }

                        // trovo il configuration Item sotto questo asset e prendo il valore nel campo calcolato
                        List<NE__OrderItem__c> orderItems = [SELECT Id, Name, TGS_OriginalConfId__c,IsRoot__c FROM NE__OrderItem__c WHERE NE__OrderId__c IN:assetId AND IsRoot__c=true AND TGS_OriginalConfId__c!=null];

                        if(orderItems.size()>0)
                        {

                            List<String> StringOriginalConfId = new List<String>();

                            for(NE__OrderItem__c tmpOrderItem :orderItems)
                            {
                                StringOriginalConfId.add(tmpOrderItem.TGS_OriginalConfId__c);
                            }

                            List<NE__Order_Item_Attribute__c> listItemAttribute = [SELECT Id, Name, NE__Value__c,NE__Order_Item__r.Name, NE__Order_Item__r.NE__OrderId__r.Case__c, NE__Order_Item__c,NE__Order_Item__r.id, NE__Order_Item__r.NE__Status__c,NE__Order_Item__r.NE__OrderId__r.RecordType.Name FROM NE__Order_Item_Attribute__c where NE__Value__c IN:StringOriginalConfId and NE__Order_Item__r.NE__OrderId__r.RecordType.Name =:'Asset'];

                            if(listItemAttribute.size()>0)
                            {
                                for(NE__Order_Item_Attribute__c itemAttribute: listItemAttribute)
                                {
                                    if(itemAttribute.NE__Order_Item__r.NE__Status__c=='Active')
                                    {
                                     // isError =   true;
                                        idError =   itemAttribute.NE__Order_Item__r.Name;

                                        idConfItemError.add(itemAttribute.NE__Value__c);
                                    }
                                }

                            }

                        }

                    }

                    if(idConfItemError.size()>0)
                    {

                        List<NE__OrderItem__c> orderItemTemp = [SELECT Id, Name, TGS_OriginalConfId__c,IsRoot__c,NE__OrderId__r.Case__c FROM NE__OrderItem__c where IsRoot__c=true AND TGS_OriginalConfId__c IN:idConfItemError];

                        List<Id> casesID = new List<Id>();
                        if(orderItemTemp.size()>0)
                        {
                            for(NE__OrderItem__c oitmps: orderItemTemp)
                            {
                             casesID.add(oitmps.NE__OrderId__r.Case__c);
                            }
                        }



                        for(Case originaCase: nameCase)
                        {
                            for(Id tmpcaseerror: casesID)
                            {
                                if(originaCase.id==tmpcaseerror)
                                {
                                     originaCase.addError('Is not permitted to close this case, because the item being disconnected is related to an active asset. Please disconnect the related asset, before closing this Case');
                                }
                            }


                         }
                     }
        } catch(Exception e) {
        }
    }


    /*-------------------------------------------------------------------------------------
     Author:      Jose Miguel Fierro
     Company:     New Energy Aborda
     Description: Helper method to fill in Case Order's fields on Case close. No queries.

     History
     <Date>       <Author>             <Description>
     12/04/2016   Jose Miguel Fierro   Initial Version
     20/05/2016   Fernando Arteaga     TGS_Site__c is not used anymore
    -------------------------------------------------------------------------------------*/
    public static Case fillOrderFieldsCaseClose(Case cas, NE__Order__c order, NE__Order__c asset) {
        //cas.Subject.addError('ONENOTE');
        if(cas != null && order != null) {
            Id idAccLE = order.NE__AccountId__c;
            Id idAccBU = order.NE__ServAccId__c;
            Id idAccCC = order.NE__BillAccId__c;
            Id idSite = order.Site__c; // FAR 20/05/2016
            //Id idSite = order.TGS_Site__c;

            // Asegurar que tienen el mismo valor
            //order.TGS_Site__c = idSite; // FAR 20/05/2016
            //order.Site__c = idSite; // FAR 20/05/2016

            if(order.NE__Order_Items__r != null) {
                for(NE__OrderItem__c ci : order.NE__Order_Items__r) {
                    ci.NE__Account__c = idAccLE;
                    ci.NE__Service_Account__c = idAccBU;
                    ci.NE__Billing_Account__c = idAccCC;
                    ci.TGS_Installation_point__c = idSite;
                    ci.Installation_point__c = idSite;
                }
            }

            if(asset != null) {
                asset.NE__AccountId__c = idAccLE;
                asset.NE__ServAccId__c = idAccBU;
                asset.NE__BillAccId__c = idAccCC;
                //asset.TGS_Site__c = idSite; // FAR 20/05/2016
                asset.Site__c = idSite;

                if(asset.NE__Order_Items__r != null) {
                    for(NE__OrderItem__c ci : asset.NE__Order_Items__r) {
                        ci.NE__Account__c                    = idAccLE;
                        ci.NE__Asset_Item_Account__c         = idAccLE;

                        ci.NE__Service_Account__c            = idAccBU;
                        ci.NE__Service_Account_Asset_Item__c = idAccBU;

                        ci.NE__Billing_Account__c            = idAccCC;
                        ci.NE__Billing_Account_Asset_Item__c = idAccCC;

                        ci.TGS_Installation_point__c = idSite;
                        ci.Installation_point__c     = idSite;
                        //cas.Priority.addError('MSACCESS');
                    }
                    //cas.Origin.addError('WINWORD');
                }// else {
                    //cas.OwnerId.addError('EXCEL');
                //}
            }// else {
                //cas.ContactId.addError('POWERPNT');
            //}

            // El caso de entrada es del AfterUpdate, y no se puede modificar
            return new Case(Id = cas.Id, AccountId = idAccLE);
        }
        return null;
    }

    /*-------------------------------------------------------------------------------------
     Author:      Jose Miguel Fierro
     Company:     New Energy Aborda
     Description: Method that fils in a case's order, asset, and CIs if its status is resolved and certain fields have changed
                  It is called from TGS_CallOrder2AssetHandler

     History
     <Date>       <Author>             <Description>
     18/04/2016   Jose Miguel Fierro   Initial Version
    -------------------------------------------------------------------------------------*/
    public static void fillRelatedObjectFields_resolved(Case newCas, Case oldCase, NE__Order__c ord, NE__Order__c ass, List<NE__Order__c> ord2Upd, List<NE__OrderItem__c> oi2Upd) {
        // Do not overwrite references to ord2Upd and oi2Upd
        try {
            if(BI_TestUtils.isRunningTest()) throw new BI_Exception('test');

            if(newCas.AccountId != oldCase.AccountId) { // If the account changed, overwrite Order and asset's values
                if(newCas.Order__c != null) {
                    ord = (NE__Order__c)TGS_CaseMethods.getExistingValue(ord2Upd, ord);
                    ord.NE__AccountId__c = newCas.AccountId;
                    if(ord.NE__Order_Items__r != null) {
                        for(NE__OrderItem__c oi : ord.NE__Order_Items__r) {
                            NE__OrderItem__c ci = (NE__OrderItem__c)TGS_CaseMethods.getExistingValue(oi2Upd, oi);
                            ci.NE__Account__c = newCas.AccountId;
                        }
                    }
                }
                if(newCas.Asset__c != null) {
                    ass = (NE__Order__c)TGS_CaseMethods.getExistingValue(ord2Upd, ass);
                    ass.NE__AccountId__c = newCas.AccountId;
                    if(ass.NE__Order_Items__r != null) {
                        for(NE__OrderItem__c oi : ass.NE__Order_Items__r) {
                            NE__OrderItem__c ci = (NE__OrderItem__c)TGS_CaseMethods.getExistingValue(oi2Upd, oi);
                            ci.NE__Account__c = newCas.AccountId;
                        }
                    }
                }
            }

        } catch (Exception exc) {
            BI_LogHelper.generate_BILog('TGS_CaseMethods.fillRelatedObjectFields_resolved', 'TGS', exc, 'Apex Class');
            //throw exc;
        }
    }

    /*-------------------------------------------------------------------------------------
     Author:      Jose Miguel Fierro
     Company:     New Energy Aborda
     Description: Returns a sobject from a list.

     History
     <Date>       <Author>             <Description>
     18/04/2016   Jose Miguel Fierro   Initial Version
    -------------------------------------------------------------------------------------*/
    public static SObject getExistingValue(List<SObject> objs, SObject obj) {
        try {
            Map<Id, SObject> mapSObjs = new Map<Id, SObject> (objs); // Very much overkill if done in a loop
            if(mapSObjs.containsKey(obj.Id)) {
                return mapSObjs.get(obj.Id);
            } else {
                objs.add(obj);
                return obj;
            }
        } catch (Exception exc) {
            BI_LogHelper.generate_BILog('TGS_CaseMethods.getExistingValue', 'TGS', exc, 'Apex Class');
            return null;
            //throw exc;
        }
    }

    /*-------------------------------------------------------------------------------------
     Author:      Jose Miguel Fierro
     Company:     New Energy Aborda
     Description: Validate that the cases' order's have sites

     History
     <Date>       <Author>             <Description>
     19/10/2016   Jose Miguel Fierro   Initial Version
    -------------------------------------------------------------------------------------*/
    public static void validateMandatorySiteMWAN(Map<Id, Case> newMap) {

        final Set<String> setMWanNames = new Set<String>(new String[] {Constants.PRODUCT_MWAN_INTERNET, Constants.PRODUCT_MWAN_SU});
        final Id rtBU = TGS_RecordTypes_Util.getRecordTypeId(Account.SObjectType, Constants.RECORD_TYPE_TGS_BUSINESS_UNIT);
        final Id rtCC = TGS_RecordTypes_Util.getRecordTypeId(Account.SObjectType, Constants.RECORD_TYPE_TGS_COST_CENTER);

        Set<Id> setMWanCaseIds = new Set<Id>();
        for(Case cas : newMap.values()) {
            if(cas.Type != Constants.TYPE_DISCONNECT && setMWanNames.contains(cas.TGS_Service__c) && cas.Status == Constants.CASE_STATUS_CLOSED) {
                setMWanCaseIds.add(cas.Id);
            }
        }

        if(!setMWanCaseIds.isEmpty()) {
            for(Case cas: [SELECT Id, CaseNumber,
                    Order__r.Site__c,
                    Order__r.NE__AccountId__c,
                    Order__r.NE__BillAccId__r.TGS_Aux_Holding__c,
                    Order__r.NE__BillAccId__r.RecordTypeId,
                    Order__r.NE__BillAccId__r.TGS_Aux_Business_Unit__c,
                    Order__r.NE__ServAccId__c,
                    Order__r.NE__ServAccId__r.TGS_Aux_Holding__c,
                    Order__r.NE__ServAccId__r.RecordTypeId
                FROM Case WHERE Id IN :setMWanCaseIds
            ]){
                NE__Order__c ord = cas.Order__r;
                /* FAR 17/03/2016 - GAP 103
                    if(ord.NE__BillAccId__r.TGS_Aux_Holding__c != ord.NE__AccountId__c || ord.NE__BillAccId__r.RecordTypeId != rtCC || ord.NE__BillAccId__r.TGS_Aux_Business_Unit__c != ord.NE__ServAccId__c ){
                     newMap.get(cas.Id).caseNumber.addError('Cost Center is not correct for this order status change');
                    }
                    if(ord.NE__ServAccId__r.TGS_Aux_Holding__c != ord.NE__AccountId__c || ord.NE__ServAccId__r.RecordTypeId != rtBU){
                     newMap.get(cas.Id).caseNumber.addError('Business Unit is not correct for this order status change');
                    }
                */
                if(String.isBlank(ord.Site__c)) {
                    newMap.get(cas.Id).caseNumber.addError('Site is mandatory field for this order status change');
                }
            }
        }
    }

    /*-------------------------------------------------------------------------------------
     Author:      Jose Miguel Fierro
     Company:     New Energy Aborda
     Description: Set Commertial Asset RFB and RFS date

    History
    <Date>        <Author>              <Description>
    20/10/2016    Jose Miguel Fierro    Moved from Order2AssetAfterUpdate.trigger
    -------------------------------------------------------------------------------------*/
    public static void fillCommAssetInfo(List<Case> news) {
        Id rtOrdManag = TGS_RecordTypes_Util.getRecordTypeId(Case.SObjectType,'Order_Management_Case');

        Set<Id> set_casAssetId = new Set<Id>();
        List<Case> lst_cases2proc = new List<Case>();
        for(Case cas : news) {
            if(cas.Asset__c != null && cas.RecordTypeId == rtOrdManag) {
                set_casAssetId.add(cas.Asset__c);
                lst_cases2proc.add(cas);
            }
        }

        if(!set_casAssetId.isEmpty()) {
            Map<Id, NE__Order__c> map_casAsset = new Map<Id, NE__Order__c>([
                SELECT Id, NE__Asset__r.Id, NE__Asset__r.TGS_RFB_date__c, NE__Asset__r.TGS_RFS_date__c
                FROM NE__Order__c
                WHERE Id IN: set_casAssetId
            ]);

            List<Id> set_comAssId = new List<Id>();
            for(NE__Order__c ass : map_casAsset.values()) {
                set_comAssId.add(ass.NE__Asset__c);
            }

            Map<Id, NE__Asset__c> map_commAsset = new Map<Id, NE__Asset__c>();
            for(Case cas : lst_cases2proc) {

                NE__Asset__c commAsset  = map_casAsset.get(cas.Asset__c).NE__Asset__r;
                commAsset.TGS_RFB_date__c = cas.TGS_RFB_date__c;
                commAsset.TGS_RFS_date__c = cas.TGS_RFS_date__c;
                map_commAsset.put(commAsset.Id, commAsset);

            }

            if(!map_commAsset.isEmpty()) {
                update new List<NE__Asset__c>(map_commAsset.values());
            }
        }
    }

    /*-------------------------------------------------------------------------------------------------------------------------------------------------------
        Author:      Juan Carlos Terrón
        Company:     Accenture
        Description: Method to process a rollback on Case statuses deleting and updating the related records depending on Case.Type.

        IN:          Map<Id,Case> x2 (trigger maps)
        OUT:         Void

        History:
        <Date>       <Author>              <Change Description>
        01/12/2016   JC Terrón             Removed comercial asset delete.
                                           Added Header.
                                           Removed debug messages.
    --------------------------------------------------------------------------------------------------------------------------------------------------------*/
    public static void case_StatusRollback(Map<Id,Case> newMap,Map<Id,Case> oldMap){
        Set<Id> set_Asset_ToDelete   = new Set<Id>();
        Set<Id> set_Order_ToUpdate   = new Set<Id>();
        Set<Id> set_CommAsset_ToDelete = new Set<Id>();
        List<NE__Order__c> list_Order_ToUpdate = new List<NE__Order__c>();
        List<NE__Order__c> list_Asset_ToDelete = new List<NE__Order__c>();
        List<NE__Asset__c> list_CommAsset_ToDelete = new List<NE__Asset__c>();
        List<NE__OrderItem__c> list_OrderItems_ToDelete = new List<NE__OrderItem__c>();
        Set<String> set_PrimaryStatus = new Set<String>{'Assigned','Pending','In Progress'};

        Map<Id,Case> map_Cases;

        map_Cases = new Map<Id,Case>([
                                        SELECT Id, Status, Type, Asset__c, Asset__r.NE__Asset__c
                                        FROM    Case
                                        WHERE Id IN :newMap.values()
                                    ]);

        if(map_Cases!=null && !map_Cases.isEmpty())
        {
            for(Case CAS : newMap.values())
            {
                if(CAS.Type == Constants.TYPE_NEW)
                {
                    if(set_PrimaryStatus.contains(CAS.Status) && oldMap.get(CAS.Id).Status == Constants.CASE_STATUS_RESOLVED)
                    {
                        if(!set_Asset_ToDelete.contains(CAS.Asset__c))
                        {
                            set_Asset_ToDelete.add(map_Cases.get(CAS.Id).Asset__c);
                            set_CommAsset_ToDelete.add(map_Cases.get(CAS.Id).Asset__r.NE__Asset__c);
                            CAS.Asset__c = null;
                            CAS.TGS_RFS_date__c = null;
                            CAS.TGS_RFB_date__c = null;
                            set_Order_ToUpdate.add(CAS.Order__c);
                        }
                    }
                }
                else
                {
                    if(set_PrimaryStatus.contains(CAS.Status) && oldMap.get(CAS.Id).Status ==Constants.CASE_STATUS_RESOLVED)
                    {
                        CAS.TGS_RFS_date__c = null;
                        CAS.TGS_RFB_date__c = null;
                        CAS.TGS_Ciudad__c = 'null';
                        set_Order_ToUpdate.add(CAS.Order__c);
                    }
                }
            }
        }
        if(!set_Order_ToUpdate.isEmpty())
        {
            for(NE__Order__c ORDER :    [
                                            SELECT Id, NE__OrderStatus__c, RecordType.DeveloperName, (SELECT Id, TGS_MarkAsDeleted__c
                                                                                                     FROM NE__Order_Items__r
                                                                                                     WHERE NE__OrderId__c IN :set_Asset_ToDelete)
                                            FROM    NE__Order__c
                                            WHERE Id IN :set_Order_ToUpdate OR
                                                    Id IN :set_Asset_ToDelete
                                        ]
                )
            {
                if(ORDER.RecordType.DeveloperName == 'Order')
                {
                    ORDER.NE__OrderStatus__c = Constants.CASE_STATUS_PENDING;
                    list_Order_ToUpdate.add(ORDER);
                }
                else
                {
                    ORDER.NE__OrderStatus__c = Constants.CASE_STATUS_PENDING;
                    list_Asset_ToDelete.add(ORDER);
                    list_OrderItems_ToDelete.addAll(ORDER.NE__Order_Items__r);
                }
            }
            if(!list_OrderItems_ToDelete.isEmpty())
            {
                for(NE__OrderItem__c OI : list_OrderItems_ToDelete)
                {
                    OI.TGS_Service_status__c = Constants.CI_TGS_SERVICE_STATUS_DELETED;
                    if(!OI.TGS_MarkAsDeleted__c)
                    {
                        OI.TGS_MarkAsDeleted__c = true;
                    }
                }
            }
        }
            NETriggerHelper.setTriggerFired('Case_Return_to_InProgress'); // JMF 27/10/2016 - Evitar borrar el caso si se está progresando hacia atrás
            update list_OrderItems_ToDelete;
            delete list_Asset_ToDelete;
            update list_Order_ToUpdate;
    }
    /*-------------------------------------------------------------------------------------------------------------------------------------------------------
        Author:      Juan Carlos Terrón
        Company:     New Energy Aborda
        Description: Product Categorization Assignment

        IN:          Trigger oldMap and new Case List
        OUT:         Void

        History:
        <Date>       <Author>            <Change Description>
        02/11/2016   JC Terrón           Initial version
        06/10/2017   Guillermo Muñoz     Set throw_exception variable to false before Exception throw
        --------------------------------------------------------------------------------------------------------------------------------------------------------*/
    public static void assigner_TGS_ProductCategorization(Map<Id,Case> oldCases,List<Case> newCases){
        BI_TestUtils.throw_exception = true;
        try
        {
            Id rt_OrderManagement = TGS_RecordTypes_Util.getRecordTypeId(Case.SObjectType,'Order_Management_Case');
            List<Case> list_Cases_toUpdate = new List<Case>();
            if(oldCases!=null)
            {
                for(Case caso : newCases)
                {
                    if(caso.RecordTypeId == rt_OrderManagement)
                    {
                        if(oldCases.containsKey(caso.Id))
                        {
                            if(String.isNotBlank(caso.TGS_Service__c) && oldCases.get(caso.Id).TGS_Service__c != caso.TGS_Service__c)
                            {
                                list_Cases_toUpdate.add(caso);
                            }
                        }
                    }
                }
            }
            else
            {
                for(Case caso : newCases)
                {
                    if(caso.RecordTypeId == rt_OrderManagement)
                    {
                        if(String.isNotBlank(caso.TGS_Service__c))
                        {
                            list_Cases_toUpdate.add(caso);
                        }
                    }
                }
            }

            if(!list_Cases_toUpdate.isEmpty())
            {
                TGS_GME_GM_Product_Categorization__c aux_CS_Record = new TGS_GME_GM_Product_Categorization__c();
                List<TGS_GME_GM_Product_Categorization__c> list_CustomSetting = new List<TGS_GME_GM_Product_Categorization__c>();
                Map<String,TGS_GME_GM_Product_Categorization__c> map_CustomSetting = new Map<String,TGS_GME_GM_Product_Categorization__c>();

                list_CustomSetting = TGS_GME_GM_Product_Categorization__c.getAll().values();

                for(TGS_GME_GM_Product_Categorization__c cs_Record : list_CustomSetting)
                {
                    map_CustomSetting.put(cs_Record.TGS_Service__c, cs_Record);
                }
                system.debug('list: ' + list_Cases_toUpdate);
                system.debug('map: ' + map_CustomSetting);
                for(Case caso : list_Cases_toUpdate)
                {
                    system.debug('caso service: ' + caso.TGS_service__c);
                    aux_CS_Record = map_CustomSetting.get(caso.TGS_service__c);
                    system.debug('aux: ' + aux_CS_Record);
                    caso.TGS_Product_Tier_1__c = aux_CS_Record.TGS_Categorization_tier_1__c;
                    caso.TGS_Product_Tier_2__c = aux_CS_Record.TGS_Categorization_tier_2__c;
                    caso.TGS_Product_Tier_3__c = aux_CS_Record.TGS_Categorization_tier_3__c;
                }
            }
            if(BI_TestUtils.isRunningTest())
            {
                BI_TestUtils.throw_exception = false;
                throw new BI_Exception('test');
            }
        }
        catch(Exception exc)
        {
                BI_LogHelper.generate_BILog('TGS_CaseMethods.assigner_TGS_ProductCategorization', 'TGS', exc, 'Apex Trigger');
        }
    }

    /*------------------------------------------------------------
        Author:      Alvaro López
        Company:     New Energy Aborda
        Description: Class to assign Queues to Cases based on a criteria(TGS_Asignaciones__c).
        Test Class:
        History
        <Date>       <Author>            <Change Description>
        04/07/2016   Alvaro López        Initial Version
        11/07/2016   Juan Carlos Terrón  Added Account filter
        26/11/2016   Juan Carlos Terrón  New Version : 2.0
                                         Remake of assig method, made a completely new version, simplified the method and added more null pointer avoiding checkers.
        30/11/2016   Juan Carlos Terrón  Changed assignation on INSERT event to use an Aux case variable to avoid read-only exception.
    ------------------------------------------------------------*/
    public static void assignerHandlerTGS(List<Case> newCases, Map<Id,Case> oldCases){
        /*Auxiliar variables*/
        String concat = '';

        /*Sets*/
        Set<Id> set_Accounts = new Set<Id>();
        Set<String> set_Queues = new Set<String>();

        /*Lists*/
        List<Case> list_Case_toUpdate = new List<Case>();
        List<Case> list_Case_toProcess = new List<Case>();

        /*Maps*/
        Map<Id,String> map_RT_byId = new Map<Id,String>();
        Map<Id,Account> map_Accounts = new Map<Id,Account>();
        Map<String,Group> map_Queues = new Map<String,Group>();
        Map<String,String> map_Asignaciones = new Map<String,String>();
        Map<String,String> map_Concatenations = new Map<String,String>();

        /*Static Block Simulation*/
        /*START*/
        Map<String,Id> map_RT_byName=TGS_RecordTypes_Util.getRecordTypeIdsByDeveloperName(Case.SObjectType);
        for(String name : map_RT_byName.keySet())
        {
            map_RT_byId.put(map_RT_byName.get(name),name);
        }
        /*END*/
        if(oldCases!=null)
        {
            /*UPDATE CALL*/
            for(Case caso : newCases)
            {
                if( map_RT_byId.get(caso.RecordTypeId) == Constants.CASE_RTYPE_DEVNAME_ORDER_MNGMNT &&
                    (caso.AccountId           != oldCases.get(caso.Id).AccountId             ||
                    caso.TGS_Service__c       != oldCases.get(caso.Id).TGS_Service__c        ||
                    caso.Status               != oldCases.get(caso.Id).Status                ||
                    caso.TGS_Status_Reason__c != oldCases.get(caso.Id).TGS_Status_Reason__c  ||
                    caso.TGS_On_Behalf__c     != oldCases.get(caso.Id).TGS_On_Behalf__c)
                    )
                {
                    /*Case checking to get the ones to process*/
                    list_Case_toProcess.add(caso);
                    if(caso.AccountId!=null)set_Accounts.add(caso.AccountId);
                }
            }
            if(!list_Case_toProcess.isEmpty() && !set_Accounts.isEmpty())
            {
                for (Account ACC :
                        [
                            SELECT Id, TGS_Aux_Holding__c,RecordTypeId,RecordType.DeveloperName
                            FROM    Account
                            WHERE Id IN :set_Accounts
                        ]
                    )
                {
                    /*Account map fullfillment in order to filter case processing by related Account RecordType.*/
                    map_Accounts.put(ACC.Id, ACC);
                }
                for(Case caso : newCases)
                {
                    if(caso.AccountId!=null && map_RT_byId.get(caso.RecordTypeId) == Constants.CASE_RTYPE_DEVNAME_ORDER_MNGMNT)
                    {
                     /*concatenation of Case fields, it depends on Account Record Type and Status reason value primally.*/
                     if(map_Accounts.get(caso.AccountId).RecordType.DeveloperName == Constants.RECORD_TYPE_TGS_HOLDING)
                     {
                         concat += caso.AccountId + '-';
                     }
                     else if(map_Accounts.get(caso.AccountId).TGS_Aux_Holding__c!=null)
                     {
                         concat += map_Accounts.get(caso.AccountId).TGS_Aux_Holding__c + '-';
                     }
                     if(caso.TGS_Service__c != null){
                        concat += caso.TGS_Service__c.deleteWhitespace().toLowerCase() + '-';
                     }
                     concat += caso.Status.deleteWhitespace().toLowerCase() + '-';
                     if(caso.TGS_Status_reason__c!=null) concat += caso.TGS_Status_reason__c.deleteWhitespace().toLowerCase();
                     concat += '-' + map_RT_byId.get(caso.RecordTypeId).toLowerCase()+'-';
                     concat += !caso.TGS_On_Behalf__c;
                     map_Concatenations.put(caso.Id, concat);
                     concat = '';
                    }
                }
            }
            if(!map_Concatenations.isEmpty())
            {
                for (TGS_Asignaciones__c ASSIGN :
                        [
                            SELECT Id, TGS_AssignId__c, TGS_Cola__c
                            FROM    TGS_Asignaciones__c
                            WHERE TGS_AssignId__c IN :map_Concatenations.values()
                        ]
                    )
                {
                    /*Getting TGS_Asignaciones map in order to get the Queues availables to be associated to the cases.*/
                    map_Asignaciones.put(ASSIGN.TGS_AssignId__c, ASSIGN.TGS_Cola__c);
                    set_Queues.add(ASSIGN.TGS_Cola__c);
                }
            }
            if(!map_Asignaciones.isEmpty() && !set_Queues.isEmpty())
            {
                for(Group QUEUE :
                    [
                        SELECT Id,DeveloperName
                        FROM    Group
                        WHERE Type = 'Queue' AND DeveloperName IN :set_Queues //Álvaro López - Added Type = 'Queue' INC000000138924
                    ]
                    )
                {
                    /*Fullfillment of Queues map with DeveloperName as key in order to match it with de concatenation of
                    Case fields throught the TGS_Asignaciones map.
                    */
                    map_Queues.put(QUEUE.DeveloperName,QUEUE);
                }
            }
            if(!map_Queues.isEmpty())
            {
                for(Case caso : newCases)
                {
                    /*OwnerId Assignment:
                    -We got the Case fields concatenation of the map by Case.Id
                    -We got the Queue DeveloperName with the TGS_Cola field from
                        TGS_Asignaciones map by the concatenation given before this step.
                    -Finally with the DeveloperName we got the Queue Id and we assign it to Case.OwnerId.
                    */
                    caso.OwnerId = map_Queues.get(map_Asignaciones.get(map_Concatenations.get(caso.Id))).Id;
                }
            }
        }
        else
        {
            /*
                OwnerId assignment for INSERT event it's the same for UPDATE Call but:
                -The field update is made by updating the records after the INSERT call.
                -The Assignment is made without any field validations for any INSERT call.
            */
            for(Case caso : newCases)
            {
                if(caso.AccountId!=null && map_RT_byId.get(caso.RecordTypeId) == Constants.CASE_RTYPE_DEVNAME_ORDER_MNGMNT) set_Accounts.add(caso.AccountId);
            }
            if(!set_Accounts.isEmpty())
            {
                map_Accounts = new Map<Id,Account>(
                    [
                        SELECT Id,TGS_Aux_Holding__c,RecordTypeId,RecordType.DeveloperName
                        FROM    Account
                        WHERE Id IN :set_Accounts
                    ]
                );
            }
            if(!map_Accounts.isEmpty())
            {
                for(Case caso : newCases)
                {
                 //MGC 21/04/2017 Cambio condición del IF
                 if(caso.AccountId!=null
                     && map_Accounts.containsKey(caso.AccountId)
                     && map_Accounts.get(caso.AccountId) != null
                     && map_RT_byId.get(caso.RecordTypeId) == Constants.CASE_RTYPE_DEVNAME_ORDER_MNGMNT)
                 {
                    if(map_Accounts.get(caso.AccountId).RecordType.DeveloperName == Constants.RECORD_TYPE_TGS_HOLDING)
                    {
                        concat += caso.AccountId + '-';
                    }
                    else if(map_Accounts.get(caso.AccountId).TGS_Aux_Holding__c!=null)
                    {
                        concat += map_Accounts.get(caso.AccountId).TGS_Aux_Holding__c + '-';
                    }
                    if(caso.TGS_Service__c != null){
                     concat += caso.TGS_Service__c.deleteWhitespace().toLowerCase() + '-';
                    }
                    concat += caso.Status.deleteWhitespace().toLowerCase() + '-';
                    if(caso.TGS_Status_reason__c!=null) concat += caso.TGS_Status_reason__c.deleteWhitespace().toLowerCase();
                    concat += '-' + map_RT_byId.get(caso.RecordTypeId).toLowerCase()+'-';
                    concat += !caso.TGS_On_Behalf__c;
                    map_Concatenations.put(caso.Id, concat);
                    concat = '';
                 }
                }
            }
            if(!map_Concatenations.isEmpty())
            {
                for (TGS_Asignaciones__c ASSIGN :
                        [
                            SELECT Id, TGS_AssignId__c, TGS_Cola__c
                            FROM    TGS_Asignaciones__c
                            WHERE TGS_AssignId__c IN :map_Concatenations.values()
                        ]
                    )
                {
                    map_Asignaciones.put(ASSIGN.TGS_AssignId__c, ASSIGN.TGS_Cola__c);
                    set_Queues.add(ASSIGN.TGS_Cola__c);
                }
            }
            if(!map_Asignaciones.isEmpty() && !set_Queues.isEmpty())
            {
                for(Group QUEUE :
                    [
                        SELECT Id,DeveloperName
                        FROM    Group
                        WHERE DeveloperName IN :set_Queues
                    ]
                    )
                {
                    map_Queues.put(QUEUE.DeveloperName,QUEUE);
                }
            }
            if(!map_Queues.isEmpty())
            {
                for(Case caso : newCases)
                {
                    Case case_toUpdate = new Case(Id = caso.Id);
                    System.debug('##_ map_Concatenations.get(caso.Id): ' + map_Concatenations.get(caso.Id));
                    System.debug('##_ map_Asignaciones.get(map_Concatenations.get(caso.Id)): ' + map_Asignaciones.get(map_Concatenations.get(caso.Id)));
                    System.debug('##_ map_Queues.get(map_Asignaciones.get(map_Concatenations.get(caso.Id))): ' + map_Queues.get(map_Asignaciones.get(map_Concatenations.get(caso.Id))));
                    case_toUpdate.OwnerId = map_Queues.get(map_Asignaciones.get(map_Concatenations.get(caso.Id))).Id;
                    list_Case_toUpdate.add(case_toUpdate);
                }
            }
            if(!list_Case_toUpdate.isEmpty())
            {
                update list_Case_toUpdate;
            }
        }
    }
    /*-------------------------------------------------------------------------------------------------------------------------------------------------------
        Author:      everis
        Company:     Everis
        Description: Notificación vía email ante un cambio en el estado de un Caso.

        History:
        <Date>       <Author>               <Change Description>
        17/11/2016   everis                 Initial version
        18/01/2017   everis                 Extracción de SOQL del for
        16/02/2017   everis                 Optimización del método.
    --------------------------------------------------------------------------------------------------------------------------------------------------------*/
    public static void notificacionMSIP(List<Case> oldCases, List<Case> newCases){
        try {

            if(BI_TestUtils.isRunningTest()) throw new BI_Exception('test');

            //Aux maps and list
            List<Case> auxCaseList = new List<Case>();
            List<ID> auxCaseIdList = new List<ID>();
            List<ID> auxAccountIdList = new List<ID>();

            map<ID,Case> mapaOld = new map<ID,case>(oldCases);
            for(Case newCase: newCases){
                Case oldCase = mapaOld.get(newCase.ID);
                //Case Status and Status Reason
                if(newCase.Status == Constants.CASE_STATUS_RESOLVED || newCase.TGS_Status_reason__c == Constants.CASE_STATUS_REASON_IN_PROVISION ||
                                                     newCase.TGS_Status_reason__c == Constants.CASE_STATUS_REASON_IN_CONFIGURATION ||
                                                     newCase.TGS_Status_reason__c == Constants.CASE_STATUS_REASON_IN_TEST)
                {
                    //Product type
                    if(newCase.TGS_Service__c != null && (newCase.TGS_Service__c.equals(Constants.PRODUCT_MSIP_CCA) || newCase.TGS_Service__c.equals(Constants.PRODUCT_MSIP_ADMIN) ||
                        newCase.TGS_Service__c.equals(Constants.PRODUCT_MSIP_HOSTED_UC) || newCase.TGS_Service__c.equals(Constants.PRODUCT_MSIP_NO_TRUNK) ||
                        newCase.TGS_Service__c.equals(Constants.PRODUCT_MSIP_TRUNK) || newCase.TGS_Service__c.equals(Constants.PRODUCT_MSIP_SPECIAL_NUMBER) ||
                        newCase.TGS_Service__c.equals(Constants.PRODUCT_MSIP_PNP) || newCase.TGS_Service__c.equals(Constants.PRODUCT_MSIP_DDI_RESALE) ||
                        newCase.TGS_Service__c.equals(Constants.PRODUCT_MSIP_DDI_STANDARD) || newCase.TGS_Service__c.equals(Constants.PRODUCT_MSIP_BUNDLE) ||
                        newCase.TGS_Service__c.equals(Constants.PRODUCT_MSIP_FLAT_RATE) || newCase.TGS_Service__c.equals(Constants.PRODUCT_MSIP_DESCUENTO_POR_VOLUMEN)))
                    {
                        //Se ha cambiado el status.
                        if (oldCase.TGS_Status_reason__c != newCase.TGS_Status_reason__c || ( oldCase.Status != newCase.status)){
                            auxCaseList.add(newCase);
                            auxCaseIdList.add(newCase.Id);
                            auxAccountIdList.add(newCase.AccountID);
                        }
                    }
                }
            }
            if (!auxCaseList.isEmpty()){
                //Template email
                String body = [Select HtmlValue From EmailTemplate where name=:Constants.EMAIL_NOTIFICATION_MSIP Limit 1].HtmlValue;

                //Map with order information
                Map <ID, NE__Order__c> orderMap = new Map <ID, NE__Order__c> ([Select NE__ServAccId__c, NE__ServAccId__r.name, NE__BillAccId__c, NE__BillAccId__r.name, name FROM NE__Order__c where case__c IN :auxCaseIdList]);

                //SOQL necesaria para recuperar lookups de 2º nivel, ya que desde newcase no se tiene acceso (Ej: newcase.Account.TGS_Aux_Holding__c == null).
                //Map with Account information
                Map<ID,Account> accountAUXMap = new Map<ID,Account>([Select TGS_Aux_Holding__r.id, TGS_Aux_Holding__r.name, RecordType.name, name FROM Account where ID IN :auxAccountIdList]);
                List<ID> auxHoldingIdList = new List<ID>();
                for(Account holdingAccount: accountAUXMap.values()){
                    if (holdingAccount.TGS_Aux_Holding__c != null && holdingAccount.TGS_Aux_Holding__r.id != null){
                        auxHoldingIdList.add(holdingAccount.TGS_Aux_Holding__r.id);
                    }
                    else if (holdingAccount.TGS_Aux_Holding__c != null){
                        auxHoldingIdList.add(holdingAccount.TGS_Aux_Holding__c);
                    } else if (holdingAccount.RecordType != null && holdingAccount.RecordType.name == Constants.RECORD_TYPE_HOLDING_ACCOUNT_LABEL){
                        auxHoldingIdList.add(holdingAccount.id);
                    }

                }

                //AccountTeamMembers del Holding sea cual sea el Account Type
                Map<ID,AccountTeamMember> atmsMap = new Map<ID,AccountTeamMember>( [SELECT UserId, TeamMemberRole, User.email FROM AccountTeamMember Where AccountID IN :auxHoldingIdList]);
                List<AccountTeamMember> atms = atmsMap.values();

                Map<ID,String> users = new Map<ID, String>();
                for(AccountTeamMember atm : atms){
                    users.put(atm.UserID, atm.User.email);
                }

                for(Case newCase: auxCaseList){
                    String emailTemplate = body;
                    Case oldCase = mapaOld.get(newCase.ID);
                    try{
                        firstRunNotification = false;
                        //Una vez obtenemos el equipo de la cuenta del Holding, revisamos States
                        List<String> receivers = new List<String>();
                        if ((oldCase.Status == newCase.status || (oldCase.Status != newCase.status && oldCase.Status == Constants.CASE_STATUS_RESOLVED))
                                                                && (newCase.TGS_Status_reason__c == Constants.CASE_STATUS_REASON_IN_PROVISION ||
                                                                newCase.TGS_Status_reason__c == Constants.CASE_STATUS_REASON_IN_CONFIGURATION ||
                                                                newCase.TGS_Status_reason__c == Constants.CASE_STATUS_REASON_IN_TEST)){
                            for (AccountTeamMember atm :atms){
                                if (atm.TeamMemberRole == Constants.ROLE_GPM){
                                    //Obtengo el Email del usuario de la cuenta.
                                    String userEmail = users.get(atm.UserId);
                                    receivers.add(userEmail);
                                }
                            }
                        }else if (newCase.status == Constants.CASE_STATUS_RESOLVED){
                            for (AccountTeamMember atm :atms){
                                if (atm.TeamMemberRole == Constants.ROLE_GPM || atm.TeamMemberRole == Constants.ROLE_PM_IT ||
                                                    atm.TeamMemberRole == Constants.ROLE_SERVICE_ARCHITECT ||
                                                    atm.TeamMemberRole == Constants.ROLE_IP_ITFS || atm.TeamMemberRole == Constants.ROLE_NEGOCIO){
                                    //Obtengo el Email del usuario de la cuenta.
                                    String userEmail = users.get(atm.UserId);
                                    receivers.add(userEmail);
                                }
                            }
                        }
                        //Hay receptores del mensaje
                        if (receivers.size()>0){
                            Messaging.SingleEmailMessage mailing = new Messaging.SingleEmailMessage();

                            //Strings del Email
                            NE__Order__c order = orderMap.get(newCase.Order__c);
                            String subject = 'Change status notification ' + order.name;

                            //Introducimos los destinatarios, y los que irán en copia (CC)
                            String[] sendTo = new String[]{};
                            String[] ccTo = new String[] {};
                            for (String email : receivers){
                                sendTo.add(email);
                            }

                            //Finalmente se configuran todos los valores necesarios en el objeto "mailing", que será el mail propiamente dicho
                            mailing.setToAddresses(sendTo);
                            mailing.setCcAddresses(ccTo);
                            mailing.setSubject(subject);
                            mailing.setUseSignature(false);
                            mailing.setBccSender(false);

                            Account accountAUX = accountAUXMap.get(newCase.AccountId);

                            Id idAccount;
                            String accountName;
                            if (accountAUX.TGS_Aux_Holding__c != null){
                                idAccount = accountAUX.TGS_Aux_Holding__r.id;
                                accountName = accountAUX.TGS_Aux_Holding__r.name;
                            }
                            //Si es null, es porque es una cuenta de tipo Holding.
                            if (accountName == null) accountName = accountAUX.name;

                            String Customer = '"' + accountName + '"';
                            String BU;
                            if (order.NE__ServAccId__c != null) BU = '"' + order.NE__ServAccId__r.name + '"';
                            String CC;
                            if (order.NE__BillAccId__c != null) CC = '"' + order.NE__BillAccId__r.name + '"';

                            //Notification to client XXXX with Business Unit YYY and Cost Center ZZZZ.
                            emailTemplate = emailTemplate.replace('OR-XXXXX', order.name);
                            emailTemplate = emailTemplate.replace('XXXX', Customer);
                            emailTemplate = emailTemplate.replace('YYY', BU);
                            emailTemplate = emailTemplate.replace('ZZZZ', CC);

                            //Modificamos el Body del mensaje.
                            if (newCase.status != oldCase.status){
                                emailTemplate = emailTemplate.replace(Constants.CASE_STATUS_IN_PROGRESS, newCase.status);
                                emailTemplate = emailTemplate.replace(Constants.CASE_STATUS_REASON_IN_PROVISION, oldCase.status);
                            }else if (newCase.TGS_Status_reason__c != null) {
                                emailTemplate = emailTemplate.replace(Constants.CASE_STATUS_REASON_IN_PROVISION, oldCase.TGS_Status_reason__c);
                                emailTemplate = emailTemplate.replace(Constants.CASE_STATUS_IN_PROGRESS, newCase.TGS_Status_reason__c);
                            }
                            mailing.setHtmlBody(emailTemplate);
                            //Orden de envío del email montado previamente
                            Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mailing});
                        }else System.debug('Everis: No existen destinatarios. No se ha realizado ningún Envío.');
                    } catch (Exception e) { System.debug('Everis: ERROR en la línea ' + e.getLineNumber() + ' ' + e);}
                }
            } else System.debug('Everis: Fin del método notificacionMSIP. No se han mandado notificaciones ya que el caso no cumple con los requisitos.');
        }catch(Exception e ){
        }
    }

    /*-------------------------------------------------------------------------------------------------------------------------------------------------------
        Author:      Juan Carlos Terrón
        Company:     Accenture
        Description: Assign casemilestone completiondate field on close Resolution.

        IN:          List<Case>(Trigger.new)
        OUT:         Void

        History:
        <Date>       <Author>                <Change Description>
    --------------------------------------------------------------------------------------------------------------------------------------------------------*/
    public static void setMilestoneEndDateTGS(List<Case> news) {
        try{
            Map<String, Id> map_RT = TGS_RecordTypes_Util.getRecordTypeIdsByDeveloperName(Case.SObjectType);
            Id id_OrderManagementCase = map_RT.get(Constants.CASE_RTYPE_DEVNAME_ORDER_MNGMNT);
            List<String> list_JSON = new List<String>();
            if(BI_TestUtils.isRunningTest()) throw new BI_Exception('test');

            Set<Id> set_caseIds2check = new Set<Id>();
            for(Case cas : news) {
                if((cas.RecordTypeId) == id_OrderManagementCase) {
                    if(cas.Status == 'Resolved' && cas.SlaExitDate == null) {
                            set_caseIds2check.add(cas.Id);
                        }
                }
            }
            if(!set_caseIds2check.isEmpty()) {
                List<CaseMilestone> lst_milestones = [SELECT Id, CompletionDate, MilestoneType.Name, Case.Status
                                                     FROM CaseMilestone WHERE CaseId IN :set_caseIds2check AND CompletionDate = null];
                if(!lst_milestones.isEmpty()) {
                    List<CaseMilestone> lst_milestones2update = new List<CaseMilestone>();
                    for(CaseMilestone cms : lst_milestones) {
                        if(cms.Case.Status == 'Resolved') {
                            if(cms.CompletionDate==null ) {
                                cms.CompletionDate = datetime.now();
                                lst_milestones2update.add(cms);
                            }
                        }
                    }
                    update lst_milestones2update;
                    for(Case caso : news)
                    {
                        if(set_caseIds2check.contains(caso.Id)) caso.TGS_SLA_Closure__c = true;
                    }
                }
            }
        } catch (Exception exc) {
            BI_LogHelper.generate_BILog('TGS_CaseMethods.setMilestoneEndDate', 'TGS', exc, 'Trigger');
        }
    }
    /*------------------------------------------------------------
        Author:      Alvaro López
        Company:     New Energy Aborda
        Description: Method to validate the selected values from the picklist TGS_Product_Tier_1__c depending on account name and case recordType.
        Test Class:
        History
        <Date>       <Author>            <Change Description>
        13/12/2016   Alvaro López        Initial Version
    ------------------------------------------------------------*/

    /*public static void validateProductTier(List<Case> news, Map<Id ,Case> map_olds){

        Set<Id> set_rtIds = new Set<Id>{
            TGS_RecordTypes_Util.getRecordTypeId(Case.SObjectType,'TGS_Incident'),
            TGS_RecordTypes_Util.getRecordTypeId(Case.SObjectType,'TGS_Change')
        };

        List<Case> lst_caseByRT = new List<Case>();

        for(Case cas: news){
            if(set_rtIds.contains(cas.RecordTypeId)){
                lst_caseByRT.add(cas);
            }
        }
        List<Case> toProcess = new List<Case>();

        if(map_olds != null){
            for(Case cas: lst_caseByRT){
                if(
                       cas.TGS_Holding_Name__c   != map_olds.get(cas.Id).TGS_Holding_Name__c
                    || cas.TGS_RTDevName__c      != map_olds.get(cas.Id).TGS_RTDevName__c
                    || cas.TGS_Product_Tier_1__c != map_olds.get(cas.Id).TGS_Product_Tier_1__c
                    || cas.TGS_Product_Tier_2__c != map_olds.get(cas.Id).TGS_Product_Tier_2__c
                    || cas.TGS_Product_Tier_3__c != map_olds.get(cas.Id).TGS_Product_Tier_3__c
                ){
                    toProcess.add(cas);
                }
            }
        }
        else{
            for(Case cas: lst_caseByRT){
                toProcess.add(cas);
            }
        }
        if(!toProcess.isEmpty()){

            List<TGS_Tier_Dependence__c> lst_depend = TGS_Tier_Dependence__c.getAll().values();
            Set<String> set_concat_tier = new Set<String>();

            if(!lst_depend.isEmpty()){
                for(TGS_Tier_Dependence__c tier :lst_depend){
                    set_concat_tier.add(tier.TGS_Holding_Name__c + ' - ' + tier.TGS_RTDevName__c + ' - ' + tier.TGS_Product_Tier_1__c + ' - ' + tier.TGS_Product_Tier_2__c + ' - ' + tier.TGS_Product_Tier_3__c);
                }
            }

            Map<Id, String> map_error = new Map<Id, String>();
            Boolean exists = false;
            String concat;

            for(Case cas: toProcess){
                exists = false;
                if(cas.TGS_Holding_Name__c != null && cas.TGS_RTDevName__c != null){
                    concat = cas.TGS_Holding_Name__c + ' - ' + cas.TGS_RTDevName__c + ' - ' + cas.TGS_Product_Tier_1__c + ' - ' + cas.TGS_Product_Tier_2__c + ' - ' + cas.TGS_Product_Tier_3__c;

                    if(set_concat_tier.contains(concat))
                        exists = true;
                }
                if(!exists){
                    map_error.put(cas.Id, 'Invalid Product Categorization for this account and case type: ' + cas.TGS_Holding_Name__c +
                                                                                                     ' - ' + cas.TGS_RTDevName__c +
                                                                                                     ' - ' + cas.TGS_Product_Tier_1__c +
                                                                                                     ' - ' + cas.TGS_Product_Tier_2__c +
                                                                                                     ' - ' + cas.TGS_Product_Tier_3__c);
                }
            }
            for(Case cas:toProcess){
                if(map_error.containsKey(cas.Id)){
                    cas.addError(map_error.get(cas.Id));
                }
            }
        }
    }*/

    /*------------------------------------------------------------
    Author:      Alvaro López
    Company:     New Energy Aborda
    Description: Method to validate the selected Product Tier values depending on account name and case recordType.
    Test Class:
    History
    <Date>      <Author>            <Change Description>
    16/02/2017  Alvaro López        Initial Version
    ------------------------------------------------------------*/

    public static void validateProductTier_AUX(List<Case> news, Map<Id ,Case> map_olds){

        Set<Id> set_rtIds = new Set<Id>{
            TGS_RecordTypes_Util.getRecordTypeId(Case.SObjectType,'TGS_Incident'),
            TGS_RecordTypes_Util.getRecordTypeId(Case.SObjectType,'TGS_Change')
        };

        List<Case> lst_caseByRT = new List<Case>();
        //DCN 14/01/2020 validate case belong Infinity
        for(Case cas: [select id,RecordTypeId,Account.TGS_Es_MNC__c,TGS_Customer_Services__c,TGS_Customer_Services__r.NE__ProdName__c,TGS_Holding_Name__c,TGS_RTDevName__c,TGS_Product_Tier_1__c,TGS_Product_Tier_2__c,TGS_Product_Tier_3__c from Case where id in :news and Account.TGS_Es_MNC__c=true and RecordTypeId in :set_rtIds ]){
            //Dummy
			if((String.isNotBlank(cas.TGS_Customer_Services__c)&&(cas.TGS_Customer_Services__r.NE__ProdName__c!='Producto generico'))||(String.isBlank(cas.TGS_Customer_Services__c))){
                lst_caseByRT.add(cas);
			}				
		}
		
		List<Case> toProcess = new List<Case>();

        if(map_olds != null){
            for(Case cas: lst_caseByRT){
                if(
                       cas.TGS_Holding_Name__c   != map_olds.get(cas.Id).TGS_Holding_Name__c
                    || cas.TGS_RTDevName__c      != map_olds.get(cas.Id).TGS_RTDevName__c
                    || cas.TGS_Product_Tier_1__c != map_olds.get(cas.Id).TGS_Product_Tier_1__c
                    || cas.TGS_Product_Tier_2__c != map_olds.get(cas.Id).TGS_Product_Tier_2__c
                    || cas.TGS_Product_Tier_3__c != map_olds.get(cas.Id).TGS_Product_Tier_3__c
                ){
                    toProcess.add(cas);
                }
            }
        }
        else{
            for(Case cas: lst_caseByRT){
                toProcess.add(cas);
            }
        }
        if(!toProcess.isEmpty()){
            List<TGS_Categorization_Tier_Dependence__c> lst_depend = ([SELECT Id, TGS_Holding_Name__c, TGS_RTDevName__c, TGS_Product_Tier_1__c, TGS_Product_Tier_2__c, TGS_Product_Tier_3__c
                                                                        FROM TGS_Categorization_Tier_Dependence__c]);
            Set<String> set_concat_tier = new Set<String>();

            if(!lst_depend.isEmpty()){
                for(TGS_Categorization_Tier_Dependence__c tier :lst_depend){
                    set_concat_tier.add(tier.TGS_Holding_Name__c + ' - ' + tier.TGS_RTDevName__c + ' - ' + tier.TGS_Product_Tier_1__c + ' - ' + tier.TGS_Product_Tier_2__c + ' - ' + tier.TGS_Product_Tier_3__c);
                }

                Map<Id, String> map_error = new Map<Id, String>();
                Boolean exists = false;
                String concat;

                for(Case cas: toProcess){
                    exists = false;
                    if(cas.TGS_Holding_Name__c != null && cas.TGS_RTDevName__c != null){
                        concat = cas.TGS_Holding_Name__c + ' - ' + cas.TGS_RTDevName__c + ' - ' + cas.TGS_Product_Tier_1__c + ' - ' + cas.TGS_Product_Tier_2__c + ' - ' + cas.TGS_Product_Tier_3__c;

                        if(set_concat_tier.contains(concat))
                            exists = true;
                    }
                    if(!exists){
                        map_error.put(cas.Id, 'Invalid Product Categorization for this account and case type: ' + cas.TGS_Holding_Name__c +
                                                                                                         ' - ' + cas.TGS_RTDevName__c +
                                                                                                         ' - ' + cas.TGS_Product_Tier_1__c +
                                                                                                         ' - ' + cas.TGS_Product_Tier_2__c +
                                                                                                         ' - ' + cas.TGS_Product_Tier_3__c);
                    }
                }
                for(Case cas:toProcess){
                    if(map_error.containsKey(cas.Id)){
                        cas.addError(map_error.get(cas.Id));
                    }
                }
            }
        }
    }

    /*------------------------------------------------------------
     Author:      Jose Miguel Fierro
     Company:     Accenture
     Description: Cambia el estado de las demás ordenes de un asset cuando se cierra una orden en vuelo
     Test Class:
     History
     <Date>       <Author>             <Change Description>
     08/03/2017   Jose Miguel Fierro   Initial Version
    ------------------------------------------------------------*/
    public static void getOrderCompleted(Map<Id, Case> mapNews, Map<Id, Case> mapOlds) {
        Id rtOrdManag = TGS_RecordTypes_Util.getRecordTypeId(Case.SObjectType, 'Order_Management_Case');
        Set<Id> set_ord2proc = new Set<Id>();
        for(Case cas : mapNews.values()) {
            if(cas.RecordTypeId == rtOrdManag && cas.Status == 'Closed' && cas.Status != mapOlds.get(cas.Id).Status && cas.Order__c != null) {
                set_ord2proc.add(cas.Order__c);
            }
        }
        if(!set_ord2proc.isEmpty()) {
            setOrderRevised(set_ord2proc);
        }
    }
    @testVisible @future
    private static void setOrderRevised(Set<Id> orders) {
        Id rtOrder = TGS_RecordTypes_Util.getRecordTypeId(NE__Order__c.SObjectType, 'Order');
        List<NE__Order__c> lst_ord2update = new List<NE__Order__c>();
        List<NE__Asset__c> lst_assets;
        for(NE__Asset__c ass : [SELECT Id, (SELECT Id FROM NE__Configurations__r WHERE NE__OrderStatus__c = 'Completed' AND RecordTypeId = :rtOrder AND Id NOT IN :orders)
                        FROM NE__Asset__c WHERE Id IN (SELECT NE__Asset__c FROM NE__Order__c WHERE Id IN :orders)]) {
            for(NE__Order__c ord : ass.NE__Configurations__r) {
                ord.NE__OrderStatus__c = 'Revised';
                lst_ord2update.add(ord);
            }
        }
        if(!lst_ord2update.isEmpty()) {
            update lst_ord2update;
        }
    }
    /*------------------------------------------------------------
     Author:      Cristina Rodriguez
     Company:     Accenture
     Description: fillBillingInfo, refactor from BI_Case.trigger
     Test Class:
     History
     <Date>       <Author>             <Change Description>
     16/05/2017   Cristina Rodriguez   Initial Version
     15/01/2018   Álvaro López         Changed condition for disconnect cases
     15/02/2018   Álvaro López         Changed condition for change cases
    ------------------------------------------------------------*/
    public static void fillBillingInfo(List<Case> news, Map<Id, Case> mapNews, Map<Id, Case> mapOlds) {
        for(Case newCase: news){
            Case oldCase =mapOlds.get(newCase.Id);
            // JCT 27/09/2016 Added condition at Line 284 to call CSUID generator methods in every Closed-Disconnect case.
            //ALA 14/03/2018 - Changed filter to call csuids
            if( ( newCase.asset__c!=null && (
                ( newCase.type == Constants.TYPE_NEW && oldCase.status == Constants.CASE_STATUS_RESOLVED && newCase.status == Constants.CASE_STATUS_CLOSED) ||
                ( newCase.type != Constants.TYPE_NEW && newCase.asset__c != oldCase.asset__c) ) ) || //PCP 18/07/2016 - Add condition to call cls that generates CSUIDs
                /*( newCase.asset__c == null && newCase.type == Constants.TYPE_DISCONNECT && (newCase.TGS_Service__c.equals(Constants.PRODUCT_MWAN_SU) || newCase.TGS_Service__c.equals(Constants.PRODUCT_MWAN_INTERNET)))||*/
                ( newCase.asset__c == null && newCase.type == Constants.TYPE_DISCONNECT && newCase.Status == Constants.CASE_STATUS_CLOSED) ||
                ( newCase.asset__c == null && newCase.type == Constants.TYPE_CHANGE && newCase.Status == Constants.CASE_STATUS_CLOSED)
            ){
                Boolean wasFired_CSUID = NETriggerHelper.getTriggerFired('TGS_fill_CSUID');
                System.debug('wasFired_CSUID: '+wasFired_CSUID);
                if(!wasFired_CSUID){
                    if(Constants.isQueueableContext){
                        /*if (newCase.Type != Constants.TYPE_DISCONNECT || // FAR 06/06/2016 - Don't generate CSUIDs if case type is Disconnect
                            (newCase.Type == Constants.TYPE_DISCONNECT &&
                            (newCase.TGS_Service__c.equals(Constants.PRODUCT_MWAN_SU) || newCase.TGS_Service__c.equals(Constants.PRODUCT_MWAN_INTERNET)))//PCP 07/07/2016 - Allow call TGS_fill_CSUID class also if disconnect and service mWan
                            )
                        {
                            //15/09/2016 JCT Added TGS_fill_CSUID.fill_CSUID_EnterpriseID method call instead of csuid() method call.
                            //25/09/2016 JCT Changed TGS_fill_CSUID.fill_CSUID_EnterpriseID method call for TGS_fill_CSUID.fill_EnterpriseID(Trigger.newMap); call
                            //           Also Added TGS_fill_CSUID.csuid(newCase); method call.
                            //27/09/2016 JCT Changed the csuid method call to get a TGS_fill_CSUID.fill_EnterpriseID(Trigger.newMap) call as parameter after the
                            //           csuid method definition reported on TGS_fill_CSUID class.
                            TGS_fill_CSUID.csuid(newCase,TGS_fill_CSUID.fill_EnterpriseID(mapNews));
                        }*/
                        TGS_fill_CSUID.csuid(newCase,TGS_fill_CSUID.fill_EnterpriseID(mapNews));
                        TGS_Billing_Date.setCiBillingDate(newCase);
                    }else{
                        /*if (newCase.Type != Constants.TYPE_DISCONNECT || // FAR 06/06/2016 - Don't generate CSUIDs if case type is Disconnect
                            (newCase.Type == Constants.TYPE_DISCONNECT &&
                            (newCase.TGS_Service__c.equals(Constants.PRODUCT_MWAN_SU) || newCase.TGS_Service__c.equals(Constants.PRODUCT_MWAN_INTERNET)))//PCP 07/07/2016 - Allow call TGS_fill_CSUID class also if disconnect and service mWan
                            )*/
                        //ALA 13/03/2018 - Changed filter to call csuids
                        //ALA 14/03/2018 - Changed filter to call csuids
                        if (newCase.Type != Constants.TYPE_DISCONNECT && newCase.Type != Constants.TYPE_CHANGE)
                        {
                            System.debug('Entro en billing queueable');
                            System.enqueueJob(new TGS_Billing_Queueable(newCase));
                        }
                    }
                }
            }
        }

    }

    /*------------------------------------------------------------
     Author:      Álvaro López
     Company:     Accenture
     Description: CR Portal SDN - fillBillingInfo
     Test Class:
     History
     <Date>       <Author>             <Change Description>
     25/10/2018   Álvaro López         Initial Version
    ------------------------------------------------------------*/
    public static void setBillingInfoFromOrder(List<Case> lst_news, Map<Id, Case> map_olds){
        try{
            System.debug('Entro en setBillingInfoFromOrder uppdate');
            //Set<String> set_services = new Set<String>{'WAN2Cloud','mWan','DIA-Internet Access'};
            Set<Id> set_casId = new Set<Id>();
            List<Case> lst_toProcess = new List<Case>();
            for(Case cas :lst_news){
                if(cas.Type == 'New' && cas.TGS_FAST_Case__c && cas.Status == Constants.CASE_STATUS_CLOSED && map_olds.get(cas.Id).Status == Constants.CASE_STATUS_RESOLVED){
                    set_casId.add(cas.Id); 
                }
            }
            if(!set_casId.isEmpty() && set_casId != null){

                lst_toProcess = [SELECT Id, Asset__r.Id, Order__r.NE__BillAccId__c, Order__r.NE__ServAccId__c, Order__r.Site__c FROM Case WHERE Id IN :set_casId];

                if(!lst_toProcess.isEmpty()){
                    Case caseN = lst_toProcess[0];
                    System.debug('caseN: ' + caseN);
                    NE__Order__c asset = new NE__Order__c(Id = caseN.Asset__r.Id);
                    asset.NE__BillAccId__c = caseN.Order__r.NE__BillAccId__c; //BU
                    asset.NE__ServAccId__c = caseN.Order__r.NE__ServAccId__c; //CC
                    asset.Site__c = caseN.Order__r.Site__c; // Site
                    update asset;
                    
                    List<NE__Order__c> listOrd = [SELECT Id, 
                                                        (SELECT Id, Installation_point__c, NE__Billing_Account__c, NE__Billing_Account_Asset_Item__c, 
                                                                NE__Service_Account__c, NE__Service_Account_Asset_Item__c, TGS_Type_Order__c 
                                                        FROM NE__Order_Items__r) 
                                                FROM NE__Order__c WHERE Id = :caseN.Asset__r.Id OR Id = :caseN.Order__r.Id];

                    List<NE__OrderItem__c> listCIs = new List<NE__OrderItem__c>();
                    for(NE__Order__c ord : listOrd){
                        for(NE__OrderItem__c CI : ord.NE__Order_Items__r){
                            CI.Installation_point__c = caseN.Order__r.Site__c;
                            CI.NE__Billing_Account__c = caseN.Order__r.NE__BillAccId__c;
                            CI.NE__Service_Account__c = caseN.Order__r.NE__ServAccId__c;

                            if(CI.TGS_Type_Order__c == Constants.RECORD_TYPE_ASSET){
                                CI.NE__Billing_Account_Asset_Item__c = caseN.Order__r.NE__BillAccId__c;
                                CI.NE__Service_Account_Asset_Item__c = caseN.Order__r.NE__ServAccId__c;
                            }
                            listCIs.add(CI);
                        }
                    }
                    if(!listCIs.isEmpty()){
                        System.debug('setBillingInfoFromOrder uppdate');
                        update listCIs;
                    }
                }
            }
        }
        catch(Exception exc){
            BI_LogHelper.generate_BILog('TGS_CaseMethods.setBillingInfoFromOrder', 'TGS', exc, 'Apex Class');
        }
    }

}