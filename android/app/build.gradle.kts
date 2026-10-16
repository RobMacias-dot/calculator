import java.security.KeyStore
import java.security.PrivateKey
import java.security.cert.X509Certificate
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Local owner-managed upload credentials. Never log property values.
val uploadPropertiesFile = rootProject.file("key.properties")
val uploadProperties = Properties().apply {
    if (uploadPropertiesFile.isFile) {
        uploadPropertiesFile.inputStream().use { load(it) }
    }
}
val uploadStoreFile = uploadProperties.getProperty("storeFile")
    ?.takeIf { it.isNotBlank() }?.let { rootProject.file(it) }

val validateUploadSigning = tasks.register("validateUploadSigning") {
    group = "verification"
    description = "Reject missing, invalid, or Android Debug upload credentials."
    doLast {
        val guidance = "Release signing blocked: configure private android/key.properties " +
            "with production upload credentials. See docs/phase18-release-signing.md."
        val required = listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
        if (!uploadPropertiesFile.isFile || required.any {
                uploadProperties.getProperty(it).isNullOrBlank()
            }) {
            throw GradleException(guidance)
        }
        val store = uploadStoreFile
        if (store == null || !store.isFile) {
            throw GradleException("$guidance Keystore file is missing.")
        }
        val alias = uploadProperties.getProperty("keyAlias")
        if (store.name.equals("debug.keystore", ignoreCase = true) ||
            alias.equals("androiddebugkey", ignoreCase = true)) {
            throw GradleException("$guidance Android Debug signing is prohibited.")
        }
        try {
            val keyStore = KeyStore.getInstance(
                store, uploadProperties.getProperty("storePassword").toCharArray()
            )
            val key = keyStore.getKey(
                alias, uploadProperties.getProperty("keyPassword").toCharArray()
            )
            val certificate = keyStore.getCertificate(alias) as? X509Certificate
            if (key !is PrivateKey || certificate == null) {
                throw IllegalArgumentException("Upload alias must contain a private key")
            }
            certificate.checkValidity()
            if (certificate.subjectX500Principal.name.contains("CN=Android Debug", ignoreCase = true)) {
                throw IllegalArgumentException("Android Debug certificate")
            }
        } catch (_: Exception) {
            // Do not include provider exceptions, passwords or private file paths.
            throw GradleException("$guidance Invalid, expired, or Android Debug upload key.")
        }
    }
}

android {
    namespace = "com.robmac.engineeringtoolkit"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.robmac.engineeringtoolkit"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("upload") {
            storeFile = uploadStoreFile
            storePassword = uploadProperties.getProperty("storePassword")
            keyAlias = uploadProperties.getProperty("keyAlias")
            keyPassword = uploadProperties.getProperty("keyPassword")
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("upload")
        }
    }
}

// Attach to variant tasks, not requested task-name strings, so aggregate and
// fully-qualified APK/AAB tasks are protected too. Debug stays independent.
tasks.configureEach {
    if (name == "preReleaseBuild" || name == "validateSigningRelease") {
        dependsOn(validateUploadSigning)
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
