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

    // MARK: - Multi-Base Key Management

    /**
     * Get keys for a specific base URL
     * Returns null if no keys exist for this base
     */
    fun getKeys(forBase: String): Keys? {
        Log.d(TAG, "Getting keys for base: $forBase")

        val sanitizedBase = sanitizeBaseURL(forBase)
        val privateKey = prefs.getString("${sanitizedBase}_private", null)
        val publicKey = prefs.getString("${sanitizedBase}_public", null)

        return if (privateKey != null && publicKey != null) {
            Log.d(TAG, "Found keys for base: $sanitizedBase")
            Keys(publicKey, privateKey)
        } else {
            Log.d(TAG, "No keys found for base: $sanitizedBase")
            null
        }
    }

    /**
     * Save keys for a specific base URL
     * Returns true if successful, false otherwise
     */
    fun saveKeys(keys: Keys, forBase: String): Boolean {
        return try {
            Log.d(TAG, "Saving keys for base: $forBase")

            val sanitizedBase = sanitizeBaseURL(forBase)

            // Delete existing keys for this base first
            deleteKeys(forBase)

            // Save new keys
            prefs.edit()
                .putString("${sanitizedBase}_private", keys.privateKey)
                .putString("${sanitizedBase}_public", keys.publicKey)
                .apply()

            Log.d(TAG, "Keys saved for base: $sanitizedBase")
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to save keys for base: $forBase", e)
            false
        }
    }

    /**
     * Delete keys for a specific base URL
     * Returns true if successful, false otherwise
     */
    fun deleteKeys(forBase: String): Boolean {
        return try {
            Log.d(TAG, "Deleting keys for base: $forBase")

            val sanitizedBase = sanitizeBaseURL(forBase)

            prefs.edit()
                .remove("${sanitizedBase}_private")
                .remove("${sanitizedBase}_public")
                .apply()

            Log.d(TAG, "Keys deleted for base: $sanitizedBase")
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to delete keys for base: $forBase", e)
            false
        }
    }

    /**
     * Get all base URLs that have keys stored
     * Returns a list of base URLs (unsanitized)
     */
    fun getAllBasesWithKeys(): List<String> {
        Log.d(TAG, "Getting all bases with keys")

        val allKeys = prefs.all.keys
        val bases = mutableSetOf<String>()

        // Find all keys ending with "_private" or "_public"
        for (key in allKeys) {
            if (key.endsWith("_private") || key.endsWith("_public")) {
                // Remove the suffix to get the sanitized base
                val sanitizedBase = key.removeSuffix("_private").removeSuffix("_public")

                // Skip the default keys (no base prefix)
                if (sanitizedBase == KEY_PRIVATE || sanitizedBase == KEY_PUBLIC) {
                    continue
                }

                bases.add(sanitizedBase)
            }
        }

        Log.d(TAG, "Found ${bases.size} bases with keys")
        return bases.toList()
    }

    /**
     * Migrate existing single-key storage to multi-base storage
     * Useful for upgrading from old version to new multi-base system
     * Returns true if migration successful or no migration needed
     */
    fun migrateToMultiBase(defaultBase: String): Boolean {
        return try {
            Log.d(TAG, "Migrating to multi-base storage with default base: $defaultBase")

            // Check if default keys exist
            val existingKeys = getKeys()
            if (existingKeys == null) {
                Log.d(TAG, "No existing keys to migrate")
                return true
            }

            // Save to the specified base
            val success = saveKeys(existingKeys, defaultBase)

            if (success) {
                Log.d(TAG, "Successfully migrated keys to base: $defaultBase")
            } else {
                Log.e(TAG, "Failed to migrate keys to base: $defaultBase")
            }

            success
        } catch (e: Exception) {
            Log.e(TAG, "Migration failed", e)
            false
        }
    }

    /**
     * Sanitize base URL to create a valid SharedPreferences key
     * Converts URL to a safe identifier by replacing special characters
     *
     * Examples:
     * - "https://localhost:5116" -> "localhost_5116"
     * - "http://example.com:8080/path" -> "example_com_8080_path"
     */
    private fun sanitizeBaseURL(baseURL: String): String {
        return baseURL
            .replace("https://", "")
            .replace("http://", "")
            .replace(":", "_")
            .replace("/", "_")
            .replace(".", "_")
    }
}
