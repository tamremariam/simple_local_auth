package com.example.simple_local_auth

import android.content.Context
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import android.os.Build
import android.os.CancellationSignal
import androidx.annotation.RequiresApi
import androidx.fragment.app.FragmentActivity
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.Result
import java.util.concurrent.Executors

class SimpleLocalAuthHandler(private val context: Context) {
    private var cancellationSignal: CancellationSignal? = null
    private var currentResult: Result? = null

    @RequiresApi(Build.VERSION_CODES.M)
    fun handle(call: MethodCall, result: Result) {
        when (call.method) {
            "isBiometricAvailable" -> {
                result.success(checkBiometricAvailability(
                    BiometricManager.Authenticators.BIOMETRIC_STRONG or
                    BiometricManager.Authenticators.BIOMETRIC_WEAK
                ))
            }
            "getAvailabilityDetails" -> {
                result.success(getDetailedAvailability())
            }
            "authenticate" -> {
                val reason = call.argument<String>("reason") ?: "Authenticate"
                val preferredType = call.argument<String>("preferredType") ?: "any"
                authenticateUser(reason, result, preferredType)
            }
            "isBiometricTypeAvailable" -> {
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
            else -> result.notImplemented()
        }
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
        val executor = Executors.newSingleThreadExecutor()

        val authenticators = when (authType) {
            "fingerprint" -> BiometricManager.Authenticators.BIOMETRIC_STRONG
            "face" -> BiometricManager.Authenticators.BIOMETRIC_WEAK
            else -> BiometricManager.Authenticators.BIOMETRIC_STRONG or 
                   BiometricManager.Authenticators.BIOMETRIC_WEAK
        }

        val promptInfo = BiometricPrompt.PromptInfo.Builder()
            .setTitle("Authentication required")
            .setSubtitle(reason)
            .setNegativeButtonText("Cancel")
            .setAllowedAuthenticators(authenticators)
            .build()
        
        val biometricPrompt = BiometricPrompt(context as FragmentActivity, executor, 
            object : BiometricPrompt.AuthenticationCallback() {
                override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) {
                    currentResult?.success(true)
                    cleanup()
                }
                
                override fun onAuthenticationFailed() {
                    // Don't complete here - wait for success or error
                }
                
                override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                    when (errorCode) {
                        BiometricPrompt.ERROR_NEGATIVE_BUTTON,
                        BiometricPrompt.ERROR_USER_CANCELED,
                        BiometricPrompt.ERROR_CANCELED -> {
                            currentResult?.success(false)
                        }
                        BiometricPrompt.ERROR_LOCKOUT -> {
                            currentResult?.error(
                                "LOCKED_OUT",
                                "Too many failed attempts. Biometric authentication is disabled for 30 seconds.",
                                null
                            )
                        }
                        BiometricPrompt.ERROR_LOCKOUT_PERMANENT -> {
                            currentResult?.error(
                                "LOCKED_OUT_PERMANENT",
                                "Too many failed attempts. Biometric authentication is disabled until you unlock with your device credentials.",
                                null
                            )
                        }
                        BiometricPrompt.ERROR_HW_NOT_PRESENT -> {
                            currentResult?.error(
                                "HW_NOT_AVAILABLE",
                                "Selected biometric method is not available on this device",
                                null
                            )
                        }
                        else -> {
                            currentResult?.error(
                                "AUTH_ERROR",
                                "Authentication error: $errString (code: $errorCode)",
                                errorCode
                            )
                        }
                    }
                    cleanup()
                }
            })
        
        try {
            biometricPrompt.authenticate(promptInfo)
        } catch (e: Exception) {
            currentResult?.error("AUTH_ERROR", e.message, null)
            cleanup()
        }
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