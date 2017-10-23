package com.sensory.cmk.tasks

import org.gradle.api.DefaultTask
import org.gradle.api.tasks.Input
import org.gradle.api.tasks.TaskAction

class PrebuildTask extends DefaultTask {
    @Input String operatingSystem
    @Input String architecture

    @TaskAction
    void makeDirectory() {
        new File("${project.buildDir}/platform/$operatingSystem/$architecture").mkdirs()
    }

}
