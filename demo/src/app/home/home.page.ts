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
  grid: Array<Array<string>> = [];
  imgPerRow: number = 3;
  options: any;

  constructor(private zone: NgZone, private webview: WebView) {
    this.requestReadPermission();
  }

  openGallery() {
    this.options = {
      outputType: 1,
    };

    imagePicker.getPictures(
      (results) => {
        this.images = [];
        this.images = [];

        this.zone.run(() => {
          for (var i = 0; i < results.length; i++) {
            let file = 'file://' + results[i];
            let path = this.webview.convertFileSrc(file);
            this.images.push(path);
          }
          this.splitGrid(this.imgPerRow);
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

  splitGrid(perRow: number) {
    let row = 0;
    this.grid = Array(Math.ceil(this.images.length / perRow));

    if (this.images.length == 0) {
      this.grid = [];
    }

    for (let i = 0; i < this.images.length; i += perRow) {
      this.grid[row] = Array(perRow);
      for (let j = 0; j < perRow; j++) {
        this.images[i + j] ? (this.grid[row][j] = this.images[i + j]) : '';
      }
      row++;
    }
  }

  removeImage(image: string) {
    this.images = this.images.filter((img) => img !== image);
    this.splitGrid(this.imgPerRow);
  }
}
