/*-------------------------------------------------------------------------------------------------------------------------------------------------------
     Author:        Manuel Ochoa
     Company:       Accenture - Tecnilogica
     Description:   Controller class for BI_LEX_CreateMultipleSubOpp lightning component
     Test Class:    BI_LEX_CreateMultipleSubOpp_TEST
     History:
     
     <Date>             <Author>                <Description>
     2019-12-16		    Manuel Ochoa		    First version     
    --------------------------------------------------------------------------------------------------------------------------------------------------------*/
public class BI_LEX_CreateMultipleSubOppControl {
    
    public static Boolean allowAction;
    public static Boolean bIsMultiSite;
    
    public static String holdingID;    
    
    public static Integer grabarActual;
    public static Integer faltanGrabar;
    
    public static Opportunity actualOpp;
    
    public static List<String> countriesSET;
    public static Set<String> serviceLineSaveSubOppSET;
    public static Set<String> catalogIDSET;
    
    //public static Map<String, String> serviceLinesTotalMAP;
    
    public static List<Opportunity> insertedsuboppLIST = new List<Opportunity>();
    public static List<BI_LEX_CreateMultipleSubOppControl.wrapperHelperOptions> customerLIST;    
    public static List<BI_LEX_CreateMultipleSubOppControl.wrapperHelperOptions> countriesEMEALIST;
    public static List<BI_LEX_CreateMultipleSubOppControl.wrapperHelperOptions> countriesAmericaLIST;
    public static List<BI_LEX_CreateMultipleSubOppControl.wrapperHelperOptions> countriesRestWorldLIST;

	//2019-12-16     Manuel Ochoa    New version	
	public static List<BI_LEX_CreateMultipleSubOppControl.wrapperHelperOptions> catalogCategoriesLIST;
	public static Map<String,List<BI_LEX_CreateMultipleSubOppControl.wrapperHelperOptions>> catalogItemsMAP; // KEY: CatalogCategoryId, VALUE: wrapperHelperOptions
	public static Map<String,String> productNamesMap; // KEY: CatalogItemId, VALUE: CategoryName + ProductName
	public static List<String> serviceLineSET;
	//2019-12-16     Manuel Ochoa    New version 
    
    public static Map<String,Account> accountCountryMAP;
    
    //For test class
    public static Boolean avoidTestPermission = false;

	/*-------------------------------------------------------------------------------------------------
    Company:       Accenture - Tecnilogica
    Description:   Retrieves data of parent opty, catalog data and countries lists

	IN:             String recordId - opty Id
    OUT:            BI_LEX_CreateMultipleSubOppControl.wrapperHelper
    
    History:
    
    <Date>             <Author>                <Description>
    2019-12-16		    Manuel Ochoa		    First version
    ----------------------------------------------------------------------------------------------------*/
    @AuraEnabled
    public static BI_LEX_CreateMultipleSubOppControl.wrapperHelper getInitialInformation(String recordId){
        
        BI_LEX_CreateMultipleSubOppControl.wrapperHelper response = new BI_LEX_CreateMultipleSubOppControl.wrapperHelper(); 
        
		customerLIST = new List<BI_LEX_CreateMultipleSubOppControl.wrapperHelperOptions>();		
        countriesEMEALIST = new List<BI_LEX_CreateMultipleSubOppControl.wrapperHelperOptions>();
        countriesAmericaLIST = new List<BI_LEX_CreateMultipleSubOppControl.wrapperHelperOptions>();
        countriesRestWorldLIST = new List<BI_LEX_CreateMultipleSubOppControl.wrapperHelperOptions>();

		//2019-12-16     Manuel Ochoa    New version
		catalogCategoriesLIST = new List<BI_LEX_CreateMultipleSubOppControl.wrapperHelperOptions>();
		catalogItemsMAP = new Map<String,List<BI_LEX_CreateMultipleSubOppControl.wrapperHelperOptions>>();
		productNamesMap = new  Map<String,String>();
		map<String,List<String>> mapCatalogNames = new map<String,List<String>>();

		FOR(BI_LEX_Catalogs__mdt cat: [SELECT BI_LEX_CatalogName__c,BI_LEX_CategoryNames__c,BI_LEX_Active__c FROM BI_LEX_Catalogs__mdt WHERE BI_LEX_Active__c=true]){			
			mapCatalogNames.put(cat.BI_LEX_CatalogName__c,cat.BI_LEX_CategoryNames__c.split(';'));			
		}
		system.debug(mapCatalogNames);

		FOR(NE__Catalog_Item__c catItem: [SELECT id,
												Name,
												NE__Catalog_Id__r.Name,
												NE__Catalog_Category_Name__c,												
												NE__Catalog_Category_Name__r.NE__Path_parent__c,
												NE__Catalog_Category_Name__r.name,
												BI_Nombre_del_Producto__c 
											FROM NE__Catalog_Item__c 
									   		WHERE NE__Catalog_Id__r.Name IN :mapCatalogNames.keyset()
											AND NE__Parent_Catalog_Item__c = null 
											AND NE__Active__c = true]){

			productNamesMap.put(catitem.Id, catitem.NE__Catalog_Category_Name__r.name + ' - ' + catitem.BI_Nombre_del_Producto__c);
			If(mapCatalogNames.containsKey(catItem.NE__Catalog_Id__r.Name)){								
				if(mapCatalogNames.get(catItem.NE__Catalog_Id__r.Name).indexOf(catItem.NE__Catalog_Category_Name__r.name)!=-1){
					if(catalogItemsMAP.containsKey(catItem.NE__Catalog_Category_Name__c)){
						catalogItemsMAP.get(catItem.NE__Catalog_Category_Name__c).add(new BI_LEX_CreateMultipleSubOppControl.wrapperHelperOptions(catItem.BI_Nombre_del_Producto__c,catItem.Id));
					}else{
						String categoryLabel = catItem.NE__Catalog_Category_Name__r.NE__Path_parent__c + ' / ' + catItem.NE__Catalog_Category_Name__r.name;
						categoryLabel = categoryLabel.remove('/ ' + catItem.NE__Catalog_Id__r.Name);
						categoryLabel = catItem.NE__Catalog_Id__r.Name + categoryLabel;
						catalogCategoriesLIST.add(new BI_LEX_CreateMultipleSubOppControl.wrapperHelperOptions(categoryLabel,catItem.NE__Catalog_Category_Name__c));
						List<BI_LEX_CreateMultipleSubOppControl.wrapperHelperOptions> auxList = new List<BI_LEX_CreateMultipleSubOppControl.wrapperHelperOptions>();
						auxList.add(new BI_LEX_CreateMultipleSubOppControl.wrapperHelperOptions(catItem.BI_Nombre_del_Producto__c,catItem.Id));
						catalogItemsMAP.put(catItem.NE__Catalog_Category_Name__c,auxList);
					}					
				}												
			}
		}
		system.debug('MOF_DEBUG Catalog Items Map');
		system.debug(JSON.serialize(catalogCategoriesLIST));
		system.debug(JSON.serialize(catalogItemsMAP));
		system.debug(JSON.serialize(productNamesMap));
		
		//2019-12-16     Manuel Ochoa    New version

        accountCountryMAP = new Map<String,Account>();
        //serviceLinesTotalMAP = new Map<String,String>();
	    actualOpp = [SELECT CloseDate, 
							Name, 
							StageName, 
							BI_O4_Opportunity_Type__c, 
							BI_O4_Service_Lines__c, 
							BI_Fecha_de_vigencia__c, 
							BI_O4_Paises__c, 
							AccountId, 
							Account.ParentId, 
                     		Account.Parent.ParentId, 
							Account.RecordType.DeveloperName, 
							Account.Name, 
							BI_O4_Countries_EMEA__c, 
							BI_O4_Countries_America__c, 
							BI_O4_Countries_Rest_of_the_world__c
							FROM Opportunity
							WHERE Id = :recordId];

        if (actualOpp.Account.RecordType.DeveloperName == Constants.RECORD_TYPE_TGS_HOLDING){
        	holdingID = actualOpp.AccountId;    
        }
        else if (actualOpp.Account.RecordType.DeveloperName == Constants.RECORD_TYPE_TGS_CUSTOMER_COUNTRY){
        	holdingID = actualOpp.Account.ParentId;    
        }	
        else if (actualOpp.Account.RecordType.DeveloperName == Constants.RECORD_TYPE_TGS_LEGAL_ENTITY){
        	holdingID = actualOpp.Account.Parent.ParentId;    
        }
		if (actualOpp.BI_O4_Opportunity_Type__c == 'Global Distributed'){
			Id rtCCId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('TGS_Customer_Country').getRecordTypeId();
			List<Account> lstCC = [SELECT Id, Name, BI_Country__c 
									FROM Account 
									WHERE ParentId = :holdingId
                                   	AND RecordTypeId = :rtCCId];
            
			for(Account acc : lstCC) {
				accountCountryMAP.put(acc.Name, acc);
			}
		}
		if (actualOpp.BI_O4_Opportunity_Type__c == 'Local Distributed'){
			Id rtLEId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('TGS_Legal_Entity').getRecordTypeId();
			List<Account> lstLE = [SELECT Id, Name, BI_Country__c 
									FROM Account 
									WHERE (ParentId = :actualOpp.AccountId AND RecordTypeId = :rtLEId) 
									OR Id = :actualOpp.AccountId
									ORDER BY RecordType.DeveloperName];
			for(Account acc : lstLE) {
				customerLIST.add(new BI_LEX_CreateMultipleSubOppControl.wrapperHelperOptions(acc.Name, acc.Name));
				accountCountryMAP.put(acc.Name, acc);
			}
		}
        //First error
		if(String.isBlank(actualOpp.BI_O4_Opportunity_Type__c)) {
            response.errorMessage = Label.BI_O4_Opportunity_Type_Mandatory;
		}		
        
        //Get picklist values from countries(America, EMEA, Rest of the world) if type is 'Centralized' or 'Global distribuited'
        for(Schema.PicklistEntry plc1 : Opportunity.BI_O4_Countries_America__c.getDescribe().getPicklistValues()){
            countriesAmericaLIST.add(new BI_LEX_CreateMultipleSubOppControl.wrapperHelperOptions(plc1.getLabel(), plc1.getValue()));
        }
        for(Schema.PicklistEntry plc2 : Opportunity.BI_O4_Countries_EMEA__c.getDescribe().getPicklistValues()){
            countriesEMEALIST.add(new BI_LEX_CreateMultipleSubOppControl.wrapperHelperOptions(plc2.getLabel(), plc2.getValue()));
        }
        for(Schema.PicklistEntry plc3 : Opportunity.BI_O4_Countries_Rest_of_the_world__c.getDescribe().getPicklistValues()){
            countriesRestWorldLIST.add(new BI_LEX_CreateMultipleSubOppControl.wrapperHelperOptions(plc3.getLabel(), plc3.getValue()));
        }
        
        response.currentOpp = actualOpp;
        response.customerLIST = customerLIST;		
		response.catalogCategoriesLIST = catalogCategoriesLIST;
		response.catalogItemsMAP = catalogItemsMAP;	
        response.accountCountryMAP = accountCountryMAP;
        response.holdingID = holdingId;
        response.countriesAmericaLIST = countriesAmericaLIST;
        response.countriesEMEALIST = countriesEMEALIST;
        response.countriesRestWorldLIST = countriesRestWorldLIST;
		response.productNamesMap = productNamesMap;		
        
        return response;
    }
    
    /*-------------------------------------------------------------------------------------------------
    Company:       Accenture - Tecnilogica
    Description:   Creates opportunity objects to be saved

	IN:             Opportunity - Parent opty
					List<String> selectedCatItemsList -  selected catatalog items list
					Map <String,String> - Products name map Key:Catalog item ID - Value:Product Name
					List<String> countryLIST - Selected Countries list
					List<String> customerLIST - Selected Customer list
					Map<String,Account> accountCountryMAP - Map of countries per account
					String holding - Account Id
					Map<String,Boolean> countryMultipleSLinesMAP - "multiple" checkbox selected by country
					Map<String,Boolean> countryRenewalMAP - "renewal" checkbox selected by country
					Map<String,Boolean> countrySitesMAP
    OUT:            BI_LEX_CreateMultipleSubOppControl.wrapperHelper
    
    History:
    
    <Date>             <Author>                <Description>
    2019-12-16		    Manuel Ochoa		    First version
    ----------------------------------------------------------------------------------------------------*/
	@AuraEnabled
	public static BI_LEX_CreateMultipleSubOppControl.wrapperHelper saveSubopportunities(Opportunity opp,
																						List<String> selectedCatItemsList,
																						Map <String,String> productNamesMap, 
																						List<String> countryLIST, 
                                                                                        List<String> customerLIST, 
																						Map<String,Account> accountCountryMAP, 
																						String holding, 
                                                                                        Map<String,Boolean> countryMultipleSLinesMAP,
                                                                                        Map<String,Boolean> countryRenewalMAP, 
																						Map<String,String> countrySitesMAP) {

		system.debug('ENTERING saveSubopportunities');
		system.debug(selectedCatItemsList);
		system.debug(accountCountryMAP);
		system.debug(productNamesMap);
		

		BI_LEX_CreateMultipleSubOppControl.wrapperHelper response = new BI_LEX_CreateMultipleSubOppControl.wrapperHelper();
        
        Integer totalPaises = 0;
		grabarActual = 0;
		faltanGrabar = 0;
		Integer totalService = 0;
		Integer totalBusiness = 0;
        Integer cantidadGrabar = 0;

		String lBusiness = Label.BI_O4_Servicios_Internacionales;
		
		serviceLineSET = selectedCatItemsList;

		List<String> errorLIST = new List<String>();
		List<Opportunity> suboppLIST = new List<Opportunity>();
		//List<String> businessLineLIST = new List<String>();
        List<String> selectedCountriesLIST = new List<String>();
        
        countriesSET = new List<String>();
		
		Boolean datavalidated = validateData(opp);
		if(!datavalidated) {
            response.errorMessage = Label.BI_O4_ContractTermError;
			return response;
		}
		
		try{		
			
            if (countryLIST != null && !countryLIST.isEmpty()){
				for (String e : countryLIST){
                    selectedCountriesLIST.add(e);
                }
			}
            
			totalPaises = selectedCountriesLIST.size();
			cantidadGrabar = 0;
            Boolean permissionuser = checkUserProfileAndPermission();

			// for Centralized or Global Distributed OPTYS
			if (opp.BI_O4_Opportunity_Type__c == 'Centralized' || opp.BI_O4_Opportunity_Type__c == 'Global Distributed'){
				for (String lCountry : selectedCountriesLIST){
					Opportunity subOpp = new Opportunity();
					subOpp.BI_Plazo_estimado_de_provision_dias__c = 0;
					subOpp.BI_Probabilidad_de_exito__c = '0';
					subOpp.BI_O4_One_off_charge__c = 0;
					subOpp.BI_Country__c = accountCountryMAP.get(lCountry) != null ? accountCountryMAP.get(lCountry).BI_Country__c : lCountry;
					subOpp.BI_Opportunity_Type__c = lBusiness;
					if(permissionuser){
						subOpp.BI_SIMP_Opportunity_Type__c='new';
					}
					subOpp.StageName = Label.BI_DefinicionSolucion;
					subOpp.CloseDate = opp.CloseDate;
					subOpp.BI_O4_MRC_Renewal__c = 0;
					subOpp.BI_Oportunidad_Padre__c = opp.Id;
					subOpp.BI_O4_MRC_New_Business__c = 0;
					subOpp.BI_Ingreso_por_unica_vez__c = 0;
					subOpp.BI_Recurrente_bruto_mensual__c = 0;
					subOpp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Oportunidad Local').getRecordTypeId();

					String baseName = lCountry + ' - ' + lBusiness;

					if (opp.BI_O4_Opportunity_Type__c == 'Centralized') {
						subOpp.AccountId = opp.AccountId;
					}else if (opp.BI_O4_Opportunity_Type__c == 'Global Distributed'){
						subOpp.AccountId = holding;

						for(Account acc:accountCountryMAP.values()){
							if (acc.BI_Country__c == lCountry){
								subOpp.AccountId = acc.Id;
								break;
							}
						}
					}

					// create multiple optys for each product or only one opty for all products
					if(countryMultipleSLinesMAP.get(lCountry)){
						for(String lService : serviceLineSET) {
							system.debug(lService);
							subOpp = subOpp.clone(false, false, false, false);
							subOpp.Name = subOpp.BI_Country__c + ' - ' + productNamesMap.get(lService) + ' - ' +  opp.Name;
							subOpp.BI_O4_Service_Line__c = lService;
							subOpp.BI_O4_Service_Lines__c = lService;
							subOpp.Description='';
							if(countryRenewalMAP.get(lCountry)){
								subOpp.Description = 'Is Renewal';     
							} 
							suboppLIST.add(subOpp);
							cantidadGrabar++;
						}
					} else {
						String serviceLines = String.join(new List<String>(serviceLineSET), ';');
						subOpp.BI_O4_Service_Lines__c = serviceLines;
						subOpp.Name = baseName + ' - ' +  opp.Name;
						subOpp.Description='';
						if(countryRenewalMAP.get(lCountry)){
							subOpp.Description = 'Is Renewal';    
						} 
						suboppLIST.add(subOpp);
						cantidadGrabar++;
					}
					countriesSET.add(subOpp.BI_Country__c);
				}
			}
			// for local distributes opty
			else
			{
				for(String so : customerLIST)
				{
					Opportunity subOpp = new Opportunity();
					subOpp.BI_Plazo_estimado_de_provision_dias__c = 0;
					subOpp.BI_Probabilidad_de_exito__c = '0';
					subOpp.BI_O4_One_off_charge__c = 0;
					subOpp.BI_Country__c = accountCountryMAP.get(so).BI_Country__c;
					subOpp.BI_Opportunity_Type__c = lBusiness;
					if(permissionuser){
						subOpp.BI_SIMP_Opportunity_Type__c='new';
					}
					subOpp.BI_O4_Bussiness_Line__c = lBusiness;
					subOpp.StageName = Label.BI_DefinicionSolucion;
					subOpp.CloseDate = opp.CloseDate;
					subOpp.BI_O4_MRC_Renewal__c = 0;
					subOpp.BI_Ingreso_por_unica_vez__c = 0;
					subOpp.BI_Recurrente_bruto_mensual__c = 0;
					subOpp.BI_Oportunidad_Padre__c = opp.Id;
					subOpp.BI_O4_MRC_New_Business__c = 0;
					subOpp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Oportunidad Local').getRecordTypeId();
						
					subOpp.AccountId = accountCountryMAP.get(so).Id;

					String baseName = subOpp.BI_Country__c + ' - ' + lBusiness;
						
					if(countryMultipleSLinesMAP.get(so)){			
						for(String lService : serviceLineSET) {
							subOpp = subOpp.clone(false, false, false, false);
							subOpp.Name = subOpp.BI_Country__c + ' - ' + productNamesMap.get(lService) + ' - ' +  opp.Name;
							subOpp.BI_O4_Service_Line__c = lService;
							subOpp.BI_O4_Service_Lines__c = lService;
							subOpp.Description = '';
							if(countryRenewalMAP.get(so)){
								subOpp.Description = 'Is Renewal';
							}
							suboppLIST.add(subOpp);
							cantidadGrabar++;
						}
					} 
					else {
						String serviceLines = String.join(new List<String>(serviceLineSET), ';');
						subOpp.BI_O4_Service_Lines__c = serviceLines;
						subOpp.Name = baseName + ' - ' +  opp.Name;
						subOpp.Description='';
						if(countryRenewalMAP.get(so)){
							subOpp.Description = 'Is Renewal';    
						} 
						suboppLIST.add(subOpp);
						cantidadGrabar++;
					}						
					countriesSET.add(subOpp.BI_Country__c);
				}
			}
			
            
			if(cantidadGrabar>=200){
                response.errorMessage = Label.BI_LEX_TooManyOpps;
				return response;
			}
			faltanGrabar = cantidadGrabar;
		} catch(Exception exc) {
			response.errorMessage = exc.getMessage();
            return response;
		}
        
        //Save subopportunities
        if(!suboppLIST.isEmpty()){
            response.toRecord = faltanGrabar;
            response.recordNow = grabarActual;
            response.insertsuboppLIST = suboppLIST;
            response.countriesSET = countriesSET;
        }
                                                                                            
        return response;
	}

	/*-------------------------------------------------------------------------------------------------
    Company:       Accenture - Tecnilogica
    Description:   Saves opportunity records and launch related order creation

	IN:             List<Opportunity> insertsuboppLIST - Opty list to be saved
					List<String> errorList - Error list from component
					Opportunity parentopp - Parent opty
					Boolean multisite - flag for multisite process
					List<String> selectedCatItemsList -  selected catatalog items list					
					List<String> catalogIDLIST - Catalog Ids list
					List<String> countryLIST - Selected Countries list
    OUT:            BI_LEX_CreateMultipleSubOppControl.wrapperHelper
    
    History:
    
    <Date>             <Author>                <Description>
    2019-12-16		    Manuel Ochoa		    First version
    ----------------------------------------------------------------------------------------------------*/    
    @AuraEnabled
    public static BI_LEX_CreateMultipleSubOppControl.wrapperHelper saveAllSubOpportunities(List<Opportunity> insertsuboppLIST, 
																						List<String> errorList, 
                                                                                        Opportunity parentopp, 
																						Boolean multisite,
																						List<String> selectedCatItemsList,
																						List<String> catalogIDLIST, 
                                                                                        List<String> countriesLIST){
        BI_LEX_CreateMultipleSubOppControl.wrapperHelper response = new BI_LEX_CreateMultipleSubOppControl.wrapperHelper();
		serviceLineSaveSubOppSET = !selectedCatItemsList.isEmpty() ? new Set<String>(selectedCatItemsList) : new Set<String>(); 

		system.debug('ENTERING saveAllSubOpportunities');
		system.debug(selectedCatItemsList);
		
        try {			
			insert insertsuboppLIST; 
			} 
		catch (Exception e) {
            //Error específico - cliente usado por otra suboportunidad
			system.debug(e.getMessage());
            if(e.getMessage().contains('UNABLE_TO_LOCK_ROW')){
                errorList.add(Label.BI_LEX_Unabletolockrow);
            }
            else {
                errorList.add('ERROR ');
            }
        }
        for(Opportunity subopp:insertsuboppLIST){
            if (subopp.BI_O4_Service_Lines__c != null){
                serviceLineSaveSubOppSET.addAll(subopp.BI_O4_Service_Lines__c.split(';'));
                insertedsuboppLIST.add(subopp);
            }
        }
        if(!multisite){
			system.debug('NOT multisite');            
			launchOrderCreation(insertedsuboppLIST, selectedCatItemsList, multisite);
			insertedsuboppLIST.clear();
		}else{
            catalogIDSET = new Set<String>();
        	for(String c : catalogIDLIST){
               	catalogIDSET.add(c);      
            }
		launchOrderCreation(insertedsuboppLIST, selectedCatItemsList, multisite);
		insertedsuboppLIST.clear();
		}
                                                                                               
        if (parentopp.BI_O4_Service_Lines__c != null)
        {
            serviceLineSaveSubOppSET.addAll(parentopp.BI_O4_Service_Lines__c.split(';'));
            for(String st : serviceLineSaveSubOppSET){
                if(st.isNumeric()){
                    serviceLineSaveSubOppSET.remove(st);
                }
            }
            parentopp.BI_O4_Service_Lines__c = String.join(new List<String>(serviceLineSaveSubOppSET), ';');
        }
        else{
            for(String st : serviceLineSaveSubOppSET){
                if(st.isNumeric()){
                    serviceLineSaveSubOppSET.remove(st);
                }
            }
            parentopp.BI_O4_Service_Lines__c = String.join(new List<String>(serviceLineSaveSubOppSET), ';');    
        }
        if (!countriesLIST.isEmpty()) 
        {
            Set<String> countriesSET = new Set<String>();
            countriesSET.addAll(countriesLIST);
            
            if (parentopp.BI_O4_Paises__c != null)
            {
                countriesSET.addAll(parentopp.BI_O4_Paises__c.split(';'));
                parentopp.BI_O4_Paises__c = String.join(new List<String>(countriesSET), ';');
            }
            else
                parentopp.BI_O4_Paises__c = String.join(new List<String>(countriesSET), ';');
        }
        parentopp.BI_O4_Geographical_Scope__c = BI_O4_Utils.calcGeographicalScope(parentopp.BI_O4_Paises__c);
                                                                                               
        update parentopp;        	

        response.errorList = errorList;
        response.serviceLineSaveSubOppLIST = new List<String>(serviceLineSaveSubOppSET);
                                                                                                                                                       
        return response;
    }

	/*-------------------------------------------------------------------------------------------------
    Company:       Accenture - Tecnilogica
    Description:   Validates if opty is elegible to process

	IN:             Opportunity opp - Parent opty
    OUT:            Boolean - true if valid opty
    
    History:
    
    <Date>             <Author>                <Description>
    2019-12-16		    Manuel Ochoa		    First version
    ----------------------------------------------------------------------------------------------------*/        
    public static Boolean validateData(Opportunity opp){
    	if ((opp.StageName == Label.BI_F1Ganada || opp.StageName == Label.BI_F1ClosedLost) && opp.BI_O4_Contract_Term_Months__c == 0){
            return false;
		}   
        return true;
    }

	/*-------------------------------------------------------------------------------------------------
    Company:       Accenture - Tecnilogica
    Description:   Launches queueable order creation process

	IN:             List<Opportunity> oppLIST - Opportunities to link with new orders
	IN:             List<String> serviceLineIDSET - Selected Catalog items 
	IN:             Boolean multisite - flag for multisite process
    OUT:            void
    
    History:
    
    <Date>             <Author>                <Description>
    2019-12-16		    Manuel Ochoa		    First version
    ----------------------------------------------------------------------------------------------------*/ 
	public static void launchOrderCreation(List<Opportunity> oppLIST, List<String> serviceLineIDSET, Boolean multisite){
        
		system.debug('ENTERING launchOrderCreation');

		if(!oppLIST.isEmpty()){
			system.debug('oppLIST.size: ' + oppLIST.size());
            Set<String> serviceIDSET = new Set<String>();
            for(String s : serviceLineIDSET){
              	serviceIDSET.add(s);
            }
            BI_LEX_O4_CreateOptyOrder orderCreate = new BI_LEX_O4_CreateOptyOrder(oppLIST, serviceIDSET, catalogIDSET, multisite);
            if(!orderCreate.checkNoCatalogData){
                Id jobID = System.enqueueJob(orderCreate);
            }
		}
	}

	/*-------------------------------------------------------------------------------------------------
    Company:       Accenture - Tecnilogica
    Description:  Checks if user is allowed to use component

	IN:             String recordId - Parent opty ID
    OUT:            BI_LEX_CreateMultipleSubOppControl.wrapperHelper
    
    History:
    
    <Date>             <Author>                <Description>
    2019-12-16		    Manuel Ochoa		    First version
    ----------------------------------------------------------------------------------------------------*/ 
	@AuraEnabled
    public static BI_LEX_CreateMultipleSubOppControl.wrapperHelper allowAccessComponent(String recordId){
        BI_LEX_CreateMultipleSubOppControl.wrapperHelper response = new BI_LEX_CreateMultipleSubOppControl.wrapperHelper();
        
        actualOpp = [SELECT Id, StageName, BI_O4_Opportunity_Type__c FROM Opportunity WHERE Id = :recordId];
        List<PermissionSetAssignment> permissionLIST = [SELECT Id, Assignee.Name, PermissionSet.Name FROM PermissionSetAssignment WHERE Assignee.Profile.Name IN ('BI_O4_TGS_Standard','BI_O4_TGS_Standard_LEX')
                                       			AND PermissionSet.Name IN ('BI_General','BI_O4_TGS_Ejecutivo_de_Cliente','BI_O4_Oportunidades') AND Assignee.Id = :UserInfo.getUserId()];
        
        System.debug('**size: ' + permissionLIST.size());
        //Check if user has access by profile and permissionsets
        if(permissionLIST.size() != 3 && !avoidTestPermission){
            response.errorMessage = Label.BI_LEX_NoPermissionsForAction;
        }
        //Check if opportunity is in proper stage
        else{
            if(actualOpp.BI_O4_Opportunity_Type__c == 'Centralized'){
				allowAction = !(actualOpp.StageName.startsWith('F1'));
            }
            else if (actualOpp.BI_O4_Opportunity_Type__c == 'Global Distributed' || actualOpp.BI_O4_Opportunity_Type__c == 'Local Distributed'){
                allowAction = !(actualOpp.StageName.startsWith('F1') || actualOpp.StageName.startsWith('F2'));
            }
            //Can't work with current opportunity
            if(!allowAction){
                response.errorMessage = Label.BI_LEX_CantCreateSubOppF1F2;
            }
        }
        
        return response;
    }

	/*-------------------------------------------------------------------------------------------------
    Company:       Accenture - Tecnilogica
    Description:  Checks if user is allowed to create optys

	IN:             void
    OUT:           Boolean
    
    History:
    
    <Date>             <Author>                <Description> 
    2019-12-16		    Manuel Ochoa		    First version
    ----------------------------------------------------------------------------------------------------*/     
    public static Boolean checkUserProfileAndPermission(){
		Set<String> setStringAllowedProfiles = new Set<String>{'BI_O4_TGS_Standard', 'BI_O4_TGS_Standard_LEX'};
        Set<String> setStringAllowedPermSets = new Set<String>{'BI_O4_TGS_Ejecutivo_de_Cliente','BI_O4_TGS_Jefe_de_Ventas'};
		List<PermissionSetAssignment> listCurrentUserPerSet = [SELECT Id, PermissionSet.Name, Assignee.Profile.Name FROM PermissionSetAssignment WHERE AssigneeId = :Userinfo.getUserId() ];

        Boolean isAllowedProfile = false;
		Boolean isAllowedPermSet = false;
		
		if(!listCurrentUserPerSet.isEmpty()){
			isAllowedProfile = setStringAllowedProfiles.contains(listCurrentUserPerSet[0].Assignee.Profile.Name);
				       	
			for(PermissionSetAssignment psa: listCurrentUserPerSet){
			    if(setStringAllowedPermSets.contains(psa.PermissionSet.Name)){
			        isAllowedPermSet = true;
					break;
			    }
			}
		}

		Boolean isAllowedUser = (isAllowedProfile && isAllowedPermSet) ? true :false;
		return isAllowedUser;
	}

	/*-------------------------------------------------------------------------------------------------
    Company:       Accenture - Tecnilogica
    Description:  	Wrapper helper class for responses
    
    History:
    
    <Date>             <Author>                <Description>
    2019-12-16		    Manuel Ochoa		    First version
    ----------------------------------------------------------------------------------------------------*/         
    public class wrapperHelper{
        @AuraEnabled public Opportunity currentOpp;
        @AuraEnabled public List<BI_LEX_CreateMultipleSubOppControl.wrapperHelperOptions> customerLIST;
        @AuraEnabled public List<BI_LEX_CreateMultipleSubOppControl.wrapperHelperOptions> businessLinesLIST;
        @AuraEnabled public List<BI_LEX_CreateMultipleSubOppControl.wrapperHelperOptions> countriesEMEALIST;
        @AuraEnabled public List<BI_LEX_CreateMultipleSubOppControl.wrapperHelperOptions> countriesAmericaLIST;
        @AuraEnabled public List<BI_LEX_CreateMultipleSubOppControl.wrapperHelperOptions> countriesRestWorldLIST;
		//2019-12-16     Manuel Ochoa    New version
		@AuraEnabled public List<BI_LEX_CreateMultipleSubOppControl.wrapperHelperOptions> catalogCategoriesLIST;
		@AuraEnabled public Map<String,List<BI_LEX_CreateMultipleSubOppControl.wrapperHelperOptions>> catalogItemsMAP;
		@AuraEnabled public Map<String,String> productNamesMap;
		//2019-12-16     Manuel Ochoa    New version
        @AuraEnabled public Map<String,Account> accountCountryMAP;
        @AuraEnabled public Map<String,Boolean> countryMultipleSLinesMAP;
        @AuraEnabled public Map<String,Boolean> countryRenewalMAP;
        @AuraEnabled public Map<String,String> countrySitesMAP;
        @AuraEnabled public Boolean multisite;
        @AuraEnabled public String holdingID;
        @AuraEnabled public String errorMessage;
        @AuraEnabled public Integer toRecord;
        @AuraEnabled public Integer recordNow;
        @AuraEnabled public Integer numberofjobs;
        @AuraEnabled public Integer limitofjobs;
        @AuraEnabled public Integer notlaunchedjobs;
        @AuraEnabled public Integer numberofoptysperjob;
        @AuraEnabled public Integer numberofoptyspercomplexjob;
        @AuraEnabled public List<Opportunity> insertsuboppLIST;
        @AuraEnabled public List<String> countriesSET;
        @AuraEnabled public List<String> errorList;
        @AuraEnabled public List<String> serviceLineSaveSubOppLIST;
    }

	/*-------------------------------------------------------------------------------------------------
    Company:       Accenture - Tecnilogica
    Description:  Wrapper helper class for dual list data
    
    History:
    
    <Date>             <Author>                <Description>
    2019-12-16		    Manuel Ochoa		    First version
    ----------------------------------------------------------------------------------------------------*/      
    public class wrapperHelperOptions{
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        
        public wrapperHelperOptions(String label, String value){
            this.label = label;
            this.value = value;
        }
    }	
}