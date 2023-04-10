public with sharing class UpdateUnirUserHistoryHelper {
    
    // El método se encarga de actualizar los registros
    // de Unit_User_History__c y los registros relacionados de Usuario (User)
    // y Preguntas y Respuestas (Questions_Answers_UUHS__r) en función de su estado y puntaje.

    public static void UpdateUnirUserHistory(List<Unit_User_History__c> triggerNew) {
     
        // Primero, se crea un conjunto vacío de Ids de unidades y se recorre
         //la lista de objetos Unit_User_History__c pasada como parámetro,
         // se agregan los Ids de las unidades que han sido contestadas a este conjunto.

        Set<Id> UnitIds= new Set<Id>();
     
        for(Unit_User_History__c uuh : triggerNew){
            if(uuh.Status_Question_Answer__c == 'Answered')
            UnitIds.add(uuh.Unit__c);
        }

        // Si el conjunto de Ids de unidades no está vacío,
        // se ejecuta una consulta SOQL que recupera todos los registros
        //  de Unit_User_History__c que tienen los Ids de unidades encontrados 
         // anteriormente. Se crea un conjunto de usuarios (User) a partir de
        //   estos registros de Unit_User_History__c, y se ejecuta una consulta SOQL
         //   adicional para recuperar los registros de usuarios que coinciden con los 
         //   usuarios en este conjunto. Los resultados de esta consulta se asignan a un
         //    mapa de Id de usuario a usuario.

        if(!UnitIds.isEmpty())
        {
            List<Unit_User_History__c> UnitUserHistoryList = [SELECT Id,Name,Status_Question_Answer__c ,Tries__c, Points__c,User__c ,(SELECT id,Answer__c, Answer__r.Is_Correct__c FROM Questions_Answers_UUHS__r ) FROM Unit_User_History__c WHERE Id IN :UnitIds];
            
            Set<Id> userSet= new Set<Id>();
            for(Unit_User_History__c uuh : UnitUserHistoryList){
                userSet.add(uuh.User__c);
            }

            Map<Id,User> userMap = new Map<Id,User>([SELECT Id,Name ,Points__c,(SELECT id FROM Units_Users_Historys__r) FROM User WHERE Id IN :userSet]);
        

            // A continuación, se itera sobre los registros de Unit_User_History__c recuperados
            // en la primera consulta y se calculan el número de intentos (tries) y la puntuación
            //  (Points__c) de cada uno de ellos en función de los registros relacionados de Preguntas 
            //  y Respuestas. Si el número de intentos es igual al número de preguntas, se actualiza el 
            //  estado del registro de Unit_User_History__c a 'Success' y se agrega la puntuación a la
            //   puntuación del usuario correspondiente. Si el número de intentos es menor al número de preguntas,
             //   se actualiza el estado del registro de Unit_User_History__c a 'Fail' y se aumenta el número de 
            //    intentos en uno. Si el número de intentos supera el umbral de 3 intentos, el estado del registro 
             //   de Unit_User_History__c se actualiza a 'Fail'. Si el número de intentos es menor que el número de
             //    preguntas y el número de intentos es igual a 2, se reduce a la mitad la puntuación del registro
             //     de Unit_User_History__c y se actualiza su estado a 'Fail'. Si el número de intentos es igual a 1,
             //      se realiza la misma operación que para 2 intentos y se aumenta el número de intentos en uno.


            for(Unit_User_History__c uuh : UnitUserHistoryList){
                
                Integer tries = 0;
                for(Question_Answer__c qa : uuh.Questions_Answers_UUHS__r){
                    if(qa.Answer__r.Is_Correct__c){
                        tries++;
                    }
                   
                }
               if(tries == uuh.Questions_Answers_UUHS__r.size()){
                    uuh.Status_Question_Answer__c = 'Success';
                   if(userMap.containsKey(uuh.User__c)){
                        User user = userMap.get(uuh.User__c);
                        user.Points__c+=uuh.Points__c;   
                    }
                }
                else{
                    Decimal counter = (uuh.Tries__c == null) ? 1 : uuh.Tries__c + 1;
                    uuh.Tries__c = counter;
                    if (counter >= 3) {
                        uuh.Status_Question_Answer__c = 'Fail';
                    } else if(counter == 2) {
                        uuh.Status_Question_Answer__c = 'Fail';
                        uuh.Tries__c+=1;
                        uuh.Points__c = uuh.Points__c / 2;
                        if (counter == 1) {
                            uuh.Status_Question_Answer__c = 'Fail';
                            uuh.Tries__c+=1;
                            uuh.Points__c = uuh.Points__c / 2;
                        }
                    }
                }
                
               
            }


            // Finalmente, se actualizan los registros de Unit_User_History__c
            //y los registros de usuario correspondientes en la base de datos utilizando 
            // los métodos de actualización de Apex "update".
            update UnitUserHistoryList;
            update userMap.values();
        }
    }
}
