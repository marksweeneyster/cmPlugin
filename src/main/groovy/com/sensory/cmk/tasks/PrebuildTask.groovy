package com.sensory.cmk.tasks

import org.gradle.api.DefaultTask
import org.gradle.api.tasks.Input
import org.gradle.api.tasks.TaskAction

class PrebuildTask extends DefaultTask {
    @Input String operatingSystem
    @Input String architecture

    @TaskAction
    void makeDirectory() {

        if (operatingSystem.contains("native") ) {
            new File("${project.buildDir}/platform/${project.ext.platform}").mkdirs()
        } else {
            new File("${project.buildDir}/platform/$operatingSystem/$architecture").mkdirs()
        }
    }

}
