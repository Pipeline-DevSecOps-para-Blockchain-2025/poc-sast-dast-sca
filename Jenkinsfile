pipeline {
    agent any
    options {
        skipDefaultCheckout()
    }
    stages {
        stage('Checkout with Submodules') {
            steps {
                checkout([
                    $class: 'GitSCM',
                    branches: scm.branches,
                    userRemoteConfigs: scm.userRemoteConfigs,
                    extensions: [
                        [$class: 'SubmoduleOption', recursiveSubmodules: true, parentCredentials: true]
                    ]
                ])
            }
        }
        stage('Build Contracts') {
            agent {
                docker {
                    image 'ghcr.io/pipeline-devsecops-para-blockchain-2025/poc-sast-dast-sca/foundry:1.4.4'
                    reuseNode true
                }
            }
            steps {
                sh 'forge build'
            }
        }
    }
    post {
        always {
            cleanWs()
        }
    }
}
