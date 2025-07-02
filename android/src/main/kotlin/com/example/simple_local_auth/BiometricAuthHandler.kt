package com.example.simple_local_auth

import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.CancellationSignal
import android.util.Log
import androidx.annotation.RequiresApi
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricManager.Authenticators.*
import androidx.biometric.BiometricPrompt
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

    companion object {
        private const val TAG = "SimpleLocalAuth"
        
        // For pre-API 29 devices where we need to check features directly
        private const val FEATURE_FINGERPRINT = "android.hardware.fingerprint"
        private const val FEATURE_FACE = "android.hardware.biometrics.face"
    }

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
        result.success(checkBiometricAvailability(BIOMETRIC_STRONG or BIOMETRIC_WEAK))
    }

    private fun handleAvailabilityDetails(result: Result) {
        result.success(getDetailedAvailability())
    }

    private fun handleAuthentication(call: MethodCall, result: Result) {
        val reason = call.argument<String>("reason") ?: "Authenticate"
        val preferredType = call.argument<String>("preferredType") ?: "any"
        val title = call.argument<String>("title") ?: "Authentication required"
        val subtitle = call.argument<String>("subtitle")
        val description = call.argument<String>("description") ?: ""
        val cancelButton = call.argument<String>("cancelButton") ?: "Cancel"
        val allowDeviceCredential = call.argument<Boolean>("allowDeviceCredential") ?: false
        
        authenticateUser(
            reason = reason,
            result = result,
            authType = preferredType,
            title = title,
            subtitle = subtitle,
            description = description,
            cancelButton = cancelButton,
            allowDeviceCredential = allowDeviceCredential
        )
    }

    private fun handleBiometricTypeAvailability(call: MethodCall, result: Result) {
        val type = call.argument<String>("type") ?: "any"
        result.success(checkSpecificBiometricType(type))
    }

    @RequiresApi(Build.VERSION_CODES.M)
    private fun checkBiometricAvailability(authenticators: Int): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            BiometricManager.from(context).canAuthenticate(authenticators) == BiometricManager.BIOMETRIC_SUCCESS
        } else {
            // For older devices, we need to check differently
            checkLegacyBiometricAvailability(authenticators)
        }
    }

    @RequiresApi(Build.VERSION_CODES.M)
    private fun checkLegacyBiometricAvailability(authenticators: Int): Boolean {
        val biometricManager = BiometricManager.from(context)
        
        // First check if we can authenticate at all
        val canAuth = biometricManager.canAuthenticate()
        if (canAuth != BiometricManager.BIOMETRIC_SUCCESS) {
            return false
        }

        // For API < 30, we need to check hardware features directly
        val pm = context.packageManager
        
        return when {
            authenticators and BIOMETRIC_STRONG != 0 -> {
                // Check for fingerprint
                pm.hasSystemFeature(FEATURE_FINGERPRINT)
            }
            authenticators and BIOMETRIC_WEAK != 0 -> {
                // Check for face unlock (only available on API 29+)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    pm.hasSystemFeature(FEATURE_FACE)
                } else {
                    false
                }
            }
            else -> true
        }
    }

    private fun checkSpecificBiometricType(type: String): Boolean {
        return when (type) {
            "fingerprint" -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                    checkBiometricAvailability(BIOMETRIC_STRONG)
                } else {
                    context.packageManager.hasSystemFeature(FEATURE_FINGERPRINT)
                }
            }
            "face" -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                    checkBiometricAvailability(BIOMETRIC_WEAK)
                } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    context.packageManager.hasSystemFeature(FEATURE_FACE)
                } else {
                    false
                }
            }
            else -> checkBiometricAvailability(BIOMETRIC_STRONG or BIOMETRIC_WEAK)
        }
    }

    @RequiresApi(Build.VERSION_CODES.M)
    private fun getDetailedAvailability(): Map<String, Any> {
        return mapOf(
            "hasHardware" to hasBiometricHardware(),
            "hasEnrolledBiometrics" to checkBiometricAvailability(BIOMETRIC_STRONG or BIOMETRIC_WEAK),
            "isFingerprintAvailable" to checkSpecificBiometricType("fingerprint"),
            "isFaceAvailable" to checkSpecificBiometricType("face"),
            "isIrisAvailable" to false, // Iris is rarely supported
            "isDeviceCredentialAvailable" to isDeviceCredentialAvailable(),
            "biometricStrength" to getBiometricStrength()
        )
    }

    private fun hasBiometricHardware(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            BiometricManager.from(context).canAuthenticate(BIOMETRIC_STRONG or BIOMETRIC_WEAK) != 
                BiometricManager.BIOMETRIC_ERROR_NO_HARDWARE
        } else {
            context.packageManager.hasSystemFeature(FEATURE_FINGERPRINT) || 
            (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q && 
             context.packageManager.hasSystemFeature(FEATURE_FACE))
        }
    }

    private fun isDeviceCredentialAvailable(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            BiometricManager.from(context).canAuthenticate(DEVICE_CREDENTIAL) == 
                BiometricManager.BIOMETRIC_SUCCESS
        } else {
            false
        }
    }

    private fun getBiometricStrength(): String {
        return when {
            checkSpecificBiometricType("fingerprint") -> "strong"
            checkSpecificBiometricType("face") -> "weak"
            else -> "none"
        }
    }

    private fun authenticateUser(
        reason: String,
        result: Result,
        authType: String,
        title: String = "Authentication required",
        subtitle: String? = null,
        description: String = "",
        cancelButton: String = "Cancel",
        allowDeviceCredential: Boolean = false
    ) {
        // Check general availability first
        if (!hasBiometricHardware()) {
            result.error("NO_HARDWARE", "No biometric hardware available", null)
            return
        }
        

        // Check specific type if requested
        if (authType != "any" && !checkSpecificBiometricType(authType)) {
            result.error(
                "TYPE_UNAVAILABLE",
                "Requested biometric type ($authType) not available",
                authType
            )
            return
        }

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
        val authenticators = getAuthenticators(authType, allowDeviceCredential)

        try {
            val builder = BiometricPrompt.PromptInfo.Builder()
                .setTitle(title)
                .setSubtitle(subtitle ?: reason)
                .setDescription(description)
                .setNegativeButtonText(cancelButton)

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                builder.setAllowedAuthenticators(authenticators)
            } else {
                // For older versions, we can't specify device credential flag
                builder.setDeviceCredentialAllowed(false)
            }

            val promptInfo = builder.build()
            val biometricPrompt = BiometricPrompt(activity, executor, createAuthCallback())
            biometricPrompt.authenticate(promptInfo)
        } catch (e: Exception) {
            Log.e(TAG, "Authentication failed", e)
            currentResult?.error("AUTHENTICATION_FAILED", e.message, null)
            cleanup()
        }
    }

    private fun getAuthenticators(authType: String, allowDeviceCredential: Boolean): Int {
        var authenticators = when (authType) {
            "fingerprint" -> BIOMETRIC_STRONG
            "face" -> BIOMETRIC_WEAK
            else -> BIOMETRIC_STRONG or BIOMETRIC_WEAK
        }

        if (allowDeviceCredential && Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            authenticators = authenticators or DEVICE_CREDENTIAL
        }

        return authenticators
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

            BiometricPrompt.ERROR_NO_BIOMETRICS -> currentResult?.error(
                "NO_ENROLLED_BIOMETRICS",
                "No biometrics enrolled on this device",
                null
            )

            else -> currentResult?.error(
                "AUTHENTICATION_ERROR",
                "Authentication error: $errString (code: $errorCode)",
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