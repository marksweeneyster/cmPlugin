package com.sensory.cmk.tasks

import org.gradle.api.tasks.Exec

import com.sensory.cmk.Platform 

class CmGenerateTask extends Exec {
    Platform platform
    String platformName    
    
    CmGenerateTask() {
        executable 'cmake'
    }
	
    @Override
    protected void exec() {
	
	workingDir = "build/$platformName"
        if (platform.toolchainFile.length() == 0) {
            args = ["-G$platform.generator", "$platform.cmListsPath"]
        } else {
            args = ["-G$platform.generator", "-DCMAKE_TOOLCHAIN_FILE=$platform.toolchainFile", "$platform.cmListsPath"]
        }
        super.exec()
    }
}
