#!/usr/bin/env groovy

/*
 * Given a release number, substitutes that version into the script at
 * get.armory.io and pushes up the new version of the installer.
 */

properties (
    [
        parameters([
            string(name: 'release_version', defaultValue: '', description: 'The armoryspinnaker version to create an installer release for.' ),
        ]),
    ]
)

node {
    checkout scm
    stage("Build Artifact") {
        sh("export SPINNAKER_TERRAFORM_VERSION=${params.release_version}; arm build")
        archiveArtifacts artifacts: 'build/*', fingerprint: true
    }
    stage("Push to get.armory.io") {
        sh("arm release")
    }
}
