/**
 * @File Name          : CPQ_JSON_PortalOperativo.cls
 * @Description        : 
 * @Author             : dculebras@makemecloud.com
 * @Group              : 
 * @Last Modified By   : jalmendros@makemecloud.com
 * @Last Modified On   : 5/12/2019 14:07:17
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    10/9/2019   jalmendros@makemecloud.com     Initial Version
**/
public with sharing class CPQ_JSON_PortalOperativo {
    public String IdOrd {get;set;}
    public String autorenovable {get;set;}
    public PO_Order poOrder {get;set;}
    public NE__Order__c neOrder;
    public Contract contract;
    Map<ID, NE__OrderItem__c> orderItemsMap;
    Map<ID, CPQ_Obra__c> obrasMap;
    Map<String, Integer> obrasFactorMap;
    Map<String, Double> currencyTable;
    Set<String> casosPermitidos;
    List<Case> lstCasos;
    Map<Id, User> lstUserCasos;
    Map<Id, Group> lstGroupCasos;
    private String pais;
    List<String> lstJSONs;

    public static final Integer MAX_FILE_SIZE = 600 * 1000 * 1000; //bytes (600MB)
    public Integer maxSplits = 0;
    public Integer splits = 0;

    private String getOrgURL() {
        return URL.getSalesforceBaseUrl().toExternalForm() + '/';
    }

    public CPQ_JSON_PortalOperativo(String orderId) {
        System.debug('CPQ_JSON_PortalOperativo orderId: '+orderId);
        this.IdOrd = orderId;
        cargaDatosOrden();
    }

    @AuraEnabled
    public static NE__Order__c getStatus (String orderId) {
        List<NE__Order__c> lOrden = [
            SELECT Id, CPQ_EstadoSincroProvisionador__c, CPQ_PedidoProvisionado__c
            FROM NE__Order__c 
            WHERE Id = :orderId];

        return lOrden.get(0);
    }

    @AuraEnabled
    public static Boolean isBackofficeUser () {
        Profile prf = [SELECT Id, Name FROM Profile WHERE Id = :UserInfo.getProfileId()];
        User usr = [SELECT BI_Permisos__c FROM User WHERE Id = :UserInfo.getUserId()];

        return prf.Name == 'System Administrator' ||
            prf.Name == 'Administrador del sistema' ||
            usr.BI_Permisos__c == 'Super Usuario' ||
            usr.BI_Permisos__c == 'Backoffice';
    }

    @AuraEnabled
    public static void crearPedidoApex (String orderId) {
        System.debug('CPQ_JSON_PortalOperativo crearPedidoApex orderId: '+orderId);
        CPQ_JSON_PortalOperativo po = new CPQ_JSON_PortalOperativo(orderId);
        po.procesaPedido('Crear');
    }

    @AuraEnabled
    public static void actualizarPedidoApex (String orderId) {
        System.debug('CPQ_JSON_PortalOperativo actualizarPedidoApex orderId: '+orderId);
        CPQ_JSON_PortalOperativo po = new CPQ_JSON_PortalOperativo(orderId);
        po.procesaPedido('Actualizar');
    }

    private void procesaPedido (String tipo) {
        // String jsonBody = JSON.serializePretty(poOrder);
        String jsonBody = JSON.serialize(poOrder);
        String credentialName = 'CPQ_ProductOrdering';

        try {
            HttpRequest req = new HttpRequest();

            switch on pais {
                when 'Argentina' {
                    credentialName += '_ARG';

                    req.setHeader('accept', 'application/json');
                    req.setHeader('cache-control', 'no-cache');
                    req.setHeader('content-type', 'application/json');
                    req.setHeader('authorization', 'Bearer ' + getAccessToken());
                    req.setHeader('x-ibm-client-id', Label.CPQ_ARG_ApiMovistarArgTokenIBMClientID);
                }

                when 'Chile' {
                    credentialName += '_CHI';

//                    req.setHeader('authorization', 'Basic c2FsZXNmb3JjZTpzYWxlc2ZvcmNlQHRlbGVmb25pY2EuY29t');
                    req.setHeader('authorization', 'Basic F5511520CB328DA646752B1A778ED8909C61BE88');
                    req.setHeader('connection', 'keep-alive');
                }
            }
            req.setTimeout(120 * 1000);

            if (String.isEmpty(credentialName)) {
                throw new ErrorPortalOperativoException('Endpoint not defined');
            }

            Http http = new Http();
            if (tipo == 'Crear') {
                req.setMethod('POST');
//                req.setEndpoint('callout:' + credentialName + '/' + neOrder.NE__AccountId__c + '/productOrders');
                req.setEndpoint('callout:' + credentialName + '/');
            } else {
                req.setMethod('PUT');
//                req.setEndpoint('callout:' + credentialName + '/' + neOrder.NE__AccountId__c + '/productOrders/' + this.IdOrd);
                req.setEndpoint('callout:' + credentialName + '/');
            }
            req.setBody(jsonBody);

            HTTPResponse res = http.send(req);
            String responseBody = res.getBody();
            // String statusCode = String.valueOf(res.getStatusCode());
            String statusCode = tipo == 'Crear' ? '201' : '200';//Mockup hasta que no creen el servicio.

            System.debug('***statusCode: ' + statusCode);
            System.debug('@CALLOUT_REQUEST: ' + req.getEndpoint());
            System.debug('@CALLOUT_RAW_RESPONSE: ' + responseBody);

            NE__Order__c order = new NE__Order__c();
            order.Id = this.IdOrd;

            if (statusCode == '201' || statusCode == '200') {
                order.CPQ_EstadoSincroProvisionador__c = 'Sincronizado';
                order.CPQ_PedidoProvisionado__c = true;
            } else {
                System.debug('@CALLOUT_RESPONSE: \n' + JSON.serializePretty(JSON.deserializeUntyped(responseBody)));
                order.CPQ_EstadoSincroProvisionador__c = 'Error';
            }

            BI_MigrationHelper.setSkippedTrigger('NE__Order__c');
            update order;
        } catch (Exception e) {
            System.debug(e.getMessage());

            NE__Order__c order = new NE__Order__c();
            order.Id = this.IdOrd;
            order.CPQ_EstadoSincroProvisionador__c = 'Error';
            BI_MigrationHelper.setSkippedTrigger('NE__Order__c');
            update order;
        }

        BI_MigrationHelper.cleanSkippedTriggers();
    }

    public static List<PO_Order> getOrders(String orderId) {
        CPQ_JSON_PortalOperativo po = new CPQ_JSON_PortalOperativo(orderId);
        Decimal necessarySplits = Blob.valueOf(JSON.serialize(po.poOrder)).size() / MAX_FILE_SIZE;
        po.maxSplits = Integer.valueOf(necessarySplits.round(System.RoundingMode.UP)) + 2;
        return po.splitOrder(po.poOrder);
    }

    private static String getAccessToken() {

        HttpRequest reqAuth = new HttpRequest();
        reqAuth.setMethod('POST');
        reqAuth.setEndpoint('callout:CPQ_ARG_ApiMovistarToken');
        reqAuth.setHeader('accept', 'application/json');
        reqAuth.setHeader('cache-control', 'no-cache');
        reqAuth.setHeader('content-type', 'application/x-www-form-urlencoded');
        String content = 'grant_type=client_credentials';
        content += '&scope=scope1';
        content += '&client_id=' + EncodingUtil.urlEncode(Label.CPQ_ARG_ApiMovistarArgTokenClientID, 'UTF-8');
        content += '&client_secret=' + EncodingUtil.urlEncode(Label.CPQ_ARG_ApiMovistarArgTokenClientSecret, 'UTF-8');
        reqAuth.setBody(content);

        Http http = new Http();
        HttpResponse res = http.send(reqAuth);

        Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        String accessToken = String.valueOf(responseBody.get('access_token'));

        return accessToken;
    }

    public void creaJSON(String title) {
        Decimal necessarySplits = Blob.valueOf(JSON.serialize(poOrder)).size() / MAX_FILE_SIZE;
        maxSplits = Integer.valueOf(necessarySplits.round(System.RoundingMode.UP)) + 2;
        List<PO_Order> orders = splitOrder(poOrder);
        List<ContentVersion> cvs = new List<ContentVersion>();
        for (Integer i = 0; i < orders.size(); i++) {
            PO_Order ord = orders.get(i);
            ContentVersion cv = new ContentVersion (
                Title = title + '_' + i,
                PathOnClient = title + '_' + i + '.json',
                VersionData = Blob.valueOf(JSON.serializePretty(ord))
            );
            cvs.add(cv);
        }
        insert cvs;
    }

    public String getJSONBody() {
        return JSON.serialize(poOrder);
    }

    private void cargaDatosContrato(String OptyId) {
        List<Contract> lContrato = [
            SELECT BI_Autorenovable__c, StartDate, ContractTerm
            FROM Contract 
            WHERE BI_Oportunidad__c = :OptyId
        ];
        if (!lContrato.isEmpty()) {
            contract = lContrato[0];
        } else {
            contract = new Contract();
        }
    }

    private PO_OrderItem_Structure[] ordenaJerarquia(Map<ID,NE__OrderItem__c> mapOrderItem) {
        PO_OrderItem_Structure[] arrPadres = new PO_OrderItem_Structure[]{};
        NE__OrderItem__c[] arrHijos = new NE__OrderItem__c[]{};

        for (String itemId : mapOrderItem.keySet()) {
            NE__OrderItem__c neoi = mapOrderItem.get(itemId);
            if (neoi.NE__Parent_Order_Item__c == null) {
                arrPadres.add(new PO_OrderItem_Structure(neoi)); 
            } else {
                arrHijos.add(neoi);
            }
        }

        for(PO_OrderItem_Structure pooi: arrPadres) {
            pooi.coloca(arrHijos);
        }

        return arrPadres;
    }

    public void cargaDatosOrden() {
        List<NE__Order__c> lOrden = [
            SELECT Id, Name, CurrencyIsoCode, NE__Recurring_Charge_Total__c, NE__One_Time_Fee_Total__c, 
            BI_Final_Total_NAV_Configuration__c, NE__Description__c, 
            OwnerId, Owner.Name, CreatedById, CreatedBy.Name, CPQ_Quote__c,
            CPQ_EstadoSincroProvisionador__c, CPQ_PedidoProvisionado__c,

            // Opportunity
            NE__OptyId__c, NE__OptyId__r.BI_Fecha_inicio_contrato__c, NE__OptyId__r.BI_Duracion_del_contrato_Meses__c, 
            NE__OptyId__r.BI_Id_Interno_de_la_Oportunidad__c, NE__OptyId__r.BI_SIMP_Opportunity_Type__c,
            NE__OptyId__r.BI_Plazo_estimado_de_provision_dias__c,

            // Account
            NE__AccountId__c, NE__AccountId__r.BI_No_Identificador_fiscal__c,
            NE__AccountId__r.BI_Tipo_de_identificador_fiscal__c, NE__AccountId__r.BI_Segment__c, 
            NE__AccountId__r.BI_Subsegment_Local__c, NE__AccountId__r.BI_Country__c

            FROM NE__Order__c 
            WHERE Id = :IdOrd];

        neOrder = lOrden[0];

        cargaDatosContrato( neOrder.NE__OptyId__c );

        pais = neOrder.NE__AccountId__r.BI_Country__c;

        poOrder = new PO_Order();
        poOrder.correlationId = neOrder.Id;
        poOrder.description = neOrder.Name;
        poOrder.productOrderType = neOrder.NE__AccountId__r.BI_Segment__c;
        poOrder.priority = '3';
        poOrder.relatedParty = creaRelatedParty( neOrder );
        poOrder.relatedObject = creaRelatedObject( neOrder );
        Datetime ahora = Datetime.now();
        poOrder.requestedStartDate = ahora;
        Datetime requestedCompletionDate = ahora.addDays( Integer.valueOf( (neOrder.NE__OptyId__r.BI_Plazo_estimado_de_provision_dias__c != null ? neOrder.NE__OptyId__r.BI_Plazo_estimado_de_provision_dias__c : 0) ) );
        poOrder.requestedCompletionDate = requestedCompletionDate;

        addData(poOrder.additionalData,'NAV', neOrder.BI_Final_Total_NAV_Configuration__c);
        // addData(poOrder.additionalData,'Name', neOrder.Name);
        addData(poOrder.additionalData,'FechaInicioContrato', contract.StartDate);
        addData(poOrder.additionalData,'duracionContrato', contract.ContractTerm);
        // addData(poOrder.additionalData,'SEGMENTO_CLIENTE', neOrder.NE__AccountId__r.BI_Segment__c);
        addData(poOrder.additionalData,'SUBSEGMENTO_CLIENTE', neOrder.NE__AccountId__r.BI_Subsegment_Local__c);
        addData(poOrder.additionalData,'INDICADOR_ENVIO', 'C');
        addData(poOrder.additionalData,'NUMERO_PAGINA', 1);
        addData(poOrder.additionalData,'PAGINA_FINAL', true);
        addData(poOrder.additionalData,'CODIGO_MONEDA', neOrder.CurrencyIsoCode);
        addData(poOrder.additionalData,'MONTO_RENTA', neOrder.NE__Recurring_Charge_Total__c);
        addData(poOrder.additionalData,'MONTO_VENTA', neOrder.NE__One_Time_Fee_Total__c);

        loadCurrencyTable();

        addData(poOrder.additionalData,'VALUE_USD', currencyTable.get('USD'));
        addData(poOrder.additionalData,'VALUE_CLP', currencyTable.get('CLP'));
        addData(poOrder.additionalData,'VALUE_CLF', currencyTable.get('CLF'));

        poOrder.orderItem = cargaDatosOrdenItem();

        system.debug('JSON creado: '+JSON.serializePretty(poOrder));

    }

    private void loadCurrencyTable() {
        currencyTable = new Map<String, Double>();
        List<CurrencyType> crs = [
            SELECT Id, IsoCode, ConversionRate FROM CurrencyType 
            WHERE IsoCode IN ('USD', 'CLP', 'CLF')
        ];
        for (CurrencyType cr : crs) {
            currencyTable.put(cr.IsoCode, cr.ConversionRate);
        }
    }

    private List<PO_OrderItem> cargaDatosOrdenItem() {
        orderItemsMap = new Map<ID, NE__OrderItem__c>([
            SELECT 
            CurrencyIsoCode, NE__RecurringChargeOv__c, NE__OneTimeFeeOv__c, BI_NAV_Producto__c, Id, NE__Parent_Order_Item__c, 
            NE__Qty__c, NE__Status__c, NE__ProdId__c, 
            NE__Description__c, Name, NE__CatalogItem__c, NE__CatalogItem__r.Name, Installation_point__c, 
            B2W_Total_RecurringCharge__c, B2W_Total_OneTimeFee__c,

            // PRODUCT
            NE__ProdId__r.Name, NE__ProdId__r.Familia_MKTG_Nivel_1__c, NE__ProdId__r.NE__Source_Product_Id__c,
            NE__ProdId__r.Familia_MKTG_Nivel_2__c, NE__ProdId__r.Familia_MKTG_Nivel_3__c, NE__ProdId__r.Familia_MKTG_Nivel_4__c, NE__ProdId__r.NE__Description__c,

            //CODIGO_SUBFAMILIA
            NE__CatalogItem__r.NE__Catalog_Category_Name__c, 
            NE__CatalogItem__r.NE__Catalog_Category_Name__r.Name, 

            //CODIGO_FAMILIA
            NE__CatalogItem__r.NE__Catalog_Category_Name__r.NE__Parent_Category_Name__c, 
            NE__CatalogItem__r.NE__Catalog_Category_Name__r.NE__Parent_Category_Name__r.Name,

            //CODIGO_LINEA
            NE__CatalogItem__r.NE__Catalog_Category_Name__r.NE__Parent_Category_Name__r.NE__Parent_Category_Name__c, 
            NE__CatalogItem__r.NE__Catalog_Category_Name__r.NE__Parent_Category_Name__r.NE__Parent_Category_Name__r.Name,

            Installation_point__r.BI_COT_MEX_Direccion_Completa__c, Installation_point__r.BI_Sede__r.Name,
            Installation_point__r.BI_Sede__r.BI_Longitud__Latitude__s, 
            Installation_point__r.BI_Sede__r.BI_Longitud__Longitude__s,
            Installation_point__r.BI_Sede__r.BI_Distrito__c, Installation_point__r.BI_Sede__r.BI_Localidad__c, 
            Installation_point__r.BI_Sede__r.BI_Provincia__c, Installation_point__r.BI_Sede__r.BI_Direccion__c,

            //ATTRIBUTES
            (
                SELECT NE__Value__c, Name, NE__FamPropId__r.NE__FamilyId__r.Name,
                NE__FamPropId__r.NE__PropId__r.B2W_Tipologia__c
                FROM NE__Order_Item_Attributes__r
            ),

            //OBRAS_SERVICIOS
            (
                SELECT Id, CPQ_Obra__c
                FROM Obras_Servicios__r
            )

            FROM NE__OrderItem__c 
            WHERE NE__OrderId__c = :neOrder.Id
        ]);
        
        cargaDatosObras();

        // PO_OrderItem_Structure[] orderItemTree = ordenaJerarquia(orderItemsMap);
        return mapOrderItems(orderItemsMap);
    }

    private void cargaDatosObras() {
        System.debug('@JAL cargaDatosObras; Order: ' + neOrder.Id);

        obrasMap = new Map<Id, CPQ_Obra__c>([
            SELECT Id, Name, CPQ_CAPEX_Total__c, CPQ_OPEX_Total__c, CPQ_OPEX_Recurrente_Total__c,
            CPQ_Tipo_fact__c, CPQ_Elemento__c, CPQ_Subelemento__c, CurrencyIsoCode, CPQ_Zona__c, CPQ_Plazo__c, 
            CPQ_Mts_construccion__c, CPQ_Mts_cable__c, CPQ_Prorrateo__c, CPQ_Plazo_Obra__c, 
            CPQ_Plazo_Permisos__c, CPQ_Plazo_Ingenieria__c, CPQ_Detalles__c, CPQ_Central__c,
            (
                SELECT Name, CPQ_Clasificacion_Coste__c, CPQ_Coste__c, CPQ_Obra__c, CPQ_Tipo_de_coste__c, CurrencyIsoCode
                FROM CPQ_Eco_Obra__r
            ),
            (
                SELECT Id, CPQ_OI__c, CPQ_OI__r.Name
                FROM Obras_Servicios__r
            )
            FROM CPQ_Obra__c
            WHERE CPQ_Order__c = :neOrder.Id
        ]);

        System.debug('@JAL obrasMap ' + obrasMap.size());

        obrasFactorMap = new Map<String, Integer>();
        // Map<ID, NE__OrderItem__c> orderItemsMap;
        for (NE__OrderItem__c oi : orderItemsMap.values()) {
            if (oi.Obras_Servicios__r != null && !oi.Obras_Servicios__r.isEmpty()) {
                for (CPQ_Obra_Servicio__c servicio : oi.Obras_Servicios__r) {
                    if (!obrasFactorMap.containsKey(servicio.CPQ_Obra__c)) {
                        obrasFactorMap.put(servicio.CPQ_Obra__c, 0);
                    }
                    obrasFactorMap.put(servicio.CPQ_Obra__c, obrasFactorMap.get(servicio.CPQ_Obra__c) + 1);
                }
            }
        }

        List<PO_Obra> poObras = new List<PO_Obra>();
        for (CPQ_Obra__c obra : obrasMap.values()) {
            PO_Obra poObra = new PO_Obra();
            poObra.name = obra.Name;
            for (CPQ_Obra_Servicio__c serv : obra.Obras_Servicios__r) {
                poObra.orderItems.add(serv.CPQ_OI__r.Name);
            }
            for (CPQ_Econ_Obra__c econ : obra.CPQ_Eco_Obra__r) {
                PO_Obra_Cost cost = new PO_Obra_Cost();
                cost.name = econ.Name;
                cost.price.amount = econ.CPQ_Coste__c;
                cost.price.units = econ.CurrencyIsoCode;
                cost.type = econ.CPQ_Clasificacion_Coste__c;
                cost.subject = econ.CPQ_Tipo_de_coste__c;
                poObra.costs.add(cost);
            }
            addData(poObra.characteristics, 'Tipo', obra.CPQ_Tipo_fact__c);
            addData(poObra.characteristics, 'Elemento', obra.CPQ_Elemento__c);
            addData(poObra.characteristics, 'Subelemento', obra.CPQ_Subelemento__c);
            addData(poObra.characteristics, 'Divisa', obra.CurrencyIsoCode);
            addData(poObra.characteristics, 'Zona', obra.CPQ_Zona__c);
            addData(poObra.characteristics, 'Plazo', obra.CPQ_Plazo__c);
            addData(poObra.characteristics, 'MtsConstruccion', obra.CPQ_Mts_construccion__c);
            addData(poObra.characteristics, 'MtsCable', obra.CPQ_Mts_cable__c);
            addData(poObra.characteristics, 'Prorrateo', obra.CPQ_Prorrateo__c);
            addData(poObra.characteristics, 'PlazoObra', obra.CPQ_Plazo_Obra__c);
            addData(poObra.characteristics, 'PlazoPermiso', obra.CPQ_Plazo_Permisos__c);
            addData(poObra.characteristics, 'PlazoIng', obra.CPQ_Plazo_Ingenieria__c);
            addData(poObra.characteristics, 'Detalles', obra.CPQ_Detalles__c);
            addData(poObra.characteristics, 'Central', obra.CPQ_Central__c);
            poObras.add(poObra);
        }

        poOrder.deploymentWorks = poObras;
    }

    private List<PO_OrderItem> mapOrderItems(Map<ID, NE__OrderItem__c> mapOI) {
        List<PO_OrderItem> ret = new List<PO_OrderItem>();

        for (NE__OrderItem__c oi : mapOI.values()) {
            // NE__OrderItem__c oi = pooi.orderItem;

            PO_OrderItem orderItem = new PO_OrderItem();
            orderItem.id = oi.Id;
            orderItem.parent = oi.NE__Parent_Order_Item__c;
            orderItem.action = neOrder.NE__OptyId__r.BI_SIMP_Opportunity_Type__c;
            orderItem.description = oi.Name;
            orderItem.productOffering.id = oi.NE__CatalogItem__c;
            orderItem.productOffering.href = getOrgURL() + oi.NE__CatalogItem__c;
            orderItem.productOffering.Name = oi.NE__CatalogItem__r.Name;
            
            orderItem.product.id = oi.NE__ProdId__r.NE__Source_Product_Id__c;
            orderItem.product.name = oi.NE__ProdId__r.Name;
            orderItem.product.href = getOrgURL() + oi.NE__ProdId__c;
            orderItem.product.description = oi.NE__ProdId__r.NE__Description__c;
            orderItem.product.productType = oi.NE__ProdId__r.Familia_MKTG_Nivel_4__c;

            PO_Product_Category cat1 = new PO_Product_Category();
            cat1.id = oi.NE__ProdId__r.Familia_MKTG_Nivel_1__c;
            PO_Product_Category cat2 = new PO_Product_Category();
            cat2.id = oi.NE__ProdId__r.Familia_MKTG_Nivel_2__c;
            PO_Product_Category cat3 = new PO_Product_Category();
            cat3.id = oi.NE__ProdId__r.Familia_MKTG_Nivel_3__c;
            cat2.subcategories.add(cat3);
            cat1.subcategories.add(cat2);
            orderItem.product.category.add(cat1);
            if (oi.Installation_point__c != null) {
                orderItem.product.place.id = oi.Installation_point__c;
                orderItem.product.place.name = oi.Installation_point__r.BI_COT_MEX_Direccion_Completa__c;
            }
            for (NE__Order_Item_Attribute__c oia : oi.NE__Order_Item_Attributes__r) {
                PO_Product_CharacteristicValue charact = new PO_Product_CharacteristicValue();
                charact.type = 'Text';
                charact.name = oia.Name;
                charact.value = oia.NE__Value__c;
                charact.familia = oia.NE__FamPropId__r.NE__FamilyId__r.Name;
                charact.tipologia = oia.NE__FamPropId__r.NE__PropId__r.B2W_Tipologia__c;
                orderItem.product.characteristic.add(
                    PO_Product_Characteristic(charact)
                );
            }

            // aqui productos complejos
            // orderItem.product.productRelationship = mapOrderItems( pooi.hijos );

            addData(orderItem.additionalData, 'NAV', oi.BI_NAV_Producto__c);
            //vemos si tenemos installation
            if (oi.Installation_point__c!=null) {
                addData(orderItem.product.additionalData, 'longitud_instalacion', oi.Installation_point__r.BI_Sede__r.BI_Longitud__Longitude__s);
                addData(orderItem.product.additionalData, 'latitud_instalacion', oi.Installation_point__r.BI_Sede__r.BI_Longitud__Latitude__s);
            }

	        addData(orderItem.product.additionalData, 'RESTO_DIRECCION', oi.Installation_point__r.BI_Sede__r.Name);
	        addData(orderItem.product.additionalData, 'NOMBRE_COMUNA', oi.Installation_point__r.BI_Sede__r.BI_Distrito__c);
	        addData(orderItem.product.additionalData, 'NOMBRE_CIUDAD', oi.Installation_point__r.BI_Sede__r.BI_Localidad__c);
	        addData(orderItem.product.additionalData, 'NOMBRE_REGION', oi.Installation_point__r.BI_Sede__r.BI_Provincia__c);
	        addData(orderItem.product.additionalData, 'NUMERO_CALLE', oi.Installation_point__r.BI_Sede__r.BI_Direccion__c);

	        addData(orderItem.product.additionalData, 'CODIGO_LINEA', oi.NE__CatalogItem__r.NE__Catalog_Category_Name__r.NE__Parent_Category_Name__r.NE__Parent_Category_Name__c);
	        addData(orderItem.product.additionalData, 'NOMBRE_LINEA', oi.NE__CatalogItem__r.NE__Catalog_Category_Name__r.NE__Parent_Category_Name__r.NE__Parent_Category_Name__r.Name);

	        addData(orderItem.product.additionalData, 'CODIGO_FAMILIA', oi.NE__CatalogItem__r.NE__Catalog_Category_Name__r.NE__Parent_Category_Name__c);
	        addData(orderItem.product.additionalData, 'NOMBRE_FAMILIA', oi.NE__CatalogItem__r.NE__Catalog_Category_Name__r.NE__Parent_Category_Name__r.Name);

	        addData(orderItem.product.additionalData, 'CODIGO_SUBFAMILIA', oi.NE__CatalogItem__r.NE__Catalog_Category_Name__c);
	        addData(orderItem.product.additionalData, 'NOMBRE_SUBFAMILIA', oi.NE__CatalogItem__r.NE__Catalog_Category_Name__r.Name);

            orderItem.quantity = String.valueOf(oi.NE__Qty__c);
            
            // precio recurrente
            PO_OrderItem_Price rec = new PO_OrderItem_Price();
            rec.Name = 'recurrent';
            rec.priceType = 'recurrent';
            // rec.recurringChargePeriod = 'monthly';
            rec.price.amount = oi.NE__RecurringChargeOv__c;
            rec.price.units = oi.CurrencyIsoCode;
            rec.taxIncluded = false;
            addData(rec.additionalData, 'total', oi.B2W_Total_RecurringCharge__c);
            orderItem.orderItemPrice.add(rec);

            // precio oneshot
            PO_OrderItem_Price one = new PO_OrderItem_Price();
            one.priceType = 'oneshot';
            one.Name = 'oneshot';
            one.price.amount = oi.NE__OneTimeFeeOv__c;
            one.price.units = oi.CurrencyIsoCode;
            one.taxIncluded = false;
            addData(one.additionalData, 'total', oi.B2W_Total_OneTimeFee__c);
            orderItem.orderItemPrice.add(one);

            // precio obras
            if (obrasMap != null && !obrasMap.isEmpty() && 
                oi.Obras_Servicios__r != null && !oi.Obras_Servicios__r.isEmpty()) {
                
                for (CPQ_Obra_Servicio__c obraServicio : oi.Obras_Servicios__r) {
                    CPQ_Obra__c obra = obrasMap.get(obraServicio.CPQ_obra__c);
                    Integer factorObra = obrasFactorMap.containsKey(obraServicio.CPQ_obra__c) ? obrasFactorMap.get(obraServicio.CPQ_obra__c) : 1;
                    for (CPQ_Econ_Obra__c econObra : obra.CPQ_Eco_Obra__r) {
                        Boolean recurrent = econObra.CPQ_Clasificacion_Coste__c.containsIgnoreCase('recurrente');
                        PO_OrderItem_Price priceObra = new PO_OrderItem_Price();
                        priceObra.Name = econObra.Name;
                        priceObra.priceType = recurrent ? 'recurrent' : 'oneshot';
                        priceObra.price.amount = econObra.CPQ_Coste__c / factorObra;
                        priceObra.price.units = econObra.CurrencyIsoCode;
                        priceObra.taxIncluded = false;
                        addData(priceObra.additionalData, 'type', econObra.CPQ_Clasificacion_Coste__c);
                        addData(priceObra.additionalData, 'subject', econObra.CPQ_Tipo_de_coste__c);
                        orderItem.orderItemPrice.add(priceObra);
                    }
                }
            }

            orderItem.status = oi.NE__Status__c;
            if (oi.NE__Status__c == 'Pending') {
                addData(poOrder.additionalData, 'INDICADOR_ENVIO', 'P');
            }
            // orderItem.validFor.startDateTime = (neOrder.NE__OptyId__r != null ? neOrder.NE__OptyId__r.BI_Fecha_inicio_contrato__c : null);
            // orderItem.validFor.endDateTime = orderItem.validFor.startDateTime != null ? orderItem.validFor.startDateTime.addMonths(Integer.valueOf(neOrder.NE__OptyId__r.BI_Duracion_del_contrato_Meses__c)) : null;
            orderItem.isAutoRenew = contract.BI_Autorenovable__c;

            ret.add(orderItem);
        }

        return ret;
    }

    private Integer getOrderSize(PO_Order order) {
        return Blob.valueOf(JSON.serialize(order)).size();
    }

    public List<PO_Order> splitOrder(PO_Order oldOrder) {
        List<PO_Order> lstFiles = new List<PO_Order>();
        PO_Order newOrder = new PO_Order();
        System.debug('Split ' + splits + '; Order size: ' + getOrderSize(oldOrder) + '; Max size: ' + MAX_FILE_SIZE);
        if (splits < maxSplits && getOrderSize(oldOrder) > MAX_FILE_SIZE) {
            splits ++;
            newOrder.correlationId = oldOrder.correlationId;
            Integer numeroPagina = (Integer) getData(oldOrder.additionalData, 'NUMERO_PAGINA');
            addData(newOrder.additionalData, 'NUMERO_PAGINA', numeroPagina + 1);
            addData(oldOrder.additionalData, 'PAGINA_FINAL', false);
            addData(newOrder.additionalData, 'PAGINA_FINAL', true);
            do {
                newOrder.orderItem.add(oldOrder.orderItem.remove(oldOrder.orderItem.size() - 1));
            } while (getOrderSize(oldOrder) > MAX_FILE_SIZE);
        }
        lstFiles.add(oldOrder);
        if (!String.isEmpty(newOrder.correlationId) && splits < maxSplits) {
            lstFiles.addAll(splitOrder(newOrder));
        }
        if (splits >= maxSplits) {
            System.debug('MAXIMUM OF SPLITS: ' + splits);
        }
        return lstFiles;
    }

    private List<PO_RelatedParty> creaRelatedParty(NE__Order__c order) {
        List<PO_RelatedParty> ret = new List<PO_RelatedParty>();

        PO_RelatedParty rpOwner = new PO_RelatedParty();
        rpOwner.id = order.OwnerId;
        rpOwner.role = 'owner';
        rpOwner.name = order.Owner.Name;
        ret.add(rpOwner);

        PO_RelatedParty rpCreator = new PO_RelatedParty();
        rpCreator.id = order.CreatedById;
        rpCreator.role = 'creator';
        rpCreator.name = order.CreatedBy.Name;
        ret.add(rpCreator);

        for (Case caso : cargaCasos()) {
            PO_RelatedParty rpCaso = new PO_RelatedParty();
            rpCaso.id = lstUserCasos.containsKey(caso.OwnerId) ? lstUserCasos.get(caso.OwnerId).BI_User_Rut__c : '';
            rpCaso.name = lstUserCasos.containsKey(caso.OwnerId) ? lstUserCasos.get(caso.OwnerId).Name : lstGroupCasos.containsKey(caso.OwnerId) ? lstGroupCasos.get(caso.OwnerId).Name : '';
            // rpCaso.name = lstOwnerCasos.get(caso.OwnerId).Name;
            switch on caso.Subject {
                when 'Aseguramiento de Facturación' {
                    rpCaso.role = 'Analista facturación';
                }
                when 'Solicitud revisión oferta' {
                    rpCaso.role = 'Validador técnico';
                }
                when 'Carga en sistemas del Pedido' {
                    rpCaso.role = 'Gestor de Pedido';
                }
            }
            ret.add(rpCaso);
        }

        return ret;
    }

    private List<Case> cargaCasos() {
        casosPermitidos = new Set<String>{
            'Aseguramiento de Facturación', 'Solicitud revisión oferta', 'Carga en sistemas del Pedido'
        };
        String query = 'SELECT Id, OwnerId, Owner.Name, Subject FROM Case ' + 
        ' WHERE Subject IN :casosPermitidos ';
        List<String> queryAnd = new List<String>();
        queryAnd.add('BI_Pedido__c = \'' + neOrder.Id + '\'');
        if (neOrder.CPQ_Quote__c != null) {
            queryAnd.add('BI_Oferta_asociada__c = \'' + neOrder.CPQ_Quote__c + '\'' );
        }
        query += ' AND ( ' + String.join(queryAnd, ' OR ') + ' ) ';
        lstCasos = Database.query(query);

        Set<String> ownerIds = new Set<String>();
        for (Case caso : lstCasos) {
            ownerIds.add(caso.OwnerId);
        }

        lstUserCasos = new Map<Id, User>([
            SELECT Id, Name, BI_User_Rut__c
            FROM User 
            WHERE Id IN :ownerIds
        ]);

        lstGroupCasos = new Map<Id, Group>([
            SELECT Id, Name
            FROM Group 
            WHERE Id IN :ownerIds
        ]);

        return lstCasos;
    }

    private List<PO_RelatedObject> creaRelatedObject(NE__Order__c order) {
        List<PO_RelatedObject> ret = new List<PO_RelatedObject>();

        PO_RelatedObject rpOwner = new PO_RelatedObject();
        rpOwner.involvement = order.NE__OptyId__r.BI_Id_Interno_de_la_Oportunidad__c;
        rpOwner.reference = 'Opportunity';
        rpOwner.href = '/'+order.NE__OptyId__c;

        ret.add(rpOwner);

        PO_RelatedObject rpCreator = new PO_RelatedObject();
        rpCreator.involvement = order.NE__AccountId__r.BI_No_Identificador_fiscal__c;
        rpCreator.reference = 'Customer';
        rpCreator.href = '/'+order.NE__AccountId__c;

        ret.add(rpCreator);

        return ret;
    }

    class PO_Order {
        public String correlationId {get;set;}
        public String description {get;set;}
        public String productOrderType {get;set;}
        public String priority {get;set;}
        public List<PO_RelatedParty> relatedParty {get;set;}
        public List<PO_RelatedObject> relatedObject {get;set;}
        public Datetime requestedStartDate {get;set;}
        public Datetime requestedCompletionDate {get;set;}
        public List<Map<String, Object>> additionalData {get;set;}
        public List<PO_OrderItem> orderItem {get;set;}
        public List<PO_Obra> deploymentWorks;

        public PO_Order() {
            additionalData = new List<Map<String, Object>>();
            orderItem = new List<PO_OrderItem>();
            deploymentWorks = new List<PO_Obra>();
        }
    }
    class PO_RelatedParty {
        public String id {get;set;}
        public String role {get;set;}
        public String name {get;set;}
    }
    class PO_RelatedObject {
        public String involvement {get;set;}
        public String reference {get;set;}
        public String href {get;set;}
    }

    class PO_OrderItem {
        String id;
        String parent;
        String action;
        String description;
        PO_OrderItem_ProductOffering productOffering;
        PO_Product product;
        String quantity;
        List<PO_OrderItem_Price> orderItemPrice;
        String status;
        String isAutoRenew;
        PO_OrderItem_ValidFor validFor;
        List<Map<String, Object>> additionalData;

        public PO_OrderItem() {
            productOffering = new PO_OrderItem_ProductOffering();
            orderItemPrice = new List<PO_OrderItem_Price>();
            product = new PO_Product();
            validFor = new PO_OrderItem_ValidFor();
            additionalData = new List<Map<String, Object>>();
        }
    }

    class PO_OrderItem_ProductOffering {
        String id;
        String href;
        String Name;
    }

    class PO_Product {
        String id;
        String href;
        String Name;
        String description;
        String productType;
        List<PO_Product_Category> category;
        PO_Product_Place place;
        PO_Product_Spec productSpec;
        List<Map<String, Object>> characteristic;
        List<PO_OrderItem> productRelationship;
        List<Map<String, Object>> additionalData;

        public PO_Product() {
            category = new List<PO_Product_Category>();
            place = new PO_Product_Place();
            productSpec = new PO_Product_Spec();
            characteristic = new List<Map<String, Object>>();
            productRelationship = new List<PO_OrderItem>();
            additionalData = new List<Map<String, Object>>();
        }
    }

    class PO_Product_Category {
        String id;
        List<PO_Product_Category> subcategories;

        public PO_Product_Category() {
            subcategories = new List<PO_Product_Category>();
        }
    }

    class PO_Product_Place {
        String id;
        String name;
    }

    class PO_Product_Spec {
        String id;
        String name;
        String href;
    }

    private Map<String, Object> PO_Product_Characteristic(PO_Product_CharacteristicValue valueType) {
        return new Map<String, Object>{
            '@type' => valueType.type,
            'name' => valueType.name,
            'value' => valueType.value,
            'category' => valueType.familia,
            'tipologia' => valueType.tipologia
        };
    }

    class PO_Product_CharacteristicValue {
        String type;
        String name;
        String value;
        String familia;
        String tipologia;
    }

    class PO_OrderItem_Price {
        String Name;
        String priceType;
        // String recurringChargePeriod;
        PO_OrderItem_Price_Pricing price;
        Boolean taxIncluded;
        List<Map<String, Object>> additionalData;

        public PO_OrderItem_Price() {
            price = new PO_OrderItem_Price_Pricing();
            additionalData = new List<Map<String, Object>>();
        }
    }

    class PO_OrderItem_Price_Pricing {
        Decimal amount;
        String units;
    }

    class PO_OrderItem_ValidFor {
        Datetime startDateTime;
        Datetime endDateTime;
    }
    class PO_OrderItem_Structure {
        public PO_OrderItem_Structure[] hijos {get;set;}
        // public String OrderItemId {get;set;}
        public NE__OrderItem__c orderItem {get;set;}

        public PO_OrderItem_Structure(NE__OrderItem__c param_orderItem) {
            orderItem = param_orderItem;
            hijos = new PO_OrderItem_Structure[]{};
        }

        public void coloca(NE__OrderItem__c[] arr) {
            if (arr == null || arr.size() == 0) {
                return;
            }
            
            for(NE__OrderItem__c neoi: arr) {
                if (neoi.NE__Parent_Order_Item__c == orderItem.Id) {
                    PO_OrderItem_Structure newPOOI = new PO_OrderItem_Structure(neoi);
                    hijos.add(newPOOI);
                    newPOOI.coloca(arr);
                }
            }
        }
    }

    class PO_Obra {
        String name;
        List<String> orderItems;
        List<PO_Obra_Cost> costs;
        List<Map<String, Object>> characteristics;

        public PO_Obra() {
            orderItems = new List<String>();
            costs = new List<PO_Obra_Cost>();
            characteristics = new List<Map<String, Object>>();
        }
    }

    class PO_Obra_Cost {
        String name;
        PO_Obra_Cost_Price price;
        String type;
        String subject;

        public PO_Obra_Cost() {
            price = new PO_Obra_Cost_Price();
        }
    }

    class PO_Obra_Cost_Price {
        Decimal amount;
        String units;
    }

    private void addData(List<Map<String, Object>> target, String key, Object value) {
        for (Map<String, Object> item : target) {
            if (item.get('key') == key) {
                item.put('value', String.valueOf(value));
                return;
            }
        }
        target.add(new Map<String, Object> {
            'key' => String.valueOf(key),
            'value' => String.valueOf(value)
        });
    }

    private Object getData(List<Map<String, Object>> source, String key) {
        for (Map<String, Object> item : source) {
            if (item.get('key') == key) {
                return item.get('value');
            }
        }
        return null;
    }

    public class ErrorPortalOperativoException extends Exception { }

}