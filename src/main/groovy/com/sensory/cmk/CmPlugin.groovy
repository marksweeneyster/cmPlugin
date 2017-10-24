package com.sensory.cmk

import org.gradle.api.Plugin
import org.gradle.api.Project
import org.gradle.api.DefaultTask
import org.gradle.model.Defaults
import org.gradle.model.Each
import org.gradle.model.Finalize
import org.gradle.model.ModelMap
import org.gradle.model.RuleSource
import org.gradle.api.Task
import org.gradle.api.tasks.Copy
import org.gradle.api.tasks.bundling.Zip

import com.sensory.cmk.tasks.*
import org.gradle.platform.base.BinaryTasks
import org.gradle.platform.base.ComponentBinaries
import org.gradle.platform.base.ComponentType
import org.gradle.platform.base.TypeBuilder

class CmPlugin implements Plugin<Project> {
    @Override
    void apply(Project target) {
        File androidBuildDir = new File("${target.buildDir}/platform/android")
        File iosBuildDir  = new File("${target.buildDir}/platform/ios")
        File iosFramework = new File("${target.buildDir}/platform/ios/dist/lib/${target.name}.framework")

        // ANDROID
        Task stageAndroid = target.tasks.create('stageAndroidLib', Copy.class){
            from "${target.rootDir}/platforms/android/aar"
            into  new File("${androidBuildDir}/aar")
        }

        Task jarAndroid = target.tasks.create('androidJar', Copy.class) {
            from ("${androidBuildDir}/dist/lib/java") {
                include "*.jar"
                rename (/(.*)\.jar/, 'classes.jar')
            }

            from ("${androidBuildDir}/dist/lib/java") {
                into "jni"
                include "**/*.so"
            }

            into "${androidBuildDir}/aar"
        }
        jarAndroid.dependsOn(stageAndroid)

        Task archiveAndroid = target.tasks.create('androidArchive', Zip.class) {
            from new File("${androidBuildDir}/aar")
            archiveName "${target.name}.aar"
            destinationDir new File("${androidBuildDir}/dist")

        }
        archiveAndroid.dependsOn(jarAndroid)

        //IOS

    }

    static class Rules extends RuleSource {

        @ComponentType
        void registerComponent(TypeBuilder<CmakeComponent> builder) {
        }

        @ComponentType
        void registerBinary(TypeBuilder<CmakeBinary> builder) {
        }

        @Defaults
        void setDefaultLibraries(ModelMap<CmakeComponent> libraries) {
            libraries.create('android') {
                os = 'android'
                arches = ['arm','arm64','x86','x86_64']
            }
            libraries.create('ios') {
                os = 'ios'
                arches = ['armv7','armv7s','arm64','x86_64','i386']
                generator = 'Unix Makefiles'
            }
            libraries.create('semitizen') {
                os = 'tizen'
                arches = ['armv7l','x86']
            }
            libraries.create('native') {
                os = 'native'
                arches = ['x86_64']
            }
            libraries.create('linux') {
                os = 'linux'
                arches = ['aarch64','armv7l']
            }
        }

        @Defaults
        void setLibraryDefaults(@Each CmakeComponent library) {

            library.generator = 'Ninja'
            library.cmListsPath = '../../'
            library.toolchainFile = ''
            library.flags = ''
        }

        @Defaults
        void setDefaults(@Each CmakeBinary cmakeBinary) {
            cmakeBinary.generator = 'Ninja'
            cmakeBinary.cmListsPath = '../../'
            cmakeBinary.toolchainFile = ''
            cmakeBinary.flags = ''
        }

        @Defaults
        void createRootOsBuildTasks(ModelMap<Task> tasks, ModelMap<CmakeComponent> libraries) {
            libraries.keySet().each { name ->
                tasks.create("${name}Build", DefaultTask)
            }
        }

        @ComponentBinaries
        void createBinariesForBinaryComponent(ModelMap<CmakeBinary> binaries, CmakeComponent library) {
            library.arches.each { architecture->
                binaries.create(architecture) {
                    arch = architecture;
                    os = library.os
                    generator = library.generator
                    toolchainFile = library.toolchainFile ?: ''
                }
            }
        }

        @BinaryTasks
        void createCmakeTasks(ModelMap<Task> tasks, CmakeBinary binary) {

            String makr = binary.tasks.taskName("mkdirs", "build")
            String genr = binary.tasks.taskName("generate", "build")
            String runr = binary.tasks.taskName("run", "build")
            String inst = binary.tasks.taskName("install", "build")
            String rootOsTask = "${binary.os}Build"

            tasks.create(makr,PrebuildTask){
                it.operatingSystem = binary.os;
                it.architecture = binary.arch;
            }
            tasks.create(genr, CmGenerateTask){
                it.operatingSystem = binary.os;
                it.architecture = binary.arch;
                it.generator    = binary.generator;
                it.cmListsPath  = "${it.project.rootDir}"
                it.toolchainFile = binary.toolchainFile.length() > 0 ? "${it.project.rootDir}/${binary.toolchainFile}" : ''

                if (it.project.ext.has('cmakeFlags')) {
                    it.flags = it.project.ext.get('cmakeFlags')
                } else {
                    it.flags = ''
                }
                it.flags += ' ' + binary.flags;

            }
            tasks.create(runr, CmBuildTask){
                it.operatingSystem = binary.os;
                it.architecture = binary.arch;
            }
            if (binary.generator=='Ninja') {
                tasks.create(inst, NinjaInstallTask){
                    it.operatingSystem = binary.os;
                    it.architecture = binary.arch;
                }
            } else {
                tasks.create(inst, MakeInstallTask){
                    it.operatingSystem = binary.os;
                    it.architecture = binary.arch;
                }
            }

            tasks.get(genr).dependsOn(makr)
            tasks.get(genr).dependsOn('setup')
            tasks.get(runr).dependsOn(genr)
            tasks.get(inst).dependsOn(runr)

        }

        @Finalize
        void setRootOsBuildTasks(ModelMap<Task> tasks, ModelMap<CmakeComponent> libraries) {
            libraries.each { library ->
                library.arches.each { arch ->
                    String installTaskName = "install"+library.name.capitalize()+arch.capitalize()+"Build"

                    tasks.get("${library.os}Build").dependsOn(installTaskName)
                }

                if (library.os.equals('android')) {
                    tasks.get("${library.os}Build").finalizedBy('androidArchive')
                } else if (library.os.equals('linux')) {
                    tasks.get("${library.os}Build").finalizedBy('nativeBuild')
                } else if (library.os.equals('ios')) {
                    tasks.get("${library.os}Build").finalizedBy('iosFrameworkZip')
                }
            }
        }
    }
}
