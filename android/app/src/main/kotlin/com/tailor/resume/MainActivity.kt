package com.tailor.resume

import android.app.Activity
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.IOException

class MainActivity : FlutterActivity() {
    private val channelName = "resume_tailor/saf"
    private val createDocumentRequest = 1001
    private var pendingResult: MethodChannel.Result? = null
    private var pendingBytes: ByteArray? = null
    private var pendingFileName: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                if (call.method == "savePdf") {
                    if (pendingResult != null) {
                        result.error("BUSY", "Another save is in progress", null)
                        return@setMethodCallHandler
                    }
                    val name = call.argument<String>("name") ?: "resume.pdf"
                    val bytes = call.argument<ByteArray>("bytes")
                    if (bytes == null) {
                        result.error("INVALID", "Missing PDF bytes", null)
                        return@setMethodCallHandler
                    }
                    pendingResult = result
                    pendingBytes = bytes
                    pendingFileName = name

                    val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                        addCategory(Intent.CATEGORY_OPENABLE)
                        type = "application/pdf"
                        putExtra(Intent.EXTRA_TITLE, name)
                    }
                    startActivityForResult(intent, createDocumentRequest)
                } else {
                    result.notImplemented()
                }
            }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != createDocumentRequest) {
            return
        }
        val result = pendingResult
        val bytes = pendingBytes
        val name = pendingFileName
        pendingResult = null
        pendingBytes = null
        pendingFileName = null

        if (result == null) {
            return
        }
        if (resultCode != Activity.RESULT_OK || data?.data == null) {
            result.success("")
            return
        }
        val uri = data.data!!
        try {
            contentResolver.openOutputStream(uri)?.use { output ->
                output.write(bytes)
                output.flush()
            } ?: run {
                result.error("WRITE_FAILED", "Unable to open output stream", null)
                return
            }
            result.success(uri.toString())
        } catch (e: IOException) {
            result.error("WRITE_FAILED", e.message, null)
        }
    }
}
