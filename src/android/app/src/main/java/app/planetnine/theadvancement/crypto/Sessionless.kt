package app.planetnine.theadvancement.crypto

import android.content.Context
import android.content.SharedPreferences
import android.util.Log
import org.bouncycastle.crypto.digests.KeccakDigest
import org.bouncycastle.crypto.params.ECDomainParameters
import org.bouncycastle.crypto.params.ECPrivateKeyParameters
import org.bouncycastle.crypto.params.ECPublicKeyParameters
import org.bouncycastle.crypto.signers.ECDSASigner
import org.bouncycastle.jce.ECNamedCurveTable
import org.bouncycastle.jce.provider.BouncyCastleProvider
import java.math.BigInteger
import java.security.*
import java.security.spec.ECGenParameterSpec
import java.security.interfaces.ECPrivateKey
import java.security.interfaces.ECPublicKey

/**
 * Sessionless authentication for Android
 *
 * Uses secp256k1 curve for ECDSA signatures with keccak256 hashing.
 * Matches the official sessionless-kt implementation.
 */
class Sessionless(context: Context) {

    companion object {
        private const val TAG = "Sessionless"
        private const val PREFS_NAME = "sessionless_keys"
        private const val KEY_PRIVATE = "private_key"
        private const val KEY_PUBLIC = "public_key"
        private const val CURVE_NAME = "secp256k1"

        // secp256k1 curve order (N)
        private val CURVE_ORDER = BigInteger("FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141", 16)
        // Half of curve order (N/2) - used for low-S normalization
        private val HALF_CURVE_ORDER = CURVE_ORDER.shiftRight(1)

        init {
            // Register BouncyCastle provider
            Security.removeProvider("BC")
            Security.insertProviderAt(BouncyCastleProvider(), 1)
        }
    }

    /**
     * Key pair data class
     */
    data class Keys(
        val publicKey: String,
        val privateKey: String
    )

    private val prefs: SharedPreferences =
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    /**
     * Get existing keys from storage
     */
    fun getKeys(): Keys? {
        val privateKey = prefs.getString(KEY_PRIVATE, null)
        val publicKey = prefs.getString(KEY_PUBLIC, null)

        return if (privateKey != null && publicKey != null) {
            Keys(publicKey, privateKey)
        } else {
            null
        }
    }

    /**
     * Generate new key pair using secp256k1 curve
     */
    fun generateKeys(): Keys {
        try {
            Log.d(TAG, "Generating new key pair with secp256k1...")

            // Generate key pair using secp256k1
            val keyPairGenerator = KeyPairGenerator.getInstance("ECDSA", "BC")
            val ecSpec = ECGenParameterSpec(CURVE_NAME)
            keyPairGenerator.initialize(ecSpec, SecureRandom())

            val keyPair = keyPairGenerator.generateKeyPair()

            // Get public key in compressed format (33 bytes with prefix 02 or 03)
            val publicKey = keyPair.public as ECPublicKey
            val publicKeyHex = encodePublicKeyCompressed(publicKey)

            // Get private key as hex string
            val privateKey = keyPair.private as ECPrivateKey
            val privateKeyHex = privateKey.s.toString(16).padStart(64, '0')

            // Save keys
            prefs.edit()
                .putString(KEY_PRIVATE, privateKeyHex)
                .putString(KEY_PUBLIC, publicKeyHex)
                .apply()

            Log.d(TAG, "Keys generated and saved. Public key: $publicKeyHex")

            return Keys(publicKeyHex, privateKeyHex)

        } catch (e: Exception) {
            Log.e(TAG, "Failed to generate keys", e)
            throw e
        }
    }

    /**
     * Sign a message with the private key
     *
     * Uses keccak256 hashing and returns R+S signature format (128 hex chars)
     * Matches iOS and official sessionless-kt implementation
     */
    fun sign(message: String): String? {
        return try {
            val keys = getKeys() ?: return null

            Log.d(TAG, "Signing message: $message")

            // Hash message with keccak256
            val messageHash = hashKeccak256(message)
            val messageHashHex = messageHash.joinToString("") { "%02x".format(it) }
            Log.d(TAG, "Message hash (keccak256): $messageHashHex")

            // Convert private key hex to BigInteger
            val privateKeyInt = BigInteger(keys.privateKey, 16)

            // Get EC parameters for secp256k1
            val ecSpec = ECNamedCurveTable.getParameterSpec(CURVE_NAME)
            val ecDomainParams = ECDomainParameters(
                ecSpec.curve,
                ecSpec.g,
                ecSpec.n,
                ecSpec.h
            )

            // Create BouncyCastle ECPrivateKeyParameters
            val privateKeyParams = ECPrivateKeyParameters(privateKeyInt, ecDomainParams)

            // Sign with ECDSA signer
            val signer = ECDSASigner()
            signer.init(true, privateKeyParams)
            val signature = signer.generateSignature(messageHash)

            // Extract R and S values
            val r = signature[0]
            var s = signature[1]

            // Normalize S to low-S (BIP-62) to prevent signature malleability
            // If S > N/2, use N - S instead
            if (s > HALF_CURVE_ORDER) {
                Log.d(TAG, "S is high, normalizing: $s")
                s = CURVE_ORDER.subtract(s)
                Log.d(TAG, "S normalized to: $s")
            }

            // Return R+S concatenated as hex (64 chars each = 128 total)
            val rHex = r.toString(16).padStart(64, '0')
            val sHex = s.toString(16).padStart(64, '0')
            val signatureHex = rHex + sHex

            Log.d(TAG, "R (raw): $r")
            Log.d(TAG, "S (raw): $s")
            Log.d(TAG, "R (hex): $rHex (${rHex.length} chars)")
            Log.d(TAG, "S (hex): $sHex (${sHex.length} chars)")
            Log.d(TAG, "Signature (R+S): $signatureHex (${signatureHex.length} chars)")

            signatureHex

        } catch (e: Exception) {
            Log.e(TAG, "Failed to sign message", e)
            e.printStackTrace()
            null
        }
    }

    /**
     * Hash a string with keccak256
     */
    private fun hashKeccak256(message: String): ByteArray {
        val messageBytes = message.toByteArray(Charsets.UTF_8)
        val digest = KeccakDigest(256)
        digest.update(messageBytes, 0, messageBytes.size)
        val hash = ByteArray(digest.digestSize)
        digest.doFinal(hash, 0)
        return hash
    }

    /**
     * Encode public key in compressed format (33 bytes)
     * Format: 02/03 prefix + x coordinate (32 bytes)
     */
    private fun encodePublicKeyCompressed(publicKey: ECPublicKey): String {
        val w = publicKey.w
        val x = w.affineX
        val y = w.affineY

        // Determine prefix based on Y coordinate parity
        val prefix = if (y.testBit(0)) "03" else "02"

        // X coordinate as hex (32 bytes = 64 hex chars)
        val xHex = x.toString(16).padStart(64, '0')

        return prefix + xHex
    }

    /**
     * Clear stored keys (for testing or logout)
     */
    fun clearKeys() {
        prefs.edit()
            .remove(KEY_PRIVATE)
            .remove(KEY_PUBLIC)
            .apply()

        Log.d(TAG, "Keys cleared from storage")
    }
}
