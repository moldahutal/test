/**
 * @description Controller class for BI_LEX_GenericApprovalAction LC
 * @author Pablo de Andrés
 * @date 25/03/2019
 */
public with sharing class BI_LEX_GenericApprovalActionControl{
    //SObjectType from recordId pass as parameter
    public static String sObjectName;
    //RecordType for Approval action
    public static String approvalActionRCDevName;
    //Set od id's for action that need to be done
    public static Set<Id> actionPendingSET;
    //Boolean value set
    public static Set<String> booleanSET = new Set<String>{'true','false'};
    //SObject List for current record
    public static List<SObject> sObjectLIST; 
    //Permission set list
    public static List<String> permissionSetLIST;
    //Action where map
    public static Map<String,String> paramMAP;
    //History action map
    public static Map<Integer,String> historyMAP;
    //Approval processes map
    public static Map<String,String> approvalProcessMAP;
    //History status map by header and action
    public static Map<Id,Map<Id,String>> historyStatusMAP;
    //Header color by header Id
    public static Map<Id,String> headerColorByHeaderIdMAP;
    //Field param step map
    public static Map<Id, List<BI_LEX_Condition__c>> fieldParamStepMAP;
    //Condition step map
    public static Map<Id, List<BI_LEX_Condition__c>> conditionStepMAP;
    //Aura component params step map
    public static Map<Id, List<BI_LEX_Condition__c>> auraParamStepMAP;
    //Pending header check map
    public static Map<Id, List<BI_LEX_Condition__c>> pendingCheckMAP;
    //Child header action steps map by parent header Id
    public static Map<Id, List<BI_LEX_ApprovalActions__c>> actionByHeaderMAP;

    /**
     * @description New version of init controller based on recent changes
     * @author Pablo de Andrés
     * @date 26/04/2019
     */
    @AuraEnabled
    public static BI_LEX_GenericApprovalActionControl.response retrieveActions(String recordId){
        String approvalProcessLoopStatus;
        Map<Id,String> approvalHeaderForReprocessMap = new Map<Id,String>();
        BI_LEX_GenericApprovalActionControl.response result = new BI_LEX_GenericApprovalActionControl.response();
        sObjectName = Id.valueOf(recordId).getSObjectType().getDescribe().getName();
        //Retrieve approval process map
        approvalProcessMAP = BI_LEX_GenericApprovalActionControl.getApprovalProcessStatusByDeveloperNameMAP(recordId);
        //Retrieve child header action steps
        List<BI_LEX_ApprovalActions__c> actionLIST = [SELECT Id, BI_LEX_ActionHeader__c, BI_LEX_ConditionsLogic__c, (SELECT Id, BI_LEX_FieldAPIName__c, BI_LEX_FieldValue__c, BI_LEX_Numero_condicion__c, 
                                                      BI_LEX_ConditionOperator__c, CPQ_Parametros_Clase_APEX__c, CurrencyIsoCode FROM Condiciones__r) FROM BI_LEX_ApprovalActions__c WHERE RecordType.DeveloperName = 'BI_LEX_ParentHeaderValidation' ORDER BY BI_LEX_Order__c];
        //Retrieve action steps by header map
        actionByHeaderMAP = new Map<Id,List<BI_LEX_ApprovalActions__c>>();
        if(!actionLIST.isEmpty()){
            for(BI_LEX_ApprovalActions__c apr : actionLIST){
                List<BI_LEX_ApprovalActions__c> auxActLIST = actionByHeaderMAP.containsKey(apr.BI_LEX_ActionHeader__c) ? actionByHeaderMAP.get(apr.BI_LEX_ActionHeader__c) : new List<BI_LEX_ApprovalActions__c>();
                auxActLIST.add(apr);
                actionByHeaderMAP.put(apr.BI_LEX_ActionHeader__c, auxActLIST);
            }
        }
        //Retrieve conditions for action steps
        List<BI_LEX_Condition__c> stepConditionLIST = [SELECT Id, Name, BI_LEX_FieldAPIName__c, BI_LEX_FieldValue__c, BI_LEX_ApprovalAction__c, BI_LEX_Numero_condicion__c, BI_LEX_FieldReferenceValue__c, CPQ_ReadOnlyField__c,
                                                       BI_LEX_ConditionOperator__c, BI_LEX_ApexMethod__c, BI_LEX_ValidationType__c, BI_LEX_PreViewCheck__c, RecordTypeId, CPQ_Parametros_Clase_APEX__c, CurrencyIsoCode 
                                                       FROM BI_LEX_Condition__c WHERE BI_LEX_ApprovalAction__c != null ORDER BY BI_LEX_Numero_condicion__c];
        //Retrieve step contidions maps
    	fieldParamStepMAP = new Map<Id,List<BI_LEX_Condition__c>>();
        conditionStepMAP = new Map<Id,List<BI_LEX_Condition__c>>();
        auraParamStepMAP = new Map<Id,List<BI_LEX_Condition__c>>();
        pendingCheckMAP = new Map<Id,List<BI_LEX_Condition__c>>();
        if(!stepConditionLIST.isEmpty()){
            String conditionRC;
            //JLA improove
            Map<Id,Schema.RecordTypeInfo> mp_rts = Schema.SObjectType.BI_LEX_Condition__c.getRecordTypeInfosById();
            for(BI_LEX_Condition__c cn : stepConditionLIST){
                List<BI_LEX_Condition__c> auxLIST;
                conditionRC = mp_rts.get(cn.RecordTypeId).getDeveloperName();
                //Fill corresponding map
                switch on conditionRC{
                    when 'BI_LEX_Condition'{
                        //JLA improve performance
                        auxLIST =conditionStepMAP.get(cn.BI_LEX_ApprovalAction__c);
                        if(auxLIST==null){
                            auxLIST  = new List<BI_LEX_Condition__c>();
                            conditionStepMAP.put(cn.BI_LEX_ApprovalAction__c, auxLIST);
                        }
                        auxLIST.add(cn);
                        /*auxLIST = conditionStepMAP.containsKey(cn.BI_LEX_ApprovalAction__c) ? conditionStepMAP.get(cn.BI_LEX_ApprovalAction__c) : new List<BI_LEX_Condition__c>();
                		auxLIST.add(cn);
                		conditionStepMAP.put(cn.BI_LEX_ApprovalAction__c, auxLIST);*/
                    }
                    when 'BI_LEX_FieldParam'{
                        auxLIST =fieldParamStepMAP.get(cn.BI_LEX_ApprovalAction__c);
                        if(auxLIST==null){
                            auxLIST  = new List<BI_LEX_Condition__c>();
                            fieldParamStepMAP.put(cn.BI_LEX_ApprovalAction__c, auxLIST);
                        }
                        auxLIST.add(cn);
                        /*auxLIST = fieldParamStepMAP.containsKey(cn.BI_LEX_ApprovalAction__c) ? fieldParamStepMAP.get(cn.BI_LEX_ApprovalAction__c) : new List<BI_LEX_Condition__c>();
                		auxLIST.add(cn);
                		fieldParamStepMAP.put(cn.BI_LEX_ApprovalAction__c, auxLIST);*/
                    }
                    when 'BI_LEX_AuraArgument'{
                        auxLIST =auraParamStepMAP.get(cn.BI_LEX_ApprovalAction__c);
                        if(auxLIST==null){
                            auxLIST  = new List<BI_LEX_Condition__c>();
                            auraParamStepMAP.put(cn.BI_LEX_ApprovalAction__c, auxLIST);
                        }
                        auxLIST.add(cn);
                        /*auxLIST = auraParamStepMAP.containsKey(cn.BI_LEX_ApprovalAction__c) ? auraParamStepMAP.get(cn.BI_LEX_ApprovalAction__c) : new List<BI_LEX_Condition__c>();
                		auxLIST.add(cn);
                		auraParamStepMAP.put(cn.BI_LEX_ApprovalAction__c, auxLIST);*/
                    }
                    when 'BI_LEX_PendingValidation'{
                        auxLIST =pendingCheckMAP.get(cn.BI_LEX_ApprovalAction__c);
                        if(auxLIST==null){
                            auxLIST  = new List<BI_LEX_Condition__c>();
                            pendingCheckMAP.put(cn.BI_LEX_ApprovalAction__c, auxLIST);
                        }
                        auxLIST.add(cn);
                        /*auxLIST = pendingCheckMAP.containsKey(cn.BI_LEX_ApprovalAction__c) ? pendingCheckMAP.get(cn.BI_LEX_ApprovalAction__c) : new List<BI_LEX_Condition__c>();
                        auxLIST.add(cn);
                        pendingCheckMAP.put(cn.BI_LEX_ApprovalAction__c, auxLIST);*/
                    }
                }
            }
        }
        //Record access wrapper
        BI_LEX_GenericApprovalActionControl.recordAccessWrapper recordAccessWrapper = BI_LEX_GenericApprovalActionControl.checkIfUserIsAllowedForHeaderManagement(recordId);
        //Retrieve all actions info
        List<BI_LEX_ApprovalActionHeader__c> allheaderLIST = [SELECT Id, Name, BI_LEX_ErrorMessage__c, BI_LEX_Tooltip__c, BI_LEX_Order__c, BI_LEX_Type__c, BI_LEX_APISegment__c, BI_LEX_AllowedPerrmissionSets__c,
                                                             BI_LEX_SObjectRecordTypeDevName__c, BI_LEX_Country__c, BI_LEX_Segment__c, BI_LEX_APICountry__c, BI_LEX_Parent_action__c, BI_LEX_PreViewCheck__c,
                                                             BI_LEX_APINameParentHeaderRelation__c, (SELECT Id FROM BI_LEX_Parent_action__r),
                                                             (SELECT Id, Name, RecordTypeId, BI_LEX_Order__c, BI_LEX_ErrorMessage__c, BI_LEX_FieldRelation__c, BI_LEX_LightningComponentAPIName__c, BI_LEX_SObjectAPINameCreate__c, 
                                                             BI_LEX_RecordTypeAPIDevCreate__c, BI_LEX_ApprovalProcessNameReference__c, BI_LEX_ManualApprover__c, BI_LEX_ApexMethod__c, BI_LEX_ConditionsLogic__c, BI_LEX_ConditionsLogicError__c FROM Acciones_de_aprobaci_n__r ORDER BY BI_LEX_Order__c), 
                                                             (SELECT Id, BI_LEX_ApprovalAction__c, BI_LEX_ActionHeader__c, BI_LEX_HistoryStatus__c, BI_LEX_Reevaluate__c FROM Historial_de_acciones__r WHERE RecordTypeId = :Schema.SObjectType.BI_LEX_ActionHistory__c.getRecordTypeInfosByDeveloperName().get('BI_LEX_Hito').getRecordTypeId() AND BI_LEX_RelatedRecordId__c =:recordId  ORDER BY LastModifiedDate DESC)
                                                             FROM BI_LEX_ApprovalActionHeader__c WHERE BI_LEX_SObjectAPIName__c = :sObjectName AND BI_LEX_Active__c = true ORDER BY BI_LEX_Order__c];
        //Headers found
        if(!allheaderLIST.isEmpty()){
            result.actionHeaderLIST = new List<BI_LEX_GenericApprovalActionControl.actionHeader>();
            //First record for APISegment and APICountry values
            BI_LEX_ApprovalActionHeader__c headercheck = allheaderLIST[0];
        	//Retrieve record info
        	String query = 'SELECT Id, RecordTypeId, RecordType.DeveloperName';
            query += headercheck.BI_LEX_APICountry__c != null ? ', ' + headercheck.BI_LEX_APICountry__c : '';
            query += headercheck.BI_LEX_APISegment__c != null ? ', ' + headercheck.BI_LEX_APISegment__c : '';
            query += ' FROM ' + sObjectName + ' WHERE Id = :recordId';
            sObjectLIST = Database.query(query);
        	//sObjectLIST = Database.query('SELECT Id, RecordTypeId, RecordType.DeveloperName,' + headercheck.BI_LEX_APICountry__c  + ', ' + headercheck.BI_LEX_APISegment__c + ' FROM ' + sObjectName + ' WHERE Id = :recordId'); 
            result.currentRecord = sObjectLIST[0];
            //Check if cancelled or closed conditions are on
            result.isClosed = BI_LEX_GenericApprovalActionControl.checkCancelledOrClosedRecord(recordId, String.valueOf(sObjectLIST[0].get('RecordTypeId')));
            //Get values for headers checking
            paramMAP = BI_LEX_GenericApprovalActionControl.getRecordValuesForHeaderCheck(result.currentRecord, headercheck.BI_LEX_APISegment__c, headercheck.BI_LEX_APICountry__c);
            //For colorClass and displays
            Boolean stopColorAndButtonDisplayCheck = false;
            //For action header display validation
            Boolean checkCondition;
            //Retrieve headers info
            for(Integer i=0; i<allheaderLIST.size();i++){
                BI_LEX_ApprovalActionHeader__c ah = allheaderLIST[i];
          		//Include only valid ones filtering by RecordType.DeveloperName, Country and Segment [if segment or country are not filled don't check them]
          		checkCondition = ah.BI_LEX_SObjectRecordTypeDevName__c != null ? (ah.BI_LEX_SObjectRecordTypeDevName__c == paramMAP.get('RecordTypeDeveloperName')) : true;
                checkCondition = paramMAP.get('Country') != null ? (checkCondition && ah.BI_LEX_Country__c == paramMAP.get('Country')) : checkCondition;
                checkCondition = paramMAP.get('Segment') != null ? (checkCondition && ah.BI_LEX_Segment__c == paramMAP.get('Segment')) : checkCondition;
                if(checkCondition){
                	BI_LEX_GenericApprovalActionControl.actionHeader ahr = new BI_LEX_GenericApprovalActionControl.actionHeader();   
                    //Allowed user check
                    ahr.allowedUser = BI_LEX_GenericApprovalActionControl.isHeaderAllowedForUser(recordAccessWrapper, ah.BI_LEX_AllowedPerrmissionSets__c);
                    ahr.name = ah.Name;
                	ahr.referenceId = ah.Id;
                	ahr.order = String.valueOf(ah.BI_LEX_Order__c);
                	ahr.tooltip = ah.BI_LEX_Tooltip__c;
                	ahr.message = ah.BI_LEX_ErrorMessage__c;
                	ahr.parentAction = ah.BI_LEX_Parent_action__c;
                    ahr.parentHeaderRelationField = ah.BI_LEX_APINameParentHeaderRelation__c != null ? ah.BI_LEX_APINameParentHeaderRelation__c : null;
                    ahr.previewConditions = ah.BI_LEX_PreViewCheck__c;
                    ahr.isParent = !ah.BI_LEX_Parent_action__r.isEmpty();
                	//ahr.conditionLIST = !ah.Condiciones__r.isEmpty() ? ah.Condiciones__r : null;
                    //Color class and displays
                    if(!ah.Historial_de_acciones__r.isEmpty() && !stopColorAndButtonDisplayCheck){
                    	BI_LEX_ActionHistory__c hs = ah.Historial_de_acciones__r[0];
                        if(!stopColorAndButtonDisplayCheck){
                        	switch on hs.BI_LEX_HistoryStatus__c{
                                when 'OK'{
                                    ahr.colorClass = 'blueCode';
                                    ahr.colorTooltip = Label.CPQ_TooltipOk;
                                }
                                when 'NOT OK'{
                                    ahr.colorClass = 'orangeCode'; 
                                    ahr.colorTooltip = Label.CPQ_TooltipNotOk;
                                    stopColorAndButtonDisplayCheck = true;
                                }
                                when 'APPROVED'{
                                    ahr.colorClass = 'greenCode';  
                                    ahr.colorTooltip = Label.CPQ_TooltipApproved;
                                }
                                when 'REJECTED'{
                                    ahr.colorClass = 'redCode'; 
                                    ahr.colorTooltip = Label.CPQ_TooltipRejected;
                                    stopColorAndButtonDisplayCheck = true;
                                }
                                when 'PENDING'{
                                    ahr.colorClass = 'warningCode';
                                    ahr.colorTooltip = Label.CPQ_TooltipPending;
                                    stopColorAndButtonDisplayCheck = true;
                                }
                                when 'NONE'{
                                    ahr.colorClass = 'grayCode';
                                    stopColorAndButtonDisplayCheck = true;
                                }
                            }    
                        }
                        else{
                        	ahr.colorClass = 'grayCode';    
                        }
                        ahr.allowReevaluate = hs.BI_LEX_Reevaluate__c;
                    }
                    else{
                        ahr.allowReevaluate = false;
                    	ahr.colorClass = 'grayCode';    
                    }
                    ahr.displayButton = ((ahr.colorClass == 'redCode' || ahr.colorClass == 'orangeCode') && ah.BI_LEX_Parent_action__r.isEmpty()) ? true : false;
                    //Set header actions
                    if(!ah.Acciones_de_aprobaci_n__r.isEmpty()){
                    	ahr.actionHeaderStepLIST = new List<BI_LEX_GenericApprovalActionControl.actionHeaderStep>();
                    	ahr.actionHeaderPreStepLIST = new List<BI_LEX_GenericApprovalActionControl.actionHeaderStep>();
                        //JLA performance 
                        Map<Id,Schema.RecordTypeInfo> mp_rtAA  =Schema.SObjectType.BI_LEX_ApprovalActions__c.getRecordTypeInfosById();
                        for(BI_LEX_ApprovalActions__c aa : ah.Acciones_de_aprobaci_n__r){
                            approvalActionRCDevName = mp_rtAA.get(aa.RecordTypeId).getDeveloperName();
                            //JLA perfrmance approvalActionRCDevName = Schema.getGlobalDescribe().get('BI_LEX_ApprovalActions__c').getDescribe().getRecordTypeInfosById().get(aa.RecordTypeId).getDeveloperName();
                            System.debug('****rct: ' + ahr.name + ' --- ' + approvalActionRCDevName);
                            BI_LEX_GenericApprovalActionControl.actionHeaderStep ahs = new BI_LEX_GenericApprovalActionControl.actionHeaderStep();
                            ahs.name = aa.Name;
                            ahs.referenceId = aa.Id;
                            ahs.message = aa.BI_LEX_ErrorMessage__c;
                            //Set attributes
                            ahs.actionHeaderStepAttributeLIST = new BI_LEX_GenericApprovalActionControl.actionHeaderStepAttribute();
                            ahs.actionHeaderStepAttributeLIST.logicConditions = aa.BI_LEX_ConditionsLogic__c;
                            ahs.actionHeaderStepAttributeLIST.logicConditionsError = aa.BI_LEX_ConditionsLogicError__c;
                            ahs.actionHeaderStepAttributeLIST.auraparamLIST = auraParamStepMAP.containsKey(aa.Id) ? auraParamStepMAP.get(aa.Id) : null;
                            ahs.actionHeaderStepAttributeLIST.conditionLIST = (approvalActionRCDevName != 'BI_LEX_ParentHeaderValidation' && conditionStepMAP.containsKey(aa.Id)) ? conditionStepMAP.get(aa.Id) : null;
                            ahs.actionHeaderStepAttributeLIST.fieldparamLIST = fieldParamStepMAP.containsKey(aa.Id) ? fieldParamStepMAP.get(aa.Id) : null;
                            ahs.actionHeaderStepAttributeLIST.pendingcheckLIST = pendingCheckMAP.containsKey(aa.Id) ? pendingCheckMAP.get(aa.Id) : null;
                            ahs.actionHeaderStepAttributeLIST.parentHeaderCheckLIST = (approvalActionRCDevName == 'BI_LEX_ParentHeaderValidation' && conditionStepMAP.containsKey(aa.Id)) ? conditionStepMAP.get(aa.Id) : null; 
                            //ahs.actionHeaderStepAttributeLIST.apexMethod = aa.BI_LEX_ApexMethod__c;
                            ahs.actionHeaderStepAttributeLIST.sObjectName = aa.BI_LEX_SObjectAPINameCreate__c;
                            //ahs.actionHeaderStepAttributeLIST.fieldRelation = aa.BI_LEX_FieldRelation__c;
                            ahs.actionHeaderStepAttributeLIST.lightningAPIName = aa.BI_LEX_LightningComponentAPIName__c;
                            ahs.actionHeaderStepAttributeLIST.recordTypeIdCreation = (aa.BI_LEX_SObjectAPINameCreate__c != null && aa.BI_LEX_RecordTypeAPIDevCreate__c != null) ? Schema.getGlobalDescribe().get(aa.BI_LEX_SObjectAPINameCreate__c).getDescribe().getRecordTypeInfosByDeveloperName().get(aa.BI_LEX_RecordTypeAPIDevCreate__c).getRecordTypeId() : null;
                            ahs.actionHeaderStepAttributeLIST.recordTypeDevNameForCreation = aa.BI_LEX_RecordTypeAPIDevCreate__c;
                            ahs.actionHeaderStepAttributeLIST.approvalProcessNameReference = aa.BI_LEX_ApprovalProcessNameReference__c;
                            //Check if approval process exists and has value
                            if(ahr.colorClass == 'warningCode' && aa.BI_LEX_ApprovalProcessNameReference__c != null && approvalProcessMAP.containsKey(aa.BI_LEX_ApprovalProcessNameReference__c)){
                            	approvalProcessLoopStatus = approvalProcessMAP.get(aa.BI_LEX_ApprovalProcessNameReference__c).toUpperCase();
                                //Assign new color
                                ahr.colorClass = approvalProcessLoopStatus == 'APPROVED' ? 'greenCode' : (approvalProcessLoopStatus == 'REJECTED' ? 'redCode' : ahr.colorClass);
                                //Reprocess
                                if(approvalProcessLoopStatus == 'APPROVED' || approvalProcessLoopStatus == 'REJECTED'){
                                	approvalHeaderForReprocessMap.put(ahr.referenceId, approvalProcessLoopStatus);
                                }
                            }
                            ahs.actionHeaderStepAttributeLIST.manualApprovalProcess = aa.BI_LEX_ManualApprover__c;
                            ahs.actionHeaderStepAttributeLIST.updateCurrentRecord = approvalActionRCDevName == 'BI_LEX_RecordUpdate' ? true : false;
                            //Add to list [pre or post depending if it's BI_LEX_PreAction RecordType or not]
                            if(approvalActionRCDevName == 'BI_LEX_PreAction'){
                                ahr.actionHeaderPreStepLIST.add(ahs);
                            }
                            else{
                                ahr.actionHeaderStepLIST.add(ahs);   
                            }
                        }
                    }
                    //Add to list
        			result.actionHeaderLIST.add(ahr);
                }
            }
        }
        //Retrieve RecordType DeveloperName and SObject Labels for pop-up and message display
        result.recordTypeAndSObjectNameLabelMAP = BI_LEX_GenericApprovalActionControl.getRecordTypeAndSObjectLabelMAP(result.actionHeaderLIST);
        //Reprocess
        if(!approvalHeaderForReprocessMap.isEmpty()){
            List<BI_LEX_ActionHistory__c> historyUpdateLIST = new List<BI_LEX_ActionHistory__c>();
            for(BI_LEX_ActionHistory__c hst : [SELECT Id, BI_LEX_ActionHeader__c, BI_LEX_HistoryStatus__c FROM BI_LEX_ActionHistory__c WHERE RecordType.DeveloperName = 'BI_LEX_Hito' 
                                               AND BI_LEX_ActionHeader__c IN :approvalHeaderForReprocessMap.keySet() AND BI_LEX_RelatedRecordId__c = :recordId]){
            	hst.BI_LEX_HistoryStatus__c = approvalHeaderForReprocessMap.get(hst.BI_LEX_ActionHeader__c);
                historyUpdateLIST.add(hst);
            }
            update historyUpdateLIST;
        }
        return result;
    }
    
    /**
     * @description Check if record is cancelled or closed and must not reevaluate anything
     * @author Pablo de Andrés
     * @date 03/06/2019
     */
    public static Boolean checkCancelledOrClosedRecord(String recordId, String recordTypeId){
        String query;
        Boolean result = false;
        List<String> whereLIST;
        List<SObject> checkLIST;
    	String sObjectName = Id.valueOf(recordId).getSObjectType().getDescribe().getName();   
        String developerName = Schema.getGlobalDescribe().get(sObjectName).getDescribe().getRecordTypeInfosById().get(recordTypeId).getDeveloperName();
        List<CPQ_HeaderCloseConf__mdt> mdtLIST = [SELECT Id, CPQ_APIFieldName__c, CPQ_APIFieldValue__c FROM CPQ_HeaderCloseConf__mdt 
                                                  WHERE CPQ_APISObjectName__c = :sObjectName AND (CPQ_APIRecordType__c = null OR CPQ_APIRecordType__c = :developerName)];
        //Check
        if(!mdtLIST.isEmpty()){
            whereLIST = new List<String>();
            query = 'SELECT Id FROM ' + sObjectName + ' WHERE ';
            for(CPQ_HeaderCloseConf__mdt mdt : mdtLIST){
            	whereLIST.add(mdt.CPQ_APIFieldName__c + ' = ' + (mdt.CPQ_APIFieldValue__c.isNumeric() || booleanSET.contains(mdt.CPQ_APIFieldValue__c.toLowerCase()) ? mdt.CPQ_APIFieldValue__c : '\'' + mdt.CPQ_APIFieldValue__c + '\''));    
            }
            query = query + '(' + String.join(whereLIST, ' OR ') + ') AND Id =:recordId';
            System.debug('****query: ' + query);
            checkLIST = Database.query(query);
            result = !checkLIST.isEmpty();
        }
        return result;
    }

    /**
     * @description Check validity for child headers [moved to CPQ_ScheduleClass]
     * @author Pablo de Andrés
     * @date 23/05/2019
     */
	  /* --ACR Se comenta método ya que no se usa actualmente
	@AuraEnabled    
    public static String checkValidityForChildHeaders(String recordId, String childHeaderJSON){
        String query;
        String result;
        String condition;
        String relatedRecord;
        String conditionLogic = '';
        Boolean hasLogic;
        Boolean hasRecord = false;
        BI_LEX_Condition__c cn;
        List<String> auxLIST;
        List<SObject> sObjLIST;
        List<BI_LEX_ActionHistory__c> historyLIST;
        Map<String,String> conditionByNumberMAP;
        BI_LEX_GenericApprovalActionControl.childHeader childHeader = (BI_LEX_GenericApprovalActionControl.childHeader) JSON.deserialize(childHeaderJSON, BI_LEX_GenericApprovalActionControl.childHeader.class);
        //Check conditions
            if(childHeader.conditionLIST != null && !childHeader.conditionLIST.isEmpty()){
                hasLogic = childHeader.conditionsLogic != null;
                conditionByNumberMAP = new Map<String,String>();
                for(Integer i=0; i<childHeader.conditionLIST.size(); i++){
                    cn = childHeader.conditionLIST[i];
                    switch on cn.BI_LEX_ConditionOperator__c{
                    	when 'NOT NULL'{
                			condition = cn.BI_LEX_FieldAPIName__c + ' != null';	    
                        }
                        when 'IS NULL'{
                            condition = cn.BI_LEX_FieldAPIName__c + ' = null';    
                        }
                        when 'LESS THAN'{
                            condition = cn.BI_LEX_FieldAPIName__c + ' < ' + cn.BI_LEX_FieldValue__c;    
                        }
                        when 'MORE THAN'{
                            condition = cn.BI_LEX_FieldAPIName__c + ' > ' + cn.BI_LEX_FieldValue__c;      
                        }
                        when 'EQUALS'{
                            condition = cn.BI_LEX_FieldAPIName__c + ' = ' + (cn.BI_LEX_FieldValue__c.isNumeric() || booleanSET.contains(cn.BI_LEX_FieldValue__c.toLowerCase()) ? cn.BI_LEX_FieldValue__c : '\'' + cn.BI_LEX_FieldValue__c + '\'');      
                        }
                        when 'NOT EQUALS'{
                            condition = cn.BI_LEX_FieldAPIName__c + ' != ' + (cn.BI_LEX_FieldValue__c.isNumeric() || booleanSET.contains(cn.BI_LEX_FieldValue__c.toLowerCase()) ? cn.BI_LEX_FieldValue__c : '\'' + cn.BI_LEX_FieldValue__c + '\'');        
                        }    
                    }
                    conditionByNumberMAP.put(String.valueOf(hasLogic ? (Integer) cn.BI_LEX_Numero_condicion__c : i), condition);
                }
                query = 'SELECT Id FROM ' + childHeader.sObjectName + ' WHERE ' + childHeader.referenceField + ' = :recordId AND ';
                //Apply logic
                if(hasLogic){
                	auxLIST =  childHeader.conditionsLogic.split('');
                    for(String key : auxLIST){
                        //Replace condition
                        if(key.isNumeric()){
                        	key = conditionByNumberMAP.get(key);    
                        }
                        conditionLogic += key;
                    }
                    query += '(' + conditionLogic + ')';
                }
                //Default
                else{
                	query += '(' + String.join(conditionByNumberMAP.values(), ' AND ').removeEnd('AND') + ')';  
                }
                System.debug('query: ' + query);
                sObjLIST = Database.query(query);
                hasRecord = !sObjLIST.isEmpty();
            }
            //No conditions for check
            else{
            	result = 'EMPTY';       
            }
        //Related valid record found
        if(hasRecord){
            System.debug('***sObj: ' + sObjLIST[0].get('Id'));
            relatedRecord = String.valueOf(sObjLIST[0].get('Id'));
            historyLIST = [SELECT Id, BI_LEX_HistoryStatus__c FROM BI_LEX_ActionHistory__c WHERE BI_LEX_ActionHeader__c = :childHeader.referenceId AND BI_LEX_RelatedRecordId__c = :relatedRecord AND RecordType.DeveloperName = 'BI_LEX_Hito'];
            System.debug('****: ' + historyLIST);
            //History found
            if(!historyLIST.isEmpty()){
            	result = historyLIST[0].BI_LEX_HistoryStatus__c;    
            }
            //No record found
            else{
            	result = 'EMPTY';    
            }
        }
        return result;
    }
    */

    /**
     * @description Retrieves RecordType.DeveloperName, Country and Segment values for proper headers retrieve => new method for new version [NON - DEFINITIVE]
     * @author Pablo de Andrés
     * @date 26/04/2019
     */
    public static Map<String,String> getRecordValuesForHeaderCheck(SObject record, String segmentAPI, String countryAPI){
        Object countryValue;
        Object segmentValue;
        SObject countrySObjectField;
        SObject segmentSObjectField;
        List<String> countryAPISplit;
        List<String> segmentAPISplit;
        //Country value retrieve
        if(countryAPI != null){
            countryValue = CPQ_NewRecordOWControl.retrieveValueByAPIField(record, new List<String>{countryAPI}).get(countryAPI);    
        }
        //Segment value retrieve
        if(segmentAPI != null){
            segmentValue = CPQ_NewRecordOWControl.retrieveValueByAPIField(record, new List<String>{segmentAPI}).get(segmentAPI);
        }
        return new Map<String,String>{'Segment' => segmentValue != null ? String.valueOf(segmentValue) : null, 
            						  'Country' => countryValue != null ? String.valueOf(countryValue) : null,
                                      'RecordTypeDeveloperName' => String.valueOf(record.getSObject('RecordType').get('DeveloperName'))};
    }
    
    /**
     * @description Get reference values for field params
     * @author Pablo de Andrés
     * @date 20/05/2019
     */
    @AuraEnabled
    public static List<BI_LEX_GenericApprovalActionControl.recordFieldData> getFieldParamValuesByReference(String recordId, String conditionLISTJSON){
        System.debug('getFieldParamValuesByReference');
        String query;
        List<SObject> sObjLIST;
        List<String> fieldAPILIST;
        Map<String,Object> retrieveMAP;
        Map<String,String> fieldByReferenceMAP = new Map<String,String>();
        Map<String,BI_LEX_Condition__c> conditionByFieldMAP = new Map<String,BI_LEX_Condition__c>();
        Map<Integer,BI_LEX_GenericApprovalActionControl.recordFieldData> resultMAP = new Map<Integer,BI_LEX_GenericApprovalActionControl.recordFieldData>();
        List<BI_LEX_GenericApprovalActionControl.recordFieldData> resultLIST = new List<BI_LEX_GenericApprovalActionControl.recordFieldData>();
        List<BI_LEX_Condition__c> conditionLIST = (List<BI_LEX_Condition__c>) JSON.deserialize(conditionLISTJSON, List<BI_LEX_Condition__c>.class);
        //Conditions found
        if(conditionLIST != null){
            //List for required fill
            List<String> requiredLIST = new List<String>(); 
            try {

            Set<Id> setApprovalActionId = new Set<Id>();
        	for(BI_LEX_Condition__c cn : conditionLIST){
                // System.debug(cn);
                setApprovalActionId.add(cn.BI_LEX_ApprovalAction__c);
            }

            if (setApprovalActionId.size() != 1) {
                throw new BI_Exception('Solo puede haber una acción de aprobación asociada.');
            }

            List<BI_LEX_ApprovalActions__c> listaApprovalActions = [SELECT BI_LEX_RecordTypeAPIDevCreate__c, BI_LEX_SObjectAPINameCreate__c 
                FROM BI_LEX_ApprovalActions__c WHERE Id = :setApprovalActionId];

            if (listaApprovalActions != null) {
                Schema.DescribeSobjectResult[] results = Schema.describeSObjects(new String[]{listaApprovalActions[0].BI_LEX_SObjectAPINameCreate__c});
                System.debug(results[0]);
                Schema.RecordTypeInfo recordTypeInfo = results[0].getRecordTypeInfosByDeveloperName().get(listaApprovalActions[0].BI_LEX_RecordTypeAPIDevCreate__c);
                System.debug(recordTypeInfo);
                String recordTypeId = recordTypeInfo.getRecordTypeId();
                System.debug(recordTypeId);
                String body = toolingAPISOQL('SELECT Layout.Name FROM ProfileLayout WHERE TableEnumOrId = \'Case\' AND ProfileId = \'' + UserInfo.getProfileId() + '\' AND RecordTypeId = \'' + recordTypeId + '\'');

                if(body != null){
                    BI_LEX_LayoutSectionsByRecordControl.toolingResponse toolR = (BI_LEX_LayoutSectionsByRecordControl.toolingResponse) JSON.deserialize(body, BI_LEX_LayoutSectionsByRecordControl.toolingResponse.class);
                    if(!toolR.records.isEmpty() && toolR.records[0].Layout != null && toolR.records[0].Layout.attributes != null && toolR.records[0].Layout.attributes.url != null){
                        String layoutResponse = restCall(URL.getSalesforceBaseUrl().toExternalForm() + '/' + toolR.records[0].Layout.attributes.url, 'GET');
                        if(layoutResponse != null){
                            BI_LEX_LayoutSectionsByRecordControl.restResponse restR = (BI_LEX_LayoutSectionsByRecordControl.restResponse) JSON.deserialize(layoutresponse, BI_LEX_LayoutSectionsByRecordControl.restResponse.class);
                            for(BI_LEX_LayoutSectionsByRecordControl.layoutSectionResponse section : restR.Metadata.layoutSections){
                                for(BI_LEX_LayoutSectionsByRecordControl.layoutColumnResponse column : section.layoutColumns){
                                    if(column.layoutItems != null && !column.layoutItems.isEmpty()){
                                        for(Integer i=0; i<column.layoutItems.size(); i++){
                                            if(column.layoutItems[i].field != null){
                                                if(column.layoutItems[i].behavior == 'Required'){
                                                    requiredLIST.add(column.layoutItems[i].field);   	    
                                                }
                                            }    
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            } catch (Exception e) {}

        	for(BI_LEX_Condition__c cn : conditionLIST){
                //Reference values
                if(cn.BI_LEX_FieldReferenceValue__c != null){
                	fieldByReferenceMAP.put(cn.BI_LEX_FieldReferenceValue__c, cn.BI_LEX_FieldAPIName__c);   
                    conditionByFieldMAP.put(cn.BI_LEX_FieldAPIName__c, cn);
                }
                //Standard values
                else {
                    Boolean required = true;
                    if (requiredLIST.indexOf(cn.BI_LEX_FieldAPIName__c) == -1) required = false;

                    resultMAP.put((Integer)cn.BI_LEX_Numero_condicion__c, 
                        new BI_LEX_GenericApprovalActionControl.recordFieldData(cn.BI_LEX_FieldValue__c, 
                            cn.BI_LEX_FieldAPIName__c, 
                            cn.CPQ_ReadOnlyField__c, 
                            required//cn.BI_LEX_FieldValue__c != null ? false : true
                        ));
                }    
            }     
        } 
        //Check references
        if(!conditionByFieldMAP.isEmpty()){
            fieldAPILIST = new List<String>();
            for(String fa : conditionByFieldMAP.keySet()){
                fieldAPILIST.add(conditionByFieldMAP.get(fa).BI_LEX_FieldReferenceValue__c);
            }
            query = (fieldAPILIST.contains('Id') ? 'SELECT ' : 'SELECT Id, ') + String.join(fieldAPILIST, ', ').removeEnd(', ') + ' FROM ' + Id.valueOf(recordId).getSObjectType().getDescribe().getName() + ' WHERE Id = :recordId';
            sObjLIST = Database.query(query);
            retrieveMAP = CPQ_NewRecordOWControl.retrieveValueByAPIField(sObjLIST[0], fieldAPILIST);
            //Set values
            for(String key : retrieveMAP.keySet()){
                resultMAP.put((Integer)conditionByFieldMAP.get(fieldByReferenceMAP.get(key)).BI_LEX_Numero_condicion__c, new BI_LEX_GenericApprovalActionControl.recordFieldData(String.valueOf(retrieveMAP.get(key)), fieldByReferenceMAP.get(key), conditionByFieldMAP.get(fieldByReferenceMAP.get(key)).CPQ_ReadOnlyField__c, retrieveMAP.get(key) != null ? false : true));
            }  
        }
        for(Integer i=0; i<resultMAP.size(); i++){
            resultLIST.add(resultMAP.get(i+1));
        }
        return resultLIST;
    }
    
    public static String toolingAPISOQL(String query) {
        String baseURL = URL.getSalesforceBaseUrl().toExternalForm();
        return restCall(baseURL + '/services/data/v41.0/tooling/query?q='+ (query.replace(' ', '+')), 'GET');
    }
    public static String restCall(String endPoint, String method) {
        HttpResponse r;
        Http h = new Http();
        HttpRequest hr = new HttpRequest();
        String sessionId = BI_LEX_GenericUtility.getSessionIdForRestApi();
        hr.setHeader('Authorization', 'Bearer ' + sessionId);
        hr.setTimeout(60000);
        hr.setEndpoint(endPoint);
        hr.setMethod(method);
        if(Test.isRunningTest()){
        	r = new HttpResponse();
			r.setStatusCode(200);    
        }
        else{
        	r = h.send(hr);    
        }
        return r.getStatusCode() == 200 ? r.getBody() : null;
    }

    /**
     * @description Upsert header history entries
     * @author Pablo de Andrés
     * @date 29/04/2019
     */
    @AuraEnabled
    public static BI_LEX_GenericApprovalActionControl.response upsertHeaderHistoryEntries(String recordId, Map<String,String> historyStatusByHeaderIdMAP){
    	BI_LEX_GenericApprovalActionControl.response result = new BI_LEX_GenericApprovalActionControl.response(); 
        //Already checked headers
        System.debug('*****recordId upsertHeaderEntry: ' + recordId);
        System.debug('****mapkeys: ' + historyStatusByHeaderIdMAP.keySet());
        Set<Id> alreadyCheckedSET = new Set<Id>();
        //List of records to upsert
        List<BI_LEX_ActionHistory__c> upsertLIST = new List<BI_LEX_ActionHistory__c>();
        //SObjectType name from recordId
        String sObjectName = Id.valueOf(recordId).getSobjectType().getDescribe().getName();
        //BI_LEX_Hito RecordTypeId (BI_LEX_ActionHistory__c)
        Id hitoRC = Schema.getGlobalDescribe().get('BI_LEX_ActionHistory__c').getDescribe().getRecordTypeInfosByDeveloperName().get('BI_LEX_Hito').getRecordTypeId();
        //Update existing records
        for(BI_LEX_ActionHistory__c ah : [SELECT Id, BI_LEX_ActionHeader__c, BI_LEX_HistoryStatus__c FROM BI_LEX_ActionHistory__c WHERE RecordTypeId = :hitoRC AND BI_LEX_SObjectAPIName__c = :sObjectName AND BI_LEX_RelatedRecordId__c = :recordId AND BI_LEX_ActionHeader__c IN :historyStatusByHeaderIdMAP.keySet()]){
       		//Keep APPROVED status if new one is OK
            ah.BI_LEX_HistoryStatus__c = ((historyStatusByHeaderIdMAP.get(ah.BI_LEX_ActionHeader__c) == 'OK' && ah.BI_LEX_HistoryStatus__c == 'APPROVED') || (historyStatusByHeaderIdMAP.get(ah.BI_LEX_ActionHeader__c) == 'NOT OK' && ah.BI_LEX_HistoryStatus__c == 'REJECTED'))  ? ah.BI_LEX_HistoryStatus__c : historyStatusByHeaderIdMAP.get(ah.BI_LEX_ActionHeader__c);	
            upsertLIST.add(ah);
            alreadyCheckedSET.add(ah.BI_LEX_ActionHeader__c);
        }
        //Generate new records
        for(String key : historyStatusByHeaderIdMAP.keySet()){
            if(!alreadyCheckedSET.contains(key)){
                BI_LEX_ActionHistory__c ahr = new BI_LEX_ActionHistory__c(RecordTypeId = hitoRC, 
                                                                          BI_LEX_ActionHeader__c = key,
                                                                          BI_LEX_HistoryStatus__c = historyStatusByHeaderIdMAP.get(key),
                                                                          BI_LEX_SObjectAPIName__c = sObjectName, 
                                                                          BI_LEX_RelatedRecordId__c = recordId);
                upsertLIST.add(ahr);
            }
        }
        //Upsert records
        if(!upsertLIST.isEmpty()){
            try{
                upsert upsertLIST;
                result.success = true;
            }
            catch(Exception e){
                result.success = false;
                result.message = e.getMessage();
            }
        }
        return result;
    }
    
    /**
     * @description Get labels for SObjectType and RecordType infos
     * @author Pablo de Andrés
     * @date 16/04/2019
     */
    public static Map<String,String> getRecordTypeAndSObjectLabelMAP(List<BI_LEX_GenericApprovalActionControl.actionHeader> actionHeaderLIST){
        Map<String,String> result = new Map<String,String>();
        Schema.DescribeSObjectResult dsc;
        List<BI_LEX_GenericApprovalActionControl.actionHeaderStep> ahsLIST;
        if(actionHeaderLIST != null && !actionHeaderLIST.isEmpty()){
            for(BI_LEX_GenericApprovalActionControl.actionHeader ah : actionHeaderLIST){
                ahsLIST = new List<BI_LEX_GenericApprovalActionControl.actionHeaderStep>();
                //Check post actions
                if(ah.actionHeaderStepLIST != null){
                    ahsLIST.addAll(ah.actionHeaderStepLIST);
                }
                //Also check pre actions
                else if(ah.actionHeaderPreStepLIST != null){
                    ahsLIST.addAll(ah.actionHeaderPreStepLIST);
                }
                //Get labels
                if(!ahsLIST.isEmpty()){
                    for(BI_LEX_GenericApprovalActionControl.actionHeaderStep ahs : ahsLIST){
                        //SObjectType label
                        if(ahs.actionHeaderStepAttributeLIST.sObjectName != null){
                            dsc = Schema.getGlobalDescribe().get(ahs.actionHeaderStepAttributeLIST.sObjectName).getDescribe();
                            result.put(ahs.actionHeaderStepAttributeLIST.sObjectName, dsc.getLabel());
                            //RecordType label
                            if(ahs.actionHeaderStepAttributeLIST.recordTypeDevNameForCreation != null){
                                result.put(ahs.actionHeaderStepAttributeLIST.recordTypeDevNameForCreation, dsc.getRecordTypeInfosByDeveloperName().get(ahs.actionHeaderStepAttributeLIST.recordTypeDevNameForCreation).getName());
                            }
                        }
                    }	    
                }
            }
        }
        return result;
    }
    
    /**
     * @description Check if action can be launched
     * @author Pablo de Andrés
     * @date 16/04/2019
     */
    @AuraEnabled
    public static BI_LEX_GenericApprovalActionControl.response checkActionConditions(String recordId, String logicConditions, String message, String conditionLISTJSON, String apexJSON){
        BI_LEX_GenericApprovalActionControl.response result = new BI_LEX_GenericApprovalActionControl.response();
		String query;
        String auxValue;
        String auxString;
        Integer auxNumber;
        List<SObject> checkLIST;
        Boolean auxBoolean;
        List<BI_LEX_Condition__c> conditionLIST = conditionLISTJSON != null ? (List<BI_LEX_Condition__c>) JSON.deserialize(conditionLISTJSON, List<BI_LEX_Condition__c>.class) : null;
        Boolean emptyLogic = (logicConditions != null && !String.isEmpty(logicConditions)) ? false : true;
        BI_LEX_Condition__c auxCondition;
        //Map of condition result by BI_LEX_Numero_condicion__c or generic index (if logicConditions has no value)
        Map<String,Boolean> conditionByNumberMAP = new Map<String,Boolean>();
        //Get apex method results if found
        List<BI_LEX_GenericApprovalActionControl.apexMethodConditionWrapper> apexMethodLIST = apexJSON != null ? (List<BI_LEX_GenericApprovalActionControl.apexMethodConditionWrapper>) JSON.deserialize(apexJSON, List<BI_LEX_GenericApprovalActionControl.apexMethodConditionWrapper>.class) : new List<BI_LEX_GenericApprovalActionControl.apexMethodConditionWrapper>();
        if(!apexMethodLIST.isEmpty()){
          	for(Integer a=0; a<apexMethodLIST.size(); a++){
                auxNumber = (!emptyLogic && apexMethodLIST[a].record.BI_LEX_Numero_condicion__c != null) ? (Integer)apexMethodLIST[a].record.BI_LEX_Numero_condicion__c : a;
              	conditionByNumberMAP.put(String.valueOf(auxNumber), apexMethodLIST[a].success);
           	}	    
        }
        //Check record conditions individually
        if(conditionLIST != null && !conditionLIST.isEmpty()){
            query = 'SELECT Id';
            Set<String> fieldSET = new Set<String>();
            //Retrieve fields for query
            for(BI_LEX_Condition__c cd : conditionLIST){
                fieldSET.add(cd.BI_LEX_FieldAPIName__c);     
            }
            query += ', ' + String.join(new List<String>(fieldSET), ', ');
            query = (query.contains(', ') ? query.removeEnd(', ') : '') + ' FROM ' + Id.valueOf(recordId).getSObjectType().getDescribe().getName() + ' WHERE Id = :recordId';
            checkLIST = Database.query(query);
            System.debug('ACR--CheckLIST: '+checkLIST);
            //Check conditions for fields
            for(Integer cn=0; cn<conditionLIST.size();cn++){
                auxCondition = conditionLIST[cn];
                switch on auxCondition.BI_LEX_ConditionOperator__c{
                    //Equals
                    when 'EQUALS','NOT EQUALS'{
                        //Number
                        if(auxCondition.BI_LEX_FieldValue__c.isNumeric()){
                        	auxBoolean = Integer.valueOf(checkLIST[0].get(auxCondition.BI_LEX_FieldAPIName__c)) == Integer.valueOf(auxCondition.BI_LEX_FieldValue__c);    
                        }
                        //Boolean
                        else if(booleanSET.contains(auxCondition.BI_LEX_FieldValue__c)){
                          	auxBoolean = String.valueOf(checkLIST[0].get(auxCondition.BI_LEX_FieldAPIName__c.toLowerCase())) == String.valueOf(auxCondition.BI_LEX_FieldValue__c.toLowerCase());      
                        }
                        //Rest of cases
                        else{
                            System.debug('--checkLIST '+checkLIST);
                          	auxBoolean = String.valueOf(checkLIST[0].get(auxCondition.BI_LEX_FieldAPIName__c)) == String.valueOf(auxCondition.BI_LEX_FieldValue__c);   
                        }
                        auxBoolean = auxCondition.BI_LEX_ConditionOperator__c == 'EQUALS' ? auxBoolean : !auxBoolean;
                    }   
                    //Greater
                    when 'MORE THAN'{
                     	auxBoolean = checkLIST[0].get(auxCondition.BI_LEX_FieldAPIName__c) == null ? false : Integer.valueOf(checkLIST[0].get(auxCondition.BI_LEX_FieldAPIName__c)) > Integer.valueOf(auxCondition.BI_LEX_FieldValue__c);     
                    }
                    //Lesser
                    when 'LESS THAN'{
                      	auxBoolean = checkLIST[0].get(auxCondition.BI_LEX_FieldAPIName__c) == null ? true : Integer.valueOf(checkLIST[0].get(auxCondition.BI_LEX_FieldAPIName__c)) < Integer.valueOf(auxCondition.BI_LEX_FieldValue__c);    
                    }
                    //Null
                    when 'IS NULL'{
                      	auxBoolean = checkLIST[0].get(auxCondition.BI_LEX_FieldAPIName__c) == null;     
                    }
                    //Not null
                    when 'NOT NULL'{
                     	auxBoolean = checkLIST[0].get(auxCondition.BI_LEX_FieldAPIName__c) != null;    
                    }
                }
                //Add condition success to map
                auxNumber = (!emptyLogic && auxCondition.BI_LEX_Numero_condicion__c != null) ? (Integer)auxCondition.BI_LEX_Numero_condicion__c : cn;
                conditionByNumberMAP.put(String.valueOf(auxNumber), auxBoolean);
                //New wrapper record
                apexMethodLIST.add(new BI_LEX_GenericApprovalActionControl.apexMethodConditionWrapper(auxCondition, auxBoolean));
             }
        }
        //Check conditions logic
        if(!conditionByNumberMAP.isEmpty()){
            String logicAction;
            Boolean checkResult;
           	List<String> charLIST;
            //AND
            if(emptyLogic){
                for(String key : conditionByNumberMAP.keySet()){
                	checkResult = checkResult == null ? conditionByNumberMAP.get(key) : (checkResult && conditionByNumberMAP.get(key));
                }
            }
           	//Follow logic steps
            else{
             	logicConditions = logicConditions.replace(' ','').replace('AND','A').replace('OR','O').removeStart('(').removeEnd(')');
                charLIST = logicConditions.split('');
                checkResult = BI_LEX_GenericApprovalActionControl.runLogicConditions(0, charLIST, conditionByNumberMAP).result;
            }
            result.success = checkResult != null ? checkResult : false;
            result.conditionSuccessLIST = apexMethodLIST;
        }
        //No conditions to check
        else{
         	result.success = true;    
        }
        return result;
    }
    
    /**
     * @description Helper method for checkActionConditions
     * @author Pablo de Andrés
     * @date 16/05/2019
     */
    public static BI_LEX_GenericApprovalActionControl.logicConditionResult runLogicConditions(Integer index, List<String> charLIST, Map<String,Boolean> conditionByNumberMAP){
        BI_LEX_GenericApprovalActionControl.logicConditionResult response = new BI_LEX_GenericApprovalActionControl.logicConditionResult();
   		Boolean result;
        Boolean auxBoolean;
        String logicAction;
        BI_LEX_GenericApprovalActionControl.logicConditionResult sub;
        for(Integer i=index; i<charLIST.size(); i++){
        	//Sub-condition
            if(charLIST[i] == '('){
            	sub = BI_LEX_GenericApprovalActionControl.runLogicConditions(i+1, charLIST, conditionByNumberMAP);
                auxBoolean = sub.result;
                result = logicAction != null ? (logicAction == 'A' ? (result && auxBoolean) : (result || auxBoolean)) : (result != null ? result : auxBoolean);
                //New index to proceed
                index = sub.index;
            }
            //End of condition [only found if it's sub one] => break loop
            else if(charLIST[i] == ')'){
                response.index = i;
                response.result = result;
                break;
            }
            //Condition number
            else if(charLIST[i].isNumeric()){
                auxBoolean = conditionByNumberMAP.get(charLIST[i]);
                result = logicAction != null ? (logicAction == 'A' ? (result && auxBoolean) : (result || auxBoolean)) : (result != null ? result : auxBoolean);
            }
            //Get action for check
            else{
            	logicAction = charLIST[i];
            }
            response.index = i;
            response.result = result;
        }
        return response;
    }
    
    /**
     * @description Put record into approval process
     * @author Pablo de Andrés 
     * @date 16/04/2019
     */
    @AuraEnabled
    public static BI_LEX_GenericApprovalActionControl.response approvalLauncherManager(String recordId, String manualApprover){
        BI_LEX_GenericApprovalActionControl.response response = new BI_LEX_GenericApprovalActionControl.response();
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Aprobación enviada desde BI_LEX_GenericApprovalAction');
        req1.setObjectId(recordId); 
        //Manual approver
        if(manualApprover != null){
            req1.setNextApproverIds(new List<Id>{manualApprover});
        }
        Approval.ProcessResult result = Approval.process(req1);
        //If error => retrieve error message for display
        if(!result.isSuccess()){
            response.success = false;
            for(Database.Error responseError : result.getErrors()){
                response.message = 'Error: ' + responseError.getStatusCode() + ', ' + responseError.getMessage();
                if(!responseError.getFields().isEmpty()){
                    if(responseError.getFields().size() > 1){
                        Integer index = 0;
                        response.message += '. ' + Label.BI_LEX_RelatedToField + ': ';
                        for(String error : responseError.getFields()){
                            response.message += index == 0 ? error : ', ' + error;
                            index++;
                        }
                    }
                    else{
                        response.message += '. ' + Label.BI_LEX_RelatedToField + ': ' + responseError.getFields()[0];
                    }
                }
            }    
        }
        //Success
        else{
            response.success = true;
        }    
        return response;
    }
    
    /**
     * @description Generate history entry
     * @author Pablo de Andrés
     * @date 22/04/2019
     */
    @AuraEnabled
    public static BI_LEX_GenericApprovalActionControl.response generateActionHistoryEntry(SObject current, String headerAndStepInfo, String generatedRecordId){
        BI_LEX_GenericApprovalActionControl.response result = new BI_LEX_GenericApprovalActionControl.response();
        //BI_LEX_Action RecordTypeId (BI_LEX_ActionHistory__c)
        Id actionRC = Schema.getGlobalDescribe().get('BI_LEX_ActionHistory__c').getDescribe().getRecordTypeInfosByDeveloperName().get('BI_LEX_Action').getRecordTypeId();
        //Retrieve header and action Id's
        BI_LEX_GenericApprovalActionControl.headerAndStepInfo info = (BI_LEX_GenericApprovalActionControl.headerAndStepInfo) JSON.deserialize(headerAndStepInfo, BI_LEX_GenericApprovalActionControl.headerAndStepInfo.class);
        //Record to create
       	BI_LEX_ActionHistory__c history = new BI_LEX_ActionHistory__c(BI_LEX_ActionHeader__c = info.headerId,
                                                                      BI_LEX_ApprovalAction__c = info.actionId,
                                                                      BI_LEX_RelatedRecordId__c = current.Id,
                                                                      RecordTypeId = actionRC,
                                                                      BI_LEX_GeneratedRecordId__c = generatedRecordId,
                                                                      BI_LEX_SObjectAPIName__c = current.Id.getSObjectType().getDescribe().getName());
        try{
        	insert history;
            result.success = true;
        }
        catch(Exception e){
            result.success = false;
            result.message = e.getMessage();
        }
        return result;
    }
    
    /**
     * @description Testing for task creation
     * @author Pablo de Andrés
     * @date 24/04/2019
     */
    @AuraEnabled
    public static BI_LEX_GenericApprovalActionControl.response generateCustomRecord(String recordFieldData, SObject record, String sObjectName){
        BI_LEX_GenericApprovalActionControl.response result = new BI_LEX_GenericApprovalActionControl.response();
        //Mapping schema field types
        Schema.DescribeFieldResult fr;
        Map<String,Schema.DisplayType> fieldDisplayTypeMAP = new Map<String,Schema.DisplayType>();
        //Is record update
        Boolean isRecordUpdate = sObjectName == null ? true : false;
        sObjectName = sObjectName == null ? Id.valueOf(record.Id).getSobjectType().getDescribe().getName() : sObjectName;
        List<Schema.DisplayType> intDisplayLIST = new List<Schema.DisplayType>{Schema.DisplayType.INTEGER,Schema.DisplayType.DOUBLE,Schema.DisplayType.CURRENCY};
        Map<String,Schema.SObjectField> fieldMAP = Schema.getGlobalDescribe().get(sObjectName).getDescribe().fields.getMap();
        for(String key : fieldMAP.keySet()){
            fr = fieldMAP.get(key).getDescribe();
			fieldDisplayTypeMAP.put(fr.getName(),fr.getType());            
        }
        //Deserialize data for insert
        List<BI_LEX_GenericApprovalActionControl.recordFieldData> recordFieldDataLIST = (List<BI_LEX_GenericApprovalActionControl.recordFieldData>) JSON.deserialize(recordFieldData, List<BI_LEX_GenericApprovalActionControl.recordFieldData>.class);
        //Generate new record
        String textvalue;
        Integer intvalue;
        Boolean boolvalue;
        Schema.DisplayType dp;
        SObject newSObj = isRecordUpdate ? record : Schema.getGlobalDescribe().get(sObjectName).newSObject();
        for(BI_LEX_GenericApprovalActionControl.recordFieldData fd : recordFieldDataLIST){
            //Proper value => based on displayType of field
            dp = fieldDisplayTypeMAP.get(fd.fieldName);
            //Boolean
            if(dp == Schema.DisplayType.BOOLEAN){
                newSObj.put(fd.fieldName, fd.value == 'true' ? true : false);   
            }
            //Number
            else if(intDisplayLIST.contains(dp)){
                newSObj.put(fd.fieldName, Integer.valueOf(fd.value));
            }
            //Rest
            else{ 
                newSObj.put(fd.fieldName, fd.value);
            }
        }
        //Insert new record
        try{
            //Record Update
            if(isRecordUpdate){
            	for(Database.SaveResult sr : Database.update(new List<SObject>{newSObj}, false)){
                    if(sr.isSuccess()){
                        result.success = true;
                    }
                    else{
                        result.success = false;
                        result.message = sr.getErrors()[0].getMessage();
                    }
                }    
            }
            //Record Insert
            else{
            	for(Database.SaveResult sr : Database.insert(new List<SObject>{newSObj}, false)){
                    if(sr.isSuccess()){
                        result.success = true;
                        result.generatedRecordId = sr.getId();
                    }
                    else{
                        result.success = false;
                        result.message = sr.getErrors()[0].getMessage();
                    }
                }    
            }
        }
        catch(Exception e){
            result.success = false;
            result.message = e.getMessage();
        }
        return result;
    }
    
    /**
     * @description Retrieve lightning flow parameters for custom call
     * @author Pablo de Andrés
     * @date 21/05/2019
     */
    @AuraEnabled
    public static BI_LEX_GenericApprovalActionControl.lightningFlowParams getLightningFlowParams(String recordId, String paramLISTJSON){
        Id auxId;
        String query;
        String auxString;
        //Flow DeveloperName
        String developerName;
        List<SObject> sObjLIST;
        List<String> fieldAPILIST;
        Map<String,Object> retrieveMAP;
        Map<String,Schema.DisplayType> displayMAP;
        //Map for null reference value fields
        Map<String,String> nullReferenceValueMAP = new Map<String,String>();
        //For params set by reference value
        Map<String,String> referenceValueByFieldMAP = new Map<String,String>();
        List<BI_LEX_Condition__c> paramLIST = (List<BI_LEX_Condition__c>) JSON.deserialize(paramLISTJSON, List<BI_LEX_Condition__c>.class);
        List<BI_LEX_GenericApprovalActionControl.lightningFlowInputVariable> inputVariables = new List<BI_LEX_GenericApprovalActionControl.lightningFlowInputVariable>();
        //Schema.DisplayType numerical types
        Set<String> displayNumSET = new Set<String>{'CURRENCY','DOUBLE','INTEGER','LONG','PERCENT'};
        for(BI_LEX_Condition__c cn : paramLIST){
            //DeveloperName for lightning:flow
            if(cn.BI_LEX_FieldAPIName__c.toLowerCase() == 'developername'){
                developerName = cn.BI_LEX_FieldValue__c;
            }
            //Input variable
            else{
            	//Reference value
                if(cn.BI_LEX_FieldReferenceValue__c != null){
                    referenceValueByFieldMAP.put(cn.BI_LEX_FieldReferenceValue__c, cn.BI_LEX_FieldAPIName__c); 
                }   
                //Rest
                else{
                    try{
                        auxId = Id.valueOf(cn.BI_LEX_FieldValue__c);
                    	inputVariables.add(new BI_LEX_GenericApprovalActionControl.lightningFlowInputVariable(cn.BI_LEX_FieldAPIName__c, 'String', auxId));
                    }
                    catch(Exception e){
                    	inputVariables.add(new BI_LEX_GenericApprovalActionControl.lightningFlowInputVariable(cn.BI_LEX_FieldAPIName__c, cn.BI_LEX_FieldValue__c.isNumeric() ? 'Number' : (booleanSET.contains(cn.BI_LEX_FieldValue__c) ? 'Boolean' : 'String'), cn.BI_LEX_FieldValue__c != null ? cn.BI_LEX_FieldValue__c : null));    
                    }    
                }
            }
        }
        //Retrieve references
        if(!referenceValueByFieldMAP.isEmpty()){
            fieldAPILIST = new List<String>(referenceValueByFieldMAP.keySet());
            query = (fieldAPILIST.contains('Id') ? 'SELECT ' : 'SELECT Id, ') + String.join(fieldAPILIST, ', ').removeEnd(', ') + ' FROM ' + Id.valueOf(recordId).getSObjectType().getDescribe().getName() + ' WHERE Id = :recordId';
            sObjLIST = Database.query(query);
            retrieveMAP = CPQ_NewRecordOWControl.retrieveValueByAPIField(sObjLIST[0], fieldAPILIST);
            //Check response and add input variables
            for(String key : retrieveMAP.keySet()){
                auxString = String.valueOf(retrieveMAP.get(key));
                //Check if it's Id
                try{
                	auxId = Id.valueOf(auxString); 
                	inputVariables.add(new BI_LEX_GenericApprovalActionControl.lightningFlowInputVariable(referenceValueByFieldMAP.get(key), 'String', auxId));
                }
                //No Id or null value
                catch(Exception e){
                    //Non-null value
                    if(auxString != null){
                    	inputVariables.add(new BI_LEX_GenericApprovalActionControl.lightningFlowInputVariable(referenceValueByFieldMAP.get(key), auxString.isNumeric() ? 'Number' : (booleanSET.contains(auxString) ? 'Boolean' : 'String'), auxString));    
                    }
                    //Null value => get type
                    else{
                   		nullReferenceValueMAP.put(key, referenceValueByFieldMAP.get(key));
                    }
                }
            }
        }
        //Retrieve null value references type
        if(!nullReferenceValueMAP.isEmpty()){
            //Map of Schema.DisplayType by field
            displayMAP = BI_LEX_GenericUtility.getDisplayTypeByAPIFieldName(Id.valueOf(recordId).getSObjectType().getDescribe().getName(), new List<String>(nullReferenceValueMAP.keySet()), false, null).displayMAP;
            //Set rows
            for(String dsp : displayMAP.keySet()){
            	inputVariables.add(new BI_LEX_GenericApprovalActionControl.lightningFlowInputVariable(nullReferenceValueMAP.get(dsp), displayNumSET.contains(String.valueOf(displayMAP.get(dsp))) ? 'Number' : (String.valueOf(displayMAP.get(dsp)) == 'BOOLEAN' ? 'Boolean' : 'String'), null));     
            }
        }
        return new BI_LEX_GenericApprovalActionControl.lightningFlowParams(developerName, inputVariables);
    }
    
    /**
     * @description Check if user has record access and retrieve assigned permission sets if so
     * @author Pablo de Andrés
     * @date 27/05/2019
     */
    public static BI_LEX_GenericApprovalActionControl.recordAccessWrapper checkIfUserIsAllowedForHeaderManagement(String recordId){
        BI_LEX_GenericApprovalActionControl.recordAccessWrapper result = new BI_LEX_GenericApprovalActionControl.recordAccessWrapper();
        List<PermissionSetAssignment> permissionLIST;
    	List<UserRecordAccess> accessLIST = [SELECT RecordID, HasReadAccess, HasEditAccess FROM UserRecordAccess WHERE UserId = :UserInfo.getUserId() AND RecordId =:recordId];
        //Record access found
        if(!accessLIST.isEmpty()){
        	//Access granted
            if(accessLIST[0].HasReadAccess && accessLIST[0].HasEditAccess){
            	result.success = true; 
                result.byPassSystemAdmin = false;
                result.userPermissionLIST = new List<String>();
                //Get assigned permission sets
                permissionLIST = [SELECT Id, PermissionSet.Name, PermissionSet.Profile.Name, PermissionSet.IsOwnedByProfile FROM PermissionSetAssignment WHERE AssigneeId = :UserInfo.getUserId()];
                //Permissions/profile found
                if(!permissionLIST.isEmpty()){
                    for(PermissionSetAssignment prm : permissionLIST){
                        if(prm.PermissionSet.IsOwnedByProfile && (prm.PermissionSet.Profile.Name == 'System Administrator' || prm.PermissionSet.Profile.Name == 'Administrador del sistema')){
                        	result.byPassSystemAdmin = true;
                            break;
                        }
                        else if(!prm.PermissionSet.IsOwnedByProfile){
                      		result.userPermissionLIST.add(prm.PermissionSet.Name); 
                        } 
                    }    
                }
            }
            else{
                result.success = false;
            }
        }
        //No access
        else{
        	result.success = false;    
        }
        return result;
    }
    
    /**
     * @description Check if header is allowed for user
     * @author Pablo de Andrés
     * @date 27/05/2019
     */
    public static Boolean isHeaderAllowedForUser(BI_LEX_GenericApprovalActionControl.recordAccessWrapper recordAccessWrapper, String allowedPermissions){
        Boolean result;
        if(recordAccessWrapper.success){
            //System administrator
            if(recordAccessWrapper.byPassSystemAdmin){
            	result = true;    
            }
            else{
            	//Check related permission sets
                if(allowedPermissions != null){
                    permissionSetLIST = allowedPermissions.split(';'); 
                    //Loop throug associated permission set list
                    if(!recordAccessWrapper.userPermissionLIST.isEmpty()){
                        result = false;
                        for(String pkey : permissionSetLIST){
                            //Match
                            if(recordAccessWrapper.userPermissionLIST.contains(pkey)){
                                result = true;
                                break;
                            }
                        }    
                    }
                    //No associated permission sets
                    else{
                        result = false;
                    }
                }
                else{
                    result = true;    
                }    
            }
        	
        }
        //Non-allowed
        else{
        	result = false;    
        }
        return result;
    }
    
    /**
     * @description Get approval process map status grouped by ProcessDefinition DeveloperName
     * @author Pablo de Andrés
     * @date 13/06/2019
     */
    public static Map<String,String> getApprovalProcessStatusByDeveloperNameMAP(String recordId){
        Map<String,String> resultMAP = new Map<String,String>();
        for(ProcessInstance pn : [SELECT Id, Status, ProcessDefinition.DeveloperName FROM ProcessInstance WHERE TargetObjectID = :recordId ORDER BY LastModifiedDate DESC]){
            if(!resultMAP.containsKey(pn.ProcessDefinition.DeveloperName)){
                resultMAP.put(pn.ProcessDefinition.DeveloperName, pn.Status);
            }
        }
        return resultMAP;
    }
	
	/**
	 * @description Enqueue jobs via CPQ_ScheduleClass
	 * @author Pablo de Andrés
	 * @date 13/06/2019
	 */    
    @AuraEnabled
    public static BI_LEX_GenericApprovalActionControl.response enqueueParentHeaderJob(String recordId, String additionalInfoWrapperJSON){
        System.debug('### enqueueParentHeaderJob -- recordId: ' + recordId);
        System.debug('### enqueueParentHeaderJob -- additionalInfoWrapperJSON: ' + additionalInfoWrapperJSON);
        BI_LEX_GenericApprovalActionControl.response result = new BI_LEX_GenericApprovalActionControl.response();
        //try{
        	List<CPQ_ScheduleClass.scheduleWrapper> additionalInfoWrapper = (List<CPQ_ScheduleClass.scheduleWrapper>) JSON.deserialize(additionalInfoWrapperJSON, List<CPQ_ScheduleClass.scheduleWrapper>.class);
            for(CPQ_ScheduleClass.scheduleWrapper iw : additionalInfoWrapper){
                System.debug('### iw: ' + iw);
                System.enqueueJob(new CPQ_ScheduleClass(recordId, 'updateParent', iw)); 
            }
            result.success = true;
        /*}
        catch(Exception e){
            result.success = false;
            result.message = e.getMessage();
        }*/
        return result;
    }
    
    /**RELATED CALL APEX METHODS**/
    
    /**
    * @description Check if the Opportunity has any quote
    * @author Javier López Andradas
    * @date 24/04/2019
    */
    @AuraEnabled
    public static BI_LEX_GenericApprovalActionControl.response oppHasQuote(String recordId){
        BI_LEX_GenericApprovalActionControl.response res = new BI_LEX_GenericApprovalActionControl.response();
    	List<NE__Order__c> lst_ord = [SELECT Id FROM NE__Order__c WHERE NE__optyId__c=:recordId ANd RecordType.DeveloperName = 'CPQ_Quote'];
        res.success = !lst_ord.isEmpty() ? true : false;
        return res;
    }

    /**
    * @description Check if the Opportunity has any order
    * @author Daniel Sánchez González
    * @date 06/06/2019
    */
    @AuraEnabled
    public static BI_LEX_GenericApprovalActionControl.response oppHasOrder(String recordId){
        BI_LEX_GenericApprovalActionControl.response res = new BI_LEX_GenericApprovalActionControl.response();
    	List<NE__Order__c> lst_ord = [SELECT Id FROM NE__Order__c WHERE NE__optyId__c=:recordId ANd RecordType.DeveloperName = 'CPQ_Order'];
        res.success = !lst_ord.isEmpty() ? true : false;
        return res;
    }
    
  /**
    * @description Check if the Opportunity has all orders in status active
    * @author Daniel Sánchez González
    * @date 06/06/2019
    */
    @AuraEnabled
    public static BI_LEX_GenericApprovalActionControl.response oppHasOrderActive(String recordId){
        BI_LEX_GenericApprovalActionControl.response res = new BI_LEX_GenericApprovalActionControl.response();
    	List<NE__Order__c> lst_ord = [SELECT Id,NE__OrderStatus__c FROM NE__Order__c WHERE NE__optyId__c=:recordId AND RecordType.DeveloperName = 'CPQ_Order'];
        res.success = !lst_ord.isEmpty() ? true : false;

        if (res.success == true){
            for (NE__Order__c ord : lst_ord){
                if(ord.NE__OrderStatus__c != 'Active'){
                    res.success = false;
                }
            }
        }

        return res;
    }

    /**
    * @description 
    * @author Daniel Sánchez (everis)
    * @date 05/06/2019
    */
    @AuraEnabled
    public static BI_LEX_GenericApprovalActionControl.response quoteHasOrder(String recordId){
        BI_LEX_GenericApprovalActionControl.response res = new BI_LEX_GenericApprovalActionControl.response();
    	NE__Order__c quote = [SELECT Id, NE__OptyId__c FROM NE__Order__c WHERE Id =:recordId];
        List<NE__Order__c> lst_ord = [SELECT Id FROM NE__Order__c WHERE RecordType.DeveloperName ='CPQ_Order' AND NE__optyId__c =:quote.NE__optyId__c AND NE__OrderStatus__c != 'Cancelled'];
        res.success = !lst_ord.isEmpty() ? true : false;

        return res;
    }
    
    /**
     * @description Coste FO
     * @author David Culebras
     * @date 07/08/2019
     */
    @AuraEnabled
    public static BI_LEX_GenericApprovalActionControl.response checkCAPEXRules(String recordId){
        //recordId id de la order
        BI_LEX_GenericApprovalActionControl.response result = new BI_LEX_GenericApprovalActionControl.response();
        result.success = true;
        return result;
    }

    /**
    * @description Check if all the CI related to the offer has any System Order related
    * @author Daniel Sánchez (everis)
    * @date 05/06/2019
    *
    @AuraEnabled
    public static BI_LEX_GenericApprovalActionControl.response CIsHaveSystemOrder(String recordId){
        BI_LEX_GenericApprovalActionControl.response res = new BI_LEX_GenericApprovalActionControl.response();
        List<NE__OrderItem__c> lst_ord = [SELECT Id, Name, (SELECT Id, B2WExtCat__Work_Order_Item_Identifier__c, B2WExtCat__Work_Order_Item_Name__c FROM B2WExtCat__Work_Order_Items__r) FROM NE__OrderItem__c WHERE NE__OrderId__c =:recordId];   
        res.success = true;
        for(NE__OrderItem__c ord : lst_ord){
            if(ord.B2WExtCat__Work_Order_Items__r.isEmpty()){
                res.success = false;
                break;
            }else{
                for(Integer i=0;i<ord.B2WExtCat__Work_Order_Items__r.size();i++){
                    if (ord.B2WExtCat__Work_Order_Items__r[i].B2WExtCat__Work_Order_Item_Identifier__c == null || ord.B2WExtCat__Work_Order_Items__r[i].B2WExtCat__Work_Order_Item_Identifier__c == '' || ord.B2WExtCat__Work_Order_Items__r[i].B2WExtCat__Work_Order_Item_Name__c == null || ord.B2WExtCat__Work_Order_Items__r[i].B2WExtCat__Work_Order_Item_Name__c == ''){
                        res.success = false;
                        break;
                    } 
                } 
            }
        }
        return res;
    }*/

    /**
    * @description Check if the Opportunity has any quote
    * @author Javier López Andradas
    * @date 24/04/2019
    */
    @AuraEnabled
    public static BI_LEX_GenericApprovalActionControl.response oppHasOpty(String recordId){
        BI_LEX_GenericApprovalActionControl.response res = new BI_LEX_GenericApprovalActionControl.response();
    	List<NE__Order__c> lst_ord = [SELECT Id FROM NE__Order__c WHERE NE__optyId__c=:recordId ANd RecordType.DeveloperName = 'Opty'];
        
        res.success = !lst_ord.isEmpty() ? true : false;
        /*if(res.success){
            checkStatusOpp(recordId);
        }*/
        return res;
    }
    
    /**
     * @description Validates if related NE__OrderItem__c records for NE__Order__c has CPQ_Tech_Status__c field equals NONE. If found => error
     * @author Pablo de Andrés
     * @date 28/05/2019
     * @history
			@description Change logic Autoatendido
			@author Diego Arias Fernández
   			@date 25/07/2019

            @description Change field to be checked: From NE__CatalogItem__r.NE__Technical_Behaviour_Opty__c to NE__CatalogItem__r.NE__Technical_Behaviour_Quote__c
            @author Diego Arias Fernández
            @date 08/10/2019
     */
    @AuraEnabled
    public static BI_LEX_GenericApprovalActionControl.response orderCIsTechStatusNONE(String recordId){
        BI_LEX_GenericApprovalActionControl.response result = new BI_LEX_GenericApprovalActionControl.response();
        result.success = true;
        List<NE__OrderItem__c> oitList =  [SELECT Id, NE__CatalogItem__r.NE__Technical_Behaviour_Quote__c FROM NE__OrderItem__c WHERE NE__OrderId__c = :recordId AND NE__CatalogItem__r.NE__Technical_Behaviour_Quote__c INCLUDES (:Label.CPQ_LBL_FactibilidadT_cnica)];
        if(!oitList.isEmpty()){
            result.success = false;
        } 
        return result;
    }

    /**
     * @description Validates if related NE__OrderItem__c records for NE__Order__c has CPQ_Cobertura__r.CPQ_Estado_Consulta__c field equals Error. If found => error
     * @author Diego Arias Fernández
     * @date 02/08/2019
     */
    @AuraEnabled
    public static BI_LEX_GenericApprovalActionControl.response orderCIsCobFieldCheck(String recordId){
        BI_LEX_GenericApprovalActionControl.response result = new BI_LEX_GenericApprovalActionControl.response();
        result.success = true;
         for(NE__OrderItem__c oit : [SELECT Id, Name, CPQ_Cobertura__r.CPQ_Estado_Consulta__c FROM NE__OrderItem__c WHERE NE__OrderId__c = :recordId]){
            if(oit.CPQ_Cobertura__r.CPQ_Estado_Consulta__c == 'Error'){
                result.success = false;
                break;
            } 
        }
        return result;
    }

    /**
     * @description Validates if related NE__OrderItem__c records for NE__Order__c has coverage
     * @author Diego Arias Fernández
     * @date 06/08/2019
     * @history
            @description Modify search filter through the attribute 'Internet profesional'
            @author Diego Arias Fernández
            @date 05/09/2019

			@description Se unifican las tecnologías con Argentina
			@author Jose Carlos Almendros
			@date 10/10/2019
     */
    @AuraEnabled
    public static BI_LEX_GenericApprovalActionControl.response orderCIsTechnologyCheck(String recordId){
       BI_LEX_GenericApprovalActionControl.response result = new BI_LEX_GenericApprovalActionControl.response();
        result.success = true;
        Map<Id, Boolean> hasCob = new Map<Id, Boolean>();
        Set<Id> setAux = new Set<Id>();
        List<NE__OrderItem__c> listOI = new List<NE__OrderItem__c>([SELECT Id, Name, CPQ_Cobertura__r.CPQ_Estado_Consulta__c FROM NE__OrderItem__c WHERE NE__OrderId__c = :recordId]);
        for(NE__OrderItem__c oit : listOI){
            setAux.add(oit.Id);
        }
        for(CPQ_Cobertura__c cob : [SELECT Id, CPQ_Direccion__c FROM CPQ_Cobertura__c]){
            if(cob.CPQ_Direccion__c != null){
                hasCob.put(cob.CPQ_Direccion__c, true);
            }else{
                hasCob.put(cob.CPQ_Direccion__c, false);
            }
        }

        List<NE__OrderItem__c> oits = [
            SELECT Id, Name, Installation_point__r.Name, Installation_point__r.BI_Sede__r.Id, CPQ_Cobertura__c,
            (SELECT Id, NE__Value__c, Name FROM NE__Order_Item_Attributes__r WHERE Name = 'Ofertas') 
            FROM NE__OrderItem__c WHERE Id IN :setAux
        ];

        Set<String> cobs = new Set<String>();
        for(NE__OrderItem__c oit : oits) {
            cobs.add(oit.CPQ_Cobertura__c);
        }

        Map<Id, CPQ_Cobertura__c> mapCobs = new Map<Id, CPQ_Cobertura__c>([
            SELECT Id, (SELECT Id, Name, CPQ_On_Set__c FROM Tecnologiaas_de_cobertura__r) FROM CPQ_Cobertura__c WHERE Id IN :cobs
        ]);

        for(NE__OrderItem__c oit : oits){          
            Boolean isInternetProfesional = false;
            if(!oit.NE__Order_Item_Attributes__r.isEmpty()){
                for(NE__Order_Item_Attribute__c neOIAttb : oit.NE__Order_Item_Attributes__r){
                    if(neOIAttb.Name == Label.CPQ_LBL_Ofertas && neOIAttb.NE__Value__c == Label.CPQ_LBL_InternetProfessional){
                        isInternetProfesional = true;
                        break;
                    } 
                }
            }

            /**JAL Se unifican las tecnologías con Argentina
            if(isInternetProfesional && oit.CPQ_Cobertura__r.CPQ_GPON__c != 'Si') result.success = false; 
            */
            if (isInternetProfesional && !String.isBlank(oit.CPQ_Cobertura__c) && mapCobs.containsKey(oit.CPQ_Cobertura__c)) {
                CPQ_Cobertura__c cob = mapCobs.get(oit.CPQ_Cobertura__c);
                Boolean hasGPON = false;
                for (CPQ_Tech_Cob__c tech : cob.Tecnologiaas_de_cobertura__r) {
                    if (tech.Name == 'GPON' && tech.CPQ_On_Set__c) {
                        hasGPON = true;
                        break;
                    }
                }
                result.success = hasGPON;
            }
        }
        return result;
    }

     /**
     * @description Validates if related NE__OrderItem__c records for NE__Order__c has CPQ_Technical_Feasibility_Cart__c true or false
     * @author Diego Arias Fernández
     * @date 09/08/2019
     */
    @AuraEnabled
    public static BI_LEX_GenericApprovalActionControl.response orderCIsQuantityCheck(String recordId){
        BI_LEX_GenericApprovalActionControl.response result = new BI_LEX_GenericApprovalActionControl.response();
        NE__Order__c ord = [SELECT Id, CPQ_Technical_Feasibility_Cart__c FROM NE__Order__c WHERE Id =: recordId];
        result.success = ord.CPQ_Technical_Feasibility_Cart__c ? false : true;
        return result;
    }

     /**
     * @description Metodo APEX para evaluar la Zona (Valida que en el OI y la sede, la dirección coinciden)
     * @author David Culebras
     * @date 29/08/2019
     */
    @AuraEnabled
    public static BI_LEX_GenericApprovalActionControl.response orderCIsZonaCheck(String recordId){
        BI_LEX_GenericApprovalActionControl.response result = new BI_LEX_GenericApprovalActionControl.response();
        result.success = true;
        List<NE__OrderItem__c> listOI = new List<NE__OrderItem__c>([SELECT Id, Name FROM NE__OrderItem__c WHERE NE__OrderId__c = :recordId]);
        Map<Id, Boolean> mapReturn = checkZonaCondition(listOI);

        for(NE__OrderItem__c oit : listOI) {
            if (mapReturn.containsKey(oit.Id) && mapReturn.get(oit.Id) == false) {
                result.success = false;
                break;
            }
        }

        return result;
    }

     /**
     * @description Metodo APEX para evaluar la Prefactibilidad (Valida las distancias entre la consulta de cobertura y la zona asignada)
     * @author David Culebras
     * @date 29/08/2019
     */
    @AuraEnabled
    public static BI_LEX_GenericApprovalActionControl.response orderCIsPrefactibilidadCheck(String recordId){
        BI_LEX_GenericApprovalActionControl.response result = new BI_LEX_GenericApprovalActionControl.response();
        result.success = true;
        List<NE__OrderItem__c> listOI = new List<NE__OrderItem__c>([SELECT Id, Name FROM NE__OrderItem__c WHERE NE__OrderId__c = :recordId]);
        Map<Id, Boolean> mapReturn = checkPrefactibilidadCondition(listOI);

        for(NE__OrderItem__c oit : listOI) {
            if (mapReturn.get(oit.Id) == false) {
                result.success = false;
                break;
            }
        }

        return result;
    }

    /**
     * @description Validates if related NE__OrderItem__c records for NE__Order__c has B2W_CnfItem_Check_Factibilidad_Tecnica__c true or false
     * @author Diego Arias Fernández
     * @date 02/09/2019
     */
    @AuraEnabled
    public static BI_LEX_GenericApprovalActionControl.response orderCIsB2WCartRules(String recordId){
        BI_LEX_GenericApprovalActionControl.response result = new BI_LEX_GenericApprovalActionControl.response();
        result.success = true;
         for(NE__OrderItem__c oit : [SELECT Id, B2W_CnfItem_Check_Factibilidad_Tecnica__c FROM NE__OrderItem__c WHERE NE__OrderId__c = :recordId]){
            if(oit.B2W_CnfItem_Check_Factibilidad_Tecnica__c){
                result.success = false;
                break;
            } 
        }
        return result;
    }

    /**
     * @description Validates if related NE__OrderItem__c records for NE__Order__c has B2W_CnfItem_Check_Factibilidad_Economica__c true or false
     * @author Diego Arias Fernández
     * @date 03/09/2019
     */
    @AuraEnabled
    public static BI_LEX_GenericApprovalActionControl.response orderCIsB2WDiscountCheck(String recordId){
        BI_LEX_GenericApprovalActionControl.response result = new BI_LEX_GenericApprovalActionControl.response();
        result.success = true;
        for(NE__OrderItem__c oit : [SELECT Id, B2W_CnfItem_Check_Factibilidad_Economica__c FROM NE__OrderItem__c WHERE NE__OrderId__c = :recordId]){
            if(oit.B2W_CnfItem_Check_Factibilidad_Economica__c){
                result.success = false;
                break;
            } 
        }
        return result;
    }

    /**
     * @description Validates if related NE__OrderItem__c records for NE__Order__c has CPQ_Net_annual_value_NAV__c between the correct values (Segment: Empresas)
     * @author Diego Arias Fernández
     * @date 09/08/2019
     * @history
            @description Se coge moneda de la order en vez de la del usuario, y se elimina el comprobar segmento (Se hacen 2 metodos) y se establece el umbral a 1800 
			@author Diego Arias Fernández
   			@date 14/09/2019
     */
    @AuraEnabled
    public static BI_LEX_GenericApprovalActionControl.response orderCIsNAVCheckEmpresas(String recordId){
        BI_LEX_GenericApprovalActionControl.response result = new BI_LEX_GenericApprovalActionControl.response();
        Map<String,Double> currencyMap = CPQ_NewRecordOWControl.getCurrencyExchangeMAP();
        NE__Order__c order = [SELECT Id, Name, NE__AccountId__c, CPQ_Net_annual_value_NAV__c,CurrencyIsoCode FROM NE__Order__c WHERE Id =: recordId];
        
        Double amountInUFs = order.CurrencyIsoCode != 'CLF' ? order.CPQ_Net_annual_value_NAV__c * currencyMap.get('CLF')/currencyMap.get(order.currencyIsoCode) : order.CPQ_Net_annual_value_NAV__c; 
        result.success = amountInUFs > 1800 ? false : true;

        return result;
    }

    /**
     * @description Validates if related NE__OrderItem__c records for NE__Order__c has CPQ_Net_annual_value_NAV__c between the correct values (Segment: Negocio)
     * @author Diego Arias Fernández
     * @date 14/09/2019
     */
    @AuraEnabled
    public static BI_LEX_GenericApprovalActionControl.response orderCIsNAVCheckNegocio(String recordId){
        BI_LEX_GenericApprovalActionControl.response result = new BI_LEX_GenericApprovalActionControl.response();
        Map<String,Double> currencyMap = CPQ_NewRecordOWControl.getCurrencyExchangeMAP();
        NE__Order__c order = [SELECT Id, Name, NE__AccountId__c, CPQ_Net_annual_value_NAV__c,CurrencyIsoCode FROM NE__Order__c WHERE Id =: recordId];
        
        Double amountInUFs = order.CurrencyIsoCode != 'CLF' ? order.CPQ_Net_annual_value_NAV__c * currencyMap.get('CLF')/currencyMap.get(order.currencyIsoCode) : order.CPQ_Net_annual_value_NAV__c; 
        result.success = amountInUFs > 240 ? false : true;

        return result;
    }

    /**
     * @description Valida que el hito de Factibilidad Técnica anterior esté autoatendido
     * @author David Culebras
     * @date 02/10/2019
     */
    @AuraEnabled
    public static BI_LEX_GenericApprovalActionControl.response orderCIsCheckFEAutoatendido(String recordId){
        BI_LEX_GenericApprovalActionControl.response result = new BI_LEX_GenericApprovalActionControl.response();
        //por defecto
        result.success = false;
        List<BI_LEX_ActionHistory__c> lHitos = [SELECT BI_LEX_HistoryStatus__c, BI_LEX_ActionHeader__r.Name
            FROM BI_LEX_ActionHistory__c WHERE RecordType.Name = 'Hito' AND BI_LEX_RelatedRecordId__c = :recordId];

        for (BI_LEX_ActionHistory__c hito : lHitos) {
            // if (hito.BI_LEX_ActionHeader__r.Name == '6. Análisis Factibilidad Técnica' &&
            if (hito.BI_LEX_ActionHeader__r.Name.containsIgnoreCase('factibilidad técnica')) {
                if (hito.BI_LEX_HistoryStatus__c == 'OK')
                    result.success = true;
                else
                    result.success = false;
            }
        }

        return result;
    }

    /**
     * @description Validates if related NE__OrderItem__c records for NE__Order__c has NE__One_Time_Fee_Total__c between the correct values
     * @author Diego Arias Fernández
     * @date 09/08/2019
     * @history
            @description Change user currency for order currency.
			@author Diego Arias Fernández
   			@date 14/08/2019
     */
     /* DAF 17092019 No applica a nivel de hito en factibilidad economica. Se comenta para test
    @AuraEnabled
    public static BI_LEX_GenericApprovalActionControl.response orderCIsSalesCheck(String recordId){
        BI_LEX_GenericApprovalActionControl.response result = new BI_LEX_GenericApprovalActionControl.response();
        Map<String,Double> currencyMap = CPQ_NewRecordOWControl.getCurrencyExchangeMAP();

        NE__Order__c order = [SELECT Id, Name, NE__AccountId__r.BI_Segment__c, NE__One_Time_Fee_Total__c, CurrencyIsoCode FROM NE__Order__c WHERE Id =: recordId];
        
        Double amountInUSD = order.CurrencyIsoCode != 'USD' ? order.NE__One_Time_Fee_Total__c * currencyMap.get('USD') : order.NE__One_Time_Fee_Total__c; 
    
        if(order.NE__AccountId__r.BI_Segment__c == 'Empresas'){
            result.success = amountInUSD > 200000 ? false : true;
        }

        return result;
    }*/

    /**
     * @description returns true if related case are Cerrado and RecordType is Matriz de Complejidad
     * @author Carlos Nombela Blanco
     * @date 09/08/2019 
     */
     /* DAF 17092019 No applica a nivel de hito en factibilidad economica. Se comenta para test
    @AuraEnabled
    public static BI_LEX_GenericApprovalActionControl.response orderCIsEngineeringCheck(String recordId){
        BI_LEX_GenericApprovalActionControl.response result = new BI_LEX_GenericApprovalActionControl.response();
        result.success = true;
        for(Case ords : [SELECT Id,Status,BI_Oferta_asociada__c,RecordType.DeveloperName FROM Case 
                                WHERE BI_Oferta_asociada__c =:recordId AND Status = 'Cerrado' AND RecordType.DeveloperName = 'E3_Caso_MC_Tecnica']){
                result.success =  false;
        }
        return result;
    }*/

    /**
     * @description Validates if related NE__OrderItem__c records for NE__Order__c has ... (Waiting for definition)
     * @author Diego Arias Fernández
     * @date 09/08/2019
     */
     /* DAF 17092019 No applica a nivel de hito en factibilidad economica. Se comenta para test
    @AuraEnabled
    public static BI_LEX_GenericApprovalActionControl.response orderCIsFCVCheck(String recordId){
        BI_LEX_GenericApprovalActionControl.response result = new BI_LEX_GenericApprovalActionControl.response();
        result.success = true;
        return result;
    }*/

     /**
     * @description check the discounts of executives .... (Waiting for definition missing a field of discount )
     * @author Carlos Nombela Blanco
     * @date 19/08/2019
     */
     /* DAF 17092019 No applica a nivel de hito en factibilidad economica. Se comenta para test
     @AuraEnabled
     public static BI_LEX_GenericApprovalActionControl.response checkOrderDiscount(String recordId){
         BI_LEX_GenericApprovalActionControl.response result = new BI_LEX_GenericApprovalActionControl.response();
         result.success = false;
         NE__Order__c neo = [SELECT Id,NE__AccountId__c FROM NE__Order__c where Id = :recordId  LIMIT 1];

         for( NE__Order__c acc : [SELECT Id,NE__AccountId__r.BI_Potencial__c FROM NE__Order__c where Id = :recordId  LIMIT 1]){
            if(acc.NE__AccountId__r.BI_Potencial__c == 'A' || acc.NE__AccountId__r.BI_Potencial__c =='B' || acc.NE__AccountId__r.BI_Potencial__c == 'C' || acc.NE__AccountId__r.BI_Potencial__c == 'A+'){
                result.success = true;
            } else {
                result.success = false;
            }
         }
        return result;
     }*/

    /**
     * @description Check if NE__OrderItem__c records associated to NE__Order__c has Installation_point__c field filled
     * @author Pablo de Andrés
     * @date 11/06/2019
     * 
     * David Culebras | 29/07/2019 | Modificada la query porque el campo es una multipicklist y puede contener varios valores posibles.
     * Amador Cáceres | 08/01/2020 | Modificada query y condicional para no pasar el hito en el caso de que existan 2 sedes que asignar
     */
    @AuraEnabled
    public static BI_LEX_GenericApprovalActionControl.response checkOrderCIAssociatedInstallationPoints(String recordId){
        BI_LEX_GenericApprovalActionControl.response result = new BI_LEX_GenericApprovalActionControl.response();
        result.success = true;
        for(NE__Order__c neo: [SELECT Id, (SELECT Id, Installation_point__c, TGS_Installation_point__c, NE__CatalogItem__r.NE__Technical_Behaviour_Quote__c FROM NE__Order_Items__r where NE__CatalogItem__r.NE__Technical_Behaviour_Quote__c INCLUDES (:Label.CPQ_LBL_SiteRequired, :Label.CPQ_LBL_SitioRequerido) ) FROM NE__Order__c WHERE Id = :recordId]){
            if(!neo.NE__Order_Items__r.isEmpty()){
                for(NE__OrderItem__c nei : neo.NE__Order_Items__r){
                	result.success = nei.Installation_point__c == null ? false : true;
                    if(nei.NE__CatalogItem__r.NE__Technical_Behaviour_Quote__c.contains('2 Site required') && result.success == true){
                        result.success = nei.TGS_Installation_point__c == null ? false : true;
                    }
                }    
            }
            /*else{
                result.success = false;
            }*/
        }
        return result;
    } 

    
    /**
     * @description Apex method to evaluate attachment files
     * @author Diego Arias Fernández
     * @date 07/08/2019
     */
    @AuraEnabled
    public static BI_LEX_GenericApprovalActionControl.response checkAttachmentsFiles(String recordId){
        //recordId id de la order
        BI_LEX_GenericApprovalActionControl.response result = new BI_LEX_GenericApprovalActionControl.response();
        result.success = false;
        //Modificación: Se incluye llamada a método para actualizar las fechas. Ver descripción.
        checkDateIfSimpleProduct(recordId);
        if(!String.isEmpty(recordId)) {
            List<ContentDocumentLink> lContentLink = new List<ContentDocumentLink>([
                SELECT Id, ContentDocumentId, LinkedEntityId FROM ContentDocumentLink 
                WHERE LinkedEntityId = :recordId
                AND ContentDocument.LatestPublishedVersion.CPQ_Type__c = 'propuesta'
            ]);
            if(!lContentLink.isEmpty()){
                result.success = true;    
            }   
        }
        return result;
    }

 /**
     * @description Evaluacion del PAYBACK
     * @author David Culebras
     * @date 07/08/2019
     */
    @AuraEnabled
    public static BI_LEX_GenericApprovalActionControl.response checkPAYBACKRules(String recordId, String param){
        System.debug('DCU checkPAYBACKRules');
        System.debug('recordId: '+recordId);
        BI_LEX_GenericApprovalActionControl.response result = new BI_LEX_GenericApprovalActionControl.response();
        //recordId id de la order

        try {
            Double payback = CPQ_DatosEconomicosControl.calculaPayback(recordId);
            System.debug('payback: '+payback);
            Map<String, Object> jsonParam = (Map<String, Object>) JSON.deserializeUntyped(param);
            Double umbral = (Double)jsonParam.get('umbral');
            result.success = payback <= umbral;

        } catch (Exception e) {
            result.success = false;
        }

        return result;
    }
    /**
     * @description Calculo de CAPEX estimado en la oferta:
     *          El CAPEX se calcula con el precio de la FO en la zona * distancia a la central y se compara con un umbral.
     * @author David Culebras
     * @date 13/11/2019
     */
    @AuraEnabled
    public static BI_LEX_GenericApprovalActionControl.response checkCAPEXEstimadoRules(String recordId, String param, String currencyIsoCode){
        BI_LEX_GenericApprovalActionControl.response result = new BI_LEX_GenericApprovalActionControl.response();
        result.success = true;
        System.debug('checkCAPEXEstimadoRules');
        System.debug('recordId: '+recordId);
        System.debug('param: '+param);
        System.debug('currencyIsoCode: '+currencyIsoCode);

        Map<String, Object> jsonParam = (Map<String, Object>) JSON.deserializeUntyped(param);
        Double umbral = (Double)jsonParam.get('umbral');
        Double CAPEXTotal = CPQ_DatosEconomicosControl.CAPEXEstimado(recordId);

        System.debug('umbral: '+umbral);
        System.debug('CAPEXTotal: '+CAPEXTotal);
        if (umbral <= CAPEXTotal) {
            result.success = false;
        }

        return result;
    }

    /**
     * @description Calculo de CAPEX Real en la oferta:
     *          Se asume que los ingenieros técnicos han rellenado el CAPEX en los CIs y se sumariza.
     * @author David Culebras
     * @date 13/11/2019
     */
    @AuraEnabled
    public static BI_LEX_GenericApprovalActionControl.response checkCAPEXRealRules(String recordId, String param, String currencyIsoCode){
        BI_LEX_GenericApprovalActionControl.response result = new BI_LEX_GenericApprovalActionControl.response();
        result.success = true;
        System.debug('checkCAPEXRealRules');
        System.debug('recordId: '+recordId);
        System.debug('param: '+param);
        System.debug('currencyIsoCode: '+currencyIsoCode);

        Map<String, Object> jsonParam = (Map<String, Object>) JSON.deserializeUntyped(param);
        Double umbral = (Double)jsonParam.get('umbral');
        Double precioFO = (Double)jsonParam.get('precioFO');
        Double distanciaTotal = 0;
        Double CAPEX = 0;
        //Saco el CAPEX de la oferta
        // List<NE__Order__c> lo = [SELECT Id, CPQ_CAPEX_total__c, CurrencyIsoCode
        //     FROM NE__Order__c WHERE Id = :recordId];
        
        // for (NE__Order__c order : lo){
        //     CAPEX += order.CPQ_CAPEX_total__c;
        // }

        List<NE__OrderItem__c> loi = [SELECT Id, CPQ_CAPEX__c 
            FROM NE__OrderItem__c WHERE NE__OrderId__c = :recordId];

        for (NE__OrderItem__c oi : loi) {
            CAPEX += (oi.CPQ_CAPEX__c == null ? 0 : oi.CPQ_CAPEX__c);
        }

        System.debug('umbral: '+umbral);
        System.debug('CAPEX: '+CAPEX);
        if (umbral <= CAPEX) {
            result.success = false;
        }

        return result;
    }
    
    /**
     * @description Check previous status
     * @author Diego Arias Fernández
     * @date 29/07/2019
     */
    /* DAF 17092019 Se dejo de usar por cambio de enfoque en configuración de hitos. A la espera de borrar, se comenta para test
    @AuraEnabled
    public static BI_LEX_GenericApprovalActionControl.response checkPreviousStatus(String recordId){
        BI_LEX_GenericApprovalActionControl.response result = new BI_LEX_GenericApprovalActionControl.response();
        result.success = false;
        List<BI_LEX_ActionHistory__c> actionHistoryList = new List<BI_LEX_ActionHistory__c>([SELECT Id, BI_LEX_ActionHeader__c, BI_LEX_HistoryStatus__c FROM BI_LEX_ActionHistory__c 
                    		                                                                WHERE BI_LEX_RelatedRecordId__c = :recordId AND RecordType.DeveloperName = 'BI_LEX_Hito']);
        Map<Id, String> statusMap = new Map<Id, String>();
        for(BI_LEX_ActionHistory__c actionHistory : actionHistoryList){
            statusMap.put(actionHistory.BI_LEX_ActionHeader__c, actionHistory.BI_LEX_HistoryStatus__c);
        }

        List<BI_LEX_ApprovalActionHeader__c> listApprovalActions = new List<BI_LEX_ApprovalActionHeader__c>([SELECT Id, (SELECT Id, RecordType.DeveloperName,BI_LEX_LightningComponentAPIName__c FROM Acciones_de_aprobaci_n__r 
                                                                                                WHERE RecordType.DeveloperName IN ('BI_LEX_CaseaCreation', 'BI_LEX_TaskCreation')
                                                                                                OR (RecordType.DeveloperName = 'BI_LEX_LightningComponentCall' AND BI_LEX_LightningComponentAPIName__c = 'BI_LEX_GenericFlowCMP') ) 
                                                                                                FROM BI_LEX_ApprovalActionHeader__c WHERE Id IN :statusMap.keySet() ORDER BY BI_LEX_Order__c]);

        if(!listApprovalActions.isEmpty()){
            for(BI_LEX_ApprovalActionHeader__c approvalAction : listApprovalActions){
                if(!approvalAction.Acciones_de_aprobaci_n__r.isEmpty()){
                    // Hay acciones
                    if(statusMap.get(approvalAction.Id) == 'NONE'){
                        return result;
                    }
                }else{
                    // No hay acciones
                    if(statusMap.get(approvalAction.Id) == 'OK' || statusMap.get(approvalAction.Id) == 'APPROVED'){
                        result.success = false;
                    }else if(statusMap.get(approvalAction.Id) != 'OK' && statusMap.get(approvalAction.Id) != 'APPROVED'){
                        result.success = true;
                    }
                }
            }   
        }
        return result;
    }*/

    /**
     * @description Apex method to evaluate the autoatendido condition on feasibility table
     * @author Diego Arias Fernández
     * @date 22/07/2019
     * @history
			@description Check values in multipicklist
			@author Diego Arias Fernández
   			@date 29/07/2019

            @description Change field to be checked: From NE__CatalogItem__r.NE__Technical_Behaviour_Opty__c to NE__CatalogItem__r.NE__Technical_Behaviour_Quote__c
            @author Diego Arias Fernández
            @date 08/10/2019
     */
    @AuraEnabled
    public static Map<Id, Boolean> checkAutoatendidoCondition(List<NE__OrderItem__c> listOI){
        Map<Id, Boolean> mapReturn = new Map<Id, Boolean>();
        Set<Id> setAux = new Set<Id>();
        for(NE__OrderItem__c oit : listOI){
            setAux.add(oit.Id);
        }
        for(NE__OrderItem__c oit : [SELECT Id, NE__CatalogItem__r.NE__Technical_Behaviour_Quote__c FROM NE__OrderItem__c WHERE Id IN :setAux]){
            Boolean result;
            result = oit.NE__CatalogItem__r.NE__Technical_Behaviour_Quote__c == null ? true : !oit.NE__CatalogItem__r.NE__Technical_Behaviour_Quote__c.contains(Label.CPQ_LBL_FactibilidadT_cnica);
            mapReturn.put(oit.Id, result);
        }
        return mapReturn;
    }

    /**
     * @description Metodo APEX para evaluar la prefactibilidad | SOLO ARGENTINA
     * @author David Culebras
     * @date 29/08/2019
     * @history
     */
    @AuraEnabled
    public static Map<Id, Boolean> checkPrefactibilidadCondition(List<NE__OrderItem__c> listOI){
        Map<Id, Boolean> mapReturn = new Map<Id, Boolean>();
        Set<Id> setAux = new Set<Id>();
        
        for(NE__OrderItem__c oit : listOI){
            setAux.add(oit.Id);
        }
        
        List<NE__OrderItem__c> loi = [SELECT Id, NE__Parent_Order_Item__c, Installation_point__r.BI_Sede__r.CPQ_Zona__r.CPQ_Zona__r.CPQ_Distancia__c, 
            CPQ_Cobertura__c, CPQ_Factor_Potenciacion__c, NE__CatalogItem__r.NE__Technical_Behaviour_Quote__c, 
            (SELECT NE__Value__c FROM NE__Order_Item_Attributes__r WHERE Name =: Label.CPQ_LBL_TecnologiaAcceso) 
            FROM NE__OrderItem__c WHERE Id IN :setAux];
        Set<Id> setIDsCob = new Set<Id>();

        for (NE__OrderItem__c oi : loi) {
            setIDsCob.add(oi.CPQ_Cobertura__c);
        }

        List<CPQ_Tech_Cob__c> lTech = [SELECT Name, CPQ_Cobertura__c, CPQ_FO_Distancia__c,CPQ_FTTH_CtoDistancia__c 
            FROM CPQ_Tech_Cob__c WHERE CPQ_Principal__c = true AND CPQ_Cobertura__c IN :setIDsCob];

        for(NE__OrderItem__c oitPadre : loi){
            Double factorPotenciacion = (oitPadre.CPQ_Factor_Potenciacion__c == null ? 1 : oitPadre.CPQ_Factor_Potenciacion__c);
            Double distancia = 99999;

            
            Boolean result = null;
            
            if (oitPadre.NE__CatalogItem__r.NE__Technical_Behaviour_Quote__c == null ||
                !oitPadre.NE__CatalogItem__r.NE__Technical_Behaviour_Quote__c.contains(Label.CPQ_LBL_SiteRequired)) {
                
                mapReturn.put(oitPadre.Id, null);
                continue;
            }

            if (String.isBlank(oitPadre.NE__Parent_Order_Item__c)) {
                for (NE__OrderItem__c oitHijo : loi) {
                    if (!String.isBlank(oitHijo.NE__Parent_Order_Item__c) && oitHijo.NE__Parent_Order_Item__c == oitPadre.Id) {
                        // distancia = 10;
                        try {
                            for (CPQ_Tech_Cob__c techCob : lTech) {
                                if (oitPadre.CPQ_Cobertura__c == techCob.CPQ_Cobertura__c) {
                                    if (oitHijo.NE__Order_Item_Attributes__r[0].NE__Value__c == Label.CPQ_LBL_FTTH) {
                                        if (techCob.Name == Label.CPQ_LBL_FTTH) {
                                            distancia = techCob.CPQ_FTTH_CtoDistancia__c;
                                        }
                                    } else if (oitHijo.NE__Order_Item_Attributes__r[0].NE__Value__c == Label.CPQ_LBL_FibraOpticaDedicada ||
                                        oitHijo.NE__Order_Item_Attributes__r[0].NE__Value__c == Label.CPQ_LBL_FibraOptica ||
                                        oitHijo.NE__Order_Item_Attributes__r[0].NE__Value__c == Label.CPQ_LBL_FO) {
                                        if (techCob.Name == Label.CPQ_LBL_Fibra_ptica) {
                                            distancia = techCob.CPQ_FO_Distancia__c;
                                        }
                                    }
                                }
                            }
                        } catch (Exception e) {}
                    }
                }

                distancia *= factorPotenciacion;
                result = distancia <= oitPadre.Installation_point__r.BI_Sede__r.CPQ_Zona__r.CPQ_Zona__r.CPQ_Distancia__c;
            }

            mapReturn.put(oitPadre.Id, result);
        }

        return mapReturn;
    }

    /**
     * @description Metodo APEX para evaluar la Zona (Valida que en el OI y la sede, la dirección coinciden)
     * @author David Culebras
     * @date 29/08/2019
     * @history
     */
    @AuraEnabled
    public static Map<Id, Boolean> checkZonaCondition(List<NE__OrderItem__c> listOI) {
        Map<Id, Boolean> mapReturn = new Map<Id, Boolean>();
        List<String> listIds = new List<String>();
        for (NE__OrderItem__c oit : listOI) {
            listIds.add(oit.Id);
        }
        listOI = [
            SELECT Id, Installation_point__r.CPQ_FormulaZona__c, (
                SELECT Id, NE__Value__c 
                FROM NE__Order_Item_Attributes__r
                WHERE Name =: Label.CPQ_LBL_Zona
            )
            FROM NE__OrderItem__c 
            WHERE Id IN :listIds
        ];
        
        for (NE__OrderItem__c oit : listOI) {
            for (NE__Order_Item_Attribute__c attr : oit.NE__Order_Item_Attributes__r) {
                mapReturn.put(oit.Id, oit.Installation_point__r.CPQ_FormulaZona__c == attr.NE__Value__c);
            }
        }

        return mapReturn;
    }

    /**
     * @description Apex method to evaluate the cob condition on feasibility table
     * @author Diego Arias Fernández
     * @date 02/08/2019
     */
    @AuraEnabled
    public static Map<Id, Boolean> checkCobCondition(List<NE__OrderItem__c> listOI){
        Map<Id, Boolean> mapReturn = new Map<Id, Boolean>();
        Set<Id> setAux = new Set<Id>();
        for(NE__OrderItem__c oit : listOI){
            setAux.add(oit.Id);
        }
        for(NE__OrderItem__c oit : [SELECT Id, CPQ_Cobertura__r.CPQ_Estado_Consulta__c FROM NE__OrderItem__c WHERE Id IN :setAux]){
            Boolean result;
            result = oit.CPQ_Cobertura__r.CPQ_Estado_Consulta__c == null ? null : (oit.CPQ_Cobertura__r.CPQ_Estado_Consulta__c == 'Ok' ? true : false);
            mapReturn.put(oit.Id, result);
        }
        return mapReturn;
    }

    /** 
     * @description Apex method to evaluate the technology condition on feasibility table
     * @author Diego Arias Fernández
     * @date 06/08/2019
     * @history
            @description Modify search filter through the attribute 'Internet profesional'
            @author Diego Arias Fernández
            @date 05/09/2019
	
			@description Se unifican las tecnologías con Argentina
			@author Jose Carlos Almendros
			@date 10/10/2019

            @descripition Se establece que aparezca la tecnología como nula a los hijos en los productos complejos y a los padres que no sean internet profesional
            @author Diego Arias Fernández
            @date 23/10/2019
     */
    @AuraEnabled
    public static Map<Id, Boolean> checkTechnologyCondition(List<NE__OrderItem__c> listOI){
         Map<Id, Boolean> mapReturn = new Map<Id, Boolean>();
        Map<Id, Boolean> hasCob = new Map<Id, Boolean>();
        Set<Id> setAux = new Set<Id>();
        for(NE__OrderItem__c oit : listOI){
            setAux.add(oit.Id);
        }
        for(CPQ_Cobertura__c cob : [SELECT Id, CPQ_Direccion__c FROM CPQ_Cobertura__c]){
            if(cob.CPQ_Direccion__c != null){
                hasCob.put(cob.CPQ_Direccion__c, true);
            }else{
                hasCob.put(cob.CPQ_Direccion__c, false);
            }
        }

        
        List<NE__OrderItem__c> oits = [
            SELECT Id, Installation_point__r.Name,  Installation_point__r.BI_Sede__r.Id, NE__ProdId__r.Name, CPQ_Cobertura__c,
            (SELECT Id, NE__Value__c, Name FROM NE__Order_Item_Attributes__r WHERE Name = 'Ofertas') 
            FROM NE__OrderItem__c WHERE Id IN :setAux
        ];

        Set<String> cobs = new Set<String>();
        for(NE__OrderItem__c oit : oits) {
            cobs.add(oit.CPQ_Cobertura__c);
        }

        Map<Id, CPQ_Cobertura__c> mapCobs = new Map<Id, CPQ_Cobertura__c>([
            SELECT Id, (SELECT Id, Name, CPQ_On_Set__c FROM Tecnologiaas_de_cobertura__r) FROM CPQ_Cobertura__c WHERE Id IN :cobs
        ]);

        for(NE__OrderItem__c oit : oits){
            Boolean isInternetProfesional = false;
            if(!oit.NE__Order_Item_Attributes__r.isEmpty()){
                for(NE__Order_Item_Attribute__c neOIAttb : oit.NE__Order_Item_Attributes__r){
                    if(neOIAttb.Name == Label.CPQ_LBL_Ofertas && neOIAttb.NE__Value__c == Label.CPQ_LBL_InternetProfessional){
                        isInternetProfesional = true;
                        break;
                    } 
                }
            }

            Boolean hasGPON = false;
            if (!String.isBlank(oit.CPQ_Cobertura__c) && mapCobs.containsKey(oit.CPQ_Cobertura__c)) {
                CPQ_Cobertura__c cob = mapCobs.get(oit.CPQ_Cobertura__c);
                for (CPQ_Tech_Cob__c tech : cob.Tecnologiaas_de_cobertura__r) {
                    if (tech.Name == 'GPON' && tech.CPQ_On_Set__c) {
                        hasGPON = true;
                        break;
                    }
                }
            }

            Boolean result = (isInternetProfesional && oit.Installation_point__r.Name != null && hasCob.get(oit.Installation_point__r.BI_Sede__r.Id)) ? hasGPON : null;
            mapReturn.put(oit.Id, result);
        }
        return mapReturn;
    }

    /**
     * @description Apex method to evaluate the 'Regla Catálogo' on feasibility table (B2W_CnfItem_Check_Factibilidad_Tecnica__c field from NE__OrderItem__c)
     * @author Diego Arias Fernández
     * @date 02/09/2019
     */
    @AuraEnabled
    public static Map<Id, Boolean> checkB2WCartRules(List<NE__OrderItem__c> listOI){
        Map<Id, Boolean> mapReturn = new Map<Id, Boolean>();
        Set<Id> setAux = new Set<Id>();
        for(NE__OrderItem__c oit : listOI){
            setAux.add(oit.Id);
        }
        for(NE__OrderItem__c oit : [SELECT Id, Name, B2W_CnfItem_Check_Factibilidad_Tecnica__c FROM NE__OrderItem__c WHERE Id IN :setAux]){
            mapReturn.put(oit.Id, !oit.B2W_CnfItem_Check_Factibilidad_Tecnica__c);
        }
        return mapReturn;
    }
    /**
     * @description Apex method to evaluate the business Line of Opportunity
     * @author Amador Cáceres Rubio
     * @date 13/12/2019
     */
    @AuraEnabled
    public static BI_LEX_GenericApprovalActionControl.response checkBusinessLineOpp(String recordId, String param, String currencyIsoCode){

        BI_LEX_GenericApprovalActionControl.response result = new BI_LEX_GenericApprovalActionControl.response();
        //Si la línea de negocio es Distinta a Fija, pasaremos el hito directamente
        result.success = true;
        System.debug('--ACR-- params: '+param);
        Map<String, Object> jsonParam = (Map<String, Object>) JSON.deserializeUntyped(param);
        String  OpportunityType = (String)jsonParam.get('BI_Opportunity_Type__c');
        System.debug('--ACR-- JSON.BI_Opportunity_Type__c '+OpportunityType);

        NE__Order__c quote = [SELECT id, NE__OptyId__r.BI_Opportunity_Type__c FROM NE__Order__c WHERE Id=:recordId LIMIT 1];
        if(quote.NE__OptyId__r.BI_Opportunity_Type__c == OpportunityType){
            //En el caso que sea fija, pararemos esta condición, y valoraremos las reglas del hito.
            result.success = false;
        }

        return result;
    }
    /**
     * @description Apex method to evaluate the NAV condition on feasibility economic table
     * @author Diego Arias Fernández
     * @date 09/08/2019
     */
     /* DAF 17092019 Se comenta ya que en Chile no aplica para Tabla factibilidad economica
    @AuraEnabled
    public static Map<Id, Boolean> checkNAVCondition(List<NE__OrderItem__c> listOI){
        Map<Id, Boolean> mapReturn = new Map<Id, Boolean>();
        Set<Id> setAux = new Set<Id>();
        for(NE__OrderItem__c oit : listOI){
            setAux.add(oit.Id);
        }
        for(NE__OrderItem__c oit : [SELECT Id FROM NE__OrderItem__c WHERE Id IN :setAux]){
            mapReturn.put(oit.Id, null); // A la espera de eliminación de tabla economica. Por ahora siempre aparece nulo.
        }
        return mapReturn;
    }*/

    /**
     * @description Apex method to evaluate the Sales condition on feasibility economic table
     * @author Diego Arias Fernández
     * @date 09/08/2019
     */
     /* DAF 17092019 Se comenta ya que en Chile no aplica para Tabla factibilidad economica
    @AuraEnabled
    public static Map<Id, Boolean> checkSalesCondition(List<NE__OrderItem__c> listOI){
        Map<Id, Boolean> mapReturn = new Map<Id, Boolean>();
        Set<Id> setAux = new Set<Id>();
        for(NE__OrderItem__c oit : listOI){
            setAux.add(oit.Id);
        }
        for(NE__OrderItem__c oit : [SELECT Id, Name FROM NE__OrderItem__c WHERE Id IN :setAux]){
            mapReturn.put(oit.Id, null); // A la espera de eliminación de tabla economica. Por ahora siempre aparece nulo.
        }
        return mapReturn;
    }*/

    /**
     * @description Apex method to evaluate the FCV condition on feasibility economic table
     * @author Diego Arias Fernández
     * @date 09/08/2019
     */
     /* DAF 17092019 Se comenta ya que en Chile no aplica para Tabla factibilidad economica
    @AuraEnabled
    public static Map<Id, Boolean> checkFCVCondition(List<NE__OrderItem__c> listOI){
        // Umbral pendiente de definir
        Map<Id, Boolean> mapReturn = new Map<Id, Boolean>();
        Set<Id> setAux = new Set<Id>();
        for(NE__OrderItem__c oit : listOI){
            setAux.add(oit.Id);
        }
        for(NE__OrderItem__c oit : [SELECT Id FROM NE__OrderItem__c WHERE Id IN :setAux]){
            mapReturn.put(oit.Id, null); // A la espera de eliminación de tabla economica. Por ahora siempre aparece nulo.
        }
        return mapReturn;
    }*/

    /**
     * @description Apex method to evaluate the B2W economic field on feasibility economic table
     * @author Diego Arias Fernández
     * @date 03/09/2018
     */
    @AuraEnabled
    public static Map<Id, Boolean> checkB2WDiscountCondition(List<NE__OrderItem__c> listOI){
        Map<Id, Boolean> mapReturn = new Map<Id, Boolean>();
        Set<Id> setAux = new Set<Id>();
        for(NE__OrderItem__c oit : listOI){
            setAux.add(oit.Id);
        }
        for(NE__OrderItem__c oit : [SELECT Id, Name, B2W_CnfItem_Check_Factibilidad_Economica__c FROM NE__OrderItem__c WHERE Id IN :setAux]){
            mapReturn.put(oit.Id, !oit.B2W_CnfItem_Check_Factibilidad_Economica__c);
        }
        return mapReturn;
    }

    /**
     * @description Apex method to check the status of oportunity and not come back the previous status
     * @author Amador Cáceres Rubio
     * @date 06/08/2019
     * @history
     */
    @AuraEnabled
    public static void checkStatusOpp(String recordId){
        BI_MigrationHelper.skipAllTriggers();
    	List<Opportunity> lst_opp = [SELECT Id, StageName FROM Opportunity WHERE Id=:recordId];
        if(!lst_opp.isEmpty()){
            boolean changeActive=false;
            for(Opportunity opp:lst_opp){
                System.debug('opp: '+opp.Id+' -- '+opp.StageName);
                if(opp.StageName == 'F5 - Solution Definition'){
                    opp.StageName = 'F4 - Offer Development';
                    changeActive = true;
                }
            }
            if(changeActive){
                update lst_opp;
            }
        }
        BI_MigrationHelper.cleanSkippedTriggers();
    }

    /**
    * @description Check if the NE__Order__c has any OI Pending
    * @author Carlos Nombela Blanco
    * @date 20/08/2019
    */
    @AuraEnabled   
    public static BI_LEX_GenericApprovalActionControl.response OIHasPending(String recordId){
        BI_LEX_GenericApprovalActionControl.response res = new BI_LEX_GenericApprovalActionControl.response();
        List<NE__OrderItem__c> lOrderItems = [SELECT Id,Name,NE__OrderId__c,NE__Status__c FROM NE__OrderItem__c WHERE  NE__Status__c = 'Pending' AND NE__OrderId__c = :recordId];
        res.success = lOrderItems.isEmpty() ? true : false;
        return res;
    }

    /**
    * @description Get status of the related case from an order
    * @author Diego Arias Fernandez
    * @date 30/08/2019
    */
    @AuraEnabled   
    public static BI_LEX_GenericApprovalActionControl.response getStatusCargaEnSistemasCase(String recordId){
        BI_LEX_GenericApprovalActionControl.response res = new BI_LEX_GenericApprovalActionControl.response();
        List<Case> caseList = [SELECT Id, Status  FROM Case WHERE BI_Oferta_asociada__c =: recordId LIMIT 1];
        res.success = caseList.isEmpty() ? false : (caseList.get(0).Status == 'Closed' ? true : false); 
        return res;
    }

    /**
    * @description Metodo para testear los parámetros de APEX
    * @author David Culebras
    * @date 22/10/2019
    */
    @AuraEnabled
    public static BI_LEX_GenericApprovalActionControl.response testAPEXMethodParam(String recordId, String param, String currencyIsoCode){
        BI_LEX_GenericApprovalActionControl.response res = new BI_LEX_GenericApprovalActionControl.response();
        System.debug('testAPEXMethodParam recordId: '+recordId);
        System.debug('testAPEXMethodParam param: '+param);
        System.debug('testAPEXMethodParam currencyIsoCode: '+currencyIsoCode);
        res.success = true;
        return res;
    }
    /**
    * @description Check if CPQ_TechnicalFeasibilityDate__c and BI_O4_Fecha_de_vigencia_de_la_oferta__c are void
    *               If is void, update with today + 1 months
    * @author Amador Cáceres
    * @date 24/09/2019
    * @Update 07/10/2019: Add condition to populate tecnical date to economic date if economic is null or void
    */
    public static void checkDateIfSimpleProduct(String recordId){
        //BI_LEX_GenericApprovalActionControl.response res = new BI_LEX_GenericApprovalActionControl.response();
        NE__Order__c order = [SELECT Id, CPQ_TechnicalFeasibilityDate__c, BI_O4_Fecha_de_vigencia_de_la_oferta__c  FROM NE__Order__c WHERE Id =: recordId LIMIT 1];
        System.debug('--- Checkeamos las dos fechas, tecnica: '+order.CPQ_TechnicalFeasibilityDate__c+' -- economica: '+order.BI_O4_Fecha_de_vigencia_de_la_oferta__c);
        //Months to add if both dates are void
        Integer monthToAdd = 1;
        List<NE__Order__c> ordersToUpdate = new List<NE__Order__c>();
        //Chequeamos si la fecha de factibilidad tecnica y la económica están vacias.
        if(((order.CPQ_TechnicalFeasibilityDate__c)==null || (order.CPQ_TechnicalFeasibilityDate__c).format()=='') 
        && ((order.BI_O4_Fecha_de_vigencia_de_la_oferta__c)==null || (order.BI_O4_Fecha_de_vigencia_de_la_oferta__c).format() =='')){
            
            order.CPQ_TechnicalFeasibilityDate__c = ((Date.newInstance(System.today().year(), System.today().month(), System.today().day())).addMonths(monthToAdd));
            order.BI_O4_Fecha_de_vigencia_de_la_oferta__c = ((Date.newInstance(System.today().year(), System.today().month(), System.today().day())).addMonths(monthToAdd));
            ordersToUpdate.add(order);
        }
        //ACR 07/10/2019 - New Condition: Si las anteriores no están vacias, y la fecha de vigencia económica esta vacia, la rellenamos.
        else if(!((order.CPQ_TechnicalFeasibilityDate__c)==null || (order.CPQ_TechnicalFeasibilityDate__c).format()=='') 
        && ((order.BI_O4_Fecha_de_vigencia_de_la_oferta__c)==null || (order.BI_O4_Fecha_de_vigencia_de_la_oferta__c).format() =='')){
            order.BI_O4_Fecha_de_vigencia_de_la_oferta__c = order.CPQ_TechnicalFeasibilityDate__c;
            ordersToUpdate.add(order);
        }
        if(!ordersToUpdate.isEmpty()){
            Update ordersToUpdate;
        }
    }
    /**
    * @description Apex Method to evaluate if field NE__Technical_Behaviour_Quote__c contains "Costes Prosionales" value.
    * @author Adrián Cegarra
    * @date 10/12/2019
    */
    @AuraEnabled
    public static BI_LEX_GenericApprovalActionControl.response ciCostProvisional(String recordId){
        BI_LEX_GenericApprovalActionControl.response result = new BI_LEX_GenericApprovalActionControl.response();
        List<NE__OrderItem__c> oitList =  [SELECT Id, NE__CatalogItem__r.NE__Technical_Behaviour_Quote__c FROM NE__OrderItem__c WHERE NE__OrderId__c = :recordId AND NE__CatalogItem__r.NE__Technical_Behaviour_Quote__c INCLUDES (:Label.CPQ_LBL_CosteProvisional)];
        result.success = !oitList.isEmpty() ? false : true;
        return result;
    }

    /**
    * @description Metodo invocable para flow del hito 10 de Argentina (CPQ_CreateCasesContract). Verifica si alguno de los OIs tienen en el Quote Behaviour 'Coste Provisional'
    * @author Diego Arias Fernandez
    * @date 22/10/2019
    */
    /* ACR - 03/12/2019 - Se comenta metodo invocable ya que no se usará en el FLOW
    @InvocableMethod(label='Evaluar autoatendido con obra estandar ARG' description='Evaluar autoatendido con obra estandar para ARG')
    public static List<String> fromH10FlowEvaluateARGAutoatendidoConObraEstandar(List<String> listRecordId){
        List<String> result = new List<String>();
        List<NE__Order__c> oListCountry = [SELECT NE__OptyId__r.BI_Country__c FROM NE__Order__c WHERE Id =: listRecordId.get(0) AND NE__OptyId__r.BI_Country__c =: Label.CPQ_LBL_Argentina];
        if(oListCountry.isEmpty()){
            result.add('false');
        }else{
            List<NE__OrderItem__c> oitList =  [SELECT Id, NE__CatalogItem__r.NE__Technical_Behaviour_Quote__c FROM NE__OrderItem__c WHERE NE__OrderId__c =: listRecordId.get(0) AND NE__CatalogItem__r.NE__Technical_Behaviour_Quote__c INCLUDES (:Label.CPQ_LBL_CosteProvisional)];
            if(!oitList.isEmpty()){
                result.add('true');
            }else{
                result.add('false');        
            }
        }
        return result;
    }/*

    /**
    * @description Checks if CPQ_Coste_Real__c (field from NE__OrderItem__c) is void. In that case, returns false; true if otherwise.
    * @author Sergio Batuecas - Everis
    * @date 10/12/2019
    */
    @AuraEnabled
    public static BI_LEX_GenericApprovalActionControl.response checkRealCostInformed(String recordId){

        //Retrieve list of NE__OrderItem__c related to NE_Order__c with recordId from input.
        List<NE__OrderItem__c> oiList = [SELECT Id, CPQ_Coste_Real__c FROM NE__OrderItem__c WHERE NE__OrderId__c =: recordId AND CPQ_Coste_Real__c !=null];
        BI_LEX_GenericApprovalActionControl.response res = new BI_LEX_GenericApprovalActionControl.response();
        // Set response to true if any of the NE__OrderItem__c records in the list has the CPQ_Coste_Real__c field filled.
        res.success = !oiList.isEmpty() ? true : false;
        return res;
    }

    /**
    * @description Set the CPQ_Type__c to "Firmado" to document attachment
    * @author Amador Cáceres - Everis
    * @date 10/01/2020
    */
    @InvocableMethod(label='Caracterizar Documento Adjuntado' description='Caracteriza el documento adjuntado como ')
    public static void defineTypeDocumentAttach(List<String> listRecordId){

        if(!listRecordId.isEmpty()) {
            List<ContentDocumentLink> lContentLink = new List<ContentDocumentLink>([
                SELECT Id, ContentDocumentId, LinkedEntityId, ContentDocument.LatestPublishedVersionId, ContentDocument.LatestPublishedVersion.CPQ_Type__c 
                FROM ContentDocumentLink WHERE LinkedEntityId in :listRecordId ORDER BY ContentDocument.CreatedDate DESC
            ]);
            if(!lContentLink.isEmpty()){
                ContentVersion cv = new ContentVersion (Id = lContentLink[0].ContentDocument.LatestPublishedVersionId, CPQ_Type__c = 'Firmado');
                update cv;
            }
        }
    }

    /**
    * @description Checks if BI_Ingreso_Recurrente_Anterior_Config__c (field from NE__Order__c) is void and Opportunity is Modify.
    * @author Amador Cáceres - Everis
    * @date 20/01/2020
    */
    @AuraEnabled
    public static BI_LEX_GenericApprovalActionControl.response checkLastRecurringCost(String recordId, String param, String currencyIsoCode){
        BI_LEX_GenericApprovalActionControl.response res = new BI_LEX_GenericApprovalActionControl.response();
        res.success = true;
        //Introducimos la tipología de la oportunidad desde el hito para que este sea configurable desde fuera
        System.debug('testAPEXMethodParam recordId: '+recordId);
        System.debug('testAPEXMethodParam param: '+param);
        System.debug('testAPEXMethodParam currencyIsoCode: '+currencyIsoCode);
        Map<String, Object> jsonParam = (Map<String, Object>) JSON.deserializeUntyped(param);
        String opportunityType = (String)jsonParam.get('tipología');
        List<String> lst_oppType = opportunityType.split(',');
        List<NE__Order__c> lst_or = [SELECT id, BI_Ingreso_Recurrente_Anterior_Config__c FROM NE__Order__c WHERE Id =: recordId AND NE__OptyId__r.BI_SIMP_Opportunity_Type__c in :lst_oppType];
        if(!lst_or.isEmpty()){
            for(NE__Order__c quote : lst_or){
                if(quote.BI_Ingreso_Recurrente_Anterior_Config__c == null)
                    res.success = false;
                    System.debug('--ACR --> Debe informarse el Recurrente Bruto Anterior en el caso de que la oportunidad sea de Modificación');
            }
        }
        return res;
    }
    /**DATA DISPLAY WRAPPERS**/
    public class response{
        @AuraEnabled public String message;
        @AuraEnabled public String newPendingStatus; //For Pending Header check => retrieves new Status for helper.js
        @AuraEnabled public String generatedRecordId; //For record creation => get recordId and associate with history record
        @AuraEnabled public Boolean success;
        @AuraEnabled public Boolean isClosed; //Check if record is cancelled or closed so it shouldn't reevaluate anything
        @AuraEnabled public SObject currentRecord;
        @AuraEnabled public String caseNumber;
        @AuraEnabled public Map<String,String> recordTypeAndSObjectNameLabelMAP;
        @AuraEnabled public List<BI_LEX_GenericApprovalActionControl.actionHeader> actionHeaderLIST;
        @AuraEnabled public List<BI_LEX_GenericApprovalActionControl.apexMethodConditionWrapper> conditionSuccessLIST;
    }
    public class actionHeader{
        @AuraEnabled public String name;
        @AuraEnabled public String order;
        @AuraEnabled public String tooltip;
        @AuraEnabled public String message;
        @AuraEnabled public String colorClass;
        @AuraEnabled public String referenceId;
        @AuraEnabled public String colorTooltip;
        @AuraEnabled public String parentAction;
        @AuraEnabled public String logicConditions;
        @AuraEnabled public String parentHeaderRelationField;
        @AuraEnabled public Boolean isParent;
        @AuraEnabled public Boolean allowedUser;
        @AuraEnabled public Boolean displayButton;
        @AuraEnabled public Boolean allowReevaluate;
        @AuraEnabled public Boolean previewConditions;
        @AuraEnabled public List<BI_LEX_Condition__c> conditionLIST;
        //@AuraEnabled public BI_LEX_GenericApprovalActionControl.childHeader childHeader; //Child header action related [ONLY ONE => IF MORE - MANAGEMENT ERROR]
        @AuraEnabled public List<BI_LEX_GenericApprovalActionControl.actionHeaderStep> actionHeaderStepLIST;
        @AuraEnabled public List<BI_LEX_GenericApprovalActionControl.actionHeaderStep> actionHeaderPreStepLIST;
    }
    public class childHeader{
        @AuraEnabled public String referenceId;
        @AuraEnabled public String sObjectName;
        @AuraEnabled public String referenceField;
        @AuraEnabled public String conditionsLogic;
        @AuraEnabled public List<BI_LEX_Condition__c> conditionLIST;
        @AuraEnabled public BI_LEX_ApprovalActions__c action; //[ONLY ONE => IF MORE - MANAGEMENT ERROR]
    }
    public class actionHeaderStep{
        @AuraEnabled public String name;
        @AuraEnabled public String message;
        @AuraEnabled public String referenceId;
        @AuraEnabled public BI_LEX_GenericApprovalActionControl.actionHeaderStepAttribute actionHeaderStepAttributeLIST;
    }
    public class actionHeaderStepAttribute{
        //@AuraEnabled public String apexMethod;
        @AuraEnabled public String sObjectName;
        //@AuraEnabled public String fieldRelation;
        @AuraEnabled public String logicConditions;
        @AuraEnabled public String lightningAPIName;
        @AuraEnabled public String logicConditionsError;
        @AuraEnabled public String recordTypeIdCreation;
        @AuraEnabled public String recordTypeDevNameForCreation;
        @AuraEnabled public String approvalProcessNameReference;
        @AuraEnabled public Boolean updateCurrentRecord;
        @AuraEnabled public Boolean manualApprovalProcess;
        @AuraEnabled public List<BI_LEX_Condition__c> conditionLIST;
        @AuraEnabled public List<BI_LEX_Condition__c> auraparamLIST;
        @AuraEnabled public List<BI_LEX_Condition__c> fieldparamLIST;
        @AuraEnabled public List<BI_LEX_Condition__c> pendingcheckLIST;
        @AuraEnabled public List<BI_LEX_Condition__c> parentHeaderCheckLIST;
    }
    
    /**HISTORY ENTRY WRAPPER**/
    public class headerAndStepInfo{
        @AuraEnabled public String headerId;
        @AuraEnabled public String actionId;
    }
    
    /**RECORD CREATION WRAPPER**/
    public class recordFieldData{
        @AuraEnabled public String value;
        @AuraEnabled public String fieldName;
        @AuraEnabled public Boolean disabled;
        @AuraEnabled public Boolean required;
        public recordFieldData(String value, String fieldName, Boolean disabled, Boolean required){
            this.value = value;
            this.fieldName = fieldName;
            this.disabled = disabled;
            this.required = required;
        }
    }
    
    /**APEX METHOD CONDITIONS WRAPPER**/
    public class apexMethodConditionWrapper{
        @AuraEnabled public BI_LEX_Condition__c record;
        @AuraEnabled public Boolean success;
        public apexMethodConditionWrapper(BI_LEX_Condition__c record, Boolean success){
            this.record = record;
            this.success = success;
        }
    }
    
    /**LOGIC CONDITIONS CHECK WRAPPER**/
    public class logicConditionResult{
        @AuraEnabled public Boolean result;
        @AuraEnabled public Integer index;
    }
    
    /**LIGHTNING:FLOW CALL WRAPPERS**/
    public class lightningFlowParams{
    	@AuraEnabled public String DeveloperName;
    	@AuraEnabled public List<BI_LEX_GenericApprovalActionControl.lightningFlowInputVariable> inputVariables; 
        public lightningFlowParams(String DeveloperName, List<BI_LEX_GenericApprovalActionControl.lightningFlowInputVariable> inputVariables){
            this.DeveloperName = DeveloperName;
            this.inputVariables = inputVariables;
        }
    }
    public class lightningFlowInputVariable{
        @AuraEnabled public String name;
        @AuraEnabled public String type;
        @AuraEnabled public Object value;
        public lightningFlowInputVariable(String name, String type, Object value){
            this.name = name;
            this.type = type;
            this.value = value;
        }
    }
    public class lightningFlowInputVariableSObjectId{
        @AuraEnabled public Object Id;
        public lightningFlowInputVariableSObjectId(Object Id){
            this.Id = Id;
        }
    }
    
    /**RECORD ACCESS WRAPPER**/
    public class recordAccessWrapper{
        @AuraEnabled public Boolean success;
        @AuraEnabled public Boolean byPassSystemAdmin;
        @AuraEnabled public List<String> userPermissionLIST;
    }
}