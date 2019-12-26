/************************************************************************************
* Avanxo Colombia
* @author           Daniel Alexander Lopez href=<dlopez@avanxo.com>
* Proyect:          Telefonica
* Description:      
*
* Changes (Version)
* -------------------------------------
*           No.     Fecha           Autor                           Descripción        
*           -----   ----------      ---------------------------     ---------------    
* @version   1.0    2015-05-04      Daniel ALexander Lopez (DL)     New Controller
* @version   1.0    2015-05-11      Javier Tibamoza Cubillos (JATC) Ajuste para utilizar la clase como StandardController
* @version   1.0    2018-04-26      Alfonso Alvarez Elbal (AJAE)    Demanda 594: Se añade método para trasladar campo duración de contrato de Opty a MS para oportunidades de Colombia.
*************************************************************************************/
public class BI_COL_Opportunity_ctr
{
    public static final string F1_CLOSED_WON = 'F1 - Closed Won';
    public static final string F2_NEGOTATION = 'F2 - Negotiation';
    public static final string F3_OFFER_PRESENTED = 'F3 - Offer Presented';

    public BI_COL_Opportunity_ctr( ApexPages.StandardController stdController )
    {
        List<Opportunity> lstNew = new List<Opportunity>();
        BI_COL_Modificacion_de_Servicio__c oMS = (BI_COL_Modificacion_de_Servicio__c)stdController.getRecord();
        Opportunity opp;
        if( oMS.BI_COL_Oportunidad__r != null )
        {
            opp = oMS.BI_COL_Oportunidad__r;
        }
        else
        {
            opp = [ Select Id, StageName, BI_COL_Autoconsumo__c, AccountId, BI_COL_Clasificacion_Preventa__c
                    From Opportunity
                    Where Id =: oMS.BI_COL_Oportunidad__c ];
        }
        
        lstNew.add( opp );

        //cup_validar_Cierre_Opt( lstNew );
        fnValidarCierreOportunidad( lstNew, new List<Opportunity>() );
    }
    /***
    * @Author: 
    * @Company: 
    * @Description: 
    * @History: 
    * Date      |   Author  |   Description
    * 08/08/2018    Alfonso Alvarez Elbal. Se incluyen trazas de BEGIN y END y se comenta debug intermedio.
    ***/
    public static void fnValidarCierreOportunidad(list<Opportunity> lstNew, list<Opportunity> lstOld )
    {
        // 08-08-2018 AJAE BEGIN 
        system.debug('BI_COL_Opportunity_ctr.fnValidarCierreOportunidad() BEGIN') ;
        // 08-08-2018 AJAE END
        if(BI_Opportunity_TriggerHelper.map_User.get(UserInfo.getUserId())== null){
            BI_Opportunity_TriggerHelper.loader_TriggerData(new List<Opportunity>());
        }
        User usu = BI_Opportunity_TriggerHelper.map_User.get(UserInfo.getUserId());
        // 08-08-2018 AJAE BEGIN
        //system.debug( '\n\n ,.-.,.- lstNew.size() '+lstNew.size()+' \n\n lstNew.get(0) '+lstNew.get(0)+' \n\n lstOld '+lstOld );
        // 08-08-2018 AJAE END
        if( lstNew.size() == 1 && usu.Pais__c == label.BI_COL_lblColombia )
        {
            List<String> listMensajesError = new List<String>();

            Opportunity oppNew = (lstNew.size()> 0 ? lstNew[0] : null);
            Opportunity oppOld = (lstOld.size()> 0 ? lstOld[0] : null);
            system.debug( '\n\n ,.-.,.- oppNew.StageName '+oppNew.StageName );
            String mensajeError = '';
            //Valida solo si es F1
            if( oppNew.StageName == F1_CLOSED_WON) 
            { 
                BI_MigrationHelper.setSkippedTrigger('NE__OrderItem__c');
                listMensajesError = fnSearchErrorF1( oppNew, listMensajesError);
                BI_MigrationHelper.cleanSkippedTriggers();
                System.debug('\n\n Linea 65 listMensajesError.size(): '+ listMensajesError.size()+'\n\n');
            }
            //Valida para F1 o F2
            if( oppNew.StageName == F1_CLOSED_WON || oppNew.StageName == F2_NEGOTATION ) 
            {
                //listMensajesError=fnSearchErrorAccountMidas( oppNew,listMensajesError );
                BI_MigrationHelper.setSkippedTrigger('NE__OrderItem__c');
                listMensajesError=fnSearchError( oppNew, oppOld,listMensajesError);
                BI_MigrationHelper.cleanSkippedTriggers();
            }
            System.debug('\n\n Linea 32 listMensajesError.size(): '+ listMensajesError.size()+'\n\n');
            //Cuando está en F3
            if( oppNew.StageName == F3_OFFER_PRESENTED )
            {
                fnSearchErrorOtherStage( oppNew );
                listMensajesError = fnSearchErrorF1( oppNew ,listMensajesError);
            }
            System.debug('\n\n Linea 80 listMensajesError.size(): '+ listMensajesError.size()+'\n\n');
            if( listMensajesError.size() > 0 )
            {
                String tmp = '';
                System.debug('\n\n Linea 84 listMensajesError: '+listMensajesError+' \n\n');
                for( String msj : listMensajesError )
                    tmp += '<li><i>' + msj + '</i></li>';
                //tmp+='</ul>';
                oppNew.addError( tmp ,false);
            }
        }
        // 08-08-2018 AJAE BEGIN
        system.debug('BI_COL_Opportunity_ctr.fnValidarCierreOportunidad() END') ;
        // 08-08-2018 AJAE END
    }
    /***
    * @Author: 
    * @Company: 
    * @Description: 
    * @History: 
    * Date      |   Author  |   Description
    * 
    ***/
    public static List<String> fnSearchError( Opportunity oppNew, Opportunity oppOld, List<String> listMensajesError)
    {
        string sEtapaOppNew = ( oppNew != null ? oppNew.StageName : null );
        string sEtapaOppOld = ( oppOld != null ? oppOld.StageName : null );
        string mensajeError = '';

        List<BI_COL_Modificacion_de_Servicio__c> lstModUp = new List<BI_COL_Modificacion_de_Servicio__c>(); 
        //List<String> listMensajesError = new List<String>();
        Set<string> opCv = new Set<string>{'SERVICIO INGENIERIA','TRASLADO','COBRO UNICO'};

        List<BI_COL_Modificacion_de_Servicio__c> lstMS = fnFindMS( oppNew, '1' );
        
        List<BI_COL_CamposValidarEtapaOpp__c> lConf = [
            SELECT  ID, NAME, Api__c, Etapa_1__c, Etapa_2__c, Mensaje_Error__c,ValidacionEspecial__c, Api2__c
            FROM    BI_COL_CamposValidarEtapaOpp__c ];
        System.debug('\n\n oMS-->'+lstMS);
        for( BI_COL_Modificacion_de_Servicio__c objMS : lstMS )
        {
            sObject oMS = objMS;
            mensajeError = '';
            System.debug('\n\n oMS-->'+oMS+' -- '+objMS);
            for( BI_COL_CamposValidarEtapaOpp__c oConf : lConf )
            {
                System.debug('\n\n ----> oConf.Api__c: '+oConf.Api__c);
                if(!oConf.ValidacionEspecial__c  && 
                 oMS.get( oConf.Api__c ) == null //&& 
                    //sEtapaOppOld == oConf.Etapa_1__c && 
                    //sEtapaOppNew == oConf.Etapa_2__c
                    )
                {
                    mensajeError = ( mensajeError == '' ? oConf.Mensaje_Error__c : mensajeError + ' ' + oConf.Mensaje_Error__c );
                }
                if( oConf.ValidacionEspecial__c )
                {
                    if( oConf.Api__c == 'BI_COL_Bloqueado__c' )
                    {
                        if( !objMS.BI_COL_Bloqueado__c )
                        {
                            objMS.BI_COL_Bloqueado__c = true;
                            lstModUp.add( objMS );
                        }
                    }

                    if( oConf.Api__c == 'BI_Contacto__c' && objMS.BI_COL_Sucursal_de_Facturacion__r.BI_Contacto__c == null )
                    {
                        mensajeError = ( mensajeError == '' ? oConf.Mensaje_Error__c : mensajeError + ' ' + oConf.Mensaje_Error__c );
                    }
                    system.debug('\n\n .-.-. api '+oConf.Api__c+'\n calif '+objMS.BI_COL_Clasificacion_Servicio__c+'\n cargo '+objMS.BI_COL_Cargo_conexion__c);
                    if( oConf.Api__c == 'BI_COL_Cargo_conexion__c'  &&
                        opCv.contains( objMS.BI_COL_Clasificacion_Servicio__c ) &&
                        objMS.BI_COL_Cargo_conexion__c == 0 )
                    {
                        mensajeError = ( mensajeError == '' ? 
                            objMS.Name + oConf.Mensaje_Error__c : 
                            mensajeError + ' ' + objMS.Name + + oConf.Mensaje_Error__c );
                    }

                    if( oConf.Api__c == 'BI_COL_Autoconsumo__c'  &&
                        oConf.Api2__c == 'BI_COL_Renovable__c'  &&
                        oppNew.BI_COL_Autoconsumo__c &&
                        objMS.BI_COL_Autoconsumo__c &&
                        objMS.BI_COL_Renovable__c )
                    {
                        mensajeError = ( mensajeError == '' ? 
                            objMS.Name + oConf.Mensaje_Error__c : 
                            mensajeError + ' ' + objMS.Name + + oConf.Mensaje_Error__c );
                    }

                    if( oConf.Api__c == 'BI_COL_Autoconsumo__c'  &&
                        oConf.Api2__c == 'BI_COL_Renovable__c'  &&
                        oppNew.BI_COL_Autoconsumo__c &&
                        objMS.BI_COL_Autoconsumo__c &&
                        objMS.BI_COL_Estado_aprobacion_autoconsumo__c != 'Aprobado' )
                    {
                        mensajeError = ( mensajeError == '' ? 
                            objMS.Name + oConf.Mensaje_Error__c : 
                            mensajeError + ' ' + objMS.Name + + oConf.Mensaje_Error__c );
                    }
                }
                System.debug('\n\n mensajeError ' +mensajeError+'\n\n');
            }
            if(mensajeError!='')
            {
                listMensajesError.add( objMS.Name +': '+ mensajeError );    
            }
            
        }

        if( listMensajesError.size() <= 0 && oppNew.StageName.equals( F1_CLOSED_WON ) )
        {
            fnUpdateDS( oppNew, lstModUp );
        }
        return listMensajesError;
    }
    /***
    * @Author: 
    * @Company: 
    * @Description: 
    * @History: 
    * Date      |   Author  |   Description
    * 
    ***/
    public static List<String> fnSearchErrorF1( Opportunity oppNew,List<String> listMensajesError )
    {
        System.debug('\n\n Ingresa a fnSearchErrorF1 \n\n');
        //List<String> listMensajesError = new List<String>();

        List<BI_COL_Modificacion_de_Servicio__c> ListMS = fnFindMS( oppNew, '3' );

        for( BI_COL_Modificacion_de_Servicio__c lms : ListMS )
        {
            

        System.debug('\n\n For Ingresa a fnSearchErrorF1 ms.BI_COL_Autoconsumo__c'+lms.BI_COL_Autoconsumo__c+' lms.BI_COL_Renovable__c '+ lms.BI_COL_Renovable__c+' \n\n');
            if( ( lms.BI_COL_Clasificacion_Servicio__c == label.BI_COL_lblALTA_DEMO || 
                  lms.BI_COL_Clasificacion_Servicio__c == label.BI_COL_lblUpgradeDemo ) && 
                  lms.BI_COL_Renovable__c == true)
            {
                listMensajesError.add( lms.Name+': Si la clasificacion del servicio de la MS asociada es ALTA DEMO o UPGRADE DEMO, ' + 
                          ' no debe tener la casilla Renovable seleccionada');
            }
            System.debug('\n\n linea 219 label.BI_COL_lblALTA_DEMO '+label.BI_COL_lblALTA_DEMO+ 'label.BI_COL_lblUpgradeDemo: '+label.BI_COL_lblUpgradeDemo+' lms.BI_COL_Estado_aprobacion__c '+lms.BI_COL_Estado_aprobacion__c+ ' lms.BI_COL_Clasificacion_Servicio__c: '+lms.BI_COL_Clasificacion_Servicio__c+'\n\n');
            if( ( lms.BI_COL_Clasificacion_Servicio__c == label.BI_COL_lblALTA_DEMO || 
                  lms.BI_COL_Clasificacion_Servicio__c == label.BI_COL_lblUpgradeDemo ) && 
                  lms.BI_COL_Estado_aprobacion__c !='Aprobado')
            {
                listMensajesError.add( lms.Name+': Si la clasificacion del servicio de la MS asociada es ALTA DEMO o UPGRADE DEMO, ' + 
                          ' Debe solocitar aprobacion');
            }

            //CFC Validacion Demos
            if( ( lms.BI_COL_Servicio_ocasional__c = false ) &&
                ( lms.BI_COL_Clasificacion_Servicio__c == label.BI_COL_lblDemo)  && 
                ( lms.BI_COL_Estado_aprobacion_autoconsumo__c == label.BI_PendienteAprobacion_Comite || 
                  lms.BI_COL_Estado_aprobacion_autoconsumo__c == label.BI_Rechazado ) )
            {
                listMensajesError.add( lms.Name+': Esta pendiente de solicitar aprobacion o Aprobar');
            }
            if(lms.BI_COL_Autoconsumo__c==true && lms.BI_COL_Renovable__c==true)
            {
                listMensajesError.add( lms.Name+': Tiene el check renovable activo y para autoconsumo no requiere');
            }
        }
        System.debug('\n\n Linea 241 listMensajesError: '+listMensajesError+'\n\n'); 
        return listMensajesError;
    }
    /***
    * @Author: 
    * @Company: 
    * @Description: 
    * @History: 
    * Date      |   Author  |   Description
    * 
    ***/
    public static List<String> fnSearchErrorAccountMidas( Opportunity oppNew,List<String> listMensajesError )
    {
        //List<String> listMensajesError = new List<String>();
        //Seleccionamos la cuenta (cliente) de la oportunidad
        //Account account = [ SELECT Id, BI_Estado_de_la_deuda__c FROM Account WHERE Id =: oppNew.AccountId  LIMIT 1 ];
        //Validamos que la cuenta tenga al d?a la cartera
        //if( account.BI_Estado_de_la_deuda__c != null && !account.BI_Estado_de_la_deuda__c.equals('OK') )
        //{
            //listMensajesError.add(Label.BI_COL_Error_Oportunidad_Estado_Aprobacion_Cliente);
        //}
        
        /*List<BI_COL_MIDAS__c> lstMidas=[
            select Id,BI_COL_Ingreso_Conectividad__c, BI_COL_Proyecto__r.Name
            from    BI_COL_MIDAS__c
            where   BI_COL_Proyecto__c =: oppNew.Id
            and     BI_COL_Estado_de_la_aprobacion__c = 'Aprobado'];*/
  
        /*if( lstMidas.size()== 0 && oppNew.BI_COL_Clasificacion_Preventa__c == label.BI_COL_lblProyecto )
        {
            listMensajesError.add( Label.BI_COL_Error_Oportunidad_MIDAS_Aprobado + ' ' );
        }*/
        return listMensajesError;
    }
    /***
    * @Author: 
    * @Company: 
    * @Description: 
    * @History: 
    * Date      |   Author  |   Description
    * 
    ***/
    public static List<String> fnSearchErrorOtherStage( Opportunity oppNew )
    {
        List<String> listMensajesError = new List<String>();

        List<BI_COL_Modificacion_de_Servicio__c> lstMS = fnFindMS( oppNew, '1' );
        //Validacion de descuentos
        /*for( BI_COL_Modificacion_de_Servicio__c objMS : lstMS )
        {
            if( objMS.BI_COL_Servicio_sin_cobro__c == null )
                listMensajesError.add( objMS.Name + ': ' + Label.BI_COL_lblErrorMSDescuento ); 
        }*/
        return listMensajesError;
    }
    /***
    * @Author: 
    * @Company: 
    * @Description: 
    * @History: 
    * Date      |   Author  |   Description
    * 
    ***/
    public static void fnUpdateDS( Opportunity oppNew, List<BI_COL_Modificacion_de_Servicio__c> lstModUp )
    {
        List<BI_COL_Descripcion_de_servicio__c> descripcionesServicio = fnFindMS( oppNew, '2' );
        //Recorremos todas las DS
        for( BI_COL_Descripcion_de_servicio__c ds : descripcionesServicio )
            ds.BI_COL_Bloqueado__c = true;
        
        oppNew.BI_COL_Bloqueado__c = true;
        
        try
        {
          update descripcionesServicio;
          update lstModUp;
        }
        catch(Exception ex)
        {
          oppNew.addError( ex.getMessage() );
        }
    }
    /***
    * @Author: 
    * @Company: 
    * @Description: 
    * @History: 
    * Date      |   Author  |   Description
    * 
    ***/
    public static List<sObject> fnFindMS( Opportunity oppNew, string sOpc )
    {
        System.debug('\n\n ---- Linea 299 sOpc'+sOpc+' --- \n\n oppNew '+oppNew);
        if( sOpc == '1' )
        {
            return [
                SELECT  Id, Name,
                        BI_COL_Tipo_Facturacion__c, 
                        BI_COL_Plazo_Vencimiento_Factura__c, 
                        BI_COL_Cargo_fijo_mes__c,
                        BI_COL_Clasificacion_Servicio__c,
                        BI_COL_Cargo_conexion__c,
                        BI_COL_Fecha_inicio_de_cobro_RFB__c, 
						/*BI_COL_Cuenta_facturar_davox__c,*/ BI_COL_Cuenta_facturar_davox1__c, 
                        BI_COL_Medio_Vendido__c,
                        BI_COL_Sucursal_de_Facturacion__r.BI_Contacto__c,
                        BI_COL_Bloqueado__c,
                        BI_COL_Cobro_unico_adicionales__c, 
                        BI_COL_Cobro_mensual_adicionales__c, 
                        BI_COL_Servicio_sin_cobro__c,
                        BI_COL_Autoconsumo__c, 
                        BI_COL_Renovable__c, 
                        BI_COL_Estado_aprobacion_autoconsumo__c,
                        (SELECT Id, Name, BI_COL_Presupuesto_Area_Origen__c FROM Viabilidad_T_cnica__r where BI_COL_Estado__c = 'Entregado')
                FROM    BI_COL_Modificacion_de_Servicio__c
                WHERE   BI_COL_Oportunidad__c <> null
                and     BI_COL_Oportunidad__c =: oppNew.Id 
                AND     BI_COL_Estado__c = 'Pendiente'
                limit 500 ];
        }
        else if( sOpc == '2' )
        {
            return [
                SELECT  Id, BI_COL_Oportunidad__c, 
                        BI_COL_Oportunidad__r.AccountId, 
                        BI_COL_Sede_Origen__c
                FROM    BI_COL_Descripcion_de_servicio__c 
                WHERE   BI_COL_Oportunidad__c =: oppNew.Id 
                and     BI_COL_Bloqueado__c=false 
                limit 500];
        }
        else
        {
            return [
                SELECT  Id, 
                        BI_COL_Oportunidad__c, 
                        BI_COL_Clasificacion_Servicio__c, 
                        BI_COL_Renovable__c,
                        BI_COL_Autoconsumo__c,
                        BI_COL_Estado_aprobacion_autoconsumo__c, Name, BI_COL_Estado_aprobacion__c
                FROM    BI_COL_Modificacion_de_Servicio__c
                WHERE   BI_COL_Oportunidad__c =: oppNew.Id 
                AND     BI_COL_Estado__c='Pendiente'];
        }
            
    }
    //Shipping Opportunity Controller
    @Future(callout=true)
    public static void enviarOptTrs( List<Id> lstIdOpt )
    {
    
        list<Opportunity> lstOportunidades =[
            Select  Id, BI_Numero_id_oportunidad__c, BI_Id_de_la_oportunidad__c,
                    (Select BI_COL_Capex_Total__c, BI_COL_Capex_Ingreso__c, BI_COL_Cobro_Unico__c, BI_COL_OIBDA__c, BI_COL_OPEX__c,
                    BI_COL_Capex_No_Efectivo__c,        
                    BI_COL_Payback__c, BI_COL_PRI__c ,BI_COL_Recurrente__c, BI_COL_VPN__c, BI_COL_VPN_Capex__c, BI_COL_TIR__c,
                    BI_COL_Margen_Directo__c, BI_COL_Markup__c From MIDAS__r where BI_COL_Estado_de_la_aprobacion__c='Aprobado') 
            From    Opportunity 
            where ID In: lstIdOpt ];
     
        List<BI_COL_MIDAS__c> lstMidasTest =[ 
            select  BI_COL_Capex_Total__c,BI_COL_Margen_Directo__c,BI_COL_OIBDA__c,BI_COL_OPEX__c,BI_COL_Capex_No_Efectivo__c,
                    BI_COL_PRI__c, BI_COL_VPN__c,BI_COL_VPN_Capex__c,BI_COL_TIR__c,BI_COL_Capex_Ingreso__c,
                    BI_COL_Cobro_Unico__c,BI_COL_Markup__c,BI_COL_Payback__c,BI_COL_Recurrente__c 
            from    BI_COL_MIDAS__c 
            where   BI_COL_Proyecto__c IN: lstIdOpt];  
                 
        ws_TrsMasivo.datosmidasCodigoOportunidad[] lstDatosOptEnviar = new ws_TrsMasivo.datosmidasCodigoOportunidad[]{};
        
        for( Opportunity opt:lstOportunidades )
        {
            ws_TrsMasivo.datosmidasCodigoOportunidad datosOpt=new ws_TrsMasivo.datosmidasCodigoOportunidad();
            List<BI_COL_MIDAS__c> midas = opt.MIDAS__r;
            if( test.isRunningTest() )
                midas = lstMidasTest;
            System.debug('\n\n midas.size() '+midas.size()+'\n\n');
            if( midas.size() > 0 )
            {
                datosOpt.capex_total = BI_COL_Shipping_Opportunity_Trs_ctr.quitaDecimal(midas[0].BI_COL_Capex_Total__c);
                datosOpt.codigoproyectosalesforce = opt.BI_Numero_id_oportunidad__c;
                datosOpt.ebitda = BI_COL_Shipping_Opportunity_Trs_ctr.quitaDecimal(midas[0].BI_COL_Margen_Directo__c);
                datosOpt.margendirecto = BI_COL_Shipping_Opportunity_Trs_ctr.quitaDecimal(midas[0].BI_COL_Margen_Directo__c);
                datosOpt.oibda = BI_COL_Shipping_Opportunity_Trs_ctr.quitaDecimal(midas[0].BI_COL_OIBDA__c);
                datosOpt.opex = BI_COL_Shipping_Opportunity_Trs_ctr.quitaDecimal(midas[0].BI_COL_OPEX__c);
                datosOpt.preciopromedio = BI_COL_Shipping_Opportunity_Trs_ctr.quitaDecimal(midas[0].BI_COL_Capex_No_Efectivo__c);
                datosOpt.pri = BI_COL_Shipping_Opportunity_Trs_ctr.quitaDecimal(midas[0].BI_COL_PRI__c);
                datosOpt.vpn = BI_COL_Shipping_Opportunity_Trs_ctr.quitaDecimal(midas[0].BI_COL_VPN__c);
                datosOpt.vpncapex = BI_COL_Shipping_Opportunity_Trs_ctr.quitaDecimal(midas[0].BI_COL_VPN_Capex__c);
                datosOpt.tir = BI_COL_Shipping_Opportunity_Trs_ctr.quitaDecimal(midas[0].BI_COL_TIR__c);
                datosOpt.payback = BI_COL_Shipping_Opportunity_Trs_ctr.quitaDecimal(midas[0].BI_COL_Payback__c);
                datosOpt.capex_ingreso = BI_COL_Shipping_Opportunity_Trs_ctr.quitaDecimal(midas[0].BI_COL_Capex_Ingreso__c);
                datosOpt.markup = BI_COL_Shipping_Opportunity_Trs_ctr.quitaDecimal(midas[0].BI_COL_Markup__c);
                datosOpt.cobro_unico = BI_COL_Shipping_Opportunity_Trs_ctr.quitaDecimal(midas[0].BI_COL_Cobro_Unico__c);
                datosOpt.recurrente = BI_COL_Shipping_Opportunity_Trs_ctr.quitaDecimal(midas[0].BI_COL_Recurrente__c);
                lstDatosOptEnviar.add( datosOpt );
            }
        }
        try
        {
            if( lstDatosOptEnviar.size() > 0 )
            {
                ws_TrsMasivo.serviciosSISGOTSOAP sw = new ws_TrsMasivo.serviciosSISGOTSOAP();
                sw.timeout_x = 120000;
                ws_TrsMasivo.midasCodigoOportunidadResponse[] resp=sw.midasCodigoOportunidad(lstDatosOptEnviar);
                creaLogTransaccion(resp[0].mensajeError,lstOportunidades,'Exitoso','Respuesta Servicio Web TRS OPT F1');
                System.debug('\n\n respuesta ws '+resp+'\n\n');
            }
        }
        catch(Exception e)
        {
            creaLogTransaccion(''+e,lstOportunidades,'FALLIDO','Error Servicio Web TRS OPT F1 MIDAS');    
        }
    }
    
    public static String quitaDecimal( Decimal numero )
    {
        String retorno = '';
        retorno = '' + numero;
        if( retorno.contains('.00') )
            retorno = retorno.substring(0, retorno.lastIndexOf('.'));      
        else if( retorno.contains('.') )
            retorno = retorno.replace('.', '');
        return retorno;
    }
    /**** OA: Método de creación de log de transacciones fallidas para el objeto Oportunidad ****/
    public static void creaLogTransaccionError(String error, List<Opportunity> lstIdClientes,String infEnviada)
     {
          List<BI_Log__c> lstLogTran=new List<BI_Log__c>();
          BI_Log__c log=null; 
          system.debug('métod de log de transacciones::Exception::'+error+'\n\n'+lstIdClientes);
        
          for(Opportunity acc:lstIdClientes)
          {
              log=new BI_Log__c(BI_COL_Informacion_recibida__c=error,BI_COL_Oportunidad__c=acc.id,BI_COL_Estado__c='FALLIDO',BI_COL_Interfaz__c='NOTIFICACIONES',BI_COL_Informacion_Enviada__c=infEnviada);
              lstLogTran.add(log);
          }
          
          system.debug('Insertando log de transacciones::::'+lstLogTran);
          insert lstLogTran;
     }
     
    public static void creaLogTransaccion( String error, List<Opportunity> lstIdOpt, String estado, String tipoLog )
    {
        List<BI_Log__c> lstLogTran = new List<BI_Log__c>();
        BI_Log__c log = null;
        
        for(Opportunity suc:lstIdOpt)
        {
            List<BI_COL_MIDAS__c> midas = suc.MIDAS__r;
            log = new BI_Log__c();
            log.BI_COL_Informacion_recibida__c = error;
            log.BI_COL_Oportunidad__c = suc.id;
            log.BI_COL_Informacion_Enviada__c=String.valueOf(midas);
            log.BI_COL_Estado__c = estado;
            log.BI_COL_Tipo_Transaccion__c='ENVIO MIDAS';
            lstLogTran.add( log );
        }
        insert lstLogTran;
        System.debug('\n\n lstLogTran :'+lstLogTran+'\n\n');
    }
    @InvocableMethod
    public static void envioProyectoTRS(List<opportunity> lstOpp)
    {
        List<String> opportunityIds = new List<String>();
        for (Opportunity opt : lstOpp) 
        {
            opportunityIds.add(opt.Id);
        }
        if(!System.isBatch() && !System.isFuture()){ /*Álvaro López 18/05/2018 - Evita errores al actualizar oportunidades de Colombia desde batch*/
            enviarOptTrs(opportunityIds);
        }
    }
    
    
   /***
    * @Author: Alfonso José Álvarez Elbal
    * @Company: Telefónica Global Techonolgy
    * @Description: Demanda 495. Punto 1: Creación Oportunidades /MS .b. Cuando una opty está abierta (<> F1) la duración del a oportunidad al ser modificada debe replicarse a todas las MS asociadas
    * a excepción de las MS que tengan duración 1 mes.
    * @History: 
    * Date      |   Author  |   Description
    * 10/05/2018    Alfonso Alvarez Elbal (AJAE).   Versión inicial del método
    * 08/08/2018	Alfonso Alvarez Elbal (AJAE).   Se modifica método para optimizar queries. 
    ***/
 public static void duracionOpty2MS(list<Opportunity> olds, list<Opportunity> news )
 {
   System.debug('BI_COL_Opportunity_ctr.duracionOpty2MS() BEGIN');
   //Mapa para almacenar los ids de las oportunidad y las duraciones de contrato de cada una  
   Map <Id,Decimal> idOptys=new Map<Id,Decimal>();
   // Filtramos por aquellas oportunidades de Colombia y que hayan modificado la fecha de duración del contrato  
   // Almacenamos en idOptys las oportunidades y las duraciones
   for(Integer i=0;i<olds.size();i++){
       Opportunity optyOld=olds.get(i);
       Opportunity optyNew=news.get(i);
       //System.debug('BI_COL_Opportunity_ctr.duracionOpty2MS(): Oportunidad ('+optyNew.Name+') de Colombia con cambio de duración contrato meses: '+optyOld.BI_Duracion_del_contrato_Meses__c+ ' valor nuevo: ' + optyNew.BI_Duracion_del_contrato_Meses__c);
	//Query comentada en el bucle, innecesaria - JMP
       //Opportunity opt=(([Select Id,Name, BI_Duracion_del_contrato_Meses__c from Opportunity where Id =: optyNew.Id]));
       //System.debug('BI_COL_Opportunity_ctr.duracionOpty2MS(): Valor actual de Oportunidad ('+optyNew.Name+') duracion:'+ opt.BI_Duracion_del_contrato_Meses__c);
       if(optyOld.BI_Country__c=='Colombia' && optyOld.BI_Duracion_del_contrato_Meses__c!=optyNew.BI_Duracion_del_contrato_Meses__c){
           idOptys.put(optyNew.Id,optyNew.BI_Duracion_del_contrato_Meses__c);
       }//if(optyOld.BI_Country__c=='Colombia' && optyOld.BI_Duracion_del_contrato_Meses__c!=optyNew.BI_Duracion_del_contrato_Meses__c){
       
   }//for(Integer i=0;i<olds.size();i++){
   //System.debug('BI_COL_Opportunity_ctr.duracionOpty2MS(): idOptys: '+idOptys.keySet());   
   //System.debug('BI_COL_Opportunity_ctr.duracionOpty2MS(): idOptys.Duración: '+idOptys.values());     
   // Obtener las MS de las oportunidades anteriormente filtradas
   //Mapa para almacenar las MS que deben modificarse.
   //08-08-2018 AJAE BEGIN
   if(idOptys.size()>0) { // Si no existen oportunidades a actualizar no se debe ejecutar nada   
     Map<Id,BI_COL_Modificacion_de_Servicio__c> mp_ms= new Map<Id,BI_COL_Modificacion_de_Servicio__c>(([Select Id,BI_COL_Oportunidad__c,BI_COL_Duracion_meses__c from BI_COL_Modificacion_de_Servicio__c where BI_COL_Oportunidad__c in :idOptys.keySet() and BI_COL_Producto__c != null]));
     //System.debug('BI_COL_Opportunity_ctr.duracionOpty2MS(): Cantidad de MS a actualizar: '+ mp_ms.size());
     // Modificar las MS con las nuevas duraciones de contrato SOLO si la duracion de la MS es distinto de 1
     for(BI_COL_Modificacion_de_Servicio__c ms : mp_ms.values()){
       String idOpty=ms.BI_COL_Oportunidad__c;
       Decimal durOpty=idOptys.get(idOpty);
       if(ms.BI_COL_Duracion_meses__c!=1){ //Solo
         System.debug('BI_COL_Opportunity_ctr.duracionOpty2MS(): MS['+ms.Id+'] de oportunidad ['+idOpty+'] con valor de duración: '+ms.BI_COL_Duracion_meses__c+' se actualiza a valor:'+durOpty);   
         ms.BI_COL_Duracion_meses__c = durOpty;   
       }else{
         System.debug('BI_COL_Opportunity_ctr.duracionOpty2MS(): MS['+ms.Id+'] de oportunidad ['+idOpty+'] con valor de duración: '+ms.BI_COL_Duracion_meses__c+' NO SE ACTUALIZA');   
       }
     }
     //System.debug('BI_COL_Opportunity_ctr.duracionOpty2MS() mp_ms.values:'+mp_ms.values());      
     update(mp_ms.values());  
   }//if(idOptys.size()>0) { 
   //08-08-2018 AJAE END  
   System.debug('BI_COL_Opportunity_ctr.duracionOpty2MS() END');      
 }//public static void duracionOpty2MS(list<Opportunity> olds, list<Opportunity> news )

    
    /*-------------------------------------------------------------------------------------------------------------------------------------------------------
    Author:        Víctor Cardozo
    Company:       Everis
    Description:   Remove configuration items without modification of services in a F3 opportunity
                   Al pasar una opty a F3 (de F4 a F3) y si la opty es de Colombia, y cumple una serie de condiciones (ver puntos)   los CI que no tengan MS se deben eliminar.
                     •	Importe Colombia diferente a Cero. opportunity.BI_COL_Valida_importe__c != 0;
                     •	Oportunidad no creada por venta Express. opportunity.VE_Express__c
                     •	Oportunidad no creada por el equipo de Multinacionales. opportunity.BI_Oportunidad_Padre__c == null

    
    History: 
    
    <Date>                  <Author>                    <Change Description>
    13/06/2018              Víctor Cardozo      		Initial Version         
    --------------------------------------------------------------------------------------------------------------------------------------------------------*/
    public static void updateCIWithoutMS(List <Opportunity> news, List <Opportunity> olds)
    {
        System.debug(loggingLevel.Debug, 'updateCIWithoutMS__START');
        Set <Id> opportunityIds = new Set <Id>();
        Set <Id> opportunityOwnersIds = new Set <Id>();
        Set <Id> opportunityOwnerProfileIds = new Set <Id>();
        List <Opportunity> filteredOp = new List<Opportunity>();
        Integer index = 0;
        System.debug(LoggingLevel.Debug, 'OP count = ' + news.size());
        // Creamos lista con los id's de la oportunidad 
        for(Opportunity opportunity : news) {
            // Filtrar oportunidades que pasan de F4 a F3
            
            // Obtener estado anterior de la oportunidad 
            Opportunity oldOpportunity = olds.get(index);
            // Actualizar index
            index++;
            
            // Valida si la oportunida viene de F4 a F3
            if (opportunity.StageName.startsWith('F3 - ') && oldOpportunity.StageName.startsWith('F4 - ')) {
                System.debug('VCF fase correcta');
                // Filtra las oportunidades de Colombia y Importe Colombia diferente a Cero y Oportunidad no creada por venta Express y Oportunidad no creada por el equipo de Multinacionales
            	Boolean isExpress = opportunity.VE_Express__c;
                Boolean colombianImportNotZero = opportunity.BI_COL_Valida_importe__c != 0;
                Boolean hasNoOpportunityParent = opportunity.BI_Oportunidad_Padre__c == null;
                Boolean isColombianOpportunity = opportunity.BI_Country__c == 'Colombia';

                if (!isExpress && hasNoOpportunityParent && colombianImportNotZero && isColombianOpportunity) {
                    // Agregamos a la lista de usuarios creadores de oportunidades (filtrado)
            		opportunityOwnersIds.add(opportunity.CreatedById);
                    
                    // Oportunidades filtradas
                    filteredOp.add(opportunity);
                }
            }
        }
        
        // Si no hay al menos un oportunidad que cumpla las condiciones, no hacer nada
        if(filteredOp.size() > 0) {
        	// Buscamos a los usuarios creadores de la oportunidad que tengan un perfil BI_O4_.
            List<User> opportunityUsers = [SELECT Id, ProfileId FROM User WHERE Id IN :opportunityOwnersIds AND (NOT Profile.Name LIKE 'BI_O4_%')];
            for(Opportunity opportunity : filteredOp) {
                for(User user: opportunityUsers) {
                    if (user.Id == opportunity.CreatedById) {
                    	opportunityIds.add(opportunity.Id);    
                        break;
                    }
                }
            }
            
            if(opportunityIds.size() > 0) {
                // Obtenemos los CI's que no tengan MS asociados
                List<NE__OrderItem__c> configurationItemsToRemove = [SELECT 
                        Id, NE__OrderId__c, NE__OneTimeFeeOv__c, NE__RecurringChargeOv__c, NE__BaseOneTimeFee__c, NE__BaseRecurringCharge__c, BI_Ingreso_Recurrente_Anterior_Producto__c,
                        NE__OrderId__r.Id, NE__OrderId__r.NE__OptyId__c, NE__OrderId__r.NE__One_Time_fee_total__c, NE__OrderId__r.NE__Recurring_Charge_Total__c, NE__OrderId__r.BI_Ingreso_Recurrente_Anterior_Config__c,
                        NE__OrderId__r.NE__Optyid__r.Id, NE__OrderId__r.NE__Optyid__r.BI_Ingreso_por_unica_vez__c, NE__OrderId__r.NE__Optyid__r.BI_Recurrente_bruto_mensual__c, NE__OrderId__r.NE__Optyid__r.BI_Recurrente_bruto_mensual_anterior__c
                    FROM NE__OrderItem__c 
                    WHERE NE__OrderId__r.NE__OptyId__c IN :opportunityIds AND BI_COL_ModificacionServicio__c = null  AND NE__OrderId__r.NE__OrderStatus__c LIKE 'Activ%' //eHelp 04264413
				];
                
                // Buscamos los MS que estén asociados con los CI previamente filtrados
                List<Id> configurationItemsToRemoveIds = new List<Id>();
                for(NE__OrderItem__c configurationItem : configurationItemsToRemove) {
                    configurationItemsToRemoveIds.add(configurationItem.Id);
                }
                List<BI_COL_Modificacion_de_Servicio__c> modificationOfServices = [SELECT Id, BI_COL_Producto__c FROM BI_COL_Modificacion_de_Servicio__c WHERE BI_COL_Producto__c IN :configurationItemsToRemoveIds];    
                system.debug ('Lista modificationOfServices-->'+modificationOfServices);
                // Quitamos de la lista a eliminar los CI's que tengan MS asociados a esos CI's
                if(configurationItemsToRemove.size()>0 && configurationItemsToRemove != null){ //ANCR ehelp 05126145
                    Map<Id,NE__OrderItem__c> configurationItemsToRemoveTemp = new Map<Id,NE__OrderItem__c>();
                    for (Integer i=0; i< configurationItemsToRemove.size(); i++) {
                        if (!modificationOfServices.isEmpty()){//ANCR ehelp 05126145
                            for (BI_COL_Modificacion_de_Servicio__c ms: modificationOfServices) {
                                if (configurationItemsToRemove.get(i).Id != ms.BI_COL_Producto__c) {
                                   configurationItemsToRemoveTemp.put(configurationItemsToRemove.get(i).Id,configurationItemsToRemove.get(i));
                                }
                            }
                        }
                    }
                    configurationItemsToRemove = configurationItemsToRemoveTemp.values();
                }
                system.debug('configurationItemsToRemove MS--->'+ configurationItemsToRemove);
                
                Map<Id, Decimal> configurationOneTimeFee = new Map<Id, Decimal>();
                Map<Id, Decimal> configurationRecurringCharge = new Map<Id, Decimal>();
                Map<Id, Decimal> configurationIngresoRecurrenteAnteriorConfig = new Map<Id, Decimal>();
                Set<NE__Order__c> configurationsSet = new Set<NE__Order__c>();
                Set<Opportunity> opportunitiesSet = new Set<Opportunity>();
                
                Map<Id, Decimal> orderOneTimeFee = new Map<Id, Decimal>();
                Map<Id, Decimal> orderRecurringCharge = new Map<Id, Decimal>();
                Map<Id, Decimal> orderRecurrenteBrutoMensualAnterior = new Map<Id, Decimal>();
                for(NE__OrderItem__c ci: configurationItemsToRemove) {
                    configurationsSet.add(ci.NE__OrderId__r);
                    opportunitiesSet.add(ci.NE__OrderId__r.NE__Optyid__r);
                    // Calculamos los valores económicos de los configuration (order)
                    if (!configurationOneTimeFee.containsKey(ci.NE__OrderId__c)) {
                        configurationOneTimeFee.put(ci.NE__OrderId__c, ci.NE__OneTimeFeeOv__c);
                    } else {
                        configurationOneTimeFee.put(ci.NE__OrderId__c, configurationOneTimeFee.get(ci.NE__OrderId__c) + ci.NE__OneTimeFeeOv__c);
                    }
                    if (!configurationRecurringCharge.containsKey(ci.NE__OrderId__c)) {
                        configurationRecurringCharge.put(ci.NE__OrderId__c, ci.NE__RecurringChargeOv__c);
                    } else {
                        configurationRecurringCharge.put(ci.NE__OrderId__c, configurationRecurringCharge.get(ci.NE__OrderId__c) + ci.NE__RecurringChargeOv__c);
                    }
                    if (!configurationIngresoRecurrenteAnteriorConfig.containsKey(ci.NE__OrderId__c)) {
                        configurationIngresoRecurrenteAnteriorConfig.put(ci.NE__OrderId__c, ci.BI_Ingreso_Recurrente_Anterior_Producto__c);
                    } else {
                        Decimal aux = configurationIngresoRecurrenteAnteriorConfig.get(ci.NE__OrderId__c);
                        configurationIngresoRecurrenteAnteriorConfig.put(ci.NE__OrderId__c, (aux == null ? 0 : aux) + ci.BI_Ingreso_Recurrente_Anterior_Producto__c);
                    }
                    
                    // Calculamos los valores económicos de las oportunidades
                    if (!orderOneTimeFee.containsKey(ci.NE__OrderId__r.NE__Optyid__r.Id)) {
                        orderOneTimeFee.put(ci.NE__OrderId__r.NE__Optyid__r.Id, ci.NE__OneTimeFeeOv__c);
                    } else {
                        orderOneTimeFee.put(ci.NE__OrderId__r.NE__Optyid__r.Id, orderOneTimeFee.get(ci.NE__OrderId__r.NE__Optyid__r.Id) + ci.NE__OneTimeFeeOv__c);
                    }
                    if (!orderRecurringCharge.containsKey(ci.NE__OrderId__r.NE__Optyid__r.Id)) {
                        orderRecurringCharge.put(ci.NE__OrderId__r.NE__Optyid__r.Id, ci.NE__RecurringChargeOv__c);
                    } else {
                        orderRecurringCharge.put(ci.NE__OrderId__r.NE__Optyid__r.Id, orderRecurringCharge.get(ci.NE__OrderId__r.NE__Optyid__r.Id) + ci.NE__RecurringChargeOv__c);
                    }
                    if (!orderRecurrenteBrutoMensualAnterior.containsKey(ci.NE__OrderId__r.NE__Optyid__r.Id)) {
                        orderRecurrenteBrutoMensualAnterior.put(ci.NE__OrderId__r.NE__Optyid__r.Id, ci.BI_Ingreso_Recurrente_Anterior_Producto__c);
                    } else {
                        orderRecurrenteBrutoMensualAnterior.put(ci.NE__OrderId__r.NE__Optyid__r.Id, orderRecurrenteBrutoMensualAnterior.get(ci.NE__OrderId__r.NE__Optyid__r.Id) + ci.BI_Ingreso_Recurrente_Anterior_Producto__c);
                    }
                    
                    // Cambiamos los valores económicos de CI's
                    ci.NE__OneTimeFeeOv__c = 0;
                    ci.NE__RecurringChargeOv__c = 0;
                    ci.NE__BaseOneTimeFee__c = 0;
                    ci.NE__BaseRecurringCharge__c = 0;
                    ci.BI_Ingreso_Recurrente_Anterior_Producto__c = 0;
                }
                List<NE__Order__c> configurations = new List<NE__Order__c>(configurationsSet);
                List<Opportunity> opportunities = new List<Opportunity>(opportunitiesSet);
                system.debug('==============================================');
                system.debug('==============================================');
                // Actualizamos los valores económicos de configuration
                system.debug('VCF - Actualizamos los valores económicos de configuration');
                for (Integer i = 0; i < configurations.size(); i++) {
                    system.debug('VCF - configurationIngresoRecurrenteAnteriorConfig');
                    system.debug(configurationIngresoRecurrenteAnteriorConfig);
                    system.debug('VCF - Antes');
                    system.debug(configurations[i].NE__One_Time_fee_total__c);
                    system.debug(configurations[i].NE__Recurring_Charge_Total__c);
                    system.debug(configurations[i].BI_Ingreso_Recurrente_Anterior_Config__c);
                    
                    configurations[i].NE__One_Time_fee_total__c -= configurationOneTimeFee.get(configurations[i].Id);
                    configurations[i].NE__Recurring_Charge_Total__c -= configurationRecurringCharge.get(configurations[i].Id);
                    if (configurationIngresoRecurrenteAnteriorConfig.get(configurations[i].Id) != null) {
                    	configurations[i].BI_Ingreso_Recurrente_Anterior_Config__c -=configurationIngresoRecurrenteAnteriorConfig.get(configurations[i].Id);    
                    }
                    
                    
                    system.debug('VCF - Después');
                    system.debug(configurations[i].NE__One_Time_fee_total__c);
                    system.debug(configurations[i].NE__Recurring_Charge_Total__c);
                    system.debug(configurations[i].BI_Ingreso_Recurrente_Anterior_Config__c);
                }
        
                // Actualizamos los valores económicos de las oportunidades
                system.debug('VCF - Actualizamos los valores económicos de las oportunidades');
                for (Integer i = 0; i < opportunities.size(); i++) {
                    for (Integer j = 0; j < configurations.size(); j++) {
                        if (opportunities[i].Id == configurations[j].NE__OptyId__c) {
                        	opportunities[i].BI_Ingreso_por_unica_vez__c = configurations[j].NE__One_Time_fee_total__c;
                            opportunities[i].BI_Recurrente_bruto_mensual__c = configurations[j].NE__Recurring_Charge_Total__c;
                            opportunities[i].BI_Recurrente_bruto_mensual_anterior__c = configurations[j].BI_Ingreso_Recurrente_Anterior_Config__c;        
                        }
                    }
                    
                    
                    /*system.debug('VCF - Antes');
                    system.debug(opportunities[i].BI_Ingreso_por_unica_vez__c);
                    system.debug(opportunities[i].BI_Recurrente_bruto_mensual__c);
                    system.debug(opportunities[i].BI_Recurrente_bruto_mensual_anterior__c);
                    opportunities[i].BI_Ingreso_por_unica_vez__c -= orderOneTimeFee.get(opportunities[i].Id);
                    opportunities[i].BI_Recurrente_bruto_mensual__c -= orderRecurringCharge.get(opportunities[i].Id);
                    opportunities[i].BI_Recurrente_bruto_mensual_anterior__c -= orderRecurrenteBrutoMensualAnterior.get(opportunities[i].Id);
                    system.debug('VCF - Después');
                    system.debug(opportunities[i].BI_Ingreso_por_unica_vez__c);
                    system.debug(opportunities[i].BI_Recurrente_bruto_mensual__c);
                    system.debug(opportunities[i].BI_Recurrente_bruto_mensual_anterior__c);*/
                }
                system.debug('==============================================');
                system.debug('==============================================');
                // Actualizamos los CIs
                BI_MigrationHelper.setSkippedTrigger('NE__OrderItem__c');
                update configurationItemsToRemove;
                BI_MigrationHelper.cleanSkippedTriggers();
                
                // Actualizamos los configuration (order)
                BI_MigrationHelper.setSkippedTrigger('NE__Order__c');
                update configurations;
                BI_MigrationHelper.cleanSkippedTriggers();
                
                // Actualizamos las oportunidades
                for (Integer i = 0; i < news.size(); i++) {
                    for (Opportunity opportunity: opportunities) {
                        if (news[i].Id == opportunity.Id) {
                            news[i].BI_Ingreso_por_unica_vez__c = opportunity.BI_Ingreso_por_unica_vez__c;
                            news[i].BI_Recurrente_bruto_mensual__c = opportunity.BI_Recurrente_bruto_mensual__c;
                            news[i].BI_Recurrente_bruto_mensual_anterior__c = opportunity.BI_Recurrente_bruto_mensual_anterior__c;
                            news[i].BI_Casilla_desarrollo__c = true;
                            break;
                        }
                    }
                }
            }
        }
        
        
        System.debug(loggingLevel.Debug, 'updateCIWithoutMS__END');
    }
    
    /*-------------------------------------------------------------------------------------------------------------------------------------------------------
    Author:        Víctor Cardozo
    Company:       Everis
    Description:   Actualizar precios de la modificación de servicios en las oportunidades que pasen a F3 
				   En el paso de la etapa de la oportunidad a F3, se lanzarán dos procesos para aquellos CI, 
				   cuyas MS asociadas tengan las siguientes clasificaciones de servicio:
                    •	Alta Demo
                    •	Alta por Normalización
                    •	Demo
                    •	Demo Upgrade

                    1-	Se quitará la relación existente entre CI,  MS y DS, de tal manera que no queden 
						asociados entre sí.
                    2-	Los precios del CI que pertenecían a estas MS, se deben actualizar a “0”,
						con el objetivo de no sumar en la Oportunidad, al haber quitado la relación previamente, 
						se evitará la modificación de la MS.

    
    History: 
    
    <Date>                  <Author>                    <Change Description>
    13/06/2018              Víctor Cardozo      		Initial Version   
    14/12/2018              Hicham Belhaj - CoE         Sustituir los campos con los que se opera cuyo valor es igual a 'null' por '0'. eHelp 04486226
	09/01/2019              Álvaro López                Se aplica cambio de tasa a la hora de hacer la resta   
    --------------------------------------------------------------------------------------------------------------------------------------------------------*/
    public static void upateCIPrice(List <Opportunity> news, List <Opportunity> olds)
    { 
        System.debug(loggingLevel.Debug, 'upateMDPrice__START');
        Set<Id> opportunities = new Set<Id>();
        Integer index = 0;
        // Filter opportunities who are in F3
        //String userProfile = [SELECT Name FROM profile WHERE id = :Userinfo.getProfileId()].Name;
        for(Integer i = 0;i<news.size();i++) {
            // Filter opportunities going from F4 to F3 
            //JLA Added BI_Oportunidad_Padre__c for avoid Multinational Opps
            //JLA put, just for testing that are too bad, BI_Country__c!=null  
            if(news.get(i).BI_Country__c!=null && news.get(i).StageName.startsWith('F3') && olds.get(i).StageName.startsWith('F4') && news.get(i).BI_Country__c.equals('Colombia') && news.get(i).BI_Oportunidad_Padre__c == null /*&& (userProfile=='BI_Standard_COL' || userProfile.contains('Admin'))*/ ) {
                // Add to list of filtered opportunities
                opportunities.add(news.get(i).Id);
            }
        }
        // Validate there is at least one opportunity that fill all conditions
        system.debug('VCF opportunities.size() ' + opportunities.size());
        if (opportunities.size() > 0) {
            List<String> clasificationOfServices = new List<String>();
            clasificationOfServices.add('Alta Demo');
            clasificationOfServices.add('Alta por Normalizacion');
            clasificationOfServices.add('Demo');
            clasificationOfServices.add('Demo Upgrade');
            
            // Get configuration items for this opportunities (filtered)
            //List<NE__OrderItem__c> configurationItems = [SELECT Id, BI_COL_ModificacionServicio__c, NE__OneTimeFeeOv__c, NE__RecurringChargeOv__c, NE__BaseOneTimeFee__c, NE__BaseRecurringCharge__c FROM NE__OrderItem__c WHERE NE__OrderId__r.NE__OptyId__c IN :opportunities AND BI_COL_ModificacionServicio__r.BI_COL_Clasificacion_Servicio__c IN :clasificationOfServices];
            
            //System.debug('VCF configurationItems size ' + configurationItems.size());
            //List<BI_COL_Modificacion_de_Servicio__c> modificationOfServices = [SELECT Id, BI_COL_Producto__c, BI_COL_Clasificacion_Servicio__c FROM BI_COL_Modificacion_de_Servicio__c WHERE BI_COL_Producto__c IN :configurationItems AND BI_COL_Clasificacion_Servicio__c IN :clasificationOfServices];
            List<BI_COL_Modificacion_de_Servicio__c> modificationOfServices = [
                SELECT 
                    Id, BI_COL_Producto__c,
                    BI_COL_Producto__r.Id, BI_COL_Producto__r.BI_Ingreso_Recurrente_Anterior_Producto__c, BI_COL_Producto__r.BI_COL_ModificacionServicio__c, BI_COL_Producto__r.NE__OneTimeFeeOv__c, BI_COL_Producto__r.NE__RecurringChargeOv__c, BI_COL_Producto__r.NE__BaseOneTimeFee__c, BI_COL_Producto__r.NE__BaseRecurringCharge__c,BI_COL_Producto__r.CurrencyIsoCode,
                	BI_COL_Producto__r.NE__OrderId__c, BI_COL_Producto__r.NE__OrderId__r.BI_Ingreso_Recurrente_Anterior_Config__c, BI_COL_Producto__r.NE__OrderId__r.NE__One_Time_fee_total__c, BI_COL_Producto__r.NE__OrderId__r.NE__Recurring_Charge_Total__c, BI_COL_Producto__r.NE__OrderId__r.CurrencyIsoCode,
                	BI_COL_Producto__r.NE__OrderId__r.NE__Optyid__r.Id, BI_COL_Producto__r.NE__OrderId__r.NE__Optyid__r.BI_Recurrente_bruto_mensual_anterior__c, BI_COL_Producto__r.NE__OrderId__r.NE__Optyid__r.BI_Ingreso_por_unica_vez__c, BI_COL_Producto__r.NE__OrderId__r.NE__Optyid__r.BI_Recurrente_bruto_mensual__c,BI_COL_Producto__r.NE__OrderId__r.NE__OptyId__r.CurrencyIsoCode,BI_COL_Producto__r.NE__OrderId__r.NE__OptyId__r.BI_Duracion_del_contrato_Meses__c ,
                    BI_COL_Codigo_unico_servicio__r.Id, BI_COL_Codigo_unico_servicio__r.BI_COL_Producto_Telefonica__c, BI_COL_Codigo_unico_servicio__r.BI_COL_MS_de_Parque__c
                FROM 
                	BI_COL_Modificacion_de_Servicio__c 
                WHERE
                	BI_COL_Producto__r.NE__OrderId__r.NE__OptyId__c IN :opportunities AND BI_COL_Clasificacion_Servicio__c IN :clasificationOfServices AND BI_COL_Producto__r.NE__OrderId__r.NE__OrderStatus__c LIKE 'Activ%' //eHelp 04264413
            ];
            //System.debug('VCF modificationOfServices size ' + modificationOfServices.size());
            //List<BI_COL_Descripcion_de_servicio__c> descriptionServices = [SELECT Id, BI_COL_Producto_Telefonica__c, BI_COL_MS_de_Parque__c FROM BI_COL_Descripcion_de_servicio__c WHERE BI_COL_MS_de_Parque__c IN :modificationOfServices];
            //System.debug('VCF descriptionServices size ' + descriptionServices.size());
            system.debug('VCF ---- ' +modificationOfServices.size());
            Set<BI_COL_Descripcion_de_servicio__c> descriptionServices = new Set<BI_COL_Descripcion_de_servicio__c>();
            Set<NE__OrderItem__c> configurationItems = new Set<NE__OrderItem__c>();
            Set<Opportunity> opportunitiesSet = new Set<Opportunity>();
            Set<NE__Order__c> configurationsSet = new Set<NE__Order__c>();
            Map<Id, Decimal> configurationOneTimeFee = new Map<Id, Decimal>();
            Map<Id, Decimal> configurationRecurringCharge = new Map<Id, Decimal>();
            Map<Id, Decimal> configurationIngresoRecurrenteAnteriorConfig = new Map<Id, Decimal>();
            Map<Id, Decimal> orderOneTimeFee = new Map<Id, Decimal>();
            Map<Id, Decimal> orderRecurringCharge = new Map<Id, Decimal>();
            Map<Id, Decimal> orderRecurrenteBrutoMensualAnterior = new Map<Id, Decimal>();
            
            // Remove relations and update economic values
            for (Integer i = 0; i < modificationOfServices.size(); i++) {
                opportunitiesSet.add(modificationOfServices[i].BI_COL_Producto__r.NE__OrderId__r.NE__Optyid__r);
                configurationsSet.add(modificationOfServices[i].BI_COL_Producto__r.NE__OrderId__r);
                Double onetimefee = modificationOfServices[i].BI_COL_Producto__r.NE__OneTimeFeeOv__c;
                Double recurringCharge = modificationOfServices[i].BI_COL_Producto__r.NE__RecurringChargeOv__c;
                Double previousRecurringCharge = modificationOfServices[i].BI_COL_Producto__r.BI_Ingreso_Recurrente_Anterior_Producto__c;
                // Calculamos los valores económicos de los configuration (order)
                if (modificationOfServices[i].BI_COL_Producto__r.NE__OneTimeFeeOv__c != null) { //HB 14/12/2018 Comprueba que el campo sea distinto de null, si no es así, le inserta el valor 0.
                    if (!configurationOneTimeFee.containsKey(modificationOfServices[i].BI_COL_Producto__r.NE__OrderId__c)) {
                        configurationOneTimeFee.put(modificationOfServices[i].BI_COL_Producto__r.NE__OrderId__c, (Decimal)BI_CurrencyHelper.convertCurrency(modificationOfServices[i].BI_COL_Producto__r.CurrencyIsoCode,modificationOfServices[i].BI_COL_Producto__r.NE__OrderId__r.CurrencyIsoCode,onetimefee));
                    } else {
                        configurationOneTimeFee.put(modificationOfServices[i].BI_COL_Producto__r.NE__OrderId__c, configurationOneTimeFee.get(modificationOfServices[i].BI_COL_Producto__r.NE__OrderId__c) + (Decimal)BI_CurrencyHelper.convertCurrency(modificationOfServices[i].BI_COL_Producto__r.CurrencyIsoCode,modificationOfServices[i].BI_COL_Producto__r.NE__OrderId__r.CurrencyIsoCode,onetimefee));
                    }
                } else { //HB 14/12/2018
                    modificationOfServices[i].BI_COL_Producto__r.NE__OneTimeFeeOv__c = 0;
                    if (!configurationOneTimeFee.containsKey(modificationOfServices[i].BI_COL_Producto__r.NE__OrderId__c)) {
                        configurationOneTimeFee.put(modificationOfServices[i].BI_COL_Producto__r.NE__OrderId__c, modificationOfServices[i].BI_COL_Producto__r.NE__OneTimeFeeOv__c);
                    } else {
                        configurationOneTimeFee.put(modificationOfServices[i].BI_COL_Producto__r.NE__OrderId__c, configurationOneTimeFee.get(modificationOfServices[i].BI_COL_Producto__r.NE__OrderId__c) + modificationOfServices[i].BI_COL_Producto__r.NE__OneTimeFeeOv__c);
                    }
                }

                if (modificationOfServices[i].BI_COL_Producto__r.NE__RecurringChargeOv__c != null) { //HB 14/12/2018 Comprueba que el campo sea distinto de null, si no es así, le inserta el valor 0.
                    if (!configurationRecurringCharge.containsKey(modificationOfServices[i].BI_COL_Producto__r.NE__OrderId__c)) {
                        configurationRecurringCharge.put(modificationOfServices[i].BI_COL_Producto__r.NE__OrderId__c, (Decimal)BI_CurrencyHelper.convertCurrency(modificationOfServices[i].BI_COL_Producto__r.CurrencyIsoCode,modificationOfServices[i].BI_COL_Producto__r.NE__OrderId__r.CurrencyIsoCode,recurringCharge));
                    } else {
                        configurationRecurringCharge.put(modificationOfServices[i].BI_COL_Producto__r.NE__OrderId__c, configurationRecurringCharge.get(modificationOfServices[i].BI_COL_Producto__r.NE__OrderId__c) + (Decimal)BI_CurrencyHelper.convertCurrency(modificationOfServices[i].BI_COL_Producto__r.CurrencyIsoCode,modificationOfServices[i].BI_COL_Producto__r.NE__OrderId__r.CurrencyIsoCode,recurringCharge));
                    }
                } else { //HB 14/12/2018
                    modificationOfServices[i].BI_COL_Producto__r.NE__RecurringChargeOv__c = 0;
                    if (!configurationRecurringCharge.containsKey(modificationOfServices[i].BI_COL_Producto__r.NE__OrderId__c)) {
                        configurationRecurringCharge.put(modificationOfServices[i].BI_COL_Producto__r.NE__OrderId__c, modificationOfServices[i].BI_COL_Producto__r.NE__RecurringChargeOv__c);
                    } else {
                        configurationRecurringCharge.put(modificationOfServices[i].BI_COL_Producto__r.NE__OrderId__c, configurationRecurringCharge.get(modificationOfServices[i].BI_COL_Producto__r.NE__OrderId__c) + modificationOfServices[i].BI_COL_Producto__r.NE__RecurringChargeOv__c);
                    }
                }

                if (modificationOfServices[i].BI_COL_Producto__r.BI_Ingreso_Recurrente_Anterior_Producto__c != null) { //HB 14/12/2018 Comprueba que el campo sea distinto de null, si no es así, le inserta el valor 0.
                    if (!configurationIngresoRecurrenteAnteriorConfig.containsKey(modificationOfServices[i].BI_COL_Producto__r.NE__OrderId__c)) {
                        configurationIngresoRecurrenteAnteriorConfig.put(modificationOfServices[i].BI_COL_Producto__r.NE__OrderId__c, (Decimal)BI_CurrencyHelper.convertCurrency(modificationOfServices[i].BI_COL_Producto__r.CurrencyIsoCode,modificationOfServices[i].BI_COL_Producto__r.NE__OrderId__r.CurrencyIsoCode,previousRecurringCharge));
                    } else {
                        configurationIngresoRecurrenteAnteriorConfig.put(modificationOfServices[i].BI_COL_Producto__r.NE__OrderId__c, configurationIngresoRecurrenteAnteriorConfig.get(modificationOfServices[i].BI_COL_Producto__r.NE__OrderId__c) + (Decimal)BI_CurrencyHelper.convertCurrency(modificationOfServices[i].BI_COL_Producto__r.CurrencyIsoCode,modificationOfServices[i].BI_COL_Producto__r.NE__OrderId__r.CurrencyIsoCode,previousRecurringCharge));
                    }
                } else { //HB 14/12/2018
                    modificationOfServices[i].BI_COL_Producto__r.BI_Ingreso_Recurrente_Anterior_Producto__c = 0;
                    if (!configurationIngresoRecurrenteAnteriorConfig.containsKey(modificationOfServices[i].BI_COL_Producto__r.NE__OrderId__c)) {
                        configurationIngresoRecurrenteAnteriorConfig.put(modificationOfServices[i].BI_COL_Producto__r.NE__OrderId__c, modificationOfServices[i].BI_COL_Producto__r.BI_Ingreso_Recurrente_Anterior_Producto__c);
                    } else {
                        configurationIngresoRecurrenteAnteriorConfig.put(modificationOfServices[i].BI_COL_Producto__r.NE__OrderId__c, configurationIngresoRecurrenteAnteriorConfig.get(modificationOfServices[i].BI_COL_Producto__r.NE__OrderId__c) + modificationOfServices[i].BI_COL_Producto__r.BI_Ingreso_Recurrente_Anterior_Producto__c);
                        System.debug(LoggingLevel.DEBUG, 'Ingresooooooooooooo FINAAAAAAAAAAAAAAAAL '+ modificationOfServices[i].BI_COL_Producto__r.BI_Ingreso_Recurrente_Anterior_Producto__c);
                    }
                }

                // Calculamos los valores económicos de las oportunidades
                if (modificationOfServices[i].BI_COL_Producto__r.NE__OneTimeFeeOv__c != null) { //HB 14/12/2018 Comprueba que el campo sea distinto de null, si no es así, inserta el valor 0.
                    if (!orderOneTimeFee.containsKey(modificationOfServices[i].BI_COL_Producto__r.NE__OrderId__r.NE__Optyid__r.Id)) {
                        orderOneTimeFee.put(modificationOfServices[i].BI_COL_Producto__r.NE__OrderId__r.NE__Optyid__r.Id, (Decimal)BI_CurrencyHelper.convertCurrency(modificationOfServices[i].BI_COL_Producto__r.CurrencyIsoCode,modificationOfServices[i].BI_COL_Producto__r.NE__OrderId__r.CurrencyIsoCode,onetimefee));
                    } else {
                        orderOneTimeFee.put(modificationOfServices[i].BI_COL_Producto__r.NE__OrderId__r.NE__Optyid__r.Id, orderOneTimeFee.get(modificationOfServices[i].BI_COL_Producto__r.NE__OrderId__r.NE__Optyid__r.Id) + (Decimal)BI_CurrencyHelper.convertCurrency(modificationOfServices[i].BI_COL_Producto__r.CurrencyIsoCode,modificationOfServices[i].BI_COL_Producto__r.NE__OrderId__r.CurrencyIsoCode,onetimefee));
                    }
                } else { //HB 14/12/2018
                    modificationOfServices[i].BI_COL_Producto__r.NE__OneTimeFeeOv__c = 0;
                    if (!orderOneTimeFee.containsKey(modificationOfServices[i].BI_COL_Producto__r.NE__OrderId__r.NE__Optyid__r.Id)) {
                        orderOneTimeFee.put(modificationOfServices[i].BI_COL_Producto__r.NE__OrderId__r.NE__Optyid__r.Id, modificationOfServices[i].BI_COL_Producto__r.NE__OneTimeFeeOv__c);
                    } else {
                        orderOneTimeFee.put(modificationOfServices[i].BI_COL_Producto__r.NE__OrderId__r.NE__Optyid__r.Id, orderOneTimeFee.get(modificationOfServices[i].BI_COL_Producto__r.NE__OrderId__r.NE__Optyid__r.Id) + modificationOfServices[i].BI_COL_Producto__r.NE__OneTimeFeeOv__c);
                    }
                }

                if (modificationOfServices[i].BI_COL_Producto__r.NE__RecurringChargeOv__c != null) { //HB 14/12/2018 Comprueba que el campo sea distinto de null, si no es así, inserta el valor 0.
                    if (!orderRecurringCharge.containsKey(modificationOfServices[i].BI_COL_Producto__r.NE__OrderId__r.NE__Optyid__r.Id)) {
                        orderRecurringCharge.put(modificationOfServices[i].BI_COL_Producto__r.NE__OrderId__r.NE__Optyid__r.Id, (Decimal)BI_CurrencyHelper.convertCurrency(modificationOfServices[i].BI_COL_Producto__r.CurrencyIsoCode,modificationOfServices[i].BI_COL_Producto__r.NE__OrderId__r.CurrencyIsoCode,recurringCharge));
                    } else {
                        orderRecurringCharge.put(modificationOfServices[i].BI_COL_Producto__r.NE__OrderId__r.NE__Optyid__r.Id, orderRecurringCharge.get(modificationOfServices[i].BI_COL_Producto__r.NE__OrderId__r.NE__Optyid__r.Id) + (Decimal)BI_CurrencyHelper.convertCurrency(modificationOfServices[i].BI_COL_Producto__r.CurrencyIsoCode,modificationOfServices[i].BI_COL_Producto__r.NE__OrderId__r.CurrencyIsoCode,recurringCharge));
                    }
                } else { //HB 14/12/2018
                    modificationOfServices[i].BI_COL_Producto__r.NE__RecurringChargeOv__c = 0;
                    if (!orderRecurringCharge.containsKey(modificationOfServices[i].BI_COL_Producto__r.NE__OrderId__r.NE__Optyid__r.Id)) {
                        orderRecurringCharge.put(modificationOfServices[i].BI_COL_Producto__r.NE__OrderId__r.NE__Optyid__r.Id, modificationOfServices[i].BI_COL_Producto__r.BI_Ingreso_Recurrente_Anterior_Producto__c);
                    } else {
                        orderRecurringCharge.put(modificationOfServices[i].BI_COL_Producto__r.NE__OrderId__r.NE__Optyid__r.Id, orderRecurringCharge.get(modificationOfServices[i].BI_COL_Producto__r.NE__OrderId__r.NE__Optyid__r.Id) + modificationOfServices[i].BI_COL_Producto__r.NE__RecurringChargeOv__c);
                    }
                }

                if (modificationOfServices[i].BI_COL_Producto__r.BI_Ingreso_Recurrente_Anterior_Producto__c != null) { //HB 14/12/2018 Comprueba que el campo sea distinto de null, si no es así, inserta el valor 0.
                    if (!orderRecurrenteBrutoMensualAnterior.containsKey(modificationOfServices[i].BI_COL_Producto__r.NE__OrderId__r.NE__Optyid__r.Id)) {
                        orderRecurrenteBrutoMensualAnterior.put(modificationOfServices[i].BI_COL_Producto__r.NE__OrderId__r.NE__Optyid__r.Id, (Decimal)BI_CurrencyHelper.convertCurrency(modificationOfServices[i].BI_COL_Producto__r.CurrencyIsoCode,modificationOfServices[i].BI_COL_Producto__r.NE__OrderId__r.CurrencyIsoCode,previousRecurringCharge));
                    } else {
                        orderRecurrenteBrutoMensualAnterior.put(modificationOfServices[i].BI_COL_Producto__r.NE__OrderId__r.NE__Optyid__r.Id, orderRecurrenteBrutoMensualAnterior.get(modificationOfServices[i].BI_COL_Producto__r.NE__OrderId__r.NE__Optyid__r.Id) + (Decimal)BI_CurrencyHelper.convertCurrency(modificationOfServices[i].BI_COL_Producto__r.CurrencyIsoCode,modificationOfServices[i].BI_COL_Producto__r.NE__OrderId__r.CurrencyIsoCode,previousRecurringCharge));
                    }
                } else { //HB 14/12/2018
                    modificationOfServices[i].BI_COL_Producto__r.BI_Ingreso_Recurrente_Anterior_Producto__c = 0;
                    if (!orderRecurrenteBrutoMensualAnterior.containsKey(modificationOfServices[i].BI_COL_Producto__r.NE__OrderId__r.NE__Optyid__r.Id)) {
                        orderRecurrenteBrutoMensualAnterior.put(modificationOfServices[i].BI_COL_Producto__r.NE__OrderId__r.NE__Optyid__r.Id, modificationOfServices[i].BI_COL_Producto__r.BI_Ingreso_Recurrente_Anterior_Producto__c);
                    } else {
                        orderRecurrenteBrutoMensualAnterior.put(modificationOfServices[i].BI_COL_Producto__r.NE__OrderId__r.NE__Optyid__r.Id, orderRecurrenteBrutoMensualAnterior.get(modificationOfServices[i].BI_COL_Producto__r.NE__OrderId__r.NE__Optyid__r.Id) + modificationOfServices[i].BI_COL_Producto__r.BI_Ingreso_Recurrente_Anterior_Producto__c);
                    }
                }

                //System.debug(LoggingLevel.DEBUG, 'Modificación de servicio antes '+ modificationOfServices[i].BI_COL_Producto__c); //HB 14/12/2018
                modificationOfServices[i].BI_COL_Producto__c = null;
                //System.debug(LoggingLevel.DEBUG, 'Modificación de servicio despues '+ modificationOfServices[i].BI_COL_Producto__c); //HB 14/12/2018
                //modificationOfService.BI_COL_Codigo_unico_servicio__r.BI_COL_MS_de_Parque__c = null;
                system.debug('antes modificationOfService.BI_COL_Codigo_unico_servicio__r '+modificationOfServices[i].BI_COL_Codigo_unico_servicio__r.BI_COL_Producto_Telefonica__c);
                system.debug('antes modificationOfService.BI_COL_Producto__r.BI_COL_ModificacionServicio__c '+modificationOfServices[i].BI_COL_Producto__r.BI_COL_ModificacionServicio__c);
                modificationOfServices[i].BI_COL_Codigo_unico_servicio__r.BI_COL_Producto_Telefonica__c = null;
                modificationOfServices[i].BI_COL_Producto__r.BI_COL_ModificacionServicio__c = null;
                modificationOfServices[i].BI_COL_Producto__r.NE__OneTimeFeeOv__c = 0;
                modificationOfServices[i].BI_COL_Producto__r.NE__RecurringChargeOv__c = 0;
                modificationOfServices[i].BI_COL_Producto__r.NE__BaseOneTimeFee__c = 0;
                modificationOfServices[i].BI_COL_Producto__r.NE__BaseRecurringCharge__c = 0;
                modificationOfServices[i].BI_COL_Producto__r.BI_Ingreso_Recurrente_Anterior_Producto__c = 0;
                configurationItems.add(modificationOfServices[i].BI_COL_Producto__r);
                descriptionServices.add(modificationOfServices[i].BI_COL_Codigo_unico_servicio__r);
            }
            
            // Update configuration
            List<NE__Order__c> configurations = new List<NE__Order__c>(configurationsSet);
            List<Opportunity> oppties = new List<Opportunity>(opportunitiesSet);
            // Actualizamos los valores económicos de configuration
            
            for (Integer i = 0; i < configurations.size(); i++) {
                if (configurations[i].BI_Ingreso_Recurrente_Anterior_Config__c != null /*&& configurations[i].NE__One_Time_fee_total__c != null && configurations[i].NE__Recurring_Charge_Total__c != null*/) { //HB 14/12/2018 Comprueba que los campos sean distintos de null, si no es así, inserta el valor 0.
                    system.debug('antes configurations[i].NE__One_Time_fee_total__c '+configurations[i].NE__One_Time_fee_total__c);
                    system.debug('antes configurations[i].NE__Recurring_Charge_Total__c '+configurations[i].NE__Recurring_Charge_Total__c);
                    configurations[i].NE__One_Time_fee_total__c -= configurationOneTimeFee.get(configurations[i].Id);
                    configurations[i].NE__Recurring_Charge_Total__c -= configurationRecurringCharge.get(configurations[i].Id);
                    configurations[i].BI_Ingreso_Recurrente_Anterior_Config__c -=configurationIngresoRecurrenteAnteriorConfig.get(configurations[i].Id);
                        System.debug(LoggingLevel.ERROR, 'FINAAAAAAAAAAAAAAAAL 2 '+ configurations[i].BI_Ingreso_Recurrente_Anterior_Config__c);
                    system.debug('después configurations[i].NE__One_Time_fee_total__c '+configurations[i].NE__One_Time_fee_total__c);
                    system.debug('después configurations[i].NE__Recurring_Charge_Total__c '+configurations[i].NE__Recurring_Charge_Total__c);
                } else { //HB 14/12/2018
                    //configurations[i].NE__One_Time_fee_total__c = 0;
                    //configurations[i].NE__Recurring_Charge_Total__c = 0;
                    configurations[i].BI_Ingreso_Recurrente_Anterior_Config__c = 0;
                    system.debug('antes configurations[i].NE__One_Time_fee_total__c '+configurations[i].NE__One_Time_fee_total__c);
                    system.debug('antes configurations[i].NE__Recurring_Charge_Total__c '+configurations[i].NE__Recurring_Charge_Total__c);
                    configurations[i].NE__One_Time_fee_total__c -= configurationOneTimeFee.get(configurations[i].Id);
                    configurations[i].NE__Recurring_Charge_Total__c -= configurationRecurringCharge.get(configurations[i].Id);
                    configurations[i].BI_Ingreso_Recurrente_Anterior_Config__c -=configurationIngresoRecurrenteAnteriorConfig.get(configurations[i].Id);
                    system.debug('después configurations[i].NE__One_Time_fee_total__c '+configurations[i].NE__One_Time_fee_total__c);
                    system.debug('después configurations[i].NE__Recurring_Charge_Total__c '+configurations[i].NE__Recurring_Charge_Total__c);
                }
            }
            // Actualizamos los valores económicos de las oportunidades
            for (Integer i = 0; i < oppties.size(); i++) {
                if (oppties[i].BI_Recurrente_bruto_mensual_anterior__c != null /*&& oppties[i].BI_Ingreso_por_unica_vez__c != null && oppties[i].BI_Recurrente_bruto_mensual__c != null*/) { //HB 14/12/2018 Comprueba que los campos sean distintos de null, si no es así, inserta el valor 0.
                    system.debug('antes opportunity.BI_Ingreso_por_unica_vez__c '+oppties[i].BI_Ingreso_por_unica_vez__c);
                    system.debug('antes opportunity.BI_Recurrente_bruto_mensual__c '+oppties[i].BI_Recurrente_bruto_mensual__c);
                    oppties[i].BI_Ingreso_por_unica_vez__c -= orderOneTimeFee.get(oppties[i].Id);
                    oppties[i].BI_Recurrente_bruto_mensual__c -= orderRecurringCharge.get(oppties[i].Id);
                    system.debug('orderRecurrenteBrutoMensualAnterior '+orderRecurrenteBrutoMensualAnterior);
                    oppties[i].BI_Recurrente_bruto_mensual_anterior__c -= orderRecurrenteBrutoMensualAnterior.get(oppties[i].Id);
                    system.debug('después opportunity.BI_Ingreso_por_unica_vez__c '+oppties[i].BI_Ingreso_por_unica_vez__c);
                    system.debug('después opportunity.BI_Recurrente_bruto_mensual__c '+oppties[i].BI_Recurrente_bruto_mensual__c);
                } else { //HB 14/12/2018
                    //oppties[i].BI_Ingreso_por_unica_vez__c = 0;
                    //oppties[i].BI_Recurrente_bruto_mensual__c = 0;
                    oppties[i].BI_Recurrente_bruto_mensual_anterior__c = 0;
                    system.debug('antes opportunity.BI_Ingreso_por_unica_vez__c '+oppties[i].BI_Ingreso_por_unica_vez__c);
                    system.debug('antes opportunity.BI_Recurrente_bruto_mensual__c '+oppties[i].BI_Recurrente_bruto_mensual__c);
                    oppties[i].BI_Ingreso_por_unica_vez__c -= orderOneTimeFee.get(oppties[i].Id);
                    oppties[i].BI_Recurrente_bruto_mensual__c -= orderRecurringCharge.get(oppties[i].Id);
                    oppties[i].BI_Recurrente_bruto_mensual_anterior__c -= orderRecurrenteBrutoMensualAnterior.get(oppties[i].Id);
                    system.debug('después opportunity.BI_Ingreso_por_unica_vez__c '+oppties[i].BI_Ingreso_por_unica_vez__c);
                    system.debug('después opportunity.BI_Recurrente_bruto_mensual__c '+oppties[i].BI_Recurrente_bruto_mensual__c);
                }
            }
            
            // Actualizamos las oportunidades
            for (Integer i = 0; i < news.size(); i++) {
                for (Opportunity opportunity: oppties) {
                    if (news[i].Id == opportunity.Id) {
                        news[i].BI_Ingreso_por_unica_vez__c = opportunity.BI_Ingreso_por_unica_vez__c;
                        news[i].BI_Recurrente_bruto_mensual__c = opportunity.BI_Recurrente_bruto_mensual__c;
                        news[i].BI_Recurrente_bruto_mensual_anterior__c = opportunity.BI_Recurrente_bruto_mensual_anterior__c;
                        //news[i].Amount = opportunity.BI_Ingreso_por_unica_vez__c + (opportunity.BI_Recurrente_bruto_mensual__c*opportunity.BI_Duracion_del_contrato_Meses__c);
                        news[i].BI_Casilla_desarrollo__c = true;
                        break;
                    }
                }
            }
            // Update DSs, MS, CIs
            BI_MigrationHelper.setSkippedTrigger('BI_COL_Descripcion_de_servicio__c');
            update new List<BI_COL_Descripcion_de_servicio__c>(descriptionServices);
            //BI_MigrationHelper.cleanSkippedTriggers();
            BI_MigrationHelper.setSkippedTrigger('NE__OrderItem__c');
            update new List<NE__OrderItem__c>(configurationItems);
            BI_MigrationHelper.cleanSkippedTriggers();
            BI_MigrationHelper.setSkippedTrigger('NE__Order__c');
            update configurations;
            BI_MigrationHelper.cleanSkippedTriggers();
            BI_MigrationHelper.setSkippedTrigger('BI_COL_Modificacion_de_Servicio__c');
            update new List<BI_COL_Modificacion_de_Servicio__c>(modificationOfServices);
            BI_MigrationHelper.cleanSkippedTriggers();
        }
        
        System.debug(loggingLevel.Debug, 'upateMDPrice__END');
    }
    
}