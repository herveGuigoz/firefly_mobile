package com.herveguigoz.firefly

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val _channel = "com.herveguigoz.firefly_app/authenticate"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, _channel).setMethodCallHandler {
            call, result -> onMethodCall(call, result)
        }
    }

    private fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "authenticate" -> {
                handleAuthorizationCodeWithOAuthManager(call)
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun handleAuthorizationCodeWithOAuthManager(call: MethodCall) {
        val clientId: String = call.argument<String>("clientId")!!
        val clientSecret: String = call.argument<String>("clientSecret")!!
        val authorizationEndpoint: String = call.argument<String>("authorizationEndpoint")!!
        val redirectUri: String = call.argument<String>("redirectUri")!!
        val oAuthManager = OAuthManager(clientId, clientSecret, authorizationEndpoint, redirectUri)
        oAuthManager.authorize(this)
    }
}
