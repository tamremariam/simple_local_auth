package com.example.simple_local_auth

import android.app.Activity
import android.content.Context
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import android.os.Build
import android.os.CancellationSignal
import androidx.annotation.RequiresApi
import androidx.core.content.ContextCompat
import androidx.fragment.app.FragmentActivity
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.Result
import java.util.concurrent.Executors

class SimpleLocalAuthHandler(private val context: Context) {
    private var cancellationSignal: CancellationSignal? = null
    private var currentResult: Result? = null
    private var activityProvider: (() -> Activity)? = null

    fun setActivityProvider(provider: () -> Activity) {
        activityProvider = provider
    }

    @RequiresApi(Build.VERSION_CODES.M)
    fun handle(call: MethodCall, result: Result) {
        when (call.method) {
            "isBiometricAvailable" -> handleBiometricAvailability(call, result)
            "getAvailabilityDetails" -> handleAvailabilityDetails(result)
            "authenticate" -> handleAuthentication(call, result)
            "isBiometricTypeAvailable" -> handleBiometricTypeAvailability(call, result)
            else -> result.notImplemented()
        }
    }

    private fun handleBiometricAvailability(call: MethodCall, result: Result) {
        result.success(checkBiometricAvailability(
            BiometricManager.Authenticators.BIOMETRIC_STRONG or
            BiometricManager.Authenticators.BIOMETRIC_WEAK
        ))
    }

    private fun handleAvailabilityDetails(result: Result) {
        result.success(getDetailedAvailability())
    }

    private fun handleAuthentication(call: MethodCall, result: Result) {
        val reason = call.argument<String>("reason") ?: "Authenticate"
        val preferredType = call.argument<String>("preferredType") ?: "any"
        authenticateUser(reason, result, preferredType)
    }

    private fun handleBiometricTypeAvailability(call: MethodCall, result: Result) {
        val type = call.argument<String>("type") ?: "any"
        result.success(checkBiometricAvailability(
            when (type) {
                "fingerprint" -> BiometricManager.Authenticators.BIOMETRIC_STRONG
                "face" -> BiometricManager.Authenticators.BIOMETRIC_WEAK
                else -> BiometricManager.Authenticators.BIOMETRIC_STRONG or
                       BiometricManager.Authenticators.BIOMETRIC_WEAK
            }
        ))
    }

    @RequiresApi(Build.VERSION_CODES.M)
    private fun checkBiometricAvailability(authenticators: Int): Boolean {
        val biometricManager = BiometricManager.from(context)
        return biometricManager.canAuthenticate(authenticators) == BiometricManager.BIOMETRIC_SUCCESS
    }

    @RequiresApi(Build.VERSION_CODES.M)
    private fun getDetailedAvailability(): Map<String, Any> {
        return mapOf(
            "hasHardware" to (BiometricManager.from(context).canAuthenticate(
                BiometricManager.Authenticators.BIOMETRIC_STRONG or
                BiometricManager.Authenticators.BIOMETRIC_WEAK
            ) != BiometricManager.BIOMETRIC_ERROR_NO_HARDWARE),
            "hasEnrolledBiometrics" to checkBiometricAvailability(
                BiometricManager.Authenticators.BIOMETRIC_STRONG or
                BiometricManager.Authenticators.BIOMETRIC_WEAK
            ),
            "isFingerprintAvailable" to checkBiometricAvailability(
                BiometricManager.Authenticators.BIOMETRIC_STRONG
            ),
            "isFaceAvailable" to checkBiometricAvailability(
                BiometricManager.Authenticators.BIOMETRIC_WEAK
            )
        )
    }

    @RequiresApi(Build.VERSION_CODES.M)
    private fun authenticateUser(reason: String, result: Result, authType: String) {
        cancelCurrentAuthentication()
        currentResult = result

        val activity = getActivity() ?: run {
            result.error("NO_ACTIVITY", "Authentication requires a foreground activity", null)
            return
        }

        if (activity.isFinishing || activity.isDestroyed) {
            result.error("INVALID_ACTIVITY_STATE", "Activity is not in a valid state", null)
            return
        }

        if (activity !is FragmentActivity) {
            result.error(
                "INVALID_ACTIVITY_TYPE", 
                "Authentication requires FragmentActivity", 
                activity.javaClass.simpleName
            )
            return
        }

        val executor = Executors.newSingleThreadExecutor()
        val authenticators = getAuthenticators(authType)

        try {
            val promptInfo = BiometricPrompt.PromptInfo.Builder()
                .setTitle("Authentication required")
                .setSubtitle(reason)
                .setNegativeButtonText("Cancel")
                .setAllowedAuthenticators(authenticators)
                .build()

            val biometricPrompt = BiometricPrompt(activity, executor, createAuthCallback())
            biometricPrompt.authenticate(promptInfo)
        } catch (e: Exception) {
            currentResult?.error("AUTHENTICATION_FAILED", e.message, null)
            cleanup()
        }
    }

    private fun getAuthenticators(authType: String): Int {
        return when (authType) {
            "fingerprint" -> BiometricManager.Authenticators.BIOMETRIC_STRONG
            "face" -> BiometricManager.Authenticators.BIOMETRIC_WEAK
            else -> BiometricManager.Authenticators.BIOMETRIC_STRONG or 
                   BiometricManager.Authenticators.BIOMETRIC_WEAK
        }
    }

    private fun createAuthCallback(): BiometricPrompt.AuthenticationCallback {
        return object : BiometricPrompt.AuthenticationCallback() {
            override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) {
                currentResult?.success(true)
                cleanup()
            }
            
            override fun onAuthenticationFailed() {
                // Don't complete here - wait for success or error
            }
            
            override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                handleAuthError(errorCode, errString)
                cleanup()
            }
        }
    }

    private fun handleAuthError(errorCode: Int, errString: CharSequence) {
        when (errorCode) {
            BiometricPrompt.ERROR_NEGATIVE_BUTTON,
            BiometricPrompt.ERROR_USER_CANCELED,
            BiometricPrompt.ERROR_CANCELED -> currentResult?.success(false)
            
            BiometricPrompt.ERROR_LOCKOUT -> currentResult?.error(
                "LOCKED_OUT",
                "Too many failed attempts. Biometric authentication is temporarily disabled.",
                null
            )
            
            BiometricPrompt.ERROR_LOCKOUT_PERMANENT -> currentResult?.error(
                "LOCKED_OUT_PERMANENT",
                "Too many failed attempts. Please authenticate with device credentials.",
                null
            )
            
            BiometricPrompt.ERROR_HW_NOT_PRESENT -> currentResult?.error(
                "HARDWARE_UNAVAILABLE",
                "Required biometric hardware is not available",
                null
            )
            
            else -> currentResult?.error(
                "AUTHENTICATION_ERROR",
                "Authentication error: $errString",
                errorCode
            )
        }
    }

   private fun getActivity(): Activity {
    return activityProvider?.invoke() ?: throw IllegalStateException("No activity available")
}


    private fun cancelCurrentAuthentication() {
        cancellationSignal?.cancel()
        currentResult?.success(false)
        cleanup()
    }

    private fun cleanup() {
        cancellationSignal = null
        currentResult = null
    }
}