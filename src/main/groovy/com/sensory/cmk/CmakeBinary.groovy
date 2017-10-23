package com.sensory.cmk

import org.gradle.model.Managed
import org.gradle.platform.base.BinarySpec

@Managed
interface CmakeBinary extends BinarySpec {
    String getArch()
    void setArch(String arch)

    String getCmListsPath()
    void setCmListsPath(String cmListsPath)

    String getGenerator()
    void setGenerator(String generator)

    String getFlags()
    void setFlags(String flags)

    String getOs()
    void setOs(String os)

    String getToolchainFile()
    void setToolchainFile(String toolchainFile)
}