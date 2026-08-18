package tv.kino.kino_app

import android.app.UiModeManager
import android.content.Context
import android.content.res.Configuration
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * The one thing Dart can't work out for itself: whether this is a television.
 *
 * It matters because a TV has no touchscreen and a remote instead — which in
 * Flutter means directional navigation, a visible focus ring and text sized to
 * be read from the sofa. Guessing from the screen size would get a landscape
 * tablet wrong; the system already knows, so this asks it.
 */
class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isTelevision" -> result.success(isTelevision())
                    else -> result.notImplemented()
                }
            }
    }

    private fun isTelevision(): Boolean {
        val modes = getSystemService(Context.UI_MODE_SERVICE) as UiModeManager
        return modes.currentModeType == Configuration.UI_MODE_TYPE_TELEVISION
    }

    private companion object {
        const val CHANNEL = "tv.kino/device"
    }
}
