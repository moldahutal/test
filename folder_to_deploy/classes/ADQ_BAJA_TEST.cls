/*-------------------------------------------------------------------------------------------------------------------------------------------------------
    Author:        Pedro Párraga
    Company:       Salesforce.com
    Description:   Test class to manage the coverage code for ADQ_BajaSitiosControllerNew class
    
    History: 
    
    <Date>                  <Author>                <Change Description>
    23/19/2017              Pedro Párraga            Initial Creation
    13/06/2017				Guillermo Muñoz			Deprecated references to Raz_n_social__c (Optimización)
    --------------------------------------------------------------------------------------------------------------------------------------------------------*/

@isTest
private  class ADQ_BAJA_TEST {
	
	@isTest static void ADQ_BajaSitiosControllerNew (){
			Account acc01  = new Account ();
				acc01.Name = 'Cuenta de prueba testCosumos2';
				acc01.BI_Segment__c = 'test';
				acc01.BI_Subsegment_Regional__c = 'test';
				acc01.BI_Territory__c = 'test';
				//acc01.Raz_n_social__c = 'Cuenta de prueba testCosumos SA CV';
			insert acc01;
			
			
			BI_Punto_de_instalacion__c puntoInstall = new BI_Punto_de_instalacion__c ();
				puntoInstall.BI_Cliente__c = acc01.Id;
				
			Account accEliminadas  = new Account ();
				accEliminadas.Name = 'CUENTAS ELIMINADAS';
				accEliminadas.BI_Segment__c = 'test';
				accEliminadas.BI_Subsegment_Regional__c = 'test';
				accEliminadas.BI_Territory__c = 'test';
				//accEliminadas.Raz_n_social__c = 'CUENTAS ELIMINADAS';
			insert accEliminadas;  
					
			Factura__c Factura = new Factura__c ();
				Factura.Activo__c = true;
				Factura.Cliente__c = acc01.Id;
				Factura.Fecha_Inicio__c = Date.today();
				Factura.Fecha_Fin__c = Date.today() + 20;
				Factura.Inicio_de_Facturaci_n__c = Date.today();
				Factura.IVA__c = '16%';
				Factura.Sociedad_Facturadora__c = 'GTM';
				Factura.Requiere_Anexo__c = 'SI';
				RecordType tiporegistro = [SELECT Id FROM RecordType where  SobjectType = 'Factura__c' and DeveloperName  ='Recurrente'];
				Factura.RecordTypeId = tiporegistro.Id;
			insert Factura;
			
				Factura.Sociedad_Facturadora__c = 'PCS';
			update  Factura;
			
			Programacion__c programacion = new Programacion__c ();
				programacion.Factura__c = Factura.Id;
				programacion.CurrencyIsoCode = 'MXN';
				programacion.Sociedad_Facturadora_Real__c = 'GTM';
				programacion.Facturado__c = false;
				programacion.Fecha__c = Date.today();
				programacion.Inicio_del_per_odo__c = Date.newInstance(2009, 11, 22);
				programacion.Fin_del_per_odo__c = Date.today();
				programacion.Fecha_de_inicio_de_cobro__c = Date.today().addDays(2);
				
				
			insert programacion;
			
				programacion.Facturado__c =  true;
				programacion.Exportado__c =  true;
				programacion.Folio_Fiscal__c = 'FGTMD00001';
				programacion.Sociedad_Facturadora_Real__c = 'PCS';
				update programacion;
				
			Test.setCurrentPageReference(new PageReference('Page.ADQ_BajaProductos'));
			System.currentPageReference().getParameters().put('fId', factura.Id);
			
			
			Factura__c FacturaDestino = new Factura__c ();
				FacturaDestino.Activo__c = true;
				FacturaDestino.Cliente__c = accEliminadas.Id;
				FacturaDestino.Fecha_Inicio__c = Date.today();
				FacturaDestino.Fecha_Fin__c = Date.today() + 20;
				FacturaDestino.Inicio_de_Facturaci_n__c = Date.today();
				
				FacturaDestino.IVA__c = '16%';
				FacturaDestino.Sociedad_Facturadora__c = 'GTM';
				FacturaDestino.Requiere_Anexo__c = 'SI';
				RecordType tiporegistro2 = [SELECT Id FROM RecordType where  SobjectType = 'Factura__c' and DeveloperName  ='Recurrente'];
				FacturaDestino.RecordTypeId = tiporegistro2.Id;
			insert FacturaDestino;
			
			Programacion__c programacionDestino = new Programacion__c ();
				programacionDestino.Factura__c = FacturaDestino.Id;
				programacionDestino.Sociedad_Facturadora_Real__c = 'GTM';
				programacionDestino.Facturado__c = false;
				programacionDestino.Fecha__c = Date.today();
				programacionDestino.Inicio_del_per_odo__c = Date.newInstance(2009, 11, 22);
				programacionDestino.Fin_del_per_odo__c = Date.newInstance(2009, 11, 22);
				programacionDestino.Fecha_de_inicio_de_cobro__c = Date.today().addDays(2);
				
				
			insert programacionDestino;
			
			
			List<NE__OrderItem__c> listaProductosReasignar = new List<NE__OrderItem__c>();
			List<Programacion__c> listaProgramaciones = new List<Programacion__c>();
			List<NE__OrderItem__c> listaProductosUnicosReasignar = new List<NE__OrderItem__c>();
			
			NE__Order__c NEORDER =  new NE__Order__c(); 
				insert NEORDER;
			
			NE__OrderItem__c NEInsert  = new NE__OrderItem__c ();
				NEInsert.NE__OrderId__c = NEORDER.id; 
				NEInsert.Factura__c = Factura.Id;
				NEInsert.NE__Qty__c = 1;
				NEInsert.Fecha_de_reasignaci_n_a_factura__c = Date.newInstance(2009, 12, 22);
				insert NEInsert;
			
			NE__OrderItem__c NEInsert2  = new NE__OrderItem__c ();
				NEInsert2.NE__OrderId__c = NEORDER.id; 
				NEInsert2.NE__Qty__c = 1;
				NEInsert2.CurrencyIsoCode = 'USD';
				NEInsert2.NE__OneTimeFeeOv__c = 100;
				NEInsert2.NE__RecurringChargeOv__c = 100;
				NEInsert2.Fecha_de_reasignaci_n_a_factura__c = date.today();
				insert NEInsert2;
				
				NEInsert2.Factura__c = Factura.Id;
				update NEInsert2;
				
				
				listaProductosReasignar.add(NEInsert);
				listaProductosUnicosReasignar.add(NEInsert);
				listaProductosUnicosReasignar.add(NEInsert2);
				
			
			
			ADQ_BajaSitiosControllerNew baja = new ADQ_BajaSitiosControllerNew ();
			
				
				for(Factura__c fac001 : [ SELECT Id,Cliente__r.Name FROM Factura__c where Cliente__r.NAme = 'CUENTAS ELIMINADAS' limit 1]){
					baja.encabezadoSeleccionado = fac001.Id;
					baja.encabezadoDestino = fac001;
				}
				baja.encabezadoDestino = FacturaDestino;
		
				baja.idEncabezado = factura.Id;
				baja.listaProductosReasignar = listaProductosReasignar;
				System.debug('baja.listaProductosReasignar: '+baja.listaProductosReasignar.size());
				
				Boolean selected = true;
				
				ADQ_BajaSitiosControllerNew.WrapperProductos wrapp = new   ADQ_BajaSitiosControllerNew.WrapperProductos (NEInsert, selected);
				List<ADQ_BajaSitiosControllerNew.WrapperProductos> listaWrapperProductosDestino = new List<ADQ_BajaSitiosControllerNew.WrapperProductos>();
				
				ADQ_BajaSitiosControllerNew.WrapperProductos wrapp2 = new   ADQ_BajaSitiosControllerNew.WrapperProductos (NEInsert2, selected);
				List<ADQ_BajaSitiosControllerNew.WrapperProductos>  listaWrapperProductosOrigen = new  List<ADQ_BajaSitiosControllerNew.WrapperProductos>();



				Programacion__c pro = new Programacion__c(Factura__c = Factura.Id, Numero_de_factura_SD__c = null,
															 Inicio_del_per_odo__c = Date.newInstance(2009, 11, 22),
															 Fin_del_per_odo__c = Date.today());
				
				insert pro;

				Pedido_PE__c  pedido = new Pedido_PE__c(Producto_en_Sitio__c = NEInsert.Id, Programacion__c = pro.Id, Precio_original__c = 168036, Precio_convertido__c = 168036,
														 CurrencyIsoCode = 'MXN', Concepto__c = 'Primera factura');
				insert pedido;
				
				listaWrapperProductosDestino.add (wrapp);
				wrapp.selected = true;
			
				listaWrapperProductosOrigen.add (wrapp2);
				baja.listaWrapperProductosDestino = listaWrapperProductosDestino;
				
				
				
				baja.programacionSeleccionada = programacion.Id;
				baja.cargaEncabezados ();
				baja.generaEncabezadoOrigen ();
				baja.generaEncabezadoDestino ();
				baja.filtroSitios ();
				baja.refresh ();
				baja.reasignaEquipo();
				
				listaWrapperProductosDestino.clear();
				wrapp.selected = true;
				listaWrapperProductosDestino.add(wrapp);
				baja.listaWrapperProductosDestino = listaWrapperProductosDestino;
				
				baja.guardaSeleccion();
				baja.reasignaProductosRecurrentes();
				baja.validaEncabezadoRecurrente ();
				
				baja.listaProductosUnicosReasignar = listaProductosUnicosReasignar;
				baja.guardaCargosUnicos();
				baja.validaEncabezadoDestino ();
				baja.existenCargosUnicos ();
				baja.cancelar ();
				
				baja.getEncabezadoDestino();
				baja.getEncabezadoOrigen();
				baja.getListaEncabezadosCuentas();
				baja.getListaSitios();
				baja.getListaProgramaciones();
				try{
					baja.getListaPeriodos ();
				}catch (Exception err){
				}
				
				baja.getListaWrapperProductosDestino();
				baja.getshowComboProgramaciones ();
				baja.getListaWrapperProductosOrigen();
				//NE__OrderItem__c equipoSitio = new NE__OrderItem__c ();
				
		
				
				
			try{
				delete Factura;
			}catch(Exception er)
			{}
			Programacion__c programacion2 = new Programacion__c ();
				programacion2.Factura__c = Factura.Id;
				programacion2.Sociedad_Facturadora_Real__c = 'GTM';
				programacion2.Facturado__c = false;
				programacion2.Fecha__c = Date.today();
				programacion2.Inicio_del_per_odo__c = Date.newInstance(2009, 11, 22);
				programacion2.Fin_del_per_odo__c = Date.today();
				programacion2.Fecha_de_inicio_de_cobro__c = Date.today().addDays(2);
				
				
			insert programacion2;
			
			List<Factura__c> listFactura = new List<Factura__c> ();
			listFactura.add (Factura);
			SociedadFacturadora sociedadTEst  = new SociedadFacturadora ();
			sociedadTEst.inicio(listFactura);
			programacion.Sociedad_Facturadora_Real__c = Factura.Sociedad_Facturadora__c;
			update programacion;
			
	}		
}