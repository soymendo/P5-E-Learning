import { LightningElement, api, wire, track } from 'lwc';
import getTrailWrapper from '@salesforce/apex/UnitService.getTrailWrapper';

export default class TrailView extends LightningElement {
   
   
    @api recordId;
   
    wrapper;
    thisTrail;
    thisProgressTrail;
    thisModule;
    thisUnits;

    
    passedModuleIds;
    error = undefined;


    @wire(getTrailWrapper, {trailId: '$recordId'})
    trail({ data, error }) {
        if(data) {
            const { trail, progressTrail, modulesList, passedUnitIds } = data;
            this.wrapper = data;
            this.thisTrail = trail;
            this.thisProgressTrail = progressTrail;

            this.thisModule = modulesList;
            console.log('Este es el Modulo' );
            console.log(this.thisModule);

            this.thisUnits = passedUnitIds;
            console.log('Este es el Unit' );
            console.log(this.thisUnits);
         
        }else if(error) {
            console.log('undefined');
        }
    }

    activeSections = ['A', 'C'];
    activeSectionsMessage = '';

    handleSectionToggle(event) {
        const openSections = event.detail.openSections;

        if (openSections.length === 0) {
            this.activeSectionsMessage = 'All sections are closed';
        } else {
            this.activeSectionsMessage =
                'Open sections: ' + openSections.join(', ');
        }
    }
    


}