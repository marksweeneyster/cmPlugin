package com.sensory.cmk.tasks

import org.gradle.api.tasks.Exec
import org.gradle.api.tasks.Input

class CmBuildTask extends Exec {
    @Input String operatingSystem
    @Input String architecture

    CmBuildTask() {
        environment "MAKEFLAGS", "-j4"
        executable 'cmake'
    }

    @Override
    protected void exec() {
        workingDir = "${project.buildDir}/platform/$operatingSystem/$architecture"
        args = ['--build','.']
        super.exec()
    }

}
