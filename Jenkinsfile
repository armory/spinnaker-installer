
node {
    checkout scm

    stage("Build Image") {
        sh("arm build")
    }

    stage('Archive Artifacts / Test Results') {
           archiveArtifacts artifacts: 'build/*', fingerprint: true
    }
}
