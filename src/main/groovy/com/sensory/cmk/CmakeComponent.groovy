package com.sensory.cmk

import org.gradle.model.Managed
import org.gradle.platform.base.LibrarySpec

@Managed
interface CmakeComponent extends LibrarySpec {
    List<String> getArches()
    void setArches(List<String> arches)

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