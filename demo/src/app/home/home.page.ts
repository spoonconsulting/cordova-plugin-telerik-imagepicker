import { Component, NgZone } from '@angular/core';
import { WebView } from '@ionic-native/ionic-webview/ngx';

declare var imagePicker: any;

@Component({
  selector: 'app-home',
  templateUrl: 'home.page.html',
  styleUrls: ['home.page.scss'],
})
export class HomePage {
  images: Array<any> = [];
  options: any;

  constructor(private zone: NgZone, private webview: WebView) {
    this.hasReadPermission();
  }

  openGallery() {
    this.options = {
      outputType: 1,
    };

    imagePicker.getPictures(
      (results) => {
        this.images = [];

        this.zone.run(() => {
          for (var i = 0; i < results.length; i++) {
            let file = 'file://' + results[i];
            let path = this.webview.convertFileSrc(file);
            this.images.push(path);
          }
        });
      },
      (error) => {
        console.log('Error: ' + error);
      },
      this.options
    );
  }

  hasReadPermission() {
    imagePicker.hasReadPermission(function (result) {
      if (!result) {
        this.requestReadPermission();
      }
    });
  }

  requestReadPermission() {
    imagePicker.requestReadPermission();
  }

  removeImage(image: string) {
    this.images = this.images.filter((img) => img !== image);
  }
}
