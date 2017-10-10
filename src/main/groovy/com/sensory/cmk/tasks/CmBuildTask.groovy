package com.sensory.cmk.tasks

import org.gradle.api.tasks.Exec

import com.sensory.cmk.Platform 

class CmBuildTask extends Exec {
    Platform platform
    String platformName    
    
    CmBuildTask() {
        executable 'cmake'
    }
	
    @Override
    protected void exec() {
        workingDir = "build/$platformName"
        args = ['--build','.']
        super.exec()
    }
}
