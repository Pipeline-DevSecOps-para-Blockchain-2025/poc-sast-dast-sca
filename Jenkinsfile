def images = [
    foundry: 'ghcr.io/pipeline-devsecops-para-blockchain-2025/poc-sast-dast-sca/foundry:1.4.4',
    slither: 'ghcr.io/pipeline-devsecops-para-blockchain-2025/poc-sast-dast-sca/slither:0.11.3',
    mythril: 'ghcr.io/pipeline-devsecops-para-blockchain-2025/poc-sast-dast-sca/mythril:0.24.8',
]

def reportCheck(Closure body) {
    withChecks(name: 'Jenkins CI', includeStage: true) {
        try {
            body()
            publishChecks(conclusion: 'SUCCESS')
        } catch (err) {
            publishChecks(conclusion: 'FAILURE', details: "${err}")
        }
    }
}

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
                    image images.foundry
                    reuseNode true
                }
            }
            steps {
                // --build-info: additional output files, used by Slither
                sh 'forge build --build-info'
            }
        }
        stage('Analysis') {
            parallel {
                stage('Foge Format') {
                    agent {
                        docker {
                            image images.foundry
                            reuseNode true
                        }
                    }
                    steps {
                        reportCheck {
                            sh 'forge fmt --check'
                        }
                    }
                }
                stage('Foge Lint') {
                    agent {
                        docker {
                            image images.foundry
                            reuseNode true
                        }
                    }
                    steps {
                        reportCheck {
                            sh 'forge lint'
                        }
                    }
                }
                stage('Foge Tests') {
                    agent {
                        docker {
                            image images.foundry
                            reuseNode true
                        }
                    }
                    steps {
                        reportCheck {
                            sh 'forge test -vvv'
                        }
                    }
                }
                stage('Slither') {
                    agent {
                        docker {
                            image images.slither
                            args '--entrypoint=' // shell for Docker Pipeline
                            reuseNode true
                        }
                    }
                    steps {
                        reportCheck {
                            sh 'mkdir -p reports'
                            // --ignore-compile: already compiled with build info
                            // --no-fail-pedantic: only fail in case of runtime issues
                            sh 'slither --ignore-compile --no-fail-pedantic . --json reports/slither.json'
                            stash name: 'slither-report', includes: 'reports/slither.json', allowEmpty: true
                        }
                    }
                }
                stage('Mythril') {
                    agent {
                        docker {
                            image images.mythril
                            args '--entrypoint=' // shell for Docker Pipeline
                            reuseNode true
                        }
                    }
                    steps {
                        reportCheck {
                            sh 'mkdir -p reports'
                            // FIXME: handle filenames with spaces and line breaks
                            sh 'myth analyze $(find contracts/ -name \'*.sol\' -print) --outform jsonv2 > reports/mythril.json'
                            stash name: 'mythril-report', includes: 'reports/mythril.json', allowEmpty: true
                        }
                    }
                }
            }
        }
    }
    post {
        always {
            catchError { unstash 'slither-report' }
            catchError { unstash 'mythril-report' }
            archiveArtifacts artifacts: 'reports/**', allowEmptyArchive: true
            cleanWs()
        }
    }
}
