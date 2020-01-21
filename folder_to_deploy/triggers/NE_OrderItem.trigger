/*------------------------------------------------------------
Author:         NewEnergy
Company:        NewEnergy
Description:    Trigger for changes in NE__OrderItem__c Object
                Call Integration to sinchronize OrderItems with RoD
History
<Date>          <Author>            <Change Description>
?               New Energy          Initial Version
20/08/2015      Francisco Ayllón    Unification with NE_OrderItem, migrated BI_NEOrderItemMethods inside the loop
                Micah Burgos
20/06/2016      Álvaro López      Added setCaseService method to TGS after update
27-Aug-2015     Jose Lopez          Unification with NE_OrderItem, Added Rod integration for Order Item
29/09/2015      Marta García        Unification with NE_OrderItem, Added field TGS_Value_Attribute fill
12/01/2016      Guillermo Muñoz     Reevaluation of the approval level of the Opportunity
19/02/2016      Micah Burgos        Reevaluation of control fields if It changes the qty of products
12/08/2016      Jorge Galindo       we have to loop the map instead of trigger.new because can be differences because of NI_FVIBorrar trigger
20/08/2016      Geraldine Perez     Add Economic values ​​calculated for the opportunity to Colombia
31/08/2016      Fernando Arteaga    Infinity W4+5: use an opportunity map instead of a list of sObjects. Also new method calls added
23/09/2016      Alfonso Alvarez     Se incluye en este trigger, el código del trigger BI_FVIBorrar (el cual se desactivará)
05/10/2016      Fernando Arteaga    Infinity W4+5: add missing encapsulation
18/11/2016      Alvaro García       añadida condición para que no requiera validación económica cuando se trate  oportunidades hijas de una oportunidad Centralizada
23/01/2017      Alberto Fernández   Adding updateValPresupuestoOrder();
20/02/2017      Gawron, Julian      Adding afterDelete, actualizarAccountCoberturaDigitalOI
15/03/2017      Álvaro López        Added TGS_Billing_Date.inFutureContext flag
27/03/2017      Pedro Pachas        Modify condition in lines 153 and 183 to pass a process of economic analysis of Opportunity
12/04/2017      Humberto Nunes      SE AGREGO LA OMISION PARA CUANDO SEA FVI
17/04/2017      Humberto Nunes      SE AGREGO LA OMISION PARA CUANDO SEA FVI EN OTRO IF INTERNO YA QUE NO FUNCIONABA EN UAT
19/04/2017      Humberto Nunes      SE HIZO LA COMPARACION CON EL Recordtype de la OPP y no con el del Padre de la OPP Y SE CONSULTO ESE VALOR EN EL QUERY
20/404/2017     Alejandro Pantoja   Delete condition in lines 153 and 183 to pass a process of economic analysis of Opportunity and check off the factibility check in order to luch the EF.
23/05/2017      Cristina Rodríguez  Added NESetDefaultOIFields.trigger and NECheckDeltaQuantity.trigger. Refactor.
01/06/2017      Álvaro López        Added CI status Active
21/06/2017      Guillermo Muñoz     Added trigger helper on BI_NEOrderItemMethods.updateSumatoria method
18/07/2017      Humberto Nunes      Encapsulado de FVI
20/07/2017      Guillermo Muñoz     Added BI_MigrationHelper.isTriggerDisabled functionality to disable the trigger
01/08/2017      Guillermo Muñoz     Added Trigger.oldMap in BI_NEOrderItemMethods.neSetDefaultOIFields call
30/08/2017      Alvaro Sevilla      Added invocation to method campoSubsidioEquipoOpp
26/09/2017      Álvaro López        fillParentQty method call in after insert and after update.
05/10/2017      Jaime Regidor       Adding BI_NEOrderItemMethods.PaybackFijaValores
12/04/2018      Alberto Fernández   Adding validateUpdate();
22/05/2018      Manuel Ochoa        If configuration comes from bulk, call updateOrderAndOrder method only when BCIR is completed
30/05/2018      Alvaro Sevilla      Se adiciono bandera para una sola ejecucion del metodo campoSubsidioEquipoOpp
16/07/2018      Álvaro López        eHelp 03913620 added method call value_attributeAC
10/04/2019      Javier López        CPQ-added BI_Duracion_del_contrato_Meses__c to opp query
29/05/2019      Pablo de Andrés     Included call to resetTechStatusOfCIToNONE method from CPQ_AuxliarMethods class
24/06/2019      Pablo de Andrés     Added call to updateOrderEconomicDataCPQ method from CPQ_NEOrderItemMethods class on after update, before delete
24/06/2019      Pablo de Andrés     Added call to replicateOptyFromCPQQuote method from CPQ_NEOrderItemMethods class on after insert, before delete
11/07/2019      Pablo de Andrés     Added call to updateEconomicDataFromOptyOnOIDelete method from CPQ_NEOrderItemMethods class on before delete
11/07/2019      Pablo de Andrés     Added call to updateNumberOfLinesOptyOrCPQQuote method from CPQ_NEOrderItemMethods class on after insert, before delete
22/10/2019      Amador Cáceres      Added call to keepHierarchyComplexProduct to recalculate economicValue when go out to cart B2W
28/10/2019      Amador Cáceres      Added NE__Catalog__r.Name and BI_Opportunity_Type__c to query
30/10/2019      Javier López        Added new economic fields to query
20/11/2019      Daniel Cordoba      Added call to method checkFamily from TBS_OT_OrderEstablishment class  
--------------------------------------------------------------------------------------------------------------------------------------------------------*/
trigger NE_OrderItem on NE__OrderItem__c (after insert, after update, before insert, before update, before delete){

    TGS_User_Org__c userTGS = TGS_User_Org__c.getInstance();
    Boolean TGS = userTGS.TGS_Is_TGS__c;
    Boolean BI = userTGS.TGS_Is_BI_EN__c;
    Boolean FVI = userTGS.BI_FVI_Is_FVI__c;
    Boolean blnTriggerExeMS = false;

    /*Álvaro López - 13/07/2017 - Evita que valide el RBMA al modificar un order item*/
    NETriggerHelper.setTriggerFiredTest('BI_OpportunityMethods.validatePreviousRecurringCharge', true);

    //GMN 20/07/2017
    Boolean isTriggerDisabled = BI_MigrationHelper.isTriggerDisabled('NE__OrderItem__c');

    // 21/05/2018 - Manuel Ochoa - if configuration comes from bulk, call updateOrderAndOrder method only when BCIR is completed
    Boolean bComesFromBulk=false;
    Boolean bBulkCompleted=false;

    //JAG 26/01/2018
    BI_bypass__c bypass = BI_bypass__c.getInstance();
    Integer index = 0;
    try{
    	for(NE__OrderItem__c oi: Trigger.new){
        	System.debug('--ACR--> Nuevo OI: '+oi.Installation_point__c);
        	if(!Trigger.isInsert)
            	System.debug('--ACR --> OLD OI: '+Trigger.old[index].Installation_point__c);
	        index++;
    	}
    }catch(Exception e){
        System.debug('--ACR Has cometido un error NOOB');
    }
    if(!isTriggerDisabled){
        /******* START NECheckOrderItems.trigger *******/
        if(trigger.isAfter && !bypass.BI_skip_trigger__c){
            System.debug ('JAG Entro en trigger.isAfter');
			list<Opportunity> listOfOptyToUpd       =   new list<Opportunity>();
            Map<Id,NE__Order__c> listOfOrderToUpd     =   new Map<Id,NE__Order__c>();
			Map<Id, Opportunity> mapOppsToUpd = new Map<Id, Opportunity>();
            if(trigger.isInsert || trigger.isUpdate ){
				
                /*--ACR 22/10/2019----------------------------------------------------------------------------------------------------------------------------------
                *  Se crea método para consultar si la jerarquía entre productos complejos cambia. Al salir del Carrito de B2W, como se ha podido comprobar tanto 
                *  despues de una actualización de tus productos, como al insertar unos nuevos, la jerarquía se inicializa, por lo que no existe una relación entre 
                *  el producto padre y los hijos. Con este método pretendemos que, si la jerarquía en el Trigger.new está establecida, hagamos una recalculación de
                *  los precios originales, en el método BI_NEOrderItemMethods.fillOrderAndOptyFields.
                *  Creamos variable booleana para entrar al método nombrado.
                ---------------------------------------------------------------------------------------------------------------------------------------------------*/
                Boolean recalculateEconomicValueHierarchy = false;
                if(trigger.isUpdate){
                    recalculateEconomicValueHierarchy = BI_NEOrderItemMethods.keepHierarchyComplexProduct(Trigger.new, Trigger.old);
                }
                boolean wasFired_NECheckOrderItems    =   NETriggerHelper.getTriggerFired('NECheckOrderItems');
                /*if(trigger.isUpdate && BI){
                    TGS_fill_Value_Attribute.value_attribute2(Trigger.newMap.keySet());
                    Constants.firstRunAttribute = true;
                }*/
                //22/10/2019 - ACR - Se incluye en la condición recalculateEconomicValueHierarchy.
                if(!wasFired_NECheckOrderItems || recalculateEconomicValueHierarchy){
                    //JLA_20190409
                    //CPQ_OrderItemMethods.checkChangeSync(Trigger.new,Trigger.old);
                    if(trigger.isUpdate){
                    /*------------------------- START TGS ---------------------*/
                        if(TGS){
                            TGS_NEOrderItemMethods.callRodWs(Trigger.newMap, Trigger.isUpdate);
                        }
                    /*---------------------------END TGS ----------------------*/
                    }
                    //ACR                  
                    //NETriggerHelper.setTriggerFired('NECheckOrderItems');

                    // FAR 30/08/2016: Add BI_O4_Gross_margin_P__c, BI_O4_Acquisition_Margin__c, BI_O4_Retention_Margin__c, BI_O4_Growth_Margin__c fields
                    //JLA con \n
                    Map<String,NE__OrderItem__c> mapOfOi    =   new Map<String,NE__OrderItem__c>([SELECT Id, NE__Catalog__r.Name, NE__OrderId__c, NE__Status__c, NE__OrderId__r.NE__OptyId__c,
                        NE__CatalogItem__r.NE__Base_OneTime_Fee__c,NE__CatalogItem__r.NE__BaseRecurringCharge__c,NE__CatalogItem__r.NE__Technical_Behaviour_Opty__c,
                        NE__OrderId__r.RecordType.Name,/*JLA*/NE__OrderId__r.RecordType.DeveloperName,NE__OrderId__r.NE__Type__c/*JLA FIN*/,NE__RecurringChargeOv__c,NE__OneTimeFeeOv__c,NE__BaseOneTimeFee__c,NE__BaseRecurringCharge__c,NE__Qty__c, 
                        RecordType.DeveloperName,NE__Billing_Account__c,NE__Billing_Account__r.TGS_Aux_Holding__c,NE__Service_Account__c,NE__Service_Account__r.TGS_Aux_Holding__c, 
                        BI_O4_Gross_margin_P__c, BI_O4_Acquisition_Margin__c, BI_O4_Retention_Margin__c, BI_O4_Growth_Margin__c,CPQ_Duracion_contrato__c, 
                        NE__CatalogItem__r.NE__ProductId__r.BI_COT_MEX_Analisis_Economico__c FROM NE__OrderItem__c WHERE Id IN: Trigger.new]);

                    list<String> listOfOptyIds  =   new list<String>();
                    list<String> listOfOrderIds  =   new list<String>();

                    Boolean IsTech = false;

                    // JGL 12/08/2016
                    //for(NE__OrderItem__c oiTrigger : Trigger.new) {
                    for(NE__OrderItem__c oi : mapOfOi.values()) {
                        //NE__OrderItem__c    oi  =   mapOfOi.get(oiTrigger.id);
                        // END JGL 12/08/2016

                        if(oi.NE__OrderId__r.NE__OptyId__c != null)
                            listOfOptyIds.add(oi.NE__OrderId__r.NE__OptyId__c);

                        listOfOrderIds.add(oi.NE__OrderId__c);
                    }
                    //map<String,NE__Order__c> mapOfOrders    =   new map<String,NE__Order__c>([SELECT Id, NE__OptyId__c, NE__OrderStatus__c, BI_Ingreso_Recurrente_Anterior_Config__c, CurrencyIsoCode, (SELECT Id, BI_Ingreso_Recurrente_Anterior_Producto__c, NE__Qty__c, CurrencyIsoCode, NE__Parent_Order_Item__c, NE__Parent_Order_Item__r.NE__Qty__c, NE__BaseRecurringCharge__c, NE__BaseOneTimeFee__c, Recurring_Cost__c, One_Time_Cost__c, NE__ProdId__r.RecordType.Name FROM NE__Order_Items__r WHERE NE__Status__c = 'Pendiente de envío' OR NE__Status__c = 'Pending' OR NE__Status__c = 'Enviado' OR NE__Status__c = 'En tramitación') FROM NE__Order__c WHERE Id IN: listOfOrderIds AND NE__OptyId__c!=null]);
                    /* 01/06/2017 Álvaro López - Added CI status Active */
                    //JLA Added new economic field to upgrade into Ord
                    map<String,NE__Order__c> mapOfOrders    =   new map<String,NE__Order__c>([SELECT Id, NE__CatalogId__r.Name,NE__Type__c,/*For historical motives */RecordType.Name,/*JLA DeveloperName */RecordType.DeveloperName,BI_O4_CAPEX_total__c,BI_O4_OPEX_no_recurrente_total__c,BI_O4_OPEX_recurrente_total__c, NE__OptyId__c, NE__OrderStatus__c, BI_Ingreso_Recurrente_Anterior_Config__c, CurrencyIsoCode, NE__One_Time_Fee_Total__c, NE__Recurring_Charge_Total__c,BI_Original_Total_Recurring_Charge__c, BI_Original_Total_One_Time_Fee__c, BI_Cantidad_de_Equipos__c,NE__Version__c, BI_Cantidad_de_Servicios__c, BI_Cantidad_de_Otros_Productos__c, BI_Total_One_Time_Cost__c,BI_Total_Recurring_Cost__c , 
                    CPQ_paybackEstimado__c,CPQ_paybackReal__c,NE__PayBack_Saved_By__c,NE__PayBack_Saved_Date__c,NE__PayBack_Status__c,CPQ_vanEstimado__c,CPQ_vanReal__c,NE__Van_on_Cost__c,Months_Return_of_Investiment__c,Factor_Commission_Security_Family__c,Factor_Annual_Depreciation_Infrastructur__c,Factor_Annual_Depreciation_Equipment__c,NE__Monthly_Discount_Rate__c,Arrearage_Percentage__c,Income_Tax_Percentage__c,NE__Management_Committee_Percentage__c,
                    (SELECT Id, BI_Ingreso_Recurrente_Anterior_Producto__c, NE__Qty__c, CurrencyIsoCode, NE__Parent_Order_Item__c, NE__Parent_Order_Item__r.NE__Qty__c, NE__BaseRecurringCharge__c, NE__BaseOneTimeFee__c,CPQ_Duracion_contrato__c, Recurring_Cost__c, One_Time_Cost__c, NE__ProdId__r.RecordType.Name, NE__OneTimeFeeOv__c, NE__RecurringChargeOv__c, NE__OrderId__c , NE__ProdId__c/*JLA NEW FIELDS */,CPQ_CAPEX__c,CPQ_OPEX_MRC__c,CPQ_OPEX__c 
                    FROM NE__Order_Items__r 
                    WHERE NE__Status__c = 'Pendiente de envío' OR NE__Status__c = 'Pending' OR NE__Status__c = 'Enviado' OR NE__Status__c = 'En tramitación' OR NE__Status__c = 'Active') 
                    FROM NE__Order__c WHERE Id IN: listOfOrderIds AND NE__OptyId__c!=null]);        // FAR 30/08/2016 - Add BI_O4_Tipo_de_OportunidadTNA__c field
                    // HN 19/04/2017 SE ADICIONO EL DEVELOPERNAME DEL RECORDTYPE
                    // 22/05/2018 - Manuel Ochoa - Added FOR UPDATE clausule to query
                    map<String,Opportunity> mapOfStdOpty    =   new map<String,Opportunity>([SELECT Id,
                                                                                                    RecordTypeId,
                                                                                                    RecordType.DeveloperName,
                                                                                                    BI_Oportunidad_padre__c,
                                                                                                    BI_Oportunidad_padre__r.RecordType.DeveloperName,
                                                                                                    BI_Oportunidad_padre__r.BI_O4_Opportunity_Type__c,
                                                                                                    Account.RecordType.DeveloperName,
                                                                                                    BI_O4_Tipo_de_OportunidadTNA__c,
                                                                                                    BI_Oferta_economica__c,
                                                                                                    BI_Origen_de_la_oferta_tecnica__c,
                                                                                                    BI_Oferta_tecnica__c,
                                                                                                    BI_Descuento__c,
                                                                                                     /**JLA CHECK */
                                                                                                    CPQ_Check__c,
                                                                                                    BI_Duracion_del_contrato_Meses__c,
                                                                                                    BI_No_requiere_comite_arg__c,
                                                                                                    BI_No_requiere_Pricing_arg__c,
                                                                                                    BI_Factibilidad_tecnica_legado_arg__c,
                                                                                                    BI_Country__c,
                                                                                                    BI_Productos_numero__c,
                                                                                                    BI_Recurrente_bruto_mensual_anterior__c,
                                                                                                    BI_Opportunity_Type__c,
                                                                                                    CurrencyIsoCode,
                                                                                                    CPQ_Cargo_recurrent_mensua_original_MRCo__c,
                                                                                                    CPQ_Cargo_por_nica_vez_original_NRCo__c,
                                                                                                    BI_Recurrente_bruto_mensual__c,
                                                                                                    BI_Ingreso_por_unica_vez__c
                                                                                                    FROM Opportunity WHERE id IN: listOfOptyIds FOR UPDATE]);
                    // 22/05/2018 - Manuel Ochoa - Added FOR UPDATE clausule to query

                    BI_NEOrderItemMethods.fillOrderAndOptyFields(mapOfOi, Trigger.oldMap, Trigger.isInsert, Trigger.isUpdate, IsTech, mapOppsToUpd, mapOfOrders, mapOfStdOpty, listOfOrderToUpd);
					//JLA Movido aqui para usar la actualización global!!!

                    if(trigger.isUpdate && BI)
						CPQ_NEOrderItemMethods.updateNumberOfLinesOptyOrCPQQuote(trigger.new, trigger.old,listOfOrderToUpd); //Added by Pablo de Andrés 12/07/2019
					else if(trigger.isinsert && BI)
						CPQ_NEOrderItemMethods.updateNumberOfLinesOptyOrCPQQuote(trigger.new, null,listOfOrderToUpd); //Added by Pablo de Andrés 11/07/2019  
                    // 22/20/2019 - ACR - Incluimos de nuevo el wasFired_NECheckOrderItems para no reejecutar este método.
                    if(!wasFired_NECheckOrderItems){
                         if(trigger.isUpdate)
                        NETriggerHelper.setTriggerFired('NECheckOrderItems');
                        // FAR 31/08/2016: Call updateOpptyForApproval, and if mapOppsToUpd contains the opps, set BI_Oferta_economica__c field
                        if (BI){

                            BI_O4_OrderItemMethods.setEconomicFeasibility(Trigger.new, Trigger.old, mapOppsToUpd, listOfOptyToUpd);
                        }
                        // END FAR 19/09/2016:
                    }

                    // 21/05/2018 - Manuel Ochoa - if configuration comes from bulk, call updateOrderAndOrder once and only when BCIR is completed
                    for(NE__OrderItem__c oi : Trigger.new){
                        if(oi.Bit2WinHUB__BulkConfigurationItemRequest__c!=null){
                            system.debug(LoggingLevel.ERROR, 'CI comes from BCIR bulk');
                            system.debug(LoggingLevel.ERROR, 'BCIR status: ' + oi.Bit2WinHUB__Bulk_Status__c);
                            bComesFromBulk=true;
                            if(oi.Bit2WinHUB__Bulk_Status__c.indexOf('Completed')!=-1){
                                system.debug(LoggingLevel.ERROR, 'BCIR completed: ');
                                bBulkCompleted=true;
                            }
                            if(oi.Bit2WinHUB__Bulk_Status__c.indexOf('Working')!=-1){
                                system.debug(LoggingLevel.ERROR, 'BCIR Working: ');
                            }
                        }
                    }
                    
                    // 21/05/2018 - Manuel Ochoa - if configuration comes from bulk, call updateOrderAndOrder only when BCIR is completed
                    if(Trigger.isUpdate && BI){
                        //JLA check Sync
                        CPQ_OrderItemMethods.checkChangeSync(mapOfOi,Trigger.new,listOfOrderToUpd,mapOppsToUpd);
                    }
                }
                /* Mariano García 02/10/2017 - campoSubsidioEquipoOpp method was encapsulated to avoid too many queries error in tgs processes*/
                if(BI || FVI){
                    //ASD Se adicionó invocacion el metodo 30/08/2017
                    //ASD Se adiciono bandera para una sola ejecucion
                    boolean wasFired_campoSubsidioEquipoOpp = NETriggerHelper.getTriggerFired('campoSubsidioEquipoOpp');
                     if(!wasFired_campoSubsidioEquipoOpp) {
                        NETriggerHelper.setTriggerFired('campoSubsidioEquipoOpp');
                        BI_NEOrderItemMethods.campoSubsidioEquipoOpp(trigger.new, trigger.old);
                    }
                }

                boolean wasFired_CalculateOR   =   NETriggerHelper.getTriggerFired('CalculateOR');
                boolean wasFired_updateModServicio   =   NETriggerHelper.getTriggerFired('updateModServicio');//GSPM 21-05-2018
                if(BI){
                    if(!wasFired_CalculateOR) {
                        NETriggerHelper.setTriggerFired('CalculateOR');
                        BI_NEOrderItemMethods.CalculateOR(trigger.new, trigger.old);
                    }
                    if(!System.isFuture())  // 30/05/2018 - GSPM
                    {
                        // 23/05/2018 - Manuel Ochoa -  this modification is pending  of revisión from GSPM
                        // it's a patch to avoid null pointer error when CIs comes from bulk process
                        if(!bComesFromBulk)
                        {// 23/05/2018 - Manuel Ochoa - Don't call updateModServicio if CIs comes from bulk
                            if(!wasFired_updateModServicio && NETriggerHelper.getTriggerFired('NEPageRedirect.updateModServicio'))//OAJF 17/08/2018 - eHelp 04029652 add flag NEPageRedirect.updateModServicio
                            {//GSPM START: 21-05-2018
                                system.debug('>>updateModServicio trigger<<');
                                NETriggerHelper.setTriggerFired('updateModServicio');
                                BI_NEOrderItemMethods.updateModServicio(trigger.new, trigger.old);
                            } //GSPM END: 21-05-2018
                        }//023/05/2018 - Manuel Ochoa - Don't call updateModServicio if CIs comes from bulk

                    }

                    BI_NEOrderItemMethods.actualizarAccountCoberturaDigitalOI(trigger.new, trigger.old); //JEG D398 17/02/2017
                    BI_NEOrderItemMethods.fillParentQty(Trigger.new, Trigger.oldMap, Trigger.isBefore); //JEG 11/10/2017
                }
				
                    if(!NETriggerHelper.getTriggerFired('TasaFromStageName')){

                        BI_NEOrderItemMethods.updateSumatoria(trigger.new, trigger.old,listOfOrderToUpd,mapOppsToUpd);
                }
            }

            if(trigger.isUpdate){
               

                if(TGS){

                    TGS_NEOrderItemMethods.setCaseService(trigger.new, trigger.old);
                }

                if (FVI)
                {
                    BI_FVIBorrarMethods.Borrar(Trigger.new);
                }
                else
                {
                    /******* START NECheckDeltaQuantity.trigger *******/
                    boolean wasFired_NECheckDeltaQuantity = NETriggerHelper.getTriggerFired('NECheckDeltaQuantity');
					//JLA LO movemos!!!
					//JLA LO QUITAMOS YA QUE DEBERIA HACERLO En el del fillOrderAndOptyFields anteriomente usado
					//CPQ_NEOrderItemMethods.updateOrderEconomicDataCPQ(trigger.new, trigger.old); //Added by Pablo de Andrés 24/06/2019
                    system.debug('*wasFired_NECheckDeltaQuantity ' + wasFired_NECheckDeltaQuantity + ' !wasFired_NECheckDeltaQuantity ' + !wasFired_NECheckDeltaQuantity);

                    if(!wasFired_NECheckDeltaQuantity){

                        NETriggerHelper.setTriggerFired('NECheckDeltaQuantity');
                        BI_NEOrderItemMethods.neCheckDeltaQuantity(trigger.new);
                    }
                    /******* END NECheckDeltaQuantity.trigger *******/
                }

                //Actualizamos los atributos 'Sede' con el nombre de la sede.
				//! JLA lo metemos aquid entro solo es para CPQ
				if(BI)
                	BI_NEOrderItemMethods.procesaSede(trigger.new, trigger.old);
            }

            //06/11/2017 GSPM START: Modificación de invocación al método duplicarOI
           if(trigger.isInsert || trigger.isUpdate ){

                boolean wasFired_duplicarOI   =   NETriggerHelper.getTriggerFired('duplicarOI');
                System.debug('====== wasFired_duplicarOI == 1 ======>>'+wasFired_duplicarOI);
                if(BI){
                    if(!wasFired_duplicarOI)
                    {
                        if(!System.isFuture() && !System.isQueueable() && !System.isScheduled() && !System.isBatch()){
                            NETriggerHelper.setTriggerFired('duplicarOI');
                            BI_NEOrderItemMethods.duplicarOI(Trigger.new, Trigger.old);}
                            System.debug('====== wasFired_duplicarOI == 2 ======>>'+wasFired_duplicarOI);
                    }
                }
				//JLA lo movemos al final para que pasen todos y depues actualice lo que tenga que actualizar!!!
				//ACR 13/11/2019 Actualizamos la lista con los valores recogidos del mapa.
                    listOfOptyToUpd.addAll(mapOppsToUpd.values());
                    if(bComesFromBulk){
                        if(bBulkCompleted){
                            system.debug(LoggingLevel.ERROR, 'updateOrderAndOrder only when BCIR completed');
                            system.debug(Trigger.new);
                            //system.debug(mapOfOrders);
                            BI_NEOrderItemMethods.updateOrderAndOrder(listOfOrderToUpd, listOfOptyToUpd);
                        }
                    }else{
                        system.debug(LoggingLevel.ERROR, 'updateOrderAndOrder update and insert - not bulk');
                        BI_NEOrderItemMethods.updateOrderAndOrder(listOfOrderToUpd, listOfOptyToUpd);
                    }
            }
            //06/11/2017 GSPM END: Modificación de invocación al método duplicarOI
            if(trigger.isDelete){

                if(BI){
                    //CPQ_OrderItemMethods.checkChangeSync(null,Trigger.old);
                    BI_NEOrderItemMethods.actualizarAccountCoberturaDigitalOI(trigger.new, trigger.old); //JEG D398 20/02/2017
                }
            }
            
            if(trigger.isInsert && BI){
                CPQ_NEOrderItemMethods.replicateOptyFromCPQQuote(trigger.new, null); //Added by Pablo de Andrés 24/06/2019  
            }
           
        }
        /******* END NECheckOrderItems.trigger *******/

        /******* START NESetDefaultOIFields.trigger *******/
        if(trigger.isBefore && !bypass.BI_skip_trigger__c){
            System.debug ('JAG Entro en trigger.isBefore');

            if(trigger.isInsert || trigger.isUpdate ){
                //Ponemos lo primeor lo primero!
				if(BI)
                	CPQ_OrderItemMethods.upgradeCost(Trigger.new,Trigger.old);
                boolean wasFired_NESetDefaultOIFields    =   NETriggerHelper.getTriggerFired('NESetDefaultOIFields');
                boolean testFired_NESetDefaultOIFields    =   NETriggerHelper.getTriggerFired('NESetDefaultOIFieldsTest');
                //DCN 20/11/2019
                TBS_OT_OrderEstablishment.checkFamily(Trigger.new);
                
                //ALM 12/05/2017
                Map <String,NE__Product__c> mapOfCi;
                list<String> listofOIci =   new list<String>();

                if(trigger.isUpdate){
                    /**Added by Pablo de Andrés 29/05/2019**/
                    
                    /*Álvaro López 16/08/2018 eHelp 03913620*/
                    if(BI){
						CPQ_AuxiliarMethods.resetTechStatusOfCIToNONE(Trigger.new, Trigger.old);
                        TGS_fill_Value_Attribute.value_attributeAC(Trigger.new);
                        Constants.firstRunAttribute = true;
                    }
                    
                    //if(TGS){
                        //TGS_NEOrderItemMethods.validateUpdate(trigger.newMap, trigger.oldMap);
                    //}
                    NE_OrderItemValidations.validateBundleBillingStartDate(Trigger.oldMap, Trigger.new);
                }

                //ALM 12/05/2017 - Moved for query reutilitation
                if(mapOfCi == null){
                    for(NE__OrderItem__c oiTrigger : Trigger.new)
                        listofOIci.add(oiTrigger.NE__ProdId__c);

                    mapOfCi = NE_OrderItemTriggerHelper.getIdProduct(listofOIci);//JEG// new map<String,NE__Product__c>([SELECT id,recordType.DeveloperName, BI_COT_MEX_Analisis_Economico__c FROM NE__Product__c WHERE id in: listofOIci]);
                }

                if(!wasFired_NESetDefaultOIFields && !testFired_NESetDefaultOIFields){

                    BI_NEOrderItemMethods.neSetDefaultOIFields(trigger.new,trigger.oldMap, mapOfCi);
                }

                if(!testFired_NESetDefaultOIFields){

                    if(Trigger.isBefore){
                        if(Trigger.isInsert){
                        if(TGS){
                            TGS_NEOrderItemMethods.fillCiSite(Trigger.new);
                        }
                        if (BI){

                            BI_O4_OrderItemMethods.setTotalPriceAndCost(Trigger.new);
                            BI_O4_OrderItemMethods.fillInvoicingModelAndUnit(Trigger.new, false);
                            BI_NEOrderItemMethods.agregaTasa(trigger.new); //JEG 03/02/2017
                            BI_NEOrderItemMethods.fillParentQty(Trigger.new, Trigger.oldMap, Trigger.isBefore); //JEG 11/10/2017
                        }
                    }
                    if(Trigger.isUpdate){

                        if(BI || FVI){

                        BI_NEOrderItemMethods.PaybackFijaValores(trigger.new, trigger.old);//JRM 17/10/2017

                        }

                        if(TGS) {

                            TGS_NEOrderItemMethods.fillRequiredData_update(Trigger.newMap, Trigger.oldMap);
                            TGS_NEOrderItemMethods.validateCIFields_update(Trigger.newMap, Trigger.oldMap);
                            System.debug('Llego al método.');
                            TGS_NEOrderItemMethods.cleaner_OrderItemPriceFields(Trigger.new);
                            System.debug('Salgo del método.');
                            //AFD Llamada a fillTaxFreePrices comentada, el método no existe.
                            //TGS_NEOrderItemMethods.fillTaxFreePrices(Trigger.new, Trigger.oldMap);
                        }
                        if (BI){
                            BI_O4_OrderItemMethods.setTotalPriceAndCost(Trigger.new, Trigger.oldMap);
                            BI_NEOrderItemMethods.fillParentQty(Trigger.new, Trigger.oldMap, Trigger.isBefore); //JEG 11/10/2017
                        }
                    }
                }
                }
            }
            if(trigger.isDelete){
				//Donde aparece por primera vez
				Map<Id,NE__Order__c> listOfOrderToUpd = new Map<Id,NE__Order__c>();
				if(BI){
	                CPQ_NEOrderItemMethods.updateOrderEconomicDataCPQ(null, trigger.old); //Added by Pablo de Andrés 24/06/2019
    	            CPQ_NEOrderItemMethods.replicateOptyFromCPQQuote(null, trigger.old); //Added by Pablo de Andrés 24/06/2019
        	        CPQ_NEOrderItemMethods.updateEconomicDataFromOptyOnOIDelete(trigger.old); //Added by Pablo de Andrés 11/07/2019
            	    CPQ_NEOrderItemMethods.updateNumberOfLinesOptyOrCPQQuote(null, trigger.old,listOfOrderToUpd); //Added by Pablo de Andrés 11/07/2019
				}
				BI_NEOrderItemMethods.updateOrderAndOrder(listOfOrderToUpd, new List<Opportunity>());
            }
        }
        /******* END NESetDefaultOIFields.trigger *******/
    }
}