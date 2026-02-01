import com.android.build.gradle.AppExtension

val android = project.extensions.getByType(AppExtension::class.java)

android.apply {
    flavorDimensions("flavor")

    productFlavors {
        create("dev") {
            dimension = "flavor"
            applicationId = "com.example.focus_flow.dev"
            resValue(type = "string", name = "app_name", value = "FocusFlow Dev")
        }
        create("pro") {
            dimension = "flavor"
            applicationId = "com.example.focus_flow"
            resValue(type = "string", name = "app_name", value = "FocusFlow")
        }
    }
}