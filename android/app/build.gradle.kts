plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties
import java.io.File
import java.io.FileInputStream

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.tustudio.neon_jump"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Requerido por flutter_local_notifications (notificaciones programadas)
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "com.tustudio.neon_jump"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }



    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
            storeFile = keystorePropertiesFile.parentFile.resolve(keystoreProperties.getProperty("storeFile") ?: "")
            storePassword = keystoreProperties.getProperty("storePassword")
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
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

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("androidx.activity:activity-ktx:1.9.3")
    implementation("androidx.core:core-ktx:1.15.0")
}

fun stripHtmlComments(input: String): String =
    input.replace(Regex("<!--[\\s\\S]*?-->"), "").replace(Regex("\\n{2,}"), "\n")

fun stripCssComments(input: String): String {
    val out = StringBuilder(input.length)
    var i = 0
    val n = input.length
    while (i < n) {
        val c = input[i]
        if (c == '\'' || c == '"') {
            val quote = c
            out.append(c)
            i++
            while (i < n) {
                val ch = input[i]
                out.append(ch)
                if (ch == '\\' && i + 1 < n) {
                    out.append(input[i + 1])
                    i += 2
                    continue
                }
                i++
                if (ch == quote) break
            }
        } else if (c == 'u' && input.startsWith("url(", i)) {
            out.append("url(")
            i += 4
            var depth = 1
            while (i < n && depth > 0) {
                val ch = input[i]
                out.append(ch)
                if (ch == '(') depth++
                else if (ch == ')') depth--
                i++
            }
        } else if (c == '/' && i + 1 < n && input[i + 1] == '*') {
            i += 2
            while (i + 1 < n && !(input[i] == '*' && input[i + 1] == '/')) i++
            i = minOf(i + 2, n)
        } else {
            out.append(c)
            i++
        }
    }
    return out.toString().replace(Regex("[ \\t]+\\r?\\n"), "\n").replace(Regex("\\n{2,}"), "\n").trimStart('\r', '\n')
}

fun stripJsComments(input: String): String {
    val out = StringBuilder(input.length)
    var i = 0
    val n = input.length
    var lastSig = '\u0000'
    var lastWord = ""
    val regexKeywords = setOf("return", "throw", "case", "in", "of", "else", "do", "typeof", "void", "delete", "new")

    fun canStartRegex(): Boolean {
        if (lastSig == '\u0000') return true
        if (lastSig in "=(,[?:!&|;{}*+-/%<>^~") return true
        if (lastWord in regexKeywords) return true
        return false
    }

    while (i < n) {
        val c = input[i]
        if (c == '\'' || c == '"') {
            val quote = c
            out.append(c)
            i++
            while (i < n) {
                val ch = input[i]
                out.append(ch)
                if (ch == '\\' && i + 1 < n) {
                    out.append(input[i + 1])
                    i += 2
                    continue
                }
                i++
                if (ch == quote) break
            }
            lastSig = quote
            lastWord = ""
        } else if (c == '/' && i + 1 < n && input[i + 1] == '/') {
            i += 2
            while (i < n && input[i] != '\n') i++
        } else if (c == '/' && i + 1 < n && input[i + 1] == '*') {
            var hadNewline = false
            i += 2
            while (i + 1 < n && !(input[i] == '*' && input[i + 1] == '/')) {
                if (input[i] == '\n') hadNewline = true
                i++
            }
            i = minOf(i + 2, n)
            out.append(if (hadNewline) '\n' else ' ')
        } else if (c == '/' && canStartRegex()) {
            out.append(c)
            i++
            var inClass = false
            while (i < n) {
                val ch = input[i]
                out.append(ch)
                if (ch == '\\' && i + 1 < n) {
                    out.append(input[i + 1])
                    i += 2
                    continue
                }
                if (ch == '[') inClass = true
                else if (ch == ']') inClass = false
                i++
                if (ch == '/' && !inClass) break
            }
            while (i < n && input[i].isLetter()) {
                out.append(input[i])
                i++
            }
            lastSig = '/'
            lastWord = ""
        } else {
            out.append(c)
            if (c.isLetterOrDigit() || c == '_' || c == '$') {
                lastWord = if (lastSig.isLetterOrDigit() || lastSig == '_' || lastSig == '$') lastWord + c else c.toString()
                lastSig = c
            } else if (!c.isWhitespace()) {
                lastSig = c
                lastWord = ""
            }
            i++
        }
    }
    return out.toString().replace(Regex("[ \\t]+\\r?\\n"), "\n").replace(Regex("\\n{2,}"), "\n").trimStart('\r', '\n')
}

afterEvaluate {
    tasks.matching { it.name == "copyFlutterAssetsRelease" }.configureEach {
        outputs.upToDateWhen { false }
        doLast {
            val roots = linkedSetOf<File>()
            outputs.files.files.forEach { file ->
                roots.add(file)
                roots.add(File(file, "assets/juego"))
                roots.add(File(file, "flutter_assets/assets/juego"))
            }
            roots.add(layout.buildDirectory.dir("intermediates/assets/release/mergeReleaseAssets/flutter_assets/assets/juego").get().asFile)
            roots.add(layout.buildDirectory.dir("intermediates/flutter/release/flutter_assets/assets/juego").get().asFile)
            val seen = HashSet<String>()
            roots.filter { it.exists() && it.isDirectory }.forEach { root ->
                root.walkTopDown().filter { it.isFile }.forEach { file ->
                    val path = file.canonicalPath
                    if (!seen.add(path)) return@forEach
                    when (file.extension.lowercase()) {
                        "js" -> file.writeText(stripJsComments(file.readText(Charsets.UTF_8)), Charsets.UTF_8)
                        "css" -> file.writeText(stripCssComments(file.readText(Charsets.UTF_8)), Charsets.UTF_8)
                        "html" -> file.writeText(stripHtmlComments(file.readText(Charsets.UTF_8)), Charsets.UTF_8)
                    }
                }
            }
        }
    }
}
