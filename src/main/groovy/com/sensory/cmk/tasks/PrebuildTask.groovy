class PrebuildTask extends DefaultTask {
    String platformName    

    @TaskAction
    void makeDirectory() {
	    new File("build/$platformName").mkdirs()  
    }
}
