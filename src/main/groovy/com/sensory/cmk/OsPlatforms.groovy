package com.sensory.cmk

import org.gradle.model.Managed
import org.gradle.model.ModelMap

@Managed
interface OsPlatforms {
    ModelMap<Platform> getPlatforms()

}