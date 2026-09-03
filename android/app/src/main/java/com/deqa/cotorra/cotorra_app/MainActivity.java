package com.deqa.cotorra.cotorra_app;

import android.app.Activity;
import android.content.ContentValues;
import android.content.pm.PackageManager;
import android.database.Cursor;
import android.net.Uri;
import android.os.Build;
import android.os.Environment;
import android.provider.MediaStore;
import android.webkit.MimeTypeMap;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import java.io.IOException;
import java.io.OutputStream;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

/**
 * Canal nativo para guardar archivos en la carpeta pública de Descargas
 * vía MediaStore (sin dependencias de plugins de terceros).
 *
 * Métodos:
 *  - saveToDownloads({fileName: String, bytes: byte[]}) -> String (path/uri guardado)
 *
 * Android 10+ : MediaStore.Downloads, sin permiso.
 * Android ≤9  : requiere WRITE_EXTERNAL_STORAGE (se pide en runtime).
 */
public class MainActivity extends FlutterActivity {

    private static final String CHANNEL = "cotorra/downloads";
    private static final int PERMISSION_REQUEST_CODE = 0xC070;

    @Nullable
    private MethodChannel.Result pendingResult;
    @Nullable
    private String pendingFileName;
    @Nullable
    private byte[] pendingBytes;

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        new MethodChannel(
                flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler(this::onMethodCall);
    }

    private void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        if (call.method.equals("saveToDownloads")) {
            String fileName = call.argument("fileName");
            byte[] bytes = call.argument("bytes");
            if (fileName == null || fileName.isEmpty() || bytes == null || bytes.length == 0) {
                result.error("BAD_ARGS", "Faltan fileName o bytes", null);
                return;
            }
            saveToDownloads(fileName, bytes, result);
        } else {
            result.notImplemented();
        }
    }

    private void saveToDownloads(String fileName, byte[] bytes, MethodChannel.Result result) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            // Android 10+: MediaStore no necesita permisos de escritura.
            try {
                String saved = insertMediaQ(fileName, bytes);
                result.success(saved);
            } catch (Exception e) {
                result.error("SAVE_FAILED", e.getMessage(), null);
            }
            return;
        }

        // Android ≤9: verificar/solicitar WRITE_EXTERNAL_STORAGE.
        if (ContextCompat.checkSelfPermission(this,
                android.Manifest.permission.WRITE_EXTERNAL_STORAGE)
                != PackageManager.PERMISSION_GRANTED) {
            pendingResult = result;
            pendingFileName = fileName;
            pendingBytes = bytes;
            ActivityCompat.requestPermissions(this,
                    new String[]{android.Manifest.permission.WRITE_EXTERNAL_STORAGE},
                    PERMISSION_REQUEST_CODE);
            return;
        }
        try {
            String saved = insertMediaLegacy(fileName, bytes);
            result.success(saved);
        } catch (Exception e) {
            result.error("SAVE_FAILED", e.getMessage(), null);
        }
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions,
                                           @NonNull int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        if (requestCode != PERMISSION_REQUEST_CODE || pendingResult == null) {
            return;
        }
        MethodChannel.Result result = pendingResult;
        String fileName = pendingFileName;
        byte[] bytes = pendingBytes;
        pendingResult = null;
        pendingFileName = null;
        pendingBytes = null;

        boolean granted = grantResults.length > 0
                && grantResults[0] == PackageManager.PERMISSION_GRANTED;
        if (!granted) {
            result.error("PERMISSION_DENIED",
                    "Permiso de almacenamiento denegado", null);
            return;
        }
        try {
            String saved = insertMediaLegacy(fileName, bytes);
            result.success(saved);
        } catch (Exception e) {
            result.error("SAVE_FAILED", e.getMessage(), null);
        }
    }

    /** Android 10+ — inserta en la colección Downloads con RELATIVE_PATH. */
    private String insertMediaQ(String fileName, byte[] bytes) throws IOException {
        ContentValues values = new ContentValues();
        values.put(MediaStore.Downloads.DISPLAY_NAME, fileName);
        values.put(MediaStore.Downloads.MIME_TYPE, mimeTypeFor(fileName));
        values.put(MediaStore.Downloads.RELATIVE_PATH,
                Environment.DIRECTORY_DOWNLOADS + "/");
        values.put(MediaStore.Downloads.IS_PENDING, 1);

        Uri collection =
                MediaStore.Downloads.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY);
        Uri uri = getContentResolver().insert(collection, values);
        if (uri == null) {
            throw new IOException("MediaStore no aceptó la inserción");
        }
        try (OutputStream os = getContentResolver().openOutputStream(uri, "w")) {
            if (os == null) throw new IOException("No se pudo abrir el output");
            os.write(bytes);
        }
        values.clear();
        values.put(MediaStore.Downloads.IS_PENDING, 0);
        getContentResolver().update(uri, values, null, null);
        return uri.toString();
    }

    /** Android ≤9 — escribe directo en el directorio público y lo indexa. */
    private String insertMediaLegacy(String fileName, byte[] bytes) throws IOException {
        java.io.File dir = Environment.getExternalStoragePublicDirectory(
                Environment.DIRECTORY_DOWNLOADS);
        if (!dir.exists() && !dir.mkdirs()) {
            throw new IOException("No se pudo crear la carpeta Descargas");
        }
        java.io.File target = new java.io.File(dir, fileName);
        try (java.io.FileOutputStream fos = new java.io.FileOutputStream(target)) {
            fos.write(bytes);
        }
        // Indexar para que otros exploradores lo vean.
        ContentValues values = new ContentValues();
        values.put(MediaStore.MediaColumns.DATA, target.getAbsolutePath());
        values.put(MediaStore.MediaColumns.DISPLAY_NAME, fileName);
        values.put(MediaStore.MediaColumns.MIME_TYPE, mimeTypeFor(fileName));
        values.put(MediaStore.MediaColumns.SIZE, bytes.length);
        Uri base = MediaStore.Files.getContentUri("external");
        // Si ya estaba indexado (descarga repetida), update en vez de insert.
        String selection = MediaStore.MediaColumns.DATA + "=?";
        Cursor existing = getContentResolver().query(base,
                new String[]{MediaStore.MediaColumns._ID}, selection,
                new String[]{target.getAbsolutePath()}, null);
        if (existing != null) {
            boolean had = existing.moveToFirst();
            existing.close();
            if (had) {
                getContentResolver().update(base, values, selection,
                        new String[]{target.getAbsolutePath()});
            } else {
                getContentResolver().insert(base, values);
            }
        } else {
            getContentResolver().insert(base, values);
        }
        return target.getAbsolutePath();
    }

    private static String mimeTypeFor(String fileName) {
        String ext = MimeTypeMap.getFileExtensionFromUrl(
                Uri.encode(fileName));
        String mime = ext == null ? null
                : MimeTypeMap.getSingleton().getMimeTypeFromExtension(ext.toLowerCase());
        return mime != null ? mime : "application/octet-stream";
    }
}
