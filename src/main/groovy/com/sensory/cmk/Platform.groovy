package com.sensory.cmk

import org.gradle.model.Finalize
import org.gradle.model.Model
import org.gradle.model.ModelMap
import org.gradle.model.Managed

@Managed
interface Platform {
    String getGenerator()
    void setGenerator(String generator)
    String getCmListsPath()
    void setCmListsPath(String cmListsPath)
    String getToolchainFile()
    void setToolchainFile(String toolchainFile)
}
