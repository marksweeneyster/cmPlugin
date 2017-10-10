package com.sensory.cmk

import org.gradle.model.Defaults
import org.gradle.model.Each
import org.gradle.model.Finalize
import org.gradle.model.Model
import org.gradle.model.ModelMap
import org.gradle.model.RuleSource
import org.gradle.model.Mutate
import org.gradle.api.Task

import com.sensory.cmk.tasks.*

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
        platform.operatingSystem = 'native'
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
