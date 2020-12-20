package com.herveguigoz.firefly

import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.Intent.FLAG_ACTIVITY_NEW_TASK
import android.net.Uri
import android.os.Binder
import android.os.IBinder
import android.util.Log
import androidx.browser.customtabs.CustomTabsIntent

/**
 * This class helps managing an OAuth flow by launching AndroidXBrowser CustomTab.
 */
class OAuthManager(
        private val mClientId: String,
//        private val mClientSecret: String,
        private val mAuthorizationEndpoint: String,
        private val mRedirectUri: String) {

    private val TAG = "OAuthManager"

    fun authorize(context: Context) {
        // Create an authorization URI to the OAuth Endpoint.
        val uri: Uri = Uri.parse("$mAuthorizationEndpoint/oauth/authorize")
                .buildUpon()
                .appendQueryParameter("response_type", "code")
                .appendQueryParameter("client_id", mClientId)
                .appendQueryParameter("redirect_uri", mRedirectUri)
                .build()

        // Open the Authorization URI in a Custom Tab.
        val customTabsIntent = CustomTabsIntent.Builder().build()
        val keepAliveIntent = Intent(context, KeepAliveService::class.java)
        customTabsIntent.intent.addFlags(Intent.FLAG_ACTIVITY_NO_HISTORY)
        customTabsIntent.intent.putExtra("android.support.customtabs.extra.KEEP_ALIVE", keepAliveIntent)
        customTabsIntent.launchUrl(context, uri)
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
