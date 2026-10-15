// مسیر: android/build.gradle.kts
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

// تضمین: همه پلاگین‌های اندروید (مثل permission_handler) با SDK 36
subprojects {
    afterEvaluate {
        val androidExt = extensions.findByName("android") ?: return@afterEvaluate
        try {
            val clazz = androidExt.javaClass
            val setCompileSdk = clazz.methods.firstOrNull {
                it.name == "setCompileSdk" && it.parameterTypes.size == 1
            }
            if (setCompileSdk != null) {
                val param = setCompileSdk.parameterTypes[0]
                when {
                    param == Int::class.javaPrimitiveType || param == Integer::class.java ->
                        setCompileSdk.invoke(androidExt, 36)
                    param == String::class.java ->
                        setCompileSdk.invoke(androidExt, "android-36")
                    else -> setCompileSdk.invoke(androidExt, 36)
                }
            } else {
                val setCompileSdkVersion = clazz.methods.firstOrNull {
                    it.name == "setCompileSdkVersion" && it.parameterTypes.size == 1
                }
                setCompileSdkVersion?.let { m ->
                    val param = m.parameterTypes[0]
                    if (param == String::class.java) {
                        m.invoke(androidExt, "android-36")
                    } else {
                        m.invoke(androidExt, 36)
                    }
                }
            }
            logger.lifecycle("Forced compileSdk 36 on :${project.name}")
        } catch (e: Exception) {
            logger.warn("compileSdk force failed on :${project.name}: ${e.message}")
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
