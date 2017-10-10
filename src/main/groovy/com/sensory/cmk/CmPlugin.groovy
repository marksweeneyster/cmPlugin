package com.sensory.cmk

import org.gradle.model.Defaults
import org.gradle.model.Each
import org.gradle.model.Finalize
import org.gradle.model.Model
import org.gradle.model.ModelMap
import org.gradle.model.Path
import org.gradle.model.RuleSource
import org.gradle.api.tasks.Exec

import com.sensory.cmk.tasks

class CmPlugin extends RuleSource {   
    @Model
    void platforms(ModelMap<Platform> platforms) { }


    /**
    * Set the defaults for the platform builds
    */
    @Defaults
    void setDefaults(@Each Platform platform) {
        platform.generator = 'Ninja'
        // the cmake command working directory is two levels below root
        platform.cmListsPath = './../../'
        platform.toolchainFile = '' 
    }

    /**
    * Rule to create tasks that will print the cmake command 
    */ 
    @Mutate
    void createPrintArgsTask(ModelMap<Task> tasks, ModelMap<Platform> platforms) {
        platforms.keySet().each { name -> 
            tasks.create("${name}Command", PrintArgs) {
                platform = platforms[name]
            }
        }
    }

    /**
    * Rule to create tasks that will make subdirectories for the respective build platforms   
    */ 
    @Mutate
    void createPrebuildTask(ModelMap<Task> tasks, ModelMap<Platform> platforms) {
        platforms.keySet().each { name -> 
            tasks.create("${name}Prebuild", PrebuildTask) {
                platformName = "${name}"
            }
        }
    }

    /**
    * Rule to create tasks that will generate builds  
    */ 
    @Mutate
    void createCmGenerateTask(ModelMap<Task> tasks, ModelMap<Platform> platforms) {
        platforms.keySet().each { name -> 
            tasks.create("${name}Generate", CmGenerateTask) {
                platform = platforms[name]
                platformName = "${name}"
            }
        }
    }

    /**
    * Rule to create tasks that will run 'cmake --build' for the respective build platforms   
    */ 
    @Mutate
    void createBuildTask(ModelMap<Task> tasks, ModelMap<Platform> platforms) {
        platforms.keySet().each { name -> 
            tasks.create("${name}Build", CmBuildTask) {
                platform = platforms[name]
                platformName = "${name}"
            }
        }
    }

    /**
    * Rule to set dependencies for tasks created by the above Rules    
    */ 
    @Finalize
    void setDependencies(ModelMap<Task> tasks, ModelMap<Platform> platforms) {
        platforms.keySet().each { name->
            tasks.get("${name}Generate").dependsOn("${name}Prebuild")
            tasks.get("${name}Build").dependsOn("${name}Generate")
        }
    }

}

@Managed
interface Platform {
    String getGenerator()
    void setGenerator(String generator)
    String getCmListsPath()
    void setCmListsPath(String cmListsPath)
    String getToolchainFile()
    void setToolchainFile(String toolchainFile)
}

class PrebuildTask extends DefaultTask {
    String platformName    

    @TaskAction
    void makeDirectory() {
	    new File("build/$platformName").mkdirs()  
    }
}

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

