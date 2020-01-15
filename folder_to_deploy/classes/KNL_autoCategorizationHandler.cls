/*------------------------------------------------------------
Author:         Jesus Blanco
Company:        Devoteam
Description:    Knowledge Handler that controls the article auto categorization
                
History
<Date>          <Author>            <Change Description>
09/01/2020      Jesus Blanco        Initial Version
--------------------------------------------------------------------------------------------------------------------------------------------------------*/

public with sharing class KNL_autoCategorizationHandler {

    private static final String GROUP_NAME = 'Prevalidacion';

    public static void execute(List<Knowledge__kav> newArticles){

        //labelToAPIMap
        Map<String, String> DATA_CATEGORY_API_NAMES = 
                        KNL_DescribeDataCategoryGroupStructures.getDescribeDataCategoryGroupStructureResults(new List<String>{'KnowledgeArticleVersion'});

        List<Knowledge__DataCategorySelection> categorizationsToInsert = new List<Knowledge__DataCategorySelection>(); 

        for(Knowledge__kav article : newArticles){

            if(String.isNotBlank(article.BI_Torre_de_Servicios__c)){
                categorizationsToInsert.add(newCategorization(
                    article.Id, DATA_CATEGORY_API_NAMES.get(article.BI_Torre_de_Servicios__c), GROUP_NAME
                ));
            }

            if(String.isNotBlank(article.BI_Stakeholders__c)){
                categorizationsToInsert.add(newCategorization(
                    article.Id, DATA_CATEGORY_API_NAMES.get(article.BI_Stakeholders__c), GROUP_NAME
                ));                
            }

            if(String.isNotBlank(article.BI_Servicio__c)){
                for(String service : article.BI_Servicio__c.split(';')){
                    categorizationsToInsert.add(newCategorization(
                        article.Id, DATA_CATEGORY_API_NAMES.get(service), GROUP_NAME
                    ));                    
                }
            }

        }

        try {
            insert categorizationsToInsert;
        }catch(Exception e){
            System.debug('Autocategorization failed: ' + e.getMessage());
            System.debug('Target: ' + JSON.serializePretty(categorizationsToInsert));
        }

    }

    private static Knowledge__DataCategorySelection newCategorization(Id parentId, String categoryName, String categoryGroup){

        Knowledge__DataCategorySelection categorization = new Knowledge__DataCategorySelection();
        categorization.ParentId = parentId;
        categorization.DataCategoryName = categoryName;
        categorization.DataCategoryGroupName = categoryGroup;

        return categorization;
    }


}