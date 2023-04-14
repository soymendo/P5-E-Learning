import { LightningElement,api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';




export default class UnitView extends NavigationMixin(LightningElement) {
    
    @api recordId;
    @api thisUnits;
    @api unit;

    /*get checkCompletedUnits() {
        return this.thisUnits.includes(this.unit.Id);
      }
      */

    handleToUnit(){
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.unit.Id,
                objectApiName: 'Unit__c',
                actionName: 'view'
            }
        });
    }


}