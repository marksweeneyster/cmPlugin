package com.sensory.cmk.tasks

import org.gradle.api.tasks.Exec
import org.gradle.api.tasks.Input

class CmGenerateTask extends Exec {
    @Input String operatingSystem
    @Input String architecture
    @Input String generator
    @Input String cmListsPath
    @Input String toolchainFile
    @Input String flags

    CmGenerateTask() {
        executable 'cmake'
    }

    @Override
    protected void exec() {
        List<String> flagList = flags.split("\\s+")

        if (operatingSystem.contains("native") ) {
            workingDir = "${project.buildDir}/platform/${project.ext.platform}"
        } else {
            workingDir = "${project.buildDir}/platform/$operatingSystem/$architecture"
        }

        if (toolchainFile.length() == 0) {
            String os = operatingSystem
            // TODO get rid of this "semi" test
            String[] osSplits = operatingSystem.split('semi')
            if (osSplits.length>1) {
                os = osSplits[1]
            }
            String s1 = "-D" + os.toUpperCase() + "=1"
            String s2 = "-DARCH=$architecture"

            if (operatingSystem.contains("native")) {
                List<String> flagList0 = ["-G$generator", "$cmListsPath"]
                flagList0.addAll(flagList)
                args = flagList0
            } else if (operatingSystem.contains("linux")) {
                List<String> flagList0 = ["-G$generator", "$cmListsPath", s2]

                flagList0.addAll(flagList)
                args = flagList0
            } else
            {
                List<String> flagList0 = ["-G$generator", "$cmListsPath", s1, s2]
                if (generator=='Ninja' && operatingSystem.contains('android')) {
                    flagList0.add("-DCMAKE_BUILD_WITH_INSTALL_RPATH=true")
                }
                flagList0.addAll(flagList)
                args = flagList0
            }
        } else {
            String osFlag = "-D" + operatingSystem.toUpperCase() + "=1 ";
            flags = "-DCMAKE_TOOLCHAIN_FILE=$toolchainFile -DARCH=$architecture " + flags + osFlag
            args = ["-G$generator", flags, "$cmListsPath"]
        }
        super.exec()
    }
}
