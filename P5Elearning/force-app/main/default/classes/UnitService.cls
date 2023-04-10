public with sharing class UnitService {
    public static String saveQuestionAnswers(Id unitId, String questionAnswerJSON) {
        
        // Obtiene el ID del usuario actual
        Id userId = UserInfo.getUserId();
        
        
       // Realiza una consulta SOQL para obtener el registro Unit_User_History__c correspondiente al usuario y unidad especificados
       Unit_User_History__c unitUserToInsert = [SELECT Id, Status_Question_Answer__c, Points__c, (SELECT Question__c, Answer__c FROM Questions_Answers_UUHS__r) FROM Unit_User_History__c WHERE Unit__c = :unitId AND User__c = :userId];
        

       // Deserializa el JSON que contiene las respuestas de las preguntas y lo almacena en un mapa
        Map<Id, Id> questionAnswerMap;
        try {
            questionAnswerMap = (Map<Id, Id>) JSON.deserializeStrict(questionAnswerJSON, Map<Id, Id>.class);
        } catch (Exception e) {
            return e.getMessage();
        }
        

        // Crea una lista vacía para almacenar las preguntas y respuestas que se van a actualizar
        List<Question_Answer__c> questionAnswerList = new List<Question_Answer__c>();

        // Recorre la lista de preguntas y respuestas existentes para actualizar las respuestas que han sido modificadas
        for (Question_Answer__c questionAnswer : unitUserToInsert.Questions_Answers_UUHS__r) {
            if (questionAnswerMap.containsKey(questionAnswer.Question__c)) {
                questionAnswer.Answer__c = questionAnswerMap.get(questionAnswer.Question__c);
                questionAnswerList.add(questionAnswer);
            }
        }
        

        // Si no se encontraron preguntas y respuestas existentes para actualizar, se crean registros nuevos a partir del JSON recibido
        if (questionAnswerList.isEmpty()) {
            for (Id question : questionAnswerMap.keySet()) {
                Question_Answer__c questionAnswer = new Question_Answer__c(Unit_User_History__c = unitUserToInsert.Id, Question__c = question, Answer__c = questionAnswerMap.get(question));
                questionAnswerList.add(questionAnswer);
            }
        }
        
        // Si se encontraron preguntas y respuestas para actualizar, se actualizan en la base de datos y se actualiza el registro 
        if (!questionAnswerList.isEmpty()) {
            update questionAnswerList;
            unitUserToInsert.Status_Question_Answer__c = 'Answered';
            update unitUserToInsert;
        }
        

        // Retorna el estado actualizado del registro Unit_User_History__c
        return unitUserToInsert.Status_Question_Answer__c;
        }
}