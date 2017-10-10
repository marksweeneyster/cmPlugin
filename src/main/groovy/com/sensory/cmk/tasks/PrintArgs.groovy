package com.sensory.cmk.tasks

import org.gradle.api.DefaultTask
import org.gradle.api.tasks.TaskAction

import com.sensory.cmk.Platform 

class PrintArgs extends DefaultTask {
    Platform platform
    
    @TaskAction
    void printCommand() {
        if (platform.toolchainFile.length() == 0) {
            println "cmake -G$platform.generator $platform.cmListsPath"
        } else {
            println "cmake -G$platform.generator -DCMAKE_TOOLCHAIN_FILE=$platform.toolchainFile $platform.cmListsPath"
        }
    }
}
