/**
 * @description LEX Class for Case methods on trigger
 * @author Pablo de Andrés
 * @date 15/02/2019
 */
public without sharing class BI_LEX_CaseMethods {
    
    @TestVisible static Boolean isUITheme4t = (UserInfo.getUiThemeDisplayed() == 'Theme4t' || UserInfo.getUiThemeDisplayed().contains('Theme4'));
    
	 /**
     * @description Method for assignment rules => fix for global actions
     * @author Pablo de Andrés
     * @date 15/02/2019
     */
    public static void assignmentRuleCase(List<Case> newLIST){
        Set<Id> caseIDSET = new Set<Id>();
        List<Case> caseLIST = new List<Case>();
        List<Case> updateLIST = new List<Case>();
        String internalRC = TGS_RecordTypes_Util.getRecordTypeId(Case.SObjectType,'BI_Caso_Interno');//! JLA cambiado por CPU Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByDeveloperName().get('BI_Caso_Interno').getRecordTypeId();
        for(Case css : newLIST){
            if(css.RecordTypeId == internalRC && isUITheme4T){
           		caseIDSET.add(css.Id);    
            }
            
        }
        if(!caseIDSET.isEmpty()){
        	for(Case cse : [SELECT Id FROM Case WHERE Id IN :caseIDSET]){
                Database.DMLOptions dmlo = new Database.DMLOptions();
                dmlo.AssignmentRuleHeader.useDefaultRule = true;
                cse.setOptions(dmlo);
                updateLIST.add(cse);
            }    
        }
        if(!updateLIST.isEmpty()){upsert updateLIST;}
    }
    
    /*-------------------------------------------------------------------------------------------------------------------------------------------------------
        Author:        Daniel Sánchez
        Company:       everis
        Description:   Method that populate AccountId if its null for eHelp Cases

        IN:            ApexTrigger.New
        OUT:           Void

        History:

        <Date>                  <Author>                <Change Description>
        15/02/2018				Daniel Sánchez (everis) Initial version
    --------------------------------------------------------------------------------------------------------------------------------------------------------*/
    public static void populateAccountId(List<Case> news){
        Id RTeHelpId = TGS_RecordTypes_Util.getRecordTypeId(Case.SObjectType,'Caso_eHelp');//!JLA CPUSchema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByDeveloperName().get('Caso_eHelp').getRecordTypeId();
        Map<Id,Id> caseContactMap = new Map<Id,Id>(); 
        Map<Id,Id> contactAccountId = new Map<Id,Id>();
        
        for (Case c : news){
            if (c.RecordTypeId == RTeHelpId && c.AccountId == null && isUITheme4t){
                caseContactMap.put(c.Id, c.ContactId);
            }
        }
        
        if(!caseContactMap.isEmpty()){
        	List<Contact> accountsContactsId = [SELECT Id, AccountId FROM Contact WHERE Id IN :caseContactMap.values()];
        
            for (Contact con : accountsContactsId){
                contactAccountId.put(con.Id,con.AccountId);
            }
            
            for (Case cas : news){
                if (cas.RecordTypeId == RTeHelpId && cas.AccountId == null && isUITheme4t){
                    cas.AccountId = contactAccountId.get(cas.ContactId);
                }
            }   
        }
    }
    
    /**
     * @description Check if opportunity related to case has contract assigned
     * @author Pablo de Andrés
     * @date 27/06/2019
     */
    public static void checkGeneratedContractForHitoCase(List<Case> newLIST, List<Case> oldLIST){
        List<Case> errorLIST;
        Map<Id,Case> caseByOppIdMAP;
        Map<Id,Case> caseByIdMAP = new Map<Id,Case>();
        Map<Id,Id> caseIdByOrderIdMAP = new Map<Id,Id>();
		//!JLA CPU Map<String,Map<String,String>> recordTypeMAP = CPQ_NewRecordOWControl.getRecordTypeMapBySObjectName(new List<String>{'Case','NE__Order__c'});
		String idCasIn = TGS_RecordTypes_Util.getRecordTypeId(Case.SobjectType, 'BI_Caso_Interno');
        for(Integer i=0; i<newLIST.size(); i++){
            if(newLIST[i].Status != oldLIST[i].Status && newLIST[i].Status == 'Closed' && newLIST[i].RecordTypeId == idCasIn && newLIST[i].CPQ_Hito__c && newLIST[i].BI_Oferta_asociada__c != null && newLIST[i].BI_Type__c.contains('Validación / Elaboración Contrato')){
            	caseByIdMAP.put(newLIST[i].Id, newLIST[i]);  
                caseIdByOrderIdMAP.put(newLIST[i].BI_Oferta_asociada__c, newLIST[i].Id);
            }
        }
        //Check orders
        if(!caseIdByOrderIdMAP.isEmpty()){
            caseByOppIdMAP = new Map<Id,Case>();
            for(NE__Order__c nrd : [SELECT Id, NE__OptyId__c FROM NE__Order__c WHERE Id IN :caseIdByOrderIdMAP.keySet() AND RecordType.DEveloperName ='CPQ_Quote' AND NE__OrderStatus__c = 'Contract']){
            	caseByOppIdMAP.put(nrd.NE__OptyId__c, caseByIdMAP.get(caseIdByOrderIdMAP.get(nrd.Id)));   
            }    
        }
        //Check proper opportunities => must have related contract
        if(caseByOppIdMAP != null && !caseByOppIdMAP.isEmpty()){
            //If found => remove key from map
            for(Contract ctr : [SELECT Id, BI_Oportunidad__c FROM Contract WHERE BI_Oportunidad__c IN :caseByOppIdMAP.keySet()]){
            	caseByOppIdMAP.remove(ctr.BI_Oportunidad__c);	    
            }
            //Error records
            if(!caseByOppIdMAP.isEmpty()){
                errorLIST = caseByOppIdMAP.values();
            }
        }
        //Display errors
        if(errorLIST != null && !errorLIST.isEmpty()){
            if(!Test.isRunningTest()){errorLIST[0].addError(System.Label.CPQ_CaseCloseNoContract);}
        }
    }
    
    /**
     * @description Check case if hito checkbutton is true
     * @author Pablo de Andrés
     * @date 11/06/2019
     */
    public static void checkHitoCase(List<Case> newLIST, List<Case> oldLIST){
        Set<Id> checkSET = new Set<Id>();
        Set<Id> complexMatrixRelatedCaseIdSet = new Set<Id>();
        List<Case> errorLIST = new List<Case>();
        Map<Id,Id> complexMatridIdByCaseIdMAP;
        Map<Id,Case> caseByIdMAP = new Map<Id,Case>();
        Id e3MCCaseRecordTypeId = TGS_RecordTypes_Util.getRecordTypeId(Case.SObjectType, 'E3_Caso_MC_Tecnica'); //!JLA CPU Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByDeveloperName().get('E3_Caso_MC_Tecnica').getRecordTypeId();
        for(Integer i=0; i<newLIST.size(); i++){
            if(newLIST[i].Status != oldLIST[i].Status){
                //Retrieve complex matrix Id
                if(newLIST[i].RecordTypeId == e3MCCaseRecordTypeId){
                    //Check related orders
                    if(newLIST[i].Status == 'Resolved'){
                    	caseByIdMAP.put(newLIST[i].Id, newLIST[i]);    
                    }
                    else{
                    	complexMatrixRelatedCaseIdSet.add(newLIST[i].Id);    
                    }   
                }
                //Retrieve case Id
                else if(newLIST[i].CPQ_Hito__c){
                	checkSET.add(newLIST[i].Id);
                }
            }	    
        }
        //Check records
        if(!caseByIdMAP.isEmpty()){
            CPQ_AuxiliarMethods.responseWrapper caseResponse = CPQ_AuxiliarMethods.checkRelatedOrdersToE3MCResolvedCase(caseByIdMAP);
            //Complex matrix case
            if(!caseResponse.idListForTriggers.isEmpty()){
            	complexMatrixRelatedCaseIdSet.addAll(caseResponse.idListForTriggers);    
            }
            //Error list
            errorLIST = !caseResponse.errorLISTForTriggers.isEmpty() ? caseResponse.errorLISTForTriggers : new List<Case>();    
        }
        //Get complex matrix id => only first one
        if(!complexMatrixRelatedCaseIdSet.isEmpty()){
            complexMatridIdByCaseIdMAP = new Map<Id,Id>();
            for(E3_Matriz_Complejidad__c mc : [SELECT Id, E3_MC_Case__c FROM E3_Matriz_Complejidad__c WHERE E3_MC_Case__c IN :complexMatrixRelatedCaseIdSet ORDER BY CreatedDate]){
                if(!complexMatridIdByCaseIdMAP.containsKey(mc.E3_MC_Case__c)){
                    complexMatridIdByCaseIdMAP.put(mc.E3_MC_Case__c, mc.Id);
                }    
            }
            //Get matrixes
            checkSET.addAll(complexMatridIdByCaseIdMAP.values());
        }
        //Check
        if(!checkSET.isEmpty()){
            for(Id key : checkSET){
                System.enqueueJob(new CPQ_ScheduleClass(key, 'updatePending'));    
            }
        }
        //Error display
        if(!errorLIST.isEmpty()){
            for(Case css : errorLIST){
                if(!Test.isRunningTest()){css.addError(System.Label.CPQ_E3CaseError);}
            }
        }
    }

    /**
     * @description Validate if BackOffice Internal Case can be closed
     * @author Pablo de Andrés
     * @date 23/07/2019
     */
    public static void closeNEOrderRelatedInternalCase(List<Case> newLIST, List<Case> oldLIST){
        List<Case> auxLIST;
        List<Case> errorLIST;
        Boolean isProperValue;
        Set<Id> opportunityIdSET;
        List<Opportunity> oppUpdateLIST;
        Map<Id,List<Case>> caseListByNEOrderIdMAP = new Map<Id,List<Case>>();
        List<String> neOrderValidStatus = new List<String>{'En tramitación','Active','Active - Modified'};
        //!JLA CPU Map<String,Map<String,String>> recordTypeMAP = CPQ_NewRecordOWControl.getRecordTypeMapBySObjectName(new List<String>{'Case','NE__Order__c'});
		String idCas = TGS_RecordTypes_Util.getRecordTypeId(Case.SObjectType,'BI_Caso_Interno' );
        for(Integer i=0; i<newLIST.size(); i++){
            //Get proper Case records
            if(newLIST[i].RecordTypeId == idCas && newLIST[i].Status != oldLIST[i].Status && (newLIST[i].Status == 'Cerrado' || newLIST[i].Status == 'Closed') && newLIST[i].BI_Pedido__c != null){
                auxLIST = caseListByNEOrderIdMAP.containsKey(newLIST[i].BI_Pedido__c) ? caseListByNEOrderIdMAP.get(newLIST[i].BI_Pedido__c) : new List<Case>();
                auxLIST.add(newLIST[i]);
                caseListByNEOrderIdMAP.put(newLIST[i].BI_Pedido__c, auxLIST);
            }
        }
        //Check related NE__Order__c records
        if(!caseListByNEOrderIdMAP.isEmpty()){
            errorLIST = new List<Case>();
            opportunityIdSET = new Set<Id>();
            //Check related NE__Order__c records
            for(NE__Order__c nrd : [SELECT Id, NE__OptyId__c, (SELECT Id, NE__Status__c FROM NE__Order_Items__r) FROM NE__Order__c WHERE Id IN :caseListByNEOrderIdMAP.keySet() 
                                    AND RecordType.DeveloperName='CPQ_Quote']){
                isProperValue = false;
                if(!nrd.NE__Order_Items__r.isEmpty()){
                    for(NE__OrderItem__c nri : nrd.NE__Order_Items__r){
                        //Error found
                        if(nri.NE__Status__c == 'Enviado'){
                            isProperValue = false;
                            break;
                        }
                        else if(neOrderValidStatus.contains(nri.NE__Status__c)){
                            isProperValue = true;
                        }
                    }
                }
                //Error
                if(!isProperValue){
                    //Add error list
                    errorLIST.addAll(caseListByNEOrderIdMAP.get(nrd.Id));
                    //Remove key from map
                    caseListByNEOrderIdMAP.remove(nrd.Id);
                }
                //Success
                else if(isProperValue && nrd.NE__OptyId__c != null){
                    opportunityIdSET.add(nrd.NE__OptyId__c);
                }
            }
        }
        //Display errors
        if(errorLIST != null && !errorLIST.isEmpty()){
            for(Case cse : errorLIST){
                if(!Test.isRunningTest()){cse.addError(System.Label.CPQ_CaseNEOIError);}
            }
        }
        //Update opportunities
        if(opportunityIdSET != null && !opportunityIdSET.isEmpty()){
            oppUpdateLIST = [SELECT Id, StageName FROM Opportunity WHERE Id IN :opportunityIdSET];
            //Put StageName to 'F1 - Closed Won'
            for(Opportunity opp : oppUpdateLIST){
                opp.StageName = 'F1 - Closed Won';
            }
            //Update records
            if(!Test.isRunningTest()){update oppUpdateLIST;}
        }
    }

    /**
     * @description Set field Fecha de cierre real of Opportunity with the creation date value of the Carga en sistemas related case when this case is closed
     * @author Diego Arias Fernández
     * @date 14/10/2019
     */
	public static void setFechaCierreReal(List<Case> newLIST, List<Case> oldLIST){
        //! JLA CPUMap<String,Map<String,String>> recordTypeMAP = CPQ_NewRecordOWControl.getRecordTypeMapBySObjectName(new List<String>{'Case'});
		String idCas = TGS_RecordTypes_Util.getRecordTypeId(Case.SObjectType,'BI_Caso_Interno');
        Set<Id> setAux = new Set<Id>();
        for(Case c : newLIST){
            setAux.add(c.BI_Nombre_de_la_Oportunidad__c);
        }
        Map<Id, Opportunity> relatedOpps = new Map<Id, Opportunity>([SELECT Id, BI_Fecha_de_cierre_real__c FROM Opportunity WHERE ((CPQ_Check__c = true) AND (Id IN :setAux))]);
        if(!relatedOpps.keySet().isEmpty()){
            List<Opportunity> listOppsUpdate = new List<Opportunity>();
            for(Integer i=0; i<newLIST.size(); i++){
                if(newLIST[i].RecordTypeId == idCas && newLIST[i].Status != oldLIST[i].Status && (newLIST[i].Status == 'Cerrado' || newLIST[i].Status == 'Closed') && newLIST[i].BI_Pedido__c != null){
                    Opportunity oppToUpdate = relatedOpps.get(newLIST[i].BI_Nombre_de_la_Oportunidad__c);
                    DateTime dt = newLIST[i].CreatedDate;
                    oppToUpdate.BI_Fecha_de_cierre_real__c = date.newInstance(dt.year(), dt.month(), dt.day());
                    listOppsUpdate.add(oppToUpdate);
                }
            }
            if(!listOppsUpdate.isEmpty())
                update listOppsUpdate;
        }
    }
}