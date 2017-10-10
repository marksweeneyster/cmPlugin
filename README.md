// example usage of the plugin

buildscript {

    repositories {

        mavenLocal()

    }

    dependencies {

        classpath group: 'com.sensory.cmk', name: 'CmPlugin',
				  version: '1.0-SNAPSHOT'

    }

}

apply plugin: 'com.sensory.cmk'
import com.sensory.cmk.Platform

model {

    platforms {

        natv(Platform)


        android(Platform) {
            toolchainFile = "${project.rootDir}/android-toolchain.cmake"

        }

    }

}
