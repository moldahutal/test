/*---------------------------------------------------------
   Author:         Daniel Córdoba
   Company:        Everis
   Description:    Clase que se llama desde el PBuilder TBS_OT_FlujoOrder
   History
   <Date>          <Author>        <Change Description>
   24-Oct-2019     Daniel Córdoba   Initial Version
   30-Oct-2019     Alfonso Arcos    Class restructuration
   -----------------------------------------------------------*/
global with sharing class TBS_OT_OrderFlowMethods {
	private static Map<Id,String> Billing = new Map<Id,String>();
	private static List<HO_e_SOF__c> esofInsert = new List<HO_e_SOF__c>();
    private static List<HO_e_SOF__c> esofInsertOK = new List<HO_e_SOF__c>();
	private static Id recordtt = Schema.SObjectType.HO_e_SOF__c.getRecordTypeInfosByDeveloperName().get('TBS_OT_Firma_eSOF').getRecordTypeId();
	private static Id recordtt2 = Schema.SObjectType.HO_e_SOF__c.getRecordTypeInfosByDeveloperName().get('TBS_OT_Purchase_Onnet').getRecordTypeId();


	/*---------------------------------------------------------
	Author:         Alfonso Arcos
	Company:        Devoteam               
	Description:    Clase que se llama desde el PBuilder TBS_OT_FlujoOrder
	History
	<Date>          <Author>        <Change Description>
	30-Oct-2019     Alfonso Arcos   Initial Version
	-----------------------------------------------------------*/
	@InvocableMethod
	public static void flowMethodSelection(list <id> objId){

		List<NE__Order__c> orderList= [select id, Name, TBS_OT_MilestoneProject__r.HO_GPM__c,TBS_OT_BillingLegalEntity__c,TBS_OT_Billing_Modality__c,OwnerId,NE__OrderStatus__c, (SELECT Id FROM SOF__r), (SELECT NE__ProdName__c FROM NE__Order_Items__r WHERE NE__Parent_Order_Item__c = null) from NE__Order__c where Id in:objId];
		//Lista con los Atributos que proceden de B2W
		List<NE__Order_Item_Attribute__c> OIattribute= [select id,name,NE__Value__c,NE__FamPropExtId__c,NE__Order_Item__r.NE__OrderId__c, NE__Order_Item__r.NE__ProdName__c from NE__Order_Item_Attribute__c where NE__Order_Item__r.NE__OrderId__c in: objId];

		Map<NE__Order__c,List<NE__Order_Item_Attribute__c> > OrdersMap = new Map<NE__Order__c,List<NE__Order_Item_Attribute__c> >();

		//Iteration to Match Orders, Order Item Atributes with their Status
		String Status;
		for(NE__Order__c o : orderList) {
			Status = o.NE__OrderStatus__c;
			List<NE__Order_Item_Attribute__c> attList = new List<NE__Order_Item_Attribute__c>();
			for(NE__Order_Item_Attribute__c att : OIattribute ) {
				if(att.NE__Order_Item__r.NE__OrderId__c == o.id) {
					attList.add(att);
				}
			}
			if(!attList.isEmpty()) {
				OrdersMap.put(o,attList);
			}
		}

        List<sObject> records = new List<sObject>();
        Id recordtt3;
			
		if(Status.equals('eSOF_Signature')) {
			records = updatefieldsEsof(OrdersMap,recordtt);
			update (List<NE__Order__c>) records;
		}else if(Status.equals('Pending SOF Shipping')) {

			TBS_OT_SOF_Methods.generateSOFs(OrdersMap);

		}else if(Status.equals('Purchased Onnet')) {//Cambiar con valor Real al tenerlo
			//STR-Añadir records = updatefieldsEsof(OrdersMap, Purchased Onnet); (Pasar por parámetro otro campo para difereciar Rec Type eSOF de Purchase Onnet )
           generatePurchaseOnnet(OrdersMap);
		}

	}
    
	/*---------------------------------------------------------
	Author:         Daniel Córdoba
	Company:        Everis
	Description:    Metodo con el id de la Orden a la que se le ha creado asignada una eSOF
	que vienen de B2W

	History
	<Date>          <Author>        <Change Description>
	24-Oct-2019     Daniel Córdoba   Initial Version
	30-Oct-2019     Alfonso Arcos    Method restructuration
	-----------------------------------------------------------*/
	public static List<sObject> updatefieldsEsof (Map<NE__Order__c,List<NE__Order_Item_Attribute__c> > OrdersMap, Id recTypeId) {   
        //Obtengo todos los valores del Custom Setting
		List<TBS_OT_FieldstoEsof__c> endPoints = TBS_OT_FieldstoEsof__c.getAll().values();

		String OwnerIdOrder;
		//Añadir RT Purchase Onnet, también añadir el otro campo que se pasa como parámetro al método (indica el RT de la eSOF)
		for(NE__Order__c key : OrdersMap.KeySet()) {
				HO_e_SOF__c esof= new HO_e_SOF__c(TBS_OT_Configuration__c=key.id,RecordTypeId=recTypeId);
                esofInsert.add(esof);
                FieldsEsof(OrdersMap,esofInsert,endPoints,recTypeId);
		}
        
		//Si no es TIWS se asignará la eSOF a una OB
		List<NE__Order__c> orderUpdate = new List<NE__Order__c>();
		for(NE__Order__c key : OrdersMap.KeySet()) {
			if(String.isnotBlank(Billing.get(key.Id))){
				if(!Billing.get(key.Id).equals('Local_TIWS')||!Billing.get(key.Id).equals('International')) {
					Map<String, String> queuenames = new Map<String, String>();
					//Asigno al mapa el Nombre de la cola y su Id
					for (TBS_OT_FieldstoEsof__c dato : endPoints) {
						queuenames.put(dato.TBS_OT_NameAttribue__c,dato.TBS_OT_QueueId__c);
					}
					OwnerIdOrder=OwnerEsof (Billing.get(key.Id),OrdersMap.get(key),endPoints,queuenames);
					if(Billing.get(key.Id).equals('Mixed_OB')) {
						CloneEsof (OrdersMap.get(key),endPoints,queuenames, key.Id);
						OwnerIdOrder='';
					}
				}
			}
			//Si el estado es firma eSOF
			if(String.isnotBlank(OwnerIdOrder))
				key.OwnerId=OwnerIdOrder;
			key.TBS_OT_Billing_Modality__c=Billing.get(key.Id);
			orderUpdate.add(key);
		}
		
        //Si el Owner de la eSof es vacio no tenemos registrada la OB, no la inserto
        for(HO_e_SOF__c checkeSOF: esofInsert){
            if(String.isNotBlank(checkeSOF.OwnerId)){
                esofInsertOK.add(checkeSOF);
            }
        }
        insert esofInsertOK;

		return orderUpdate;
	}

	/*---------------------------------------------------------
	Author:         Daniel Córdoba
	Company:        Everis
	Description:    Metodo que se encarga de mapear a la eSOF los campos del objeto OIattribute
	que vienen de B2W

	History
	<Date>          <Author>        <Change Description>
		24-Oct-2019     Daniel Córdoba   Initial Version
		30-Oct-2019     Alfonso Arcos    Method restructuration
	-----------------------------------------------------------*/

	public static void FieldsEsof (Map<NE__Order__c,List<NE__Order_Item_Attribute__c> > OrdersMap,List<HO_e_SOF__c> esofList,List<TBS_OT_FieldstoEsof__c> endPoints,Id recorHSofts) {

		//Añadir RT Purchase Onnet, también añadir el otro campo que se pasa como parámetro al método (indica el RT de la eSOF)

		Map<String, Schema.SObjectField> eSoftypes= Schema.SObjectType.HO_e_SOF__c.fields.getMap();
		//Mapa que recogera el name y value de los OIAtribute
		Map<String, String> states = new Map<String, String>();

		for(NE__Order__c key : OrdersMap.KeySet()) {
			//Recorro todos los valores del Objeto OIAtribute y los meto en nuestro mapa
			for(NE__Order_Item_Attribute__c iattribute: OrdersMap.get(key)) {
				states.put(iattribute.name,iattribute.NE__Value__c);
				System.debug('STR - stat :'+states);

				//Obtengo Tipo de Facturación ---PENDIENTE ACLARAR JIRA---
				if(iattribute.Name=='Billing Modality') {
					String Bill=iattribute.NE__Value__c;
					Billing.put(key.Id,Bill);
				}
			}
		}

		//Recorro todos los valores del CSetting para asignarlos en el mapa
		for (TBS_OT_FieldstoEsof__c dato : endPoints) {
			for(HO_e_SOF__c esof : esofList) {
				//Compruebo que el Atributo viene en el Custom
				if((states.containsKey(dato.TBS_OT_Name__c)&& String.isnotBlank(states.get(dato.TBS_OT_Name__c))) && ((dato.TBS_OT_objectType__c.equals('e-SOF') && esof.RecordTypeId.equals(recordtt)) /*|| (dato.TBS_OT_objectType__c.equals('Purchase Onnet') && esof.RecordTypeId.equals(recordtt2))*/)){
                    if((String.valueof(eSoftypes.get(dato.TBS_OT_NameAttribue__c).getDescribe().getType()) =='CURRENCY') || (String.valueof(eSoftypes.get(dato.TBS_OT_NameAttribue__c).getDescribe().getType())=='DOUBLE')){
						//Mapeo en el campo api de la eSOF el valor que tenia en OIAtribute
						esof.put(dato.TBS_OT_NameAttribue__c,Decimal.valueOf(states.get(dato.TBS_OT_Name__c)));
					}else{
						esof.put(dato.TBS_OT_NameAttribue__c,states.get(dato.TBS_OT_Name__c));
					}
				}
			}
		}
	}

	/*---------------------------------------------------------
	Author:         Daniel Córdoba
	Company:        Everis
	Description:    Metodo que se encarga de enviar la eSOF a una OB comercializadora o prestadora
	History
	<Date>          <Author>        <Change Description>
	24-Oct-2019     Daniel Córdoba   Initial Version
	-----------------------------------------------------------*/

	public static String OwnerEsof (String Billingfield,List<NE__Order_Item_Attribute__c> listOIattribute,List<TBS_OT_FieldstoEsof__c> endPoints,Map<String, String> queuenames) {
		Boolean isMainAccess= false;
		String OwnerIdOrd;

		//Recorro todos los valores del Objeto OIAtribute y los meto en nuestro mapa
		for(NE__Order_Item_Attribute__c iattribute:listOIattribute) {
			//OB comercializadora
			if(Billingfield.equals('Central')) {
				if(iattribute.name.equals('Direct Customer Name')&&(String.isNotBlank(iattribute.NE__Value__c))) {
					for(HO_e_SOF__c esof : esofInsert) {
						if(esof.TBS_OT_Configuration__c == iattribute.NE__Order_Item__r.NE__OrderId__c) {
							esof.OwnerId= queuenames.get(iattribute.NE__Value__c);
							OwnerIdOrd=queuenames.get(iattribute.NE__Value__c);
						}
					}
				}
			}
			//OB Prestadora
			if(Billingfield.equals('Local_OB')||Billingfield.equals('Mixed_OB')) {
				if((!isMainAccess)&&iattribute.name.equals('Backup Access Supplier Name')&&(String.isNotBlank(iattribute.NE__Value__c))) {
					for(HO_e_SOF__c esof : esofInsert) {
						if(esof.TBS_OT_Configuration__c == iattribute.NE__Order_Item__r.NE__OrderId__c) {
							esof.OwnerId=queuenames.get(iattribute.NE__Value__c);
							OwnerIdOrd=queuenames.get(iattribute.NE__Value__c);
						}
						
					}
				}else if(iattribute.name.equals('Main Access Supplier Name')&&(String.isNotBlank(iattribute.NE__Value__c))) {
					for(HO_e_SOF__c esof : esofInsert) {
						if(esof.TBS_OT_Configuration__c == iattribute.NE__Order_Item__r.NE__OrderId__c) {
							esof.OwnerId=queuenames.get(iattribute.NE__Value__c);
							OwnerIdOrd=queuenames.get(iattribute.NE__Value__c);
							isMainAccess=true;
						}
					}
				}
			}
		}
		return OwnerIdOrd;
	}

	/*---------------------------------------------------------
	Author:         Daniel Córdoba
	Company:        Everis
	Description:    Metodo que se encarga de enviar la eSOF a una OB comercializadora o prestadora
	History
	<Date>          <Author>        <Change Description>
	24-Oct-2019     Daniel Córdoba   Initial Version
	-----------------------------------------------------------*/
	public static void CloneEsof (List<NE__Order_Item_Attribute__c> listOIattribute,List<TBS_OT_FieldstoEsof__c> endPoints,Map<String, String> queuenames, Id orderId){

		List<HO_e_SOF__c> newEsofs = new List<HO_e_SOF__c>();

		for(HO_e_SOF__c eSOForigin : esofInsert) {
			if(eSOForigin.TBS_OT_Configuration__c == orderId) {
				HO_e_SOF__c eSOFclonar=eSOForigin.clone(false,true,true,false);
				for(NE__Order_Item_Attribute__c iattribute:listOIattribute) {
					if(iattribute.name.equals('Direct Customer Name')&&(String.isNotBlank(iattribute.NE__Value__c))) {
						eSOFclonar.OwnerId= queuenames.get(iattribute.NE__Value__c);
					}
				}
				newEsofs.add(eSOFclonar);
			}
		}
		esofInsert.addAll(newEsofs);
	}
    
 /*---------------------------------------------------------
    Author:         Sergio Turo
    Company:        Everis
    Description:    
    History
    <Date>          <Author>        <Change Description>
    24-Oct-2019     Sergio Turo   Initial Version
    -----------------------------------------------------------*/
    public static void generatePurchaseOnnet (Map <NE__Order__c, List<NE__Order_Item_Attribute__c>> ordersMap){
        
        List <HO_e_SOF__c> pOnnetList = new List <HO_e_SOF__c> ();
        Map <String, String> attr2pOnnet = new Map <String, String> (); 
        Map<String, String> colasOB = new Map<String, String>();
        Map<String, Schema.SObjectField> eSoftypes= Schema.SObjectType.HO_e_SOF__c.fields.getMap();
        String billingModality = '';
        String directCname = '';
        String mainProvName = '';
        for (TBS_OT_FieldstoEsof__c dato : TBS_OT_FieldstoEsof__c.getAll().values()) {
            if(String.isNotBlank(dato.TBS_OT_QueueId__c)){    
                colasOB.put(dato.TBS_OT_NameAttribue__c,dato.TBS_OT_QueueId__c);
            }
        }

        for (TBS_OT_FieldstoEsof__c attMapping : TBS_OT_FieldstoEsof__c.getAll().values()) {
            if (attMapping.TBS_OT_objectType__c == 'Purchase Onnet') {
                attr2pOnnet.put(attMapping.TBS_OT_Name__c, attMapping.TBS_OT_NameAttribue__c);
            }
        }
        
        for (NE__Order__c o : ordersMap.keySet()) {
             HO_e_SOF__c newOnnet = new HO_e_SOF__c (
                RecordTypeId= recordtt2, 
                TBS_OT_Configuration__c = o.Id
             ); 

             for (NE__Order_Item_Attribute__c oia : ordersMap.get(o)) {
                  if (attr2pOnnet.containsKey(oia.Name) ) {
                     if((String.valueof(eSoftypes.get(attr2pOnnet.get(oia.Name)).getDescribe().getType()) =='CURRENCY') || (String.valueof(eSoftypes.get(attr2pOnnet.get(oia.Name)).getDescribe().getType())=='DOUBLE')){
                          newOnnet.put(attr2pOnnet.get(oia.Name),Decimal.valueOf(oia.NE__Value__c));
                     }else{
                          if(oia.Name.equals('Billing Modality')){
                                billingModality = oia.NE__Value__c;  
                          }else if(oia.Name.equals('Main Access Provider Name')){
                              mainProvName = oia.NE__Value__c;
                          }
                          newOnnet.put(attr2pOnnet.get(oia.Name),oia.NE__Value__c);
                          
                    }
                     
                  }else if(oia.Name.equals('Direct Customer Name')){
                      directCname = oia.NE__Value__c;
                  }
             }
			 if(billingModality.equals('Local_OB') || billingModality.equals('Local_TIWS')){
                if(String.isNotBlank(directCname)){
                    newOnnet.OwnerId= colasOB.get(directCname);

                } else if (String.isNotBlank(mainProvName)){
                    if(String.isBlank(directCname)){
                    	 newOnnet.OwnerId= colasOB.get(mainProvName); 
                    }
                 }
             }
             pOnnetList.add(newOnnet);
        }
        if (!pOnnetList.isEmpty()) {
            insert pOnnetList;
        }
        
    }
}