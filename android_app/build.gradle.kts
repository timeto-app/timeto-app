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
        versionCode = 143
        versionName = "2023.03.12"
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"))
        }
    }

    buildFeatures.compose = true
    composeOptions.kotlinCompilerExtensionVersion = "1.4.0"
}

dependencies {
    implementation(project(":shared"))
    implementation("androidx.activity:activity-compose:1.6.1")
    implementation("androidx.compose.material:material:1.3.1")
    implementation("com.google.android.material:material:1.8.0")
    implementation("androidx.navigation:navigation-compose:2.5.3")
}
