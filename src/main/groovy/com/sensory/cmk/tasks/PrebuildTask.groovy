package com.sensory.cmk.tasks

import org.gradle.api.DefaultTask
import org.gradle.api.tasks.TaskAction

import com.sensory.cmk.Platform 

class PrebuildTask extends DefaultTask {
    String platformName    

    @TaskAction
    void makeDirectory() {
	    new File("build/$platformName").mkdirs()  
    }
}
