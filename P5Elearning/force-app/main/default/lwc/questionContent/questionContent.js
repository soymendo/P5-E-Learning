import { LightningElement, track,api } from 'lwc';

export default class YourComponent extends LightningElement {
  @api question;
  selectedAnswer = '';

  get options() {
      return [{ label: '', value: '' }];
  }

  handleAnswerSelected(event) {
      this.selectedAnswer = event.detail.value;
  }
}