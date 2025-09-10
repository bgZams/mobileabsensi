package com.example.mobileabsensi // Ganti dengan nama paket Anda
import android.content.ContentValues
import android.content.Context
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.provider.MediaStore
import android.view.WindowManager
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.OutputStream

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.mobileabsensi/gallery_saver"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Set secure flag by default
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE
        )
    }

    override fun onResume() {
        super.onResume()
        // Ensure secure flag is set when app is resumed
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE
        )
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
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
        val resolver = context.contentResolver
        val contentValues = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, "$name.png")
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
            
            bitmap.compress(android.graphics.Bitmap.CompressFormat.PNG, 100, outputStream)
            
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
        }
    }
}