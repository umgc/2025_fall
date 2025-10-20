package com.example.care_connect_app

import android.content.Context
import android.graphics.Rect
import android.net.Uri
import com.google.android.gms.tasks.Tasks
import com.google.mlkit.vision.barcode.BarcodeScannerOptions
import com.google.mlkit.vision.barcode.BarcodeScanning
import com.google.mlkit.vision.barcode.common.Barcode
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

object OcrHandler : MethodChannel.MethodCallHandler {

    private lateinit var channel: MethodChannel
    private lateinit var appContext: Context

    fun register(context: Context, messenger: BinaryMessenger) {
        appContext = context.applicationContext
        channel = MethodChannel(messenger, "care_connect/ocr")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "recognizeText" -> recognizeText(call, result)
            "analyze" -> analyze(call, result)
            else -> result.notImplemented()
        }
    }

    private fun recognizeText(call: MethodCall, result: MethodChannel.Result) {
        val args = call.arguments as? Map<*, *>
        val paths = (args?.get("paths") as? List<*>)?.filterIsInstance<String>() ?: emptyList()

        Thread {
            try {
                val recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
                val outputs = ArrayList<Map<String, Any?>>(paths.size)
                for (path in paths) {
                    val img = InputImage.fromFilePath(appContext, Uri.fromFile(File(path)))
                    val vt = Tasks.await(recognizer.process(img))
                    outputs.add(mapOf("path" to path, "text" to vt.text))
                }
                android.os.Handler(appContext.mainLooper).post { result.success(outputs) }
            } catch (e: Exception) {
                android.os.Handler(appContext.mainLooper).post { result.error("OCR_ERROR", e.message, null) }
            }
        }.start()
    }

    private fun analyze(call: MethodCall, result: MethodChannel.Result) {
        val args = call.arguments as? Map<*, *>
        val paths = (args?.get("paths") as? List<*>)?.filterIsInstance<String>() ?: emptyList()

        Thread {
            try {
                val recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
                val barcodeScanner = BarcodeScanning.getClient(
                    BarcodeScannerOptions.Builder()
                        .setBarcodeFormats(Barcode.FORMAT_QR_CODE) // add other formats if needed
                        .build()
                )

                val outputs = ArrayList<Map<String, Any?>>(paths.size)
                for (path in paths) {
                    val file = File(path)
                    val img = InputImage.fromFilePath(appContext, Uri.fromFile(file))

                    val vt = Tasks.await(recognizer.process(img))
                    val bcs = Tasks.await(barcodeScanner.process(img))

                    val width = (img.width.takeIf { it > 0 } ?: 1).toFloat()
                    val height = (img.height.takeIf { it > 0 } ?: 1).toFloat()

                    // Lines with nullable box
                    val lines = mutableListOf<Map<String, Any?>>()
                    for (block in vt.textBlocks) {
                        for (line in block.lines) {
                            val box = rectToNorm(line.boundingBox, width, height)
                            lines.add(mapOf("text" to line.text, "box" to box))
                        }
                    }

                    // QR values with nullable box
                    val qrcodes = mutableListOf<Map<String, Any?>>()
                    for (bc in bcs) {
                        val raw = bc.rawValue ?: ""
                        val box = rectToNorm(bc.boundingBox, width, height)
                        qrcodes.add(mapOf("value" to raw, "box" to box))
                    }

                    outputs.add(
                        mapOf(
                            "path" to path,
                            "text" to vt.text,
                            "lines" to lines,
                            "qrcodes" to qrcodes
                        )
                    )
                }

                android.os.Handler(appContext.mainLooper).post { result.success(outputs) }
            } catch (e: Exception) {
                android.os.Handler(appContext.mainLooper).post { result.error("ANALYZE_ERROR", e.message, null) }
            }
        }.start()
    }

    private fun rectToNorm(r: Rect?, w: Float, h: Float): Map<String, Double>? {
        if (r == null || w <= 0f || h <= 0f) return null
        val l = (r.left / w).coerceIn(0f, 1f).toDouble()
        val t = (r.top / h).coerceIn(0f, 1f).toDouble()
        val rw = (r.width() / w).coerceIn(0f, 1f).toDouble()
        val rh = (r.height() / h).coerceIn(0f, 1f).toDouble()
        return mapOf("l" to l, "t" to t, "w" to rw, "h" to rh)
    }
}
