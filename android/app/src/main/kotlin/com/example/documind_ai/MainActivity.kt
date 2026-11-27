package com.example.documind_ai

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * Receives files shared to DocuMind from other apps ("Share" or "Open with").
 * Each shared file is copied into the app's cache and handed to Dart as
 * {path, name}. Dart pulls files that arrived at launch ("takeInitial") and
 * is pushed files that arrive while the app is open ("shared").
 */
class MainActivity : FlutterActivity() {
    private var channel: MethodChannel? = null
    private var pending: List<Map<String, String>>? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val ch = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "documind/share")
        ch.setMethodCallHandler { call, result ->
            if (call.method == "takeInitial") {
                result.success(pending ?: emptyList<Map<String, String>>())
                pending = null
            } else {
                result.notImplemented()
            }
        }
        channel = ch
        pending = extractFiles(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val files = extractFiles(intent)
        if (!files.isNullOrEmpty()) channel?.invokeMethod("shared", files)
    }

    private fun extractFiles(intent: Intent?): List<Map<String, String>>? {
        if (intent == null) return null
        val uris = ArrayList<Uri>()
        when (intent.action) {
            Intent.ACTION_SEND -> streamExtra(intent)?.let { uris.add(it) }
            Intent.ACTION_SEND_MULTIPLE -> uris.addAll(streamListExtra(intent))
            Intent.ACTION_VIEW -> intent.data?.let { uris.add(it) }
            else -> return null
        }
        // Handled: a rotation or recreation must not import the files again.
        intent.action = Intent.ACTION_MAIN
        val out = ArrayList<Map<String, String>>()
        for (uri in uris) {
            try {
                copyToCache(uri)?.let { out.add(it) }
            } catch (_: Exception) {
                // Skip a file that cannot be read; the others still import.
            }
        }
        return out
    }

    @Suppress("DEPRECATION")
    private fun streamExtra(intent: Intent): Uri? =
        if (Build.VERSION.SDK_INT >= 33) intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
        else intent.getParcelableExtra(Intent.EXTRA_STREAM)

    @Suppress("DEPRECATION")
    private fun streamListExtra(intent: Intent): List<Uri> =
        (if (Build.VERSION.SDK_INT >= 33) intent.getParcelableArrayListExtra(Intent.EXTRA_STREAM, Uri::class.java)
        else intent.getParcelableArrayListExtra<Uri>(Intent.EXTRA_STREAM)) ?: emptyList()

    private fun displayName(uri: Uri): String {
        var name: String? = null
        if (uri.scheme == "content") {
            contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)?.use { c ->
                if (c.moveToFirst()) name = c.getString(0)
            }
        }
        var result = name ?: uri.lastPathSegment ?: "shared_file"
        if (!result.contains('.')) {
            // No extension in the name: take it from the file's type.
            val ext = when (contentResolver.getType(uri)) {
                "application/pdf" -> ".pdf"
                "application/vnd.openxmlformats-officedocument.wordprocessingml.document" -> ".docx"
                "text/plain" -> ".txt"
                "application/rtf", "text/rtf" -> ".rtf"
                "image/png" -> ".png"
                "image/jpeg" -> ".jpg"
                else -> ""
            }
            result += ext
        }
        return result
    }

    private fun copyToCache(uri: Uri): Map<String, String>? {
        val name = displayName(uri)
        val dir = File(cacheDir, "shared_in").apply { mkdirs() }
        val safe = name.replace(Regex("[^a-zA-Z0-9._-]"), "_")
        val target = File(dir, "${System.currentTimeMillis()}_$safe")
        contentResolver.openInputStream(uri)?.use { input ->
            target.outputStream().use { output -> input.copyTo(output) }
        } ?: return null
        return mapOf("path" to target.absolutePath, "name" to name)
    }
}
