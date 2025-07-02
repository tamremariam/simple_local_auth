package com.example.simple_local_auth

import android.app.Activity
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodChannel

class SimpleLocalAuthPlugin: FlutterPlugin, ActivityAware {
    private lateinit var channel: MethodChannel
    private lateinit var authHandler: SimpleLocalAuthHandler
    private var activityBinding: ActivityPluginBinding? = null

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "simple_local_auth")
        authHandler = SimpleLocalAuthHandler(flutterPluginBinding.applicationContext)
        channel.setMethodCallHandler { call, result ->
            authHandler.handle(call, result)
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityBinding = binding
        authHandler.setActivityProvider { binding.activity }
    }

    override fun onDetachedFromActivity() {
        activityBinding = null
        authHandler.setActivityProvider { 
            throw IllegalStateException("No activity available")
        }
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        onDetachedFromActivity()
    }
}