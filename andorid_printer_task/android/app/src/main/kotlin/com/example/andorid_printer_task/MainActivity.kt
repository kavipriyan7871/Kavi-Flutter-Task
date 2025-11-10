package com.example.andorid_printer_task

import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "z91_printer"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "printText" -> {
                        val text: String? = call.argument("text")
                        if (text.isNullOrEmpty()) {
                            result.error("ARG_ERR", "Text missing", null)
                        } else {
                            Thread {
                                val ok = printWithDriverManager(text)
                                runOnUiThread {
                                    if (ok) result.success("printed")
                                    else result.error("PRINT_ERR", "Failed to print", null)
                                }
                            }.start()
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun printWithDriverManager(text: String): Boolean {
        Log.i("Z91Printer", "🟣 Starting print process")

        return try {
            // 1) DriverManager -> getInstance
            val driverClass = Class.forName("com.zcs.sdk.DriverManager")
            val getInstance = driverClass.getMethod("getInstance")
            val driverManager = getInstance.invoke(null)
            Log.i("Z91Printer", "✔ DriverManager.getInstance() OK")

            // 2) Get printer
            val getPrinter = driverClass.getMethod("getPrinter")
            val printer = getPrinter.invoke(driverManager)
            if (printer == null) {
                Log.e("Z91Printer", "❌ Printer is null (hardware not ready)")
                return false
            }
            Log.i("Z91Printer", "✔ Printer instance found: ${printer.javaClass.name}")

            // 3) Dump all printer methods (for debugging)
            Log.i("Z91Printer", "📋 Listing all methods in ${printer.javaClass.name}")
            printer.javaClass.methods.forEach { m ->
                val params = m.parameterTypes.joinToString { it.simpleName ?: "?" }
                Log.i("Z91Printer", "➡ ${m.name}($params)")
            }

            // 4) Prepare format if available
            val format = try {
                val formatClass = Class.forName("com.zcs.sdk.print.PrnStrFormat")
                formatClass.getConstructor().newInstance()
            } catch (e: Exception) {
                Log.w("Z91Printer", "⚠️ PrnStrFormat not available or failed to instantiate: ${e.message}")
                null
            }

            // 5) Try alignment (best-effort)
            if (format != null) {
                try {
                    val alignEnumClass = Class.forName("com.zcs.sdk.print.PrnAlignTypeEnum")
                    val alignField = alignEnumClass.fields.firstOrNull {
                        it.name.contains("CENTER", true) || it.name.contains("MIDDLE", true)
                    }?.get(null)
                    val setAlign = format.javaClass.methods.find { it.name.contains("Align", true) }
                    if (setAlign != null && alignField != null) {
                        setAlign.invoke(format, alignField)
                        Log.i("Z91Printer", "✔ Alignment applied via ${setAlign.name}")
                    } else {
                        Log.w("Z91Printer", "⚠️ No alignment method/constant applied")
                    }
                } catch (e: Exception) {
                    Log.w("Z91Printer", "⚠️ Alignment skipped: ${e.message}")
                }
            }

            // 6) Try to set font (best-effort, use PrnTextFont if present)
            if (format != null) {
                try {
                    val fontEnumClass = Class.forName("com.zcs.sdk.print.PrnTextFont")
                    val fontField = fontEnumClass.fields.firstOrNull()?.get(null)
                    val setFontMethod = format.javaClass.methods.find { it.name.contains("Font", true) && it.parameterTypes.size == 1 }
                    if (fontField != null && setFontMethod != null) {
                        setFontMethod.invoke(format, fontField)
                        Log.i("Z91Printer", "✔ Font applied via ${setFontMethod.name}")
                    } else {
                        Log.w("Z91Printer", "⚠️ Font not applied (no matching constant/method found)")
                    }
                } catch (e: Exception) {
                    Log.w("Z91Printer", "⚠️ Font setup skipped: ${e.message}")
                }
            }

            // 7) Append text into buffer (if API supports append)
            try {
                val appendMethod = printer.javaClass.methods.find { it.name.contains("setPrintAppendString", true) }
                if (appendMethod != null && format != null) {
                    appendMethod.invoke(printer, text + "\n", format)
                    appendMethod.invoke(printer, "Powered by Flutter\n", format)
                    Log.i("Z91Printer", "✔ Text appended for print job (append API)")
                } else {
                    val printTextMethod = printer.javaClass.methods.find { it.name.equals("printText", true) }
                    if (printTextMethod != null) {
                        printTextMethod.invoke(printer, text + "\nPowered by Flutter\n")
                        Log.i("Z91Printer", "✔ Used printText() fallback")
                    } else {
                        Log.w("Z91Printer", "⚠️ No append/printText method found; attempting print-start directly")
                    }
                }
            } catch (e: Exception) {
                Log.w("Z91Printer", "⚠️ Append/printText attempt failed: ${e.message}")
            }

            // 8) Find candidate print/start methods
            val candidates = printer.javaClass.methods.filter {
                val n = it.name.lowercase()
                n.contains("print") || n.contains("start") || n.contains("paper") || n.contains("begin")
            }.distinctBy { it.name }

            Log.i("Z91Printer", "🔍 Found ${candidates.size} candidate print/start methods.")

            // helper: create sensible default arg for a parameter type
            fun defaultForParam(p: Class<*>): Any? {
                return when {
                    p == java.lang.Integer.TYPE || p == java.lang.Integer::class.java -> 0
                    p == java.lang.Long.TYPE || p == java.lang.Long::class.java -> 0L
                    p == java.lang.Boolean.TYPE || p == java.lang.Boolean::class.java -> false
                    p == java.lang.Byte.TYPE || p == java.lang.Byte::class.java -> 0.toByte()
                    p == java.lang.Short.TYPE || p == java.lang.Short::class.java -> 0.toShort()
                    p == java.lang.Character.TYPE || p == java.lang.Character::class.java -> '\u0000'
                    p == java.lang.Float.TYPE || p == java.lang.Float::class.java -> 0f
                    p == java.lang.Double.TYPE || p == java.lang.Double::class.java -> 0.0
                    p == java.lang.String::class.java -> ""
                    p == ByteArray::class.java -> ByteArray(0)
                    else -> null // for objects we pass null (may or may not work)
                }
            }

            // 9) Try to invoke candidates. First try zero-arg ones, then try with default args.
            var started = false
            for (m in candidates) {
                try {
                    Log.i("Z91Printer", "🧩 Candidate: ${m.name} (params: ${m.parameterCount})")
                    if (m.parameterCount == 0) {
                        // try no-arg
                        try {
                            m.invoke(printer)
                            Log.i("Z91Printer", "✅ Print started via ${m.name} (no-arg)")
                            started = true
                            break
                        } catch (inner: Throwable) {
                            Log.w("Z91Printer", "⚠️ ${m.name} no-arg invoke failed: ${inner.message}")
                        }
                    }

                    // try with default args (single- and multi- param support)
                    val params = m.parameterTypes
                    val args = arrayOfNulls<Any>(params.size)
                    var canFill = true
                    for (i in params.indices) {
                        val def = defaultForParam(params[i])
                        if (def == null && params[i].isPrimitive) {
                            // cannot pass null to primitive param -> can't try this signature safely
                            canFill = false
                            break
                        }
                        args[i] = def
                    }
                    if (!canFill) {
                        Log.i("Z91Printer", "→ Skipping ${m.name} because signature contains unsupported primitive/object types")
                        continue
                    }

                    try {
                        m.invoke(printer, *args)
                        Log.i("Z91Printer", "✅ Print started via ${m.name} (with default args)")
                        started = true
                        break
                    } catch (inner: Throwable) {
                        val cause = if (inner.cause != null) inner.cause!!.message else inner.message
                        Log.w("Z91Printer", "⚠️ ${m.name} invoke with defaults failed: $cause")
                    }
                } catch (e: Exception) {
                    Log.w("Z91Printer", "⚠️ Candidate ${m.name} failed: ${e.message}")
                }
            }

            if (!started) {
                Log.e("Z91Printer", "❌ No print/start method worked. See candidate list above. Copy the '➡' and '🧩 Candidate' lines and share them.")
            } else {
                Log.i("Z91Printer", "🎉 Print request completed (method invoked).")
            }

            started
        } catch (e: Exception) {
            Log.e("Z91Printer", "❌ Printing failed: ${e.message}", e)
            false
        }
    }
}
