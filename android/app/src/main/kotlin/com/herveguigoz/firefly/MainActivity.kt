package com.herveguigoz.firefly

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Bundle
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel


class MainActivity: FlutterActivity() {
    private val _channel = "com.herveguigoz.firefly/channel"
    private val _events = "com.herveguigoz.firefly/events"
    private var _startString: String? = null
    private var linksReceiver: BroadcastReceiver? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        _startString = intent.data?.toString()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        if (intent.action === Intent.ACTION_VIEW) {
            linksReceiver?.onReceive(this.applicationContext, intent)
        }
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, _channel).setMethodCallHandler {
            call, result -> onMethodCall(call, result)
        }

        EventChannel(flutterEngine.dartExecutor, _events).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(args: Any?, events: EventChannel.EventSink) {
                    linksReceiver = createChangeReceiver(events)
                }

                override fun onCancel(args: Any?) {
                    linksReceiver = null
                }
            }
        )
    }

    private fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "initialLink" -> {
                if (_startString != null) {
                    result.success(_startString)
                }
            }
            "authenticate" -> {
                handleAuthorizationCodeWithOAuthManager(call)
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    fun createChangeReceiver(events: EventChannel.EventSink): BroadcastReceiver? {
        return object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                // NOTE: assuming intent.getAction() is Intent.ACTION_VIEW
                val dataString = intent.dataString ?:
                events.error("UNAVAILABLE", "Link unavailable", null)
                events.success(dataString)
            }
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
