import { LightningElement,api,wire } from 'lwc';
import getUnitWrapper  from '@salesforce/apex/UnitService.getUnitWrapper';

export default class UnitContent extends LightningElement {

    @api recordId;
    @api thisUnit;
    @api thisQuestions;

    

  @wire(getUnitWrapper, {unitId: '$recordId'})
    unit({ data, error }) {
        if(data) {
            const { thisUnit, thisQuestions } = data;
            this.thisUnit = thisUnit;
            this.thisQuestions = thisQuestions;
            console.log('Este es el Unit' );
            console.log(this.thisUnit);
            console.log('Este es el QuestionList' );
            console.log(this.questionList);
        }else if(error) {
            console.log('undefined');
        }
    }
    

}