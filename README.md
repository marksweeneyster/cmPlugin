// example usage of the plugin

buildscript {

    repositories {

        mavenLocal()

    }

    dependencies {

        classpath 'com.sensory.cmk:CmPlugin:1.0-SNAPSHOT'

    }

}

apply plugin: 'com.sensory.cmk'

model {

    components {

        moreAndroid(CmakeComponent) {
            os = 'android'
            arches = ['mips']
        }

    }

}
