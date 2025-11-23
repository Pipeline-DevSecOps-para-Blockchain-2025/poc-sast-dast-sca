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
                // --build-info: additional output files, used by Slither
                sh 'forge build --build-info'
            }
        }
        stage('Analysis') {
            stages {
                stage('Slither') {
                    agent {
                        docker {
                            image 'ghcr.io/pipeline-devsecops-para-blockchain-2025/poc-sast-dast-sca/slither:0.11.3'
                            args '--entrypoint=' // shell for Docker Pipeline
                            reuseNode true
                        }
                    }
                    steps {
                        sh 'mkdir reports'
                        // --ignore-compile: already compiled with build info
                        // --no-fail-pedantic: only fail in case of runtime issues
                        sh 'slither --ignore-compile --no-fail-pedantic . --json reports/slither.json'
                        stash name: 'slither-report', includes: 'reports/slither.json'
                    }
                }
            }
        }
    }
    post {
        always {
            cleanWs()
            // TODO: stash may not be available
            unstash 'slither-report'
            archiveArtifacts artifacts: 'reports/**', allowEmptyArchive: true
        }
    }
}
