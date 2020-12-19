package com.herveguigoz.firefly

import android.content.Context
import android.content.Intent.FLAG_ACTIVITY_NEW_TASK
import android.net.Uri
import android.util.Log
import androidx.browser.customtabs.CustomTabsIntent

/**
 * This class helps managing an OAuth flow. It was created with the goal of demonstrating how to
 * use Custom Tabs to handle the authorization flow and is not meant as a complete implementation
 * of the OAuth protocol. We recommend checking out https://github.com/openid/AppAuth-Android for
 * a comprehensive implementation of the OAuth protocol.
 */
class OAuthManager(
        private val mClientId: String,
        private val mClientSecret: String,
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
        customTabsIntent.intent.flags = FLAG_ACTIVITY_NEW_TASK
        customTabsIntent.launchUrl(context, uri)
    }
}