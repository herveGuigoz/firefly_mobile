package com.herveguigoz.firefly

import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.net.Uri
import android.os.Binder
import android.os.IBinder
import androidx.browser.customtabs.CustomTabColorSchemeParams
import androidx.browser.customtabs.CustomTabsIntent

/**
 * This class helps managing an OAuth flow by launching AndroidXBrowser CustomTab.
 */
class OAuthManager(
        private val mClientId: String,
        private val mClientSecret: String,
        private val mAuthorizationEndpoint: String,
        private val mRedirectUri: String,
        private val mToolbarColor: String? = null) {

//    private val TAG = "OAuthManager"

    fun authorize(context: Context) {
        val uri: Uri = buildUri()

        // Open the Authorization URI in a Custom Tab.
        val builder = CustomTabsIntent.Builder()
        setToolBarColor(builder)
        val customTabsIntent = builder.build()
        val keepAliveIntent = Intent(context, KeepAliveService::class.java)
        customTabsIntent.intent.addFlags(Intent.FLAG_ACTIVITY_NO_HISTORY)
        customTabsIntent.intent.putExtra("android.support.customtabs.extra.KEEP_ALIVE", keepAliveIntent)
        customTabsIntent.launchUrl(context, uri)
    }

    // Create an authorization URI to the OAuth Endpoint.
    private fun buildUri() : Uri {
        return Uri.parse("$mAuthorizationEndpoint/oauth/authorize")
                .buildUpon()
                .appendQueryParameter("response_type", "code")
                .appendQueryParameter("client_id", mClientId)
                .appendQueryParameter("client_secret", mClientSecret) // ? is necessary
                .appendQueryParameter("redirect_uri", mRedirectUri)
                .build()
    }

    private fun setToolBarColor(builder : CustomTabsIntent.Builder) {
        //  ^               # start of the line
        //  #               # start with a number sign `#`
        //  (               # start of (group 1)
        //  [a-fA-F0-9]{6}  # support z-f, A-F and 0-9, with a length of 6
        //  |               # or
        //  [a-fA-F0-9]{3}  # support z-f, A-F and 0-9, with a length of 3
        //  )               # end of (group 1)
        //  $               # end of the line
        val hexRegex = Regex("^#([a-fA-F0-9]{6}|[a-fA-F0-9]{3})\$")

        if (mToolbarColor != null && hexRegex.matches(mToolbarColor)) {
            val colorInt: Int = Color.parseColor(mToolbarColor)
            val colorScheme  = CustomTabColorSchemeParams.Builder()
            colorScheme.setToolbarColor(colorInt)
            builder.setDefaultColorSchemeParams(colorScheme.build())
        }
    }
}

class KeepAliveService: Service() {
    companion object {
        val binder = Binder()
    }

    override fun onBind(intent: Intent): IBinder {
        return binder
    }
}
