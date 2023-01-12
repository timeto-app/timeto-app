plugins {
    kotlin("android")
    id("com.android.application")
}

android {

    namespace = "app.time_to.timeto"
    compileSdk = 33

    defaultConfig {
        applicationId = "app.time_to.timeto"
        minSdk = 26
        targetSdk = 33
        versionCode = 115
        versionName = "2023.01.09"
    }
    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"))
        }
    }
    buildFeatures {
        compose = true
    }
    composeOptions {
        kotlinCompilerExtensionVersion = "1.3.2"
    }
    packagingOptions {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }
}

dependencies {

    implementation(project(":shared"))

    implementation("androidx.compose.material:material:1.3.1")
    implementation("androidx.compose.animation:animation-graphics:1.3.2")
    implementation("androidx.navigation:navigation-compose:2.5.3")
    implementation("com.google.android.material:material:1.7.0")

    val accompanist_version = "0.23.0"
    implementation("com.google.accompanist:accompanist-systemuicontroller:$accompanist_version")
}