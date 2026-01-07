package com.pasbar.mobileabsensi

import android.content.ContentValues
import android.content.Context
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Debug
import android.os.Environment
import android.provider.MediaStore
import android.provider.Settings
import android.view.WindowManager
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.OutputStream

class MainActivity: FlutterActivity() {
    
    private val CHANNEL = "com.pasbar.mobileabsensi/gallery_saver"
    private val CHANNEL_DEVICE = "com.example.app/device_id"
    private val CHANNEL_SECURITY = "com.example.app/security"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE
        )

        // Pengecekan Developer Mode secara Native
        val isDevMode = Settings.Global.getInt(
            contentResolver, 
            Settings.Global.DEVELOPMENT_SETTINGS_ENABLED, 0
        ) != 0

        val isDebuggerAttached = Debug.isDebuggerConnected()

        // Menggantikan BuildConfig.DEBUG dengan mengecek flag applicationInfo
        val isDebuggable = (applicationInfo.flags and android.content.pm.ApplicationInfo.FLAG_DEBUGGABLE) != 0

        // Logika: Hanya tutup jika Release Mode, Dev Options Aktif, dan Kabel tidak dicolok debugger
        if (isDevMode && !isDebuggerAttached && !isDebuggable) {
            finishAffinity()
            System.exit(0)
        }
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_SECURITY).setMethodCallHandler { call, result ->
            if (call.method == "isDebuggerConnected") {
                val connected = Debug.isDebuggerConnected()
                val isDebuggable = (applicationContext.applicationInfo.flags and android.content.pm.ApplicationInfo.FLAG_DEBUGGABLE) != 0
                val isDevMode = Settings.Global.getInt(
                    context.contentResolver, 
                    Settings.Global.DEVELOPMENT_SETTINGS_ENABLED, 0
                ) != 0
                result.success(connected || isDebuggable || isDevMode)
            } else {
                result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_DEVICE).setMethodCallHandler { call, result ->
            if (call.method == "getAndroidID") {
                val androidId = Settings.Secure.getString(contentResolver, Settings.Secure.ANDROID_ID)
                if (androidId != null) {
                    result.success(androidId)
                } else {
                    result.error("UNAVAILABLE", "ID tidak ditemukan.", null)
                }
            } else {
                result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "saveImage") {
                val bytes = call.argument<ByteArray>("bytes")
                val name = call.argument<String>("name")
                if (bytes != null && name != null) {
                    saveImageToGallery(this, bytes, name, result)
                } else {
                    result.error("INVALID_ARGUMENTS", "Byte array or name is null", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun saveImageToGallery(context: Context, bytes: ByteArray, name: String, result: MethodChannel.Result) {
        val bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
        if (bitmap == null) {
            result.error("DECODE_FAILED", "Failed to decode image bytes", null)
            return
        }
        
        val resolver = context.contentResolver
        val timestamp = System.currentTimeMillis()
        val contentValues = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, "${name}_${timestamp}.png")
            put(MediaStore.MediaColumns.MIME_TYPE, "image/png")
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_PICTURES)
                put(MediaStore.MediaColumns.IS_PENDING, 1)
            }
        }
        
        var uri: Uri? = null
        var outputStream: OutputStream? = null
        try {
            val collection = MediaStore.Images.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
            uri = resolver.insert(collection, contentValues)
            if (uri == null) {
                throw Exception("Failed to create new MediaStore record.")
            }
            
            outputStream = resolver.openOutputStream(uri)
            if (outputStream == null) {
                throw Exception("Failed to get output stream.")
            }
            
            if (!bitmap.compress(android.graphics.Bitmap.CompressFormat.PNG, 100, outputStream)) {
                throw Exception("Failed to compress bitmap.")
            }
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                contentValues.clear()
                contentValues.put(MediaStore.MediaColumns.IS_PENDING, 0)
                resolver.update(uri, contentValues, null, null)
            }

            result.success(uri.toString())
        } catch (e: Exception) {
            if (uri != null) {
                resolver.delete(uri, null, null)
            }
            result.error("SAVE_FAILED", e.message, e.toString())
        } finally {
            outputStream?.close()
            bitmap.recycle() // Penting!
        }
    }
}