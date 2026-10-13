package ke.co.oyukojoseph.attendancepayroll

import android.content.pm.ApplicationInfo
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Payroll and attendance are sensitive. In release builds the window is
        // marked secure: it is blacked out in the recent-apps switcher and cannot
        // be screenshotted or screen-recorded. Documents leave the app through
        // the PDF and share features instead. Debug builds stay capturable so
        // development screenshots keep working.
        val debuggable = (applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0
        if (!debuggable) {
            window.setFlags(
                WindowManager.LayoutParams.FLAG_SECURE,
                WindowManager.LayoutParams.FLAG_SECURE,
            )
        }
    }
}
