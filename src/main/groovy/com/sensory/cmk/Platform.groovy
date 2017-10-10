package com.sensory.cmk

import org.gradle.model.Managed

@Managed
interface Platform {
    String getGenerator()
    void setGenerator(String generator)

    String getCmListsPath()
    void setCmListsPath(String cmListsPath)

    String getToolchainFile()
    void setToolchainFile(String toolchainFile)

    String getOperatingSystem()
    void setOperatingSystem(String operatingSystem)
}
