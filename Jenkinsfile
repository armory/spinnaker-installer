#!/usr/bin/env groovy

node {
    checkout scm
    stage("Testing") {
        print("Nothing to test yet.")
    }
    if(env.BRANCH_NAME == "master") {
        stage("Install 'arm' on Jenkins.") {
            sh("cp bin/arm /usr/local/bin")
        }
    }
}
