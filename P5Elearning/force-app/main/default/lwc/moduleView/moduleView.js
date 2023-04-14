import { LightningElement,api} from 'lwc';
import { NavigationMixin } from 'lightning/navigation';


export default class ModuleView extends LightningElement {
    activeSectionMessage = '';

   
   // @api passedModuleIds;
    @api thisUnits;
    @api module;
    @api passedModuleIds;

    /*
    get completedModule(){
        return (this.passedModuleIds.includes(this.module.Id) );
    }
*/
   

    handleToModule(){
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.module.Id,
                objectApiName: 'Module__c',
                actionName: 'view'
            }
        });
    } 
}