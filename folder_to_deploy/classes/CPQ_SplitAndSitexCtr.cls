/*****************
@Author: JAvier Lopez
@Compnay: gcTIo
@Description: Apex Classs to clontro CPQ_SplitAndSite component
*********************/
public class CPQ_SplitAndSitexCtr {

    /*****************
    @Author: Javier Lopez ANdradas
    @Company: gcTIO
    @Description: retrieves all Sites from an Account
    <date>      <version>       <description>
    2019/05/16  1.0             initial
    2019/07/10  1.1             CNB - Se añade para filtrar por UserRecordAccess
    2019/07/11  1.2             DCU - Solo se cargan las sedes de tipo "Punto de Instalación"
    2019/07/11  1.3             DCU - Cargo el pais de la dirección
    2019/09/18  1.4             DAF - Añado en la query el nombre de la sede
    *********************/
    @AuraEnabled
    public static List<BI_Punto_de_instalacion__c> getSites(String accId){
        List<BI_Punto_de_instalacion__c> lpuntoInst = new List<BI_Punto_de_instalacion__c>();
        Map<Id,BI_Punto_de_instalacion__c> mPuntoInst = new Map<Id,BI_Punto_de_instalacion__c>();

        for(BI_Punto_de_instalacion__c bpunt: [select Id,BI_COT_MEX_Direccion_Completa__c,BI_Sede__c,BI_Sede__r.BI_Country__c,Name,CPQ_FormulaZona__c from BI_Punto_de_instalacion__c where BI_ACtivo__c=true AND BI_Tipo_de_sede__c='Punto Instalación' AND BI_Cliente__c=:accId]) {
            mPuntoInst.put(bpunt.Id,bpunt);
        }
        
        if(!mPuntoInst.isEmpty()){
            for(UserRecordAccess us: [select RecordId,HasReadAccess from UserRecordAccess where UserId = :UserInfo.getUserId() AND RecordId IN :mPuntoInst.keySet() ]) {
               if(us.HasReadAccess)
                    lpuntoInst.add(mPuntoInst.get(us.RecordId));
            }      
        }
        return lpuntoInst;
    }

    /*****************
    @Author: Javier Lopez ANdradas
    @Company: gcTIO
    @Description: retrieves all CIs from a Order
    <date>      <version>       <description>
    2019/05/16  1.0             initial
    2019/08/05  1.1             Deleted filter and retrieve thje innfo of Tech Behaviour
    2019/09/18  1.2             DAF - Se añade a la query el nombre de la sede
    *********************/
    @AuraEnabled
    public static List<NE__OrderItem__c> rCis(String idOrd){
        return [
            SELECT Id, Installation_point__c, Installation_point__r.BI_Sede__c, Installation_point__r.BI_COT_MEX_Direccion_Completa__c, 
                Installation_point__r.BI_Sede__r.BI_Country__c,NE__CatalogItem__r.NE__Technical_Behaviour_Quote__c,
                NE__ProdId__r.Name, NE__Qty__c, NE__OneTimeFeeOv__c, NE__RecurringChargeOv__c, Name, NE__Parent_Order_Item__c , Installation_point__r.Name,
				TGS_Installation_point__c,TGS_Installation_point__r.BI_COT_MEX_Direccion_Completa__c,TGS_Installation_point__r.BI_Sede__c,TGS_Installation_point__r.Name
            FROM NE__OrderItem__c 
            WHERE NE__OrderId__c =: idOrd 
            /*AND NE__CatalogItem__r.NE__Technical_Behaviour_Quote__c='Site required'*/];
    }
    /*****************
    @Author: Javier Lopez ANdradas
    @Company: gcTIO
    @Description: updates all cIs with the new site
    <date>      <version>       <description>
    2019/05/16  1.0             initial
    *********************/
    @AuraEnabled
    public static String asigCis(List<NE__OrderItem__c> lst_cis){
       update lst_cis;
       return Label.CPQ_LBL_OK;
    }
    
    /*****************
    @Author: Javier Lopez ANdradas
    @Company: gcTIO
    @Description: makes the split of the Cis listed
    <date>      <version>       <description>
    2019/05/16  1.0             initial
    *********************/
    @AuraEnabled
    public static string splitCis(List<String> lst_ids,List<String> lst_ori,Integer numNew,Integer div,String idQuote,Boolean isMain,String idopty){
        //vamos a hacerlo con la que tenemos de generate Quotes...
        List<NE__OrderItem__c>  lst_cis = new List<NE__OrderItem__c>();
        SavePoint svr =  Database.setSavepoint();
        for(String idci:lst_ori){
            NE__OrderItem__c oi = new NE__OrderItem__c(Id=idci,NE__Qty__c=numNew);
            lst_cis.add(oi);
        }
        List<String> lst_res = new List<String>();
        BI_MigrationHelper.setSkippedTrigger('NE__OrderItem__c');
        BI_MigrationHelper.setSkippedTrigger('NE__Order__c');
        update lst_cis;
        //-----------------------------------ACR-------------------------------------------------
        wrapperClassSplit response = cloneCIs(idQuote,lst_ids,div);
        if(response.err != null){
            Database.rollback( svr );
            return response.err;
        }
        lst_res.addAll(response.lst_cis);
        //----------------------------------------------------ACR-------------------------------------------------

        // for(Integer i = 0;i<div-1;i++){
        //     System.debug('JLA_LLEgamos la CI-->'+i);
        //     CPQ_Generate_QuoteClass.WrapperClass res = CPQ_Generate_QuoteClass.cloneCIs(idQuote,lst_ids,false);
        //     if(res.err!=null){
        //        Database.rollback( svr );
        //        return res.err;
        //     }
        //     lst_res.addAll(res.lst_cis);
        //     //Ahora hemos de generar los nuevos Cis si la quote es de tipo Principal
        // }
        BI_MigrationHelper.cleanSkippedTriggers(); //Added by Pablo de Andrés 29/07/2019
		//Aqui va esa parte tan maravillosa

        System.debug('JLA_Metimos todo');
        if(!lst_res.isEmpty() && isMain){
			system.debug('Entramos es main');
			BI_MigrationHelper.setSkippedTrigger('NE__OrderItem__c');
            BI_MigrationHelper.setSkippedTrigger('NE__Order__c');
			//generamos las copias de los cIs recien creados
			String IdOpp = [select Id from NE__Order__c where NE__optyId__c=:idopty AND NE__OrderStatus__c like 'Activ%'].Id;
			CPQ_Generate_QuoteClass.WrapperClass resDop = CPQ_Generate_QuoteClass.cloneCIs(IdOpp,lst_res,false);
			//JLA_Al ser main debemos actualizar la opty Original con los valores que corresponden
			List<NE__OrderItem__c> lst_OIOpp = [select Id from NE__OrderItem__c where NE__AssetItemEnterpriseId__c in :lst_ori AND NE__OrderId__r.RecordType.DeveloperName='Opty' AND NE__orderId__r.NE__OrderStatus__c like 'Activ%'];
			if(!lst_OIOpp.isEmpty()){
				for(NE__OrderItem__c oi :lst_OIOpp)
					oi.NE__Qty__c = numNew;
				update lst_OIOpp;
			}
            //BI_LEX_ActivateVersionNEOControl.activateVersion(idQuote);
            BI_MigrationHelper.cleanSkippedTriggers();
        }
        return Label.CPQ_LBL_OK;
    }
    @AuraEnabled
    public static NE__Order__c getData(String idOrd){
        return [Select Id,NE__optyId__c,NE__accountId__c,RecordType.DeveloperName,NE__Type__c,NE__OptyId__r.BI_Country__c from NE__Order__c where Id=:idOrd limit 1];
    }
    /*************
    @author: JAvier Lopez andradas
    @Compnay: gCTIO
    @Description: creates a Site
    <date>      <version>       <description>
    2019/06/10  1.0             Initial
    **************/
    @AuraEnabled
    public static string createSiteAcc(String idAddr,String idAcc){
        BI_Punto_de_instalacion__c pi = new BI_Punto_de_instalacion__c();
        pi.BI_Cliente__c=idAcc;
        pi.BI_Sede__c=idAddr;
        pi.BI_ACtivo__c=true;
        pi.BI_Tipo_de_sede__c='Punto Instalación';
        System.debug('JLA_DEBUF--->'+pi);
        insert pi;
        return Label.CPQ_LBL_OK;
    }
    /**********************
    @Author: Javier Lopez Andradas
    @Company: gcTIO
    @Description: create clones of a ci and sets a given site

    <date>      <version>       <description>
    2019/06/10  1.0              Initial
    ************************/
    @AuraEnabled
    public static string createAndAssign(String idCi,String idSede, String idCob, String idQuote,boolean onlyUpd,Decimal Qty,List<String> allCis,String oppId,String type){
        //Muy parecido al de arriba
		System.debug('JLA_ENTRANDO EN CREATE AND ASSIGN:');
		System.debug('Opp-->'+oppId);
		System.debug('Type-->'+type);
        String idNew =idCI;
        Decimal newQty=Qty;
		String idOpp= null;
        if(onlyUpd==false){
            CPQ_Generate_QuoteClass.WrapperClass res = CPQ_Generate_QuoteClass.cloneCIs(idQuote,allCis,false);
            if(res.err!=null){        
                return res.err;
            }
            idNew=res.lst_cis[0];
            newQty=1;
			if(type=='Principal'){
				//tenemos que crear el homologo del tipo
				system.debug('JLA__2**Entramos es main sites');
				String IdOPty = [Select Id from NE__Order__c where NE__optyId__c=:oppId AND NE__OrderStatus__c like 'Activ%'].Id;
				system.debug('JLA__2**Entramos es main sites-->idOpy: '+idOpty);
				CPQ_Generate_QuoteClass.WrapperClass res2 = CPQ_Generate_QuoteClass.cloneCIs(IdOPty,res.lst_cis,false);
				//creado
				idOpp=res2.lst_cis[0];
			}
        }
		List<NE__OrderItem__c> toUpd = new List<NE__OrderItem__C>();

        NE__OrderItem__c oi = new NE__OrderItem__c();
        oi.Id=idNew;
        oi.NE__Qty__c=newQty;
        oi.CPQ_Cobertura__c = idCob;
        oi.Installation_point__c=idSede;
		toUpd.add(oi);
		if(idOpp!=null){
			NE__OrderItem__c oiOpp = new NE__OrderItem__c();
			oiOpp.Id=idOpp;
			oiOpp.Installation_point__c=idSede;
			oiOpp.CPQ_Cobertura__c = idCob;
			oiOpp.NE__qty__c=newQty;
			toUpd.add(oiOpp);
		}else if(type=='Principal'){
			//tenemos que encontrar el CI del que ya exitia para cambiarlo
			System.debug('JLA_Actualizamos el original...');
			NE__OrderItem__c oiOri = [select Id from NE__orderItem__c where NE__AssetItemEnterpriseId__c=:idCi AND NE__OrderId__r.RecordType.DeveloperName='Opty' AND NE__orderId__r.NE__OrderStatus__c like 'Activ%'];
			oiOri.NE__Qty__c=newQty;
			oiOri.CPQ_Cobertura__c = idCob;
        	oiOri.Installation_point__c=idSede;
			toUpd.add(oiOri);
		}
		
		
        BI_MigrationHelper.setSkippedTrigger('NE__OrderItem__c');
        update toUpd;
        //DCU: Fuerzo lo que se ejecuta en el trigger
        List<NE__OrderItem__c> lstOINew = new List<NE__OrderItem__c>();
        List<NE__OrderItem__c> lstOIOld = new List<NE__OrderItem__c>();
        NE__OrderItem__c oiDummy = new NE__OrderItem__c();
        oiDummy.Id=idNew;
        lstOIOld.add(oiDummy);
        lstOINew.add(oi);
        BI_NEOrderItemMethods.procesaSede(lstOINew, lstOIOld);
        // CPQ_Cobertura__c cob = new CPQ_Cobertura__c(
        //     Id = idCob,
        //     CPQ_OrderItem__c = oi.Id
        // );
        // update cob;
        BI_MigrationHelper.cleanSkippedTriggers();
        return Label.CPQ_LBL_OK;
    }

    /**********************
    @Author: Javier Lopez Andradas
    @Company: gcTIO
    @Description: create clones of a ci and sets a given site

    <date>      <version>       <description>
    2019/06/10  1.0              Initial
    ************************/
    @AuraEnabled
    public static void updateopty(String idQuote){
        BI_LEX_ActivateVersionNEOControl.activateVersion(idQuote);

    }
    /**********************
    @Author: Javier Lopez Andradas
    @Company: gcTIO
    @Description: refresh coberage result for a given addres
    @Resturn param : {Id_Address,[AlltechCob]}
    <date>      <version>       <description>
    2019/06/10  1.0              Initial
    ************************/
    @AuraEnabled
    public static String checkCob(List<String> lst_address){
        //This will be self construct for country but for now its just dummy
        Map<string, CPQ_Cobertura__c> mp_cob = new Map<String,CPQ_Cobertura__c>();
        Map<String, CPQ_CoverageConsultation.WrapperResponse> cobConsult = CPQ_CoverageConsultation.getCoverage(lst_address);
        for(String idAddr : lst_address) {
            CPQ_Cobertura__c cob = new CPQ_Cobertura__c ();
            if (cobConsult.containsKey(idAddr)) {
                cob = cobConsult.get(idAddr).cobertura;
            } else {
                cob.CPQ_Direccion__c = idAddr;
                cob.CPQ_Estado_Consulta__c = 'Error';
                cob.CPQ_Error_Description__c = 'Unknown error';
            }
            if (cob.Id == null) {
            mp_cob.put(idAddr, cob);
            }
        }
        insert mp_cob.values();

        List<CPQ_Tech_Cob__c> lst_tech = new List<CPQ_Tech_Cob__c>();
        for(String idAddr : mp_cob.keySet()) {
            if (cobConsult.containsKey(idAddr)) {
                List<CPQ_Tech_Cob__c> lstTechs = cobConsult.get(idAddr).lstTecnologias;
                for (CPQ_Tech_Cob__c tech : lstTechs) {
                    tech.CPQ_Cobertura__c = mp_cob.get(idAddr).Id;
                    lst_tech.add(tech);
                }
            }
        }
        insert lst_tech;
        
        return JSON.serialize(cobConsult);

    }
    
    @AuraEnabled
    /**
    * @description
    * @author jalmendros@makemecloud.com | 15/7/2019
    * @param List<String> sitesIDs
    * @return List<BI_Punto_de_instalacion__c>
	* <date>		<version>		<description>
	* 2019/08/13	1.1				JLA-added CPQ_GPON__c
    * 2019/09/25    1.2             DAF-quit CPQ_GPON__c and quit CPQ_Velocidad__c
    */
    public static String getCobInfo(String orderId) {
        Map<String, CPQ_CoverageConsultation.WrapperResponse> result = new Map<String, CPQ_CoverageConsultation.WrapperResponse>();

        List<NE__OrderItem__c> orderItems = [
            SELECT Id, Installation_point__r.BI_Sede__c, CPQ_Cobertura__c
            FROM NE__OrderItem__c 
            WHERE NE__OrderId__c = :orderId
        ];
        
        Set<String> coberturasIDs = new Set<String>();
        for (NE__OrderItem__c orderItem : orderItems) {
            coberturasIDs.add(orderItem.CPQ_Cobertura__c);
        }
        System.debug('### coberturasIDs: ' + coberturasIDs);
        // DAF Case 04429671: Quit CPQ_GPON__c from first query, and CPQ_Velocidad__c and CPQ_Unidad_de_velocidad__c from the subquery
        List<CPQ_Cobertura__c> coverages = [
            SELECT Id, CPQ_Direccion__c, CPQ_CHI_IsConnectivityGuaranteed__c, CPQ_Error_Description__c, CPQ_Estado_Consulta__c,
                (
                    SELECT Id, Name, CPQ_Principal__c, CPQ_On_set__c  
                    FROM Tecnologiaas_de_cobertura__r
                )
            FROM CPQ_Cobertura__c 
            WHERE Id IN :coberturasIDs
            ORDER BY CreatedDate DESC
        ];
        System.debug('### coverages: ' + coverages);
        for (CPQ_Cobertura__c cob : coverages) {
            System.debug('### cob evaluada: ' + cob + ' -- ' + cob.CPQ_Direccion__c);
            if (!result.containsKey(cob.CPQ_Direccion__c)) {
                CPQ_CoverageConsultation.WrapperResponse wrapp = new CPQ_CoverageConsultation.WrapperResponse();
                wrapp.cobertura = cob;
                wrapp.lstTecnologias = cob.Tecnologiaas_de_cobertura__r;
                System.debug('### wrapp: ' + wrapp);
                result.put(cob.CPQ_Direccion__c, wrapp);
            }
        }
        System.debug('### result isEmpty? ' + result.isEmpty());
        System.debug('### result: ' + result);
        if (result.isEmpty()) {
            return '';
        }
        return JSON.serialize(result);
    }
    /**
    * @description
    * @author Amador Cáceres - Everis | 15/01/2019
    * @param String idQuote         --> Id de la oferta
    *        List<String> lst_idCis --> Lista de Id de los OI a clonar
    *        Integer div --> numero de duplicados a realizar
    * @return wrapperClassSplit
	* <date>		<version>		<description>
	* 15/01/2019	1.0				Initial Version
    */
    public static wrapperClassSplit cloneCIs(String idQuote, List<String> lst_idCis, Integer div){
        System.debug('Entramos en el nuevo Clone CIs');
        wrapperClassSplit response = new wrapperClassSplit(null, null);

        //Recuperamos los OI a partir de lis_idCis, estos los OI son los originales a partir de los cuales realizaremos los Splits
        Map<String,Schema.SObjectField> mp_fi = Schema.getGlobalDescribe().get('NE__OrderItem__c').getDescribe().fields.getMap();
        String query = 'Select ';
        query+=string.join(new List<String>(mp_fi.keySet()),',');
        query=query+', NE__OrderId__r.currencyIsoCode, NE__OrderId__r.NE__OptyId__r.BI_CoE_Duplicando__c,NE__CatalogItem__r.NE__Technical_Behaviour_Quote__c from NE__OrderItem__c where Id in:lst_idCIs';
        List<NE__OrderItem__c> lst_act = Database.query(query);

        Map<String,List<String>> mp_parent = new Map<String,List<String>>();
        Map<String,List<String>> mp_root = new Map<String,List<String>>();
        Map<String, List<NE__OrderItem__c>> mp_listOri = new Map<String, List<NE__OrderItem__c>>();
        List<NE__OrderItem__c> lstOItoInsert = new List<NE__OrderItem__c>();
        //Lista para las obras
		List<String> lst_oiObr = new List<String>();

        //sacamos el id de la OR relacionada
		String idOriOrd = lst_act.get(0).NE__OrderId__c;

        for(NE__OrderItem__c oi:lst_act){
            if(oi.NE__Root_Order_Item__c != null){
                List<String> aux = mp_root.get(oi.NE__Root_Order_Item__c);
                if(aux==null){
                    aux=new List<String>();
                    mp_root.put(oi.NE__Root_Order_Item__c,aux);
                }
                aux.add(oi.Id);
            }
            //Recogemos los OI padres y llenamos el mapa mp_parent
            if(oi.NE__Parent_Order_Item__c!=null){
                List<String> aux = mp_parent.get(oi.NE__Parent_Order_Item__c);
                if(aux==null){
                    aux=new List<String>();
                    mp_parent.put(oi.NE__Parent_Order_Item__c,aux);
                }
                aux.add(oi.Id);
            }
            //Clonamos los OI, tantas veces como divisiones tengamos
            for(Integer i = 0;i<div-1;i++){
                NE__OrderItem__c oiClone = oi.clone(false, false, false, false);

                if(oiClone.NE__OrderId__r.NE__OptyId__r.BI_CoE_Duplicando__c)
                    oiClone.Installation_point__c = null;

                oiClone.NE__AssetItemEnterpriseId__c=oi.id;
                System.debug('JLA_Catalog---->'+oi.NE__Catalog__c);
                oiClone.NE__Catalog__c=oi.NE__Catalog__c;
                
                Integer rand = Math.abs(Crypto.getRandomInteger());
                oiClone.NE__Configuration_item_update_key__c=idQuote+'_'+rand;
                oiClone.NE__Item_Code__c=String.valueOf(rand);
                oiClone.NE__orderId__c=idQuote;
                
                //Insertamos los OI dentro de un mapa, para no perder tener agrupados todos los padres con sus hijos respectivamente juntos en función del original
                if(mp_listOri.get(oi.Id) == null){
                    mp_listOri.put(oi.Id, new List<NE__OrderItem__c>());
                }
                mp_listOri.get(oi.Id).add(oiClone);
                //Insertamos los OI dentro de la lista para insertarla a posterior
                lstOItoInsert.add(oiClone);
                //Revisamos si los OI requieren Obras
                if(oi.NE__CatalogItem__r.NE__Technical_Behaviour_Quote__c!=null && oi.NE__CatalogItem__r.NE__Technical_Behaviour_Quote__c.contains('Obra requerida'))
                    lst_oiObr.add(oi.Id);
            }
        }
        BI_MigrationHelper.setSkippedTrigger('NE__OrderItem__c');
        BI_MigrationHelper.setSkippedTrigger('NE__Order__c');
        try{
            System.debug('--ACR--> Insertamos los Order Item ');
            insert lstOItoInsert;
            System.debug('--ACR--> Insertado');
        }catch(exception e){
            System.debug('--ACR--> Error insertando los OIs '+e);
            response.err = 'Error insertando los OIs: '+e.getMessage();
            return response;
        }
        //Recuperamos los Order Item Discount
        Set<String> stAux = mp_listOri.keySet();
        List<NE__Order_Item_Discount__c> lstOIDiscount = [SELECT NE__Applied_Discount__c,NE__Asset_update_key__c,NE__Canvas__c,
                                                        NE__Code__c,NE__Commercial_Promotion__c,CurrencyIsoCode,NE__Discount_Item__c,
                                                        NE__End_Date__c,NE__One_Time_Percentage__c,NE__One_Time_Price__c,
                                                        NE__One_Time_Value__c,NE__Order_Item__c,NE__Reason__c,NE__Recurring_Percentage__c,
                                                        NE__Recurring_Price__c,NE__Recurring_Value__c,NE__Sequence__c,
                                                        NE__Start_Date__c,NE__Status__c,NE__Type__c FROM NE__Order_Item_Discount__c
                                                        WHERE NE__Order_Item__c in : stAux];
        List<NE__Order_Item_Discount__c> lstOIDiscountToInsert = new List<NE__Order_Item_Discount__c>();

        // Recuperamos los OIAtt de cada OI Original
        List<NE__order_Item_Attribute__c> lst_OIAtt = [SELECT Id,NE__Order_Item__c,NE__Value__c, Name,NE__FamPropId__c,NE__FamPropExtId__c
                                                        FROM NE__order_Item_Attribute__c WHERE NE__Order_Item__c in:lst_idCis];
        List<NE__order_Item_attribute__c> lst_OIAttToInsert = new List<NE__order_Item_Attribute__c>();
        //Establecemos las jerarquías
        Boolean hasBun = false;
        for(Integer i = 0;i<div-1;i++){
            for(String idOIParent:mp_root.keySet()){
                List<String> lstOIchild = mp_root.get(idOIParent);
                for(String idChild:lstOIchild){
                    if(mp_listOri.get(idOIParent)[i]!=null){
                        //Establecemos el ID del padre a la hija
                        mp_listOri.get(idChild)[i].NE__Root_Order_Item__c=mp_listOri.get(idOIParent)[i].Id;
                    }
                    
                }
            }
            for(String idOIParent:mp_parent.keyset()){
                List<String> lstOIchild = mp_parent.get(idOIParent);
                for(String idChild : lstOIchild){
                    if(mp_listOri.get(idOIParent)[i]!=null){
                        //Establecemos el ID del padre a la hija
                        mp_listOri.get(idChild)[i].NE__Parent_Order_Item__c=mp_listOri.get(idOIParent)[i].Id;
                    } 
                }
            }
            //Establecemos los Bundles en el caso en el que apliquen
            for(String idOIParent : mp_listOri.keySet()){
                NE__OrderItem__c OIclone = mp_listOri.get(idOIParent)[i];
                if(OIClone.NE__Bundle_Configuration__c != null){
                    hasBun = true;
                    //NE__Bundle_Configuration es el ID del padre, que se setea tanto en el padre como en los hijos
                    //OI clonado del item i = OIs padres en la posición i
                    OIclone.NE__Bundle_Configuration__c = mp_listOri.get(OIclone.NE__Bundle_Configuration__c)[i].Id;
                }
            }
            //Clonamos y asignamos el OI al OIDiscount clonado
            for(NE__Order_Item_Discount__c oiDiscount: lstOIDiscount){
                NE__Order_Item_Discount__c oiDiscountClone = oiDiscount.clone(false,false,false,false);
                oiDiscountClone.NE__Order_Item__c = mp_listOri.get(oiDiscountClone.NE__Order_Item__c)[i].Id;
                lstOIDiscountToInsert.add(oiDiscountClone);
            }
            //Clonamos y asignamos el OI al OIAttribute clonado
            for(NE__order_Item_Attribute__c oiAtt : lst_OIAtt){
                NE__order_Item_Attribute__c oiAttClone = oiAtt.clone(false,false,false,false);
                oiAttClone.NE__Order_Item__c= mp_listOri.get(oiAtt.NE__Order_Item__c)[i].Id;
                lst_OIAttToInsert.add(oiAttClone);
            }
        }
        lstOItoInsert.clear();
        for(String idOIOriginal : mp_listOri.keySet()){
            lstOItoInsert.addAll(mp_listOri.get(idOIOriginal));
        }
        if((!mp_root.values().isEmpty() || !mp_parent.values().isEmpty() || hasBun ) && !lstOItoInsert.isEmpty()){
            try{
                System.debug('--ACR--> Actualizando los OI tras verificar la jerarquia y los Bundles');
                update lstOItoInsert;

                System.debug('--ACR--> Insertamos los Order Item Discount');
                insert lstOIDiscountToInsert;

                System.debug('--ACR--> Insertamos los Order Item Attribute');
                insert lst_OIAttToInsert;
            }catch(Exception e){
                System.debug('--ACR--> Error en CloneCIS de SplitAndSites '+e);
                response.err = 'Error en SplitAndSites: '+e.getStackTraceString();
                return response;
            }
        }
        // Falta por meter lo de obras-----------------------------------------------------------------------------------------------
        // if(!lst_oiObr.isEmpty()){
        //     System.debug('--ACR --> Entramos en obras');
        //     mp_fi = Schema.getGlobalDescribe().get('CPQ_Obra__c').getDescribe().fields.getMap();
        //     query = 'SELECT ';
        //     query+=string.join(new List<String>(mp_fi.keySet()),',');
        //     query+=' FROM CPQ_Obra__c WHERE CPQ_Order__c = \''+idOriOrd+'\'';
        //     List<CPQ_Obra__c> lst_obr = Database.query(query);
        //     if(!lst_obr.isEmpty()){
        //         System.debug('--ACR --> Tenemos obras en nuestra OR');
        //         List<CPQ_Obra__c> lst_ObrasToInsert = new List<CPQ_Obra__c>();
        //         for(CPQ_Obra__c obr : lst_obr){
        //             CPQ_Obra__c = obrClone = obr.clone(false,false,false,false);
        //             obrClone.CPQ_Id_Ori__c=obr.Id;
        //             obrClone.CPQ_Order__c=idQuote;
        //             lst_ObrasToInsert.add(obrClone);
        //         }
        //     }
        // }
        //Fin de Obras---------------------------------------------------------------------------------------------------------------
        BI_MigrationHelper.cleanSkippedTriggers();
        System.debug('--ACR--> Salimos de CloneCIS en Split');
        response.res = new Map<String,String>();
        response.res.put('res','OK');
        for(String idOIOriginal : mp_listOri.keySet()){
            for(NE__OrderItem__c oiClone : mp_listOri.get(idOIOriginal))
                response.lst_cis.add(oiClone.Id);
        }
        return response;
    }
    public class wrapperClassSplit{
        @AuraEnabled public Map <String,String> res;
        @AuraEnabled public String err;
        public List<String> lst_cis;
        wrapperClassSplit(Map<String,String> res,String err){
            this.res=res;
            this.err=err;
            this.lst_cis=new List<String>();
        }
    }

}