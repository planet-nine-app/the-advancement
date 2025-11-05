package app.planetnine.theadvancement.config

/**
 * Configuration object for Planet Nine service URLs
 *
 * Provides dynamic URL generation in the format:
 * https://subdomain.service.domain.tld
 *
 * Current environment: hitchhikers.*.allyabase.com
 */
object Configuration {
    // Environment: "production", "test", or "local"
    const val ENVIRONMENT: String = "production"

    // Toggle this for local development
    const val USE_LOCAL_SERVICES: Boolean = false

    // For production
    const val SUBDOMAIN: String = "plr"
    const val BASE_DOMAIN: String = "allyabase.com"
    const val USE_HTTPS: Boolean = true

    // For local development (Android emulator uses 10.0.2.2 for host localhost)
    const val LOCAL_HOST: String = "10.0.2.2"

    // Helper to check if running in production
    val isProduction: Boolean get() = ENVIRONMENT == "production"

    private enum class Service(val serviceName: String) {
        BDO("bdo"),
        ADDIE("addie"),
        FOUNT("fount"),
        NEXUS("nexus"),
        SANORA("sanora"),
        COVENANT("covenant"),
        DOLORES("dolores")
    }

    private fun serviceURL(service: Service, port: Int? = null): String {
        if (USE_LOCAL_SERVICES) {
            val localPort = port ?: getDefaultPort(service)
            return "http://$LOCAL_HOST:$localPort"
        }

        val scheme = if (USE_HTTPS) "https" else "http"
        return "$scheme://$SUBDOMAIN.${service.serviceName}.$BASE_DOMAIN"
    }

    private fun getDefaultPort(service: Service): Int = when (service) {
        Service.BDO -> 3000
        Service.FOUNT -> 3001
        Service.ADDIE -> 2999
        Service.SANORA -> 7423
        Service.COVENANT -> 5122
        Service.NEXUS -> 3002
        Service.DOLORES -> 3007
    }

    val bdoBaseURL: String = serviceURL(Service.BDO)
    val addieBaseURL: String = serviceURL(Service.ADDIE)
    val fountBaseURL: String = serviceURL(Service.FOUNT)
    val nexusBaseURL: String = serviceURL(Service.NEXUS)
    val sanoraBaseURL: String = serviceURL(Service.SANORA)
    val covenantBaseURL: String = serviceURL(Service.COVENANT)
    val doloresBaseURL: String = serviceURL(Service.DOLORES)

    /**
     * BDO service endpoints
     */
    object BDO {
        fun createUser(): String = "$bdoBaseURL/user/create"

        fun putBDO(userUUID: String): String = "$bdoBaseURL/user/$userUUID/bdo"

        fun getEmojicode(pubKey: String): String = "$bdoBaseURL/pubkey/$pubKey/emojicode"

        val baseURL: String = "$bdoBaseURL/"
    }

    /**
     * Fount service endpoints
     */
    object Fount {
        fun createUser(): String = "$fountBaseURL/user/create"

        fun getBDO(bdoPubKey: String): String = "$fountBaseURL/bdo/$bdoPubKey"

        fun createBDO(): String = "$fountBaseURL/bdo"

        fun getUser(userUUID: String): String = "$fountBaseURL/user/$userUUID"

        fun grantExperience(userUUID: String): String = "$fountBaseURL/user/$userUUID/grant"

        fun resolve(spellName: String): String = "$fountBaseURL/resolve/$spellName"

        val baseURL: String = "$fountBaseURL/"
    }

    /**
     * Addie service endpoints
     */
    object Addie {
        fun createUser(): String = "$addieBaseURL/user/create"

        fun chargeWithSavedMethod(): String = "$addieBaseURL/charge"

        val baseURL: String = "$addieBaseURL/"
    }

    /**
     * Sanora service endpoints
     */
    object Sanora {
        fun listProducts(): String = "$sanoraBaseURL/products"

        fun getProduct(productId: String): String = "$sanoraBaseURL/product/$productId"

        val baseURL: String = "$sanoraBaseURL/"
    }

    /**
     * Covenant service endpoints
     */
    object Covenant {
        fun signContract(contractUuid: String): String = "$covenantBaseURL/contract/$contractUuid/sign"

        fun getContract(contractUuid: String): String = "$covenantBaseURL/contract/$contractUuid"

        val baseURL: String = "$covenantBaseURL/"
    }

    /**
     * Dolores service endpoints
     */
    object Dolores {
        fun audioPlayer(feedUrl: String): String {
            val encodedFeedUrl = java.net.URLEncoder.encode(feedUrl, "UTF-8")
            return "$doloresBaseURL/audio-player.html?feedUrl=$encodedFeedUrl"
        }

        val baseURL: String = "$doloresBaseURL/"
    }
}
