public with sharing class UnitService {

    @AuraEnabled(cacheable=false)
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
        if (questionAnswerList.isEmpty()  || questionAnswerList == null) {
            for (Id question : questionAnswerMap.keySet()) {
                Question_Answer__c questionAnswer = new Question_Answer__c(Unit_User_History__c = unitUserToInsert.Id, Question__c = question, Answer__c = questionAnswerMap.get(question));
                questionAnswerList.add(questionAnswer);
            }
        }
        
        // Si se encontraron preguntas y respuestas para actualizar, se actualizan en la base de datos y se actualiza el registro 
        if (!questionAnswerList.isEmpty() && questionAnswerList != null) {
            update questionAnswerList;
            unitUserToInsert.Status_Question_Answer__c = 'Answered';
            update unitUserToInsert;
        }
        
        // Si se está respondiendo la primera unidad del módulo, se crea un registro nuevo de Unit_User_History__c en estado "In Progress"
       /* if (unitUserToInsert.Unit__r.Module__c != null && unitUserToInsert.Unit__r.Module__r.id == unitId) {
            Unit_User_History__c newUnitUserHistory = new Unit_User_History__c(User__c = userId, Unit__c = unitId, Status__c = 'In Progress');
            insert newUnitUserHistory;
        } */

        // Retorna el estado actualizado del registro Unit_User_History__c, en este caso "Answered"
        return unitUserToInsert.Status_Question_Answer__c;
        }   





        /**
         * La clase TrailWrapper es una clase envoltorio que contiene información sobre el Trail,
         *  sus módulos y unidades, el progreso del usuario y los módulos y unidades completados por el usuario.
         */

        public class TrailWrapper{ 

            //Registro de Trail solicitado
            @AuraEnabled
            public Trail__c trail; 


            //Módulos con Unidades relacionadas
            @AuraEnabled
            public List<Module__c> modulesList;


            //Ids de módulos relacionados al Trail actual en los que el Alumno ya aprobó
            @AuraEnabled
            public List<Module_User_History__c> passedModuleIds; 


            


            //Ids de Unidades relacionadas a módulos del Trail actual que el Alumno ya aprobó
            @AuraEnabled
            public List<Id> passedUnitIds; 


            //Porcentaje de progreso del Alumno en el Trail
            @AuraEnabled
            public Integer progressTrail; 
    
            public TrailWrapper(Trail__c trail, List<Module__c> modulesList, List<Module_User_History__c> passedModuleIds, List<Id> passedUnitIds){
                this.trail = trail;
                this.modulesList = modulesList;
                this.passedModuleIds = passedModuleIds;
                this.passedUnitIds = passedUnitIds;      
                this.progressTrail = passedModuleIds.size()*100 / modulesList.size();
            }
        }
        


        /**
         * El método getTrailWrapper es el punto de entrada del componente y toma el Id del Trail como entrada.
         *  Este método llama a los métodos getModules, getModuleIdsCompleted y getUnitIdsCompleted para obtener
         *  la información necesaria para crear un objeto TrailWrapper.
         */
        @AuraEnabled(cacheable=true)
        public static TrailWrapper getTrailWrapper(Id trailId){
            //New Instance of TrailWrapper
            TrailWrapper trailWrap = new TrailWrapper([SELECT Name, Description__c, Time__c, Points__c  FROM Trail__c WHERE Id =: trailId], getModules(trailId), getModuleIdsCompleted(trailId), getUnitIdsCompleted(trailId));
    
            return trailWrap;
        }
    

        

      /**
       * El método getModules obtiene los módulos relacionados con el Trail y la información de cada módulo,
       *  incluyendo sus unidades relacionadas y los historiales de los usuarios completados.
       *  Utiliza una consulta SOQL para obtener los Trail_Module__c relacionados con el Trail,
       *  recopila los Ids de los módulos y realiza otra consulta SOQL para obtener información detallada sobre
       *  los módulos y sus unidades relacionadas. Luego, crea una lista de módulos con la información recopilada.
       */
      
        public static List<Module__c> getModules(Id trailId) {
            Id userId = UserInfo.getUserId();
            List<Trail_Module__c> trailModules = [SELECT Id, Module__c FROM Trail_Module__c WHERE Trail__c = :trailId];
            Set<Id> moduleIds = new Set<Id>();
            for (Trail_Module__c trailModule : trailModules) {
                moduleIds.add(trailModule.Module__c);
            }
            List<Module__c> modules = [SELECT Name, Cant_Time__c, Cant_Points__c, Description__c, (SELECT Name, Estimated_Time__c, Points__c FROM Units__r), (SELECT Id, Module__c FROM Modules_Users_Historys__r WHERE Status__c = 'Completed' AND User__c = :userId) FROM Module__c WHERE Id IN :moduleIds];
            return modules;
        }
        
       
       


        /**
         * El método getModuleIdsCompleted utiliza el método getModules para obtener los módulos relacionados
         *  con el Trail y recopilar información sobre los historiales de los usuarios completados. 
         * Utiliza un bucle para recorrer cada módulo y su lista relacionada de historiales de usuarios completados. 
         * Cada historial se agrega a una lista que luego se devuelve.
         */

        public static List<Module_User_History__c> getModuleIdsCompleted(Id trailId){
            List<Module__c> modules = getModules(trailId);
    
            List<Module_User_History__c> moduleProgress = new List<Module_User_History__c>();
            for(Module__c module: modules){
                for(Module_User_History__c moduleProg: module.modules_Users_Historys__r){
                    moduleProgress.add(moduleProg);
                }
            }
            return moduleProgress;
        }





        /**
         * El método getUnitIdsCompleted utiliza el método getModules para obtener los módulos relacionados con el Trail
         *  y recopilar información sobre las unidades completadas por el usuario. Utiliza un bucle para recorrer cada módulo
         *  y su lista relacionada de unidades. Luego, utiliza una consulta SOQL para obtener las unidades con un estado completado
         *  por el usuario y crea una lista de los Ids de las unidades completadas. La lista se devuelve.
         */

        public static List<Id> getUnitIdsCompleted(Id trailId){
       
            List<Unit_User_History__c> unitProgress = [SELECT Unit__c FROM Unit_User_History__c WHERE Status__c = 'Completed'  AND User__c = :UserInfo.getUserId() AND Unit__r.Module__c IN : getModules(trailId)];
            Set<Id> unitIds = new Set<Id>();
            for(Unit_User_History__c unitProg: unitProgress){
                unitIds.add(unitProg.Unit__c);
            }
            return new List<Id>(unitIds);

        }
    
       



        /**
         * La clase UnitWrapper es una clase que envuelve una instancia de la sObjeto personalizado Unit__c
         *  y una lista de objetos de tipo Question__c.
         */
        public class UnitWrapper{
            @AuraEnabled
            public Unit__c thisUnit;
           
            @AuraEnabled
            public List<Question__c> thisQuestions = new List<Question__c>();  
           
    
            public UnitWrapper(Unit__c thisUnit, List<Question__c> thisQuestions){
                this.thisUnit = thisUnit;
                this.thisQuestions = thisQuestions;
            }
        }
    

        /**El método getUnitWrapper recibe como parámetro un Id de una unidad, y devuelve una instancia de UnitWrapper
         *  que representa la unidad y sus preguntas relacionadas. En primer lugar, realiza una consulta SOQL en la base de datos
         *  para obtener una instancia de Unit__c y, a continuación, llama al método getQuestions para obtener una lista 
         * de preguntas relacionadas con esa unidad. Finalmente, crea una instancia de UnitWrapper con la unidad y la lista de preguntas y la devuelve. */

        @AuraEnabled(cacheable=true)
        public static UnitWrapper getUnitWrapper(Id unitId){
    
            UnitWrapper unitWrapper = new UnitWrapper(([SELECT Content__c, Points__c, Estimated_Time__c,Name FROM Unit__c WHERE Id = :unitId]), getQuestions(unitId));
            return unitWrapper;
        }
    
       
        /**
         * El método getQuestions recibe como parámetro el Id de una unidad, y devuelve una lista de preguntas (Question__c) 
         * relacionadas con esa unidad. La consulta SOQL utilizada para obtener las preguntas también incluye las respuestas relacionadas
         *  y los registros de Questions_Answers_UUHS__r. Retorna la lista de preguntas obtenidas de la consulta.
         */
        public static List<Question__c> getQuestions(Id unitId){
            List<Question__c> questions = [SELECT Content__c, (SELECT Id, Content__c, Is_Correct__c FROM Answers__r), (SELECT Is_Completed__c, Answer__c, Question__c FROM Questions_Answers_UUHS__r) FROM Question__c WHERE Unit__c =: unitId];
    
            return questions;
        }
        

}