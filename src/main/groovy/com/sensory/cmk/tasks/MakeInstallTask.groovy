package com.sensory.cmk.tasks

import org.gradle.api.tasks.Exec
import org.gradle.api.tasks.Input

class MakeInstallTask extends Exec {
    @Input String operatingSystem
    @Input String architecture

    MakeInstallTask() {
        executable 'make'
    }

    @Override
    protected void exec() {
        if (operatingSystem.contains("native")) {
            workingDir = "${project.buildDir}/platform/${project.ext.platform}"
        } else {
            workingDir = "${project.buildDir}/platform/$operatingSystem/$architecture"
        }
        args = ['install']
        super.exec()
    }
}
