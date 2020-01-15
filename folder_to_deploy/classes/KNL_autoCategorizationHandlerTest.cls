/*------------------------------------------------------------
Author:         Jesus Blanco
Company:        Devoteam
Description:    Knowledge Handler test class to check the article auto categorization
                
History
<Date>          <Author>            <Change Description>
09/01/2020      Jesus Blanco        Initial Version
--------------------------------------------------------------------------------------------------------------------------------------------------------*/

@isTest
public with sharing class KNL_autoCategorizationHandlerTest {

    private static final Map<String, String> DATA_CATEGORIES;
    static {
        DATA_CATEGORIES = KNL_DescribeDataCategoryGroupStructures.getDescribeDataCategoryGroupStructureResults(new List<String>{'KnowledgeArticleVersion'});
    }
/*
    @TestSetup
    static void makeData(){

    }
*/
    @IsTest
    static void noCategorizationTest(){
        
        Knowledge__kav article = new Knowledge__kav(Title = 'Test', UrlName = 'Test' + System.now().getTime());

        Test.startTest();
        //System.runAs(contextuser){
            insert article;
        //}
        Test.stopTest();

        List<Knowledge__DataCategorySelection> categorization = [Select Id from Knowledge__DataCategorySelection where ParentId =: article.Id];
        
        System.assertEquals(0, categorization.size(), 'Incorrect number of autocategorization');

    }

    @IsTest
    static void serviceCategorizationTest(){
        
        Knowledge__kav article = new Knowledge__kav(Title = 'Test', UrlName = 'Test' + System.now().getTime(), BI_Servicio__c = 'D-CDS');

        Test.startTest();
            insert article;
        Test.stopTest();

        List<Knowledge__DataCategorySelection> categorization = [Select Id, DataCategoryName from Knowledge__DataCategorySelection where ParentId =: article.Id];
        
        System.assertEquals(1, categorization.size(), 'Incorrect number of autocategorization');
        System.assertEquals(DATA_CATEGORIES.get(article.BI_Servicio__c), categorization[0].DataCategoryName, 'Wrong auto categorization');

    }

    @IsTest
    static void fullCategorizationTest(){
        
        String BI_Servicio = 'D-CDS';
        String BI_Torre_de_Servicios = 'Security Service';
        String BI_Stakeholders = 'Project Architecture';
        List<String> expectedCategoryAPINames = new List<String>{DATA_CATEGORIES.get(BI_Servicio),
                                                            DATA_CATEGORIES.get(BI_Torre_de_Servicios),
                                                            DATA_CATEGORIES.get(BI_Stakeholders)};

        Knowledge__kav article = new Knowledge__kav(Title = 'Test', UrlName = 'Test' + System.now().getTime(), BI_Servicio__c = BI_Servicio,
                                                        BI_Torre_de_Servicios__c = BI_Torre_de_Servicios,
                                                        BI_Stakeholders__c = BI_Stakeholders);

        Test.startTest();
            insert article;
        Test.stopTest();

        List<Knowledge__DataCategorySelection> categorization = [Select Id, DataCategoryName from Knowledge__DataCategorySelection where ParentId =: article.Id];
        
        System.assertEquals(expectedCategoryAPINames.size(), categorization.size(), 'Incorrect number of auto categorization');

        List<String> actualCategoryAPINames = new List<String>();
        for(Knowledge__DataCategorySelection currentCategorization : categorization){
            actualCategoryAPINames.add(currentCategorization.DataCategoryName);
        }

        for(String expectedCategory : expectedCategoryAPINames){
            System.assert(actualCategoryAPINames.contains(expectedCategory), 'Wrong auto categorization');
        }

    }    

}