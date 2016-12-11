
node {
    checkout scm

    stage("Build Script") {
        sh("arm build")
    }

    /*
    stage('Archive Artifacts / Test Results') {
           archiveArtifacts artifacts: 'build/*', fingerprint: true
    }
    */
}
