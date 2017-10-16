node {
    checkout scm
    stage("Build Artifact") {
        sh("export SPINNAKER_TERRAFORM_VERSION=dummy; arm build")
        archiveArtifacts artifacts: 'build/*', fingerprint: true
    }
}
