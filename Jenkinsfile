node {
    checkout scm
    stage("Build Artifact") {
        sh("arm build")
        archiveArtifacts artifacts: 'build/*', fingerprint: true
    }
    stage("Publish Artifact") {
        sh("arm push")
    }
    /*
    stage("Promote Artifact") {
        sh("arm publish")
    }
    */
}