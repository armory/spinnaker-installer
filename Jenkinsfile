
node {
    checkout scm

    stage("Build Script") {
        sh("arm build")
        sh("arm integration")
    }

    /*
    stage('Archive Artifacts / Test Results') {
           archiveArtifacts artifacts: 'build/*', fingerprint: true
    }
    */
}
