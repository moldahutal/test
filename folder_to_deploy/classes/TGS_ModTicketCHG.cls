/*------------------------------------------------------------ 
Author:         Ana Cirac 
Company:        Deloitte
Description:    Class to create/update CHANGES
History
<Date>          <Author>        <Change Description>
24-Feb-2015     Ana Cirac        Initial Version
21-Oct-2016     JC Terrón        Deleted IF(logInContact) sentence since it's already in the called method. Lines  171,312.
------------------------------------------------------------*/
global with sharing class TGS_ModTicketCHG {
    
    /* A CHG is created or updated */
    webservice static TGS_ModTicket.Result upsertCHG(String Ticket_ID, String CaseNumber, String Operation, String Impact, String Urgency, String Subject, String Description, String Reported_Source, String AssigneeName, String logInContact, String Company,
                                       String Direct_Contact_Site, String Direct_Contact_Department, String  CI_ID, String Categorization_Tier_1, String Categorization_Tier_2, String Categorization_Tier_3, String Product_Categorization_Tier_1, String Product_Categorization_Tier_2, 
                                       String Product_Categorization_Tier_3, String Direct_Contact_Organization, String Coordinator_Group, String Status, String Status_Reason, String Priority, String Timming, String TGS_Actual_End_Date, String TGS_Actual_Start_Date,
                                       String TGS_Scheduled_Start_Date, String TGS_Scheduled_End_Date, String TGS_Site_Id_RoD){
    Savepoint savePointCheckout = Database.setSavepoint();  
    /* Result of the request */
     TGS_ModTicket.Result resul = new TGS_ModTicket.Result();
     
     try{
         if (Operation.equals(TGS_ModTicket.ROD_SF_CREATE_CHANGE)){ 
            /*CREATES A CHG*/
            resul = createCHG(Ticket_ID, CaseNumber,  Operation,  Impact, Urgency, Subject,  Description, Reported_Source, AssigneeName, logInContact,  Company,
                      Direct_Contact_Site, Direct_Contact_Department, CI_ID, Categorization_Tier_1, Categorization_Tier_2, Categorization_Tier_3, Product_Categorization_Tier_1, Product_Categorization_Tier_2, 
                      Product_Categorization_Tier_3, Direct_Contact_Organization, Coordinator_Group, Status, Status_Reason, Priority, Timming,TGS_Actual_End_Date,TGS_Actual_Start_Date,TGS_Scheduled_Start_Date,
                      TGS_Scheduled_End_Date,TGS_Site_Id_RoD);
            
         }else if(Operation.equals(TGS_ModTicket.ROD_SF_MODIFY_CHANGE)){
            /*UPDATES A CHG*/
            resul = updateCHG(Ticket_ID, CaseNumber,  Operation,  Impact, Urgency, Subject,  Description, Reported_Source, AssigneeName, logInContact,  Company,
                      Direct_Contact_Site, Direct_Contact_Department, CI_ID, Categorization_Tier_1, Categorization_Tier_2, Categorization_Tier_3, Product_Categorization_Tier_1, Product_Categorization_Tier_2, 
                      Product_Categorization_Tier_3, Direct_Contact_Organization, Coordinator_Group, Status, Status_Reason, Priority, Timming,TGS_Actual_End_Date,TGS_Actual_Start_Date,TGS_Scheduled_Start_Date,
                      TGS_Scheduled_End_Date,TGS_Site_Id_RoD);
            
         }else{
            
            throw new IntegrationException('Invalid Operation');
         }
     } catch(Exception e) {
            resul.Operation_Status = 'ERROR'; 
            resul.Error_Msj = e.getMessage();
            resul.CaseNumber = CaseNumber;
            system.debug('Exception found: '+e+' At line: '+e.getLineNumber());
            DataBase.rollback(savePointCheckout);
            //add a tgs_error_integrations_c object
            TGS_Error_Integrations__c error= new TGS_Error_Integrations__c();
            error.TGS_Interface__c = 'ROD'; 
            error.TGS_Operation__c = Operation;
            error.TGS_RecordId__c = CaseNumber;                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               
            error.TGS_RequestInfo__c = 'Message: '+e.getMessage();
            insert error;
     }  
     return resul;
    
    }
    /*------------------------------------------------------------ 
    Author:         Ana Cirac 
    Company:        Deloitte
    Description:    Web Service that consumes RoD to create CHANGES
    History
    <Date>          <Author>        <Change Description>
    24-Feb-2015     Ana Cirac        Initial Version
    ------------------------------------------------------------*/
     static TGS_ModTicket.Result createCHG(String Ticket_ID, String CaseNumber, String Operation, String Impact, String Urgency, String Subject, String Description, String Reported_Source, String AssigneeName, String logInContact, String Company,
                                       String Direct_Contact_Site, String Direct_Contact_Department, String CI_ID, String Categorization_Tier_1, String Categorization_Tier_2, String Categorization_Tier_3, String Product_Categorization_Tier_1, String Product_Categorization_Tier_2, 
                                       String Product_Categorization_Tier_3, String Direct_Contact_Organization, String Coordinator_Group, String Status, String Status_Reason, String Priority, String Timming, String TGS_Actual_End_Date, String TGS_Actual_Start_Date,
                                       String TGS_Scheduled_Start_Date, String TGS_Scheduled_End_Date, String TGS_Site_Id_RoD){
                                        
            TGS_ModTicket.Result resul = new TGS_ModTicket.Result();     
            resul.operation_status = 'OK'; 
            /* New Case to create */
            Case caseNew = new Case();  
            caseNew.TGS_Ticket_Id__c=Ticket_ID;
            /* Record Type */ 
            //Id rtId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Change').getRecordTypeId();                     
            Id rtId = TGS_RecordTypes_Util.getRecordTypeId(Case.SObjectType,'TGS_Change');
            caseNew.RecordTypeId = rtId;
            caseNew.Type = 'Change';
            /* Technical_Assignee */
            caseNew.TGS_Technical_Assignee__c = AssigneeName;
            
             /*TGS_Acting_as__c */
             //caseNew.TGS_Acting_as__c = 'Authorized User';
            /*Coordinator Group*/
            if(!String.isNotBlank(Coordinator_Group)){      
                
                throw new IntegrationException('Coordinator Group is mandatory');   
            }else {
                /* attributes caseNew.ownerId is assigned */
                TGS_ModTicket.validateOwner(caseNew,Coordinator_Group);
            }
            /*Timming */     
            if (String.isNotBlank(Timming)){        
                    
                caseNew.TGS_Change_Type__c = Timming;
                            
            }
            /* TGS_Ticket_Site__c */
            String site = TGS_ModTicket.ValidateSite(Direct_Contact_Site);
             if(site.equals('-1')){
                        
                throw new IntegrationException('Invalid Direct Contact Site');  
             }else if (String.isNotBlank(site)){ 
                    caseNew.TGS_Ticket_Site__c =site;
             }
            /* Impact */
            Set<String> listImpact= TGS_ModTicket.getPickListValues('Case','TGS_Impact__c');
           
            if (!String.isNotBlank(Impact)){         
                    
                throw new IntegrationException('Impact is mandatory');  
                            
            }else if(!listImpact.contains(Impact)) {
                
                throw new IntegrationException('The Impact ' +Impact+ ' does not exist');   
                
            }else{
                caseNew.TGS_Impact__c = Impact;
            }
            /* Valid values of Urgency */
            Set<String> lstUrgency = TGS_ModTicket.getPickListValues('Case','TGS_Urgency__c');
                system.debug(lstUrgency);
            if (!String.isNotBlank(Urgency)){       
                
                throw new IntegrationException('Urgency is mandatory'); 
                            
            }else if(!lstUrgency.contains(Urgency)) {
                
                throw new IntegrationException('The Urgency ' +Urgency+ ' does not exist'); 
                
            }else{
                
                caseNew.TGS_Urgency__c = Urgency;
            }   
            /* Subject */
            if (!String.isNotBlank(Subject)){       
                
                throw new IntegrationException('Description is mandatory'); 
                            
            }else{
                caseNew.Subject = Subject;
            }
            /* Description */
            if (!String.isNotBlank(Description)){       
                
                throw new IntegrationException('Detailed Description is mandatory');    
                            
            }else{
                // Álvaro López - Added abbreviate for Description
                if(Description.length() > 32000){
                    caseNew.Description = Description.abbreviate(32000);
                }
                else{
                    caseNew.Description = Description;
                }
            }
            /* Origin*/
            if (!String.isNotBlank(Reported_Source)){       
                
                throw new IntegrationException('Reported Source is mandatory'); 
                
            }else if (!TGS_ModTicket.validReportedSources.contains(Reported_Source)){

                throw new IntegrationException('The Reported Source ' +Reported_Source+ ' is not valid');   
                    
            }else {
                
                caseNew.origin = TGS_ModTicket.validateReportedSource(Reported_Source);  
                
            }
            
            /* Account */
           if(!TGS_ModTicket.validateAccount(caseNew,Direct_Contact_Organization,Direct_Contact_Department, Company)){
               
                throw new IntegrationException('A valid Account is mandatory');
            }
            /* Attribute Assignee*/
            //JCT 21/10/2016 Deleted IF(logInContact) sentence since it's already in the called method.
            TGS_ModTicket.validateContact(caseNew,logInContact);
            
            /* Status */
            if (!String.isNotBlank(Status)){        
                    
                throw new IntegrationException('Status is mandatory');  
                            
            }else {
                
                 
                 caseNew.Status = 'Assigned';
                  /*TGS_Acting_as__c */
                  //caseNew.TGS_Acting_as__c =  TGS_ModTicket.OB;
            }
                            
            /* Validates Not Mandatory attributes  */
            TGS_ModTicket.validateNotMandatoryAtt(caseNew, Status_Reason, Priority, Categorization_Tier_1, Categorization_Tier_2,
                                              Categorization_Tier_3, Product_Categorization_Tier_1, Product_Categorization_Tier_2, Product_Categorization_Tier_3, '');
           
            /*TGS_Actual_End_Date */     
            if (String.isNotBlank(TGS_Actual_End_Date)){        
                    
                caseNew.TGS_Actual_End_Date__c = parseStringDate(TGS_Actual_End_Date);
                            
            }
            
            /*TGS_Actual_Start_Date */     
            if (String.isNotBlank(TGS_Actual_Start_Date)){        
                    
                caseNew.TGS_Actual_Start_Date__c = parseStringDate(TGS_Actual_Start_Date);
                            
            }
            
            /*TGS_Scheduled_Start_Date */     
            if (String.isNotBlank(TGS_Scheduled_Start_Date)){        
                    
                caseNew.TGS_Scheduled_Start_Date__c =  parseStringDate(TGS_Scheduled_Start_Date);
                            
            }
            
            /*TGS_Scheduled_End_Date */     
            if (String.isNotBlank(TGS_Scheduled_End_Date)){        
                    
                caseNew.TGS_Scheduled_End_Date__c =  parseStringDate(TGS_Scheduled_End_Date);
                            
            }
            
            /*TGS_Site_Id_RoD */     
            if (String.isNotBlank(TGS_Site_Id_RoD)){        
                    
                caseNew.TGS_Site_Id_RoD__c = TGS_Site_Id_RoD;
                            
            }                              
                                           
             /* Skip assigment rules*/
            Database.DMLOptions dmo = new Database.DMLOptions();
            dmo.assignmentRuleHeader.useDefaultRule= false;
            caseNew.setOptions(dmo);
             /* validate and assigns CI_ID*/
            TGS_ModTicket.validateCI(caseNew,CI_ID);
            /* Inserts the case */
            insert caseNew;  
           
           
            /* Updates the case Status */ 
            if (Status.equals('In Progress')){
                
                caseNew.Status = Status;
               
                /*TGS_Acting_as__c */
                //caseNew.TGS_Acting_as__c =  TGS_ModTicket.SA;
                
                update caseNew;
            }
            /* Calculates the CaseNumber of the case to retun it */
            String caseNum = [SELECT Id, CaseNumber FROM Case WHERE Id=:caseNew.Id].CaseNumber;
            //resul.ID_Ticket = caseNew.Id; 
            resul.CaseNumber = caseNum;
            return resul;
     }
    /*------------------------------------------------------------ 
    Author:         Julio ASenjo
    Company:        Everis
    Description:    aux method to parse string date 
    History
    <Date>          <Author>        <Change Description>
    24-Feb-2015     Ana Cirac        Initial Version
    ------------------------------------------------------------*/
    
    public Static DateTime parseStringDate(string d){
        // FORMAT Expected = '2017-07-27T17:48:00+02:00'
        return datetime.newInstance(integer.valueof(d.substring(0, 4)), integer.valueof(d.substring(5, 7)), integer.valueof(d.substring(8, 10)), integer.valueof(d.substring(11, 13)),integer.valueof(d.substring(14, 16)),integer.valueof(d.substring(17, 19)));


    }
     /*------------------------------------------------------------ 
    Author:         Ana Cirac 
    Company:        Deloitte
    Description:    Web Service that consumes RoD to update CHANGES
    History
    <Date>          <Author>        <Change Description>
    24-Feb-2015     Ana Cirac        Initial Version
    ------------------------------------------------------------*/
     static TGS_ModTicket.Result updateCHG(String Ticket_ID, String CaseNumber, String Operation, String Impact, String Urgency, String Subject, String Description, String Reported_Source, String AssigneeName, String logInContact, String Company,
                                       String Direct_Contact_Site, String Direct_Contact_Department, String CI_ID, String Categorization_Tier_1, String Categorization_Tier_2, String Categorization_Tier_3, String Product_Categorization_Tier_1, String Product_Categorization_Tier_2, 
                                       String Product_Categorization_Tier_3, String Direct_Contact_Organization, String Coordinator_Group, String Status, String Status_Reason, String Priority, String Timming, String TGS_Actual_End_Date, String TGS_Actual_Start_Date,
                                       String TGS_Scheduled_Start_Date, String TGS_Scheduled_End_Date, String TGS_Site_Id_RoD){
                                           
            System.debug('STATUS RECIBIDO: '+Status);                                                    
            TGS_ModTicket.Result resul = new TGS_ModTicket.Result();     
            resul.operation_status = 'OK'; 
            resul.CaseNumber = CaseNumber; 
            if (!String.isNotBlank(CaseNumber)){
                throw new IntegrationException('CaseNumber Mandatory');
            }
            //RPM 04/05/2017 recupera el RecordTypeId que antes no lo recuperaba                              
            List<Case> lisCaseUpdate = [SELECT ID, CaseNumber,RecordTypeId, Account.RecordType.DeveloperName FROM Case WHERE CaseNumber=:CaseNumber];
            //FIN RPM                               
             if (lisCaseUpdate.size()==0){
                
                throw new IntegrationException('Invalid CaseNumber');
                
            }
            /*Case to update */
            Case caseUpdate  = lisCaseUpdate.get(0);         
            /* Technical_Assignee */
            caseUpdate.TGS_Technical_Assignee__c = AssigneeName;
           
            /*ownerId */
            if (String.isNotBlank(Coordinator_Group)){  
                    
              TGS_ModTicket.validateOwner(caseUpdate,Coordinator_Group);
            }
        
             if (String.isNotBlank(Timming)){       
                
                caseUpdate.TGS_Change_Type__c = Timming;
                        
             }
            if (String.isNotBlank(Direct_Contact_Site)){    
                  /* TGS_Ticket_Site__c */
                  String site = TGS_ModTicket.ValidateSite(Direct_Contact_Site);
                  if(site.equals('-1')){
                            
                    throw new IntegrationException('Invalid Direct Contact Site');  
                  }else if (String.isNotBlank(site)){    
                        caseUpdate.TGS_Ticket_Site__c =site;
                  }
             }
            /* Impact */
            if (String.isNotBlank(Impact)){      
                Set<String> listImpact= TGS_ModTicket.getPickListValues('Case','TGS_Impact__c');    
                if(!listImpact.contains(Impact)) {
                    
                    throw new IntegrationException('The Impact ' +Impact+ ' does not exist');   
                    
                }else{
                    caseUpdate.TGS_Impact__c = Impact;
                }
            }
            /* Urgency */
            if (String.isNotBlank(Urgency)){
                /* Valid Urgency */     
                Set<String> lstUrgency = TGS_ModTicket.getPickListValues('Case','TGS_Urgency__c');
                if(!lstUrgency.contains(Urgency)) {
                    
                    throw new IntegrationException('The Urgency ' +Urgency+ ' does not exist'); 
                    
                }else{
                    
                    caseUpdate.TGS_Urgency__c = Urgency;
                }   
            }  
            /* Subject */
            if (String.isNotBlank(Subject)){        
                caseUpdate.Subject = Subject;
            }
            /* Description */
            if (String.isNotBlank(Description)){ 
                // Álvaro López - Added abbreviate for Description
                if(Description.length() > 32000){
                    caseUpdate.Description = Description.abbreviate(32000);
                }
                else{
                    caseUpdate.Description = Description;
                }
            }
            /* Origin*/
            if (String.isNotBlank(Reported_Source)){        
                /* valid Reported Sources */
               if (!TGS_ModTicket.validReportedSources.contains(Reported_Source)){
                
                    throw new IntegrationException('The Reported Source ' +Reported_Source+ ' is not valid');   
                }else {
                    caseUpdate.origin = TGS_ModTicket.validateReportedSource(Reported_Source); 
                }
            }   

            /* Account */
           TGS_ModTicket.updateAccounts(caseUpdate, Direct_Contact_Department, Direct_Contact_Organization,Company);
            /* Attribute Assignee*/
            //JCT 21/10/2016 Deleted IF(logInContact) sentence since it's already in the called method.
            TGS_ModTicket.validateContact(caseUpdate,logInContact);
           
            /* contactId */
            /* try{
                Contact contact = [SELECT Id,Name FROM Contact WHERE Email=:Email];
                caseUpdate.ContactId= contact.Id;
            }catch(Exception e){
                throw new IntegrationException('Invalid Email');    
            }*/
            
            /* Status */
            if (String.isNotBlank(Status)){     
                    
               if(!TGS_ModTicket.validStatus.contains(Status)){
                    
                    throw new IntegrationException('The Status ' +Status+ ' does not exist');   
                }else{
                     caseUpdate.Status = Status;
                         
                     
                          
                        /*TGS_Acting_as__c */
                        //caseUpdate.TGS_Acting_as__c =  TGS_ModTicket.OB;
                       
                            
                        
                        /* If Status=Resolved -> Proposed Solution = Change Completed, please review and confirm acceptance */
                        if(Status.equals(Constants.CASE_STATUS_RESOLVED)){
                            String solution = 'Change Completed, please review and confirm acceptance';
                            TGS_ModTicket.setResolution(solution,caseUpdate.Id);

                        }
                    
                }
            }
            /* Validates Not Mandatory attributes  */
            TGS_ModTicket.validateNotMandatoryAtt(caseUpdate, Status_Reason, Priority, Categorization_Tier_1, Categorization_Tier_2,
                                              Categorization_Tier_3, Product_Categorization_Tier_1, Product_Categorization_Tier_2, Product_Categorization_Tier_3, '');
                       
            /*TGS_Actual_End_Date */     
            if (String.isNotBlank(TGS_Actual_End_Date)){        
                    
                caseUpdate.TGS_Actual_End_Date__c = parseStringDate(TGS_Actual_End_Date);
                            
            }
            
            /*TGS_Actual_Start_Date */     
            if (String.isNotBlank(TGS_Actual_Start_Date)){        
                    
                caseUpdate.TGS_Actual_Start_Date__c =  parseStringDate(TGS_Actual_Start_Date);
                            
            }
            
            /*TGS_Scheduled_Start_Date */     
            if (String.isNotBlank(TGS_Scheduled_Start_Date)){        
                    
                caseUpdate.TGS_Scheduled_Start_Date__c = parseStringDate(TGS_Scheduled_Start_Date);
                            
            }
            
            /*TGS_Scheduled_End_Date */     
            if (String.isNotBlank(TGS_Scheduled_End_Date)){        
                    
                caseUpdate.TGS_Scheduled_End_Date__c =  parseStringDate(TGS_Scheduled_End_Date);
                            
            }
            
            /*TGS_Site_Id_RoD */     
            if (String.isNotBlank(TGS_Site_Id_RoD)){        
                    
                caseUpdate.TGS_Site_Id_RoD__c = TGS_Site_Id_RoD;
                            
            }
            /* validates and assigns CI_ID*/
            TGS_ModTicket.validateCI(caseUpdate,CI_ID);
            /* Updates the case */
            update caseUpdate;  
           
            return resul;
     }

}