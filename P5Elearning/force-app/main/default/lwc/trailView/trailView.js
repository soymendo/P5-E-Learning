import { LightningElement, api, wire, track } from 'lwc';
import getTrailWrapper from '@salesforce/apex/UnitService.getTrailWrapper';

export default class TrailView extends LightningElement {
    @api recordId;
    error = undefined;
   
    wrapper;
    thisTrail;
    thisProgressTrail;
    thisModules;
    thisUnits;

    

    @wire(getTrailWrapper, {trailId: '$recordId'})
    trail({ data, error }) {
        if(data) {
            const { trail, progressTrail, modulesList, passedUnitIds } = data;
            this.wrapper = data;
            this.thisTrail = trail;
            this.thisProgressTrail = progressTrail;
            this.thisModules = modulesList;
            this.thisUnits = passedUnitIds;
        }else if(error) {
            this.error = error;
        }
    }

}
