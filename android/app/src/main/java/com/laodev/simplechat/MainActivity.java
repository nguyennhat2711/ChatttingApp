package com.laodev.simplechat;

import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.media.ThumbnailUtils;
import android.os.Bundle;
import android.provider.MediaStore;
import android.util.Base64;
import android.util.Log;

import androidx.annotation.NonNull;

import java.io.ByteArrayOutputStream;
import java.util.Arrays;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {

    final String imageChannel = "com.laodev.simplechat/thumbnail";

    private String sharedText;
    final String sharedChannel = "com.laodev.simplechat/shared";
    MethodChannel sharedMethodChannel;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        Intent intent = getIntent();
        String action = intent.getAction();
        String type = intent.getType();

        if (Intent.ACTION_SEND.equals(action) && type != null) {
            if ("text/plain".equals(type)) {
                sharedText = intent.getStringExtra(Intent.EXTRA_TEXT);
                Log.d("Shared Text", sharedText);
                handleSendText(intent);
            }
        }
    }

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), imageChannel).setMethodCallHandler((call, result) -> {
            if (call.method.equals("image")) {
                String params = call.arguments.toString();
                Log.d("[MethodChannel]", params);

                params = params.replace("[", "");
                params = params.replace("]", "");
                params = params.replace(" ", "");
                String[] paramData = params.split(",");
                Log.d("[MethodChannel]", Arrays.toString(paramData));

                Bitmap thumbImage = ThumbnailUtils.extractThumbnail(
                        BitmapFactory.decodeFile(paramData[0]),
                        Integer.parseInt(paramData[1]),
                        Integer.parseInt(paramData[2]));

                ByteArrayOutputStream bos = new ByteArrayOutputStream();
                thumbImage.compress(Bitmap.CompressFormat.PNG,100, bos);
                byte[] bb = bos.toByteArray();
                String base64 = Base64.encodeToString(bb, 0);

                result.success(base64);
            } else if (call.method.equals("video")) {
                String params = call.arguments.toString();
                Log.d("[MethodChannel]", params);

                params = params.replace("[", "");
                params = params.replace("]", "");
                params = params.replace(" ", "");
                String[] paramData = params.split(",");
                Log.d("[MethodChannel]", Arrays.toString(paramData));

                try {

                    Bitmap thumbImage = ThumbnailUtils.createVideoThumbnail(paramData[0], MediaStore.Video.Thumbnails.MINI_KIND);

                    ByteArrayOutputStream bos = new ByteArrayOutputStream();
                    thumbImage.compress(Bitmap.CompressFormat.PNG,100, bos);
                    byte[] bb = bos.toByteArray();
                    String base64 = Base64.encodeToString(bb, 0);

                    result.success(base64);
                } catch (Throwable throwable) {
                    result.notImplemented();
                }
            } else {
                result.notImplemented();
            }
        });

        sharedMethodChannel = new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), sharedChannel);
    }

    void handleSendText(Intent intent) {
        sharedText = intent.getStringExtra(Intent.EXTRA_TEXT);
        if (sharedMethodChannel != null) {
            sharedMethodChannel.invokeMethod("text", sharedText);
        }
    }

}
