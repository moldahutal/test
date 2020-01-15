/*------------------------------------------------------------
Author:         Jesus Blanco
Company:        Devoteam
Description:    Knowledge Trigger
                
History
<Date>          <Author>            <Change Description>
09/01/2020      Jesus Blanco        Initial Version
--------------------------------------------------------------------------------------------------------------------------------------------------------*/
trigger KnowledgeTrigger on Knowledge__kav (after insert) {

    if(Trigger.isAfter){
        if(Trigger.isInsert){
            KNL_autoCategorizationHandler.execute(Trigger.new);
        }

    }


}