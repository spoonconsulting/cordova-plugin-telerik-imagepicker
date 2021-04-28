package com.synconset;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import android.app.Activity;
import android.content.ClipData;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.os.Bundle;
import android.provider.MediaStore;

import java.util.ArrayList;


public class ImagePicker extends CordovaPlugin {
    private static final String ACTION_GET_PICTURES = "getPictures";
    private static final int PERMISSION_REQUEST_CODE = 100;
    private static final int SELECT_PICTURE = 200;

    private CallbackContext callbackContext;

    public boolean execute(String action, final JSONArray args, final CallbackContext callbackContext) throws JSONException {
        this.callbackContext = callbackContext;

        if (ACTION_GET_PICTURES.equals(action)) {
            final JSONObject params = args.getJSONObject(0);

            Intent imagePickerIntent = new Intent(Intent.ACTION_GET_CONTENT, MediaStore.Images.Media.EXTERNAL_CONTENT_URI);
            imagePickerIntent.setType("image/*");
            imagePickerIntent.putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true);

            int max = 20;
            int desiredWidth = 0;
            int desiredHeight = 0;
            int quality = 100;
            int outputType = 0;
            if (params.has("maximumImagesCount")) {
                max = params.getInt("maximumImagesCount");
            }
            if (params.has("width")) {
                desiredWidth = params.getInt("width");
            }
            if (params.has("height")) {
                desiredHeight = params.getInt("height");
            }
            if (params.has("quality")) {
                quality = params.getInt("quality");
            }
            if (params.has("outputType")) {
                outputType = params.getInt("outputType");
            }

            imagePickerIntent.putExtra("MAX_IMAGES", max);
            imagePickerIntent.putExtra("WIDTH", desiredWidth);
            imagePickerIntent.putExtra("HEIGHT", desiredHeight);
            imagePickerIntent.putExtra("QUALITY", quality);
            imagePickerIntent.putExtra("OUTPUT_TYPE", outputType);
            cordova.startActivityForResult(this, imagePickerIntent, SELECT_PICTURE);
            return true;
        }
        return false;
    }

    public void onActivityResult(int requestCode, int resultCode, Intent data) {
        if (resultCode == Activity.RESULT_OK && data != null) {
            ArrayList<String> fileURIs = new ArrayList<String>();
            if (requestCode == SELECT_PICTURE) {
                if (data.getData() != null) {
                    Uri uri = data.getData();
                    fileURIs.add(uri.toString());
                } else {
                    ClipData clip = data.getClipData();
                    for (int i=0;i<clip.getItemCount();i++) {
                        Uri uri = clip.getItemAt(i).getUri();
                        fileURIs.add(uri.toString());
                    }
                }
            }
            JSONArray res = new JSONArray(fileURIs);
            callbackContext.success(res);

        } else if (resultCode == Activity.RESULT_CANCELED && data != null) {
            String error = data.getStringExtra("ERRORMESSAGE");
            callbackContext.error(error);

        } else if (resultCode == Activity.RESULT_CANCELED) {
            JSONArray res = new JSONArray();
            callbackContext.success(res);

        } else {
            callbackContext.error("No images selected");
        }
    }

    /**
     * Choosing a picture launches another Activity, so we need to implement the
     * save/restore APIs to handle the case where the CordovaActivity is killed by the OS
     * before we get the launched Activity's result.
     *
     * @see http://cordova.apache.org/docs/en/dev/guide/platforms/android/plugin.html#launching-other-activities
     */
    public void onRestoreStateForActivityResult(Bundle state, CallbackContext callbackContext) {
        this.callbackContext = callbackContext;
    }


    @Override
    public void onRequestPermissionResult(int requestCode, String[] permissions, int[] grantResults) throws JSONException {

        // For now we just have one permission, so things can be kept simple...
        if (grantResults.length > 0 && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
            callbackContext.success(1);
        } else {
            callbackContext.success(0);
        }
    }

}
