def images = [
    foundry: 'ghcr.io/pipeline-devsecops-para-blockchain-2025/poc-sast-dast-sca/foundry:1.5.1',
    slither: 'ghcr.io/pipeline-devsecops-para-blockchain-2025/poc-sast-dast-sca/slither:0.11.5',
    mythril: 'ghcr.io/pipeline-devsecops-para-blockchain-2025/poc-sast-dast-sca/mythril:0.24.8',
    aderyn: 'ghcr.io/pipeline-devsecops-para-blockchain-2025/poc-sast-dast-sca/aderyn:0.6.8',
]

findingSeverities = ['High', 'Medium', 'Low', 'Informational', 'Optimization']
maxAnnotations = 50

def reportCheck(Closure body) {
    withChecks(name: 'Jenkins CI', includeStage: true) {
        try {
            body()
            publishChecks(conclusion: 'SUCCESS')
        } catch (err) {
            publishChecks(conclusion: 'FAILURE', summary: "${err}")
            throw err
        }
    }
}

def extractSettingsJson(String json) {
    def config = new groovy.json.JsonSlurper().parseText(json)
    return groovy.json.JsonOutput.toJson([remappings: config.remappings])
}

def mapSeverity(String severity) {
    switch (severity?.toLowerCase()) {
        case 'high':   return 'FAILURE'
        case 'medium': return 'WARNING'
        default:       return 'NOTICE'
    }
}

def pushMetrics(String url, String body) {
    try {
        def client   = java.net.http.HttpClient.newHttpClient()
        def request  = java.net.http.HttpRequest.newBuilder()
            .uri(java.net.URI.create(url))
            .header('Content-Type', 'text/plain')
            .POST(java.net.http.HttpRequest.BodyPublishers.ofString(body))
            .build()
        def response = client.send(request, java.net.http.HttpResponse.BodyHandlers.ofString())
        if (response.statusCode() >= 400) {
            println "WARN: VictoriaMetrics returned HTTP ${response.statusCode()}: ${response.body()}"
        }
    } catch (Exception e) {
        println "WARN: Failed to push metrics to VictoriaMetrics: ${e.message}"
    }
}

def newSeverityCounts() {
    def counts = [:]
    findingSeverities.each { severity -> counts[severity] = 0 }
    return counts
}

def initContractStats() {
    [total: 0, severityCounts: newSeverityCounts()]
}

def escapePromLabel(String value) {
    def v = value == null ? '' : value.toString()
    v = v.replace('\\', '\\\\')
    v = v.replace('"', '\\"')
    v = v.replace('\n', '\\n')
    return v
}

def formatPromLabels(Map labels) {
    def parts = []
    labels.each { k, v ->
        parts << "${k}=\"${escapePromLabel(v)}\""
    }
    return parts.join(',')
}

def buildSecurityMetricLines(List findings, List contracts, String tool, Map commonLabels) {
    def byContract = [:]

    contracts.each { contract ->
        byContract[contract] = initContractStats()
    }

    findings.each { f ->
        def contract = f.file.replaceFirst(/^contracts\//, '')
        if (!byContract.containsKey(contract)) {
            byContract[contract] = initContractStats()
        }

        byContract[contract].total += 1
        def sev = f.severity ?: 'Low'
        if (!byContract[contract].severityCounts.containsKey(sev)) {
            byContract[contract].severityCounts[sev] = 0
        }
        byContract[contract].severityCounts[sev] += 1
    }

    def lines = []
    byContract.each { contract, stats ->
        def base = commonLabels + [tool: tool, contract: contract]
        lines << "ci_security_contract_scanned{${formatPromLabels(base)}} 1"
        lines << "ci_security_contract_findings_total{${formatPromLabels(base)}} ${stats.total}"

        findingSeverities.each { sev ->
            def labels = base + [severity: sev]
            lines << "ci_security_findings{${formatPromLabels(labels)}} ${stats.severityCounts[sev] ?: 0}"
        }
    }

    return lines
}

def findingKey(Map finding) {
    [
        finding.tool,
        finding.file,
        finding.detector,
        finding.severity,
        finding.startLine,
        finding.endLine,
        finding.message,
    ].collect { it == null ? '' : it.toString() }.join('|')
}

def countNewFindings(List currentFindings, List previousFindings) {
    def previousKeys = previousFindings.collect { findingKey(it) } as Set
    return currentFindings.count { !previousKeys.contains(findingKey(it)) }
}

def loadPreviousFindings() {
    def findings = [slither: [], mythril: [], aderyn: []]
    def previousBuild = currentBuild.previousSuccessfulBuild
    def sourceJobName = env.JOB_NAME
    def sourceSelector = null
    def sourceDescription = null

    if (previousBuild) {
        sourceSelector = specific("${previousBuild.number}")
        sourceDescription = "build ${previousBuild.number} of ${sourceJobName}"
    } else if (env.BRANCH_NAME && env.BRANCH_NAME != 'main') {
        sourceJobName = 'main'
        sourceSelector = lastSuccessful()
        sourceDescription = "last successful build of ${sourceJobName}"
    }

    if (!sourceSelector) {
        return findings
    }

    try {
        copyArtifacts(
            projectName: sourceJobName,
            selector: sourceSelector,
            filter: 'reports/slither.json,reports/mythril/*.json,reports/aderyn.json',
            target: 'previous-reports',
            optional: true,
        )
    } catch (Exception e) {
        echo "WARN: Failed to load previous findings from ${sourceDescription}: ${e.message}"
        return findings
    }

    if (fileExists('previous-reports/reports/slither.json')) {
        findings.slither = parseSlitherReport(readFile('previous-reports/reports/slither.json'))
    }

    def mythrilEntries = []
    findFiles(glob: 'previous-reports/reports/mythril/*.json').each { f ->
        def text = readFile(f.path).trim()
        if (text) {
            mythrilEntries << [name: f.name, content: text]
        }
    }
    findings.mythril = parseMythrilReports(mythrilEntries)

    if (fileExists('previous-reports/reports/aderyn.json')) {
        findings.aderyn = parseAderynReport(readFile('previous-reports/reports/aderyn.json'))
    }

    return findings
}

def sendNotification(String subject, String body) {
    try {
        emailext(
            to: '$DEFAULT_RECIPIENTS',
            subject: subject,
            body: body,
            mimeType: 'text/plain',
        )
    } catch (Exception e) {
        echo "WARN: Failed to send email notification: ${e.message}"
    }
}

@NonCPS
def parseSlitherReport(String json) {
    def data     = new groovy.json.JsonSlurper().parseText(json)
    def findings = []

    data?.results?.detectors?.each { det ->
        def el  = det.elements?.find { it.source_mapping?.filename_relative?.startsWith('contracts/') }
        if (!el) return

        def lines = el.source_mapping?.lines ?: [1]
        def startLine = 1
        def endLine = 1
        if (lines) {
            startLine = lines[0] as int
            endLine = lines[0] as int
            lines.each { line ->
                int n = line as int
                if (n < startLine) startLine = n
                if (n > endLine) endLine = n
            }
        }
        findings << [
            tool      : 'slither',
            detector  : det.check ?: 'unknown',
            severity  : det.impact ?: 'Informational',
            confidence: det.confidence ?: 'Low',
            file      : el.source_mapping.filename_relative,
            startLine : startLine,
            endLine   : endLine,
            message   : det.description?.replaceAll(/\n/, ' ')?.take(512) ?: '',
        ]
    }

    return findings
}

@NonCPS
def parseMythrilReports(List reportEntries) {
    def findings = []

    reportEntries.each { entry ->
        def baseName = entry.name
        def srcFile  = baseName
            .replaceFirst(/\.json$/, '')
            .replaceFirst(/^(vulnerable|clean)_/, '')
        def srcPath  = baseName.startsWith('clean_')
            ? "contracts/clean/${srcFile}"
            : "contracts/vulnerable/${srcFile}"

        def data = new groovy.json.JsonSlurper().parseText(entry.content)
        def issues = data instanceof List ? data[0]?.issues : data?.issues
        issues?.each { issue ->
            findings << [
                tool      : 'mythril',
                detector  : issue.swcID ?: 'unknown',
                severity  : issue.severity ?: 'Low',
                confidence: 'N/A',
                file      : srcPath,
                startLine : 1,
                endLine   : 1,
                message   : issue.description?.head?.take(512) ?: '',
            ]
        }
    }

    return findings
}

@NonCPS
def parseAderynReport(String json) {
    def data = new groovy.json.JsonSlurper().parseText(json)
    def findings = []

    [
        [bucket: 'high_issues', severity: 'High'],
        [bucket: 'low_issues', severity: 'Low'],
    ].each { entry ->
        def bucket = data == null ? null : data[entry.bucket]
        bucket?.issues?.each { issue ->
            issue.instances?.each { instance ->
                def path = instance.contract_path ?: instance.file_path ?: ''
                if (!path.startsWith('contracts/')) return

                def line = 1
                if (instance.line_no instanceof Number) {
                    line = instance.line_no as int
                } else if (instance.line_no) {
                    try {
                        line = instance.line_no.toString().toInteger()
                    } catch (Exception ignored) {
                        line = 1
                    }
                }

                findings << [
                    tool      : 'aderyn',
                    detector  : issue.detector_name ?: issue.title ?: 'unknown',
                    severity  : entry.severity,
                    confidence: 'N/A',
                    file      : path,
                    startLine : line,
                    endLine   : line,
                    message   : issue.description?.replaceAll(/\n/, ' ')?.take(512) ?: issue.title ?: '',
                ]
            }
        }
    }

    return findings
}

@NonCPS
def buildSummary(List slitherFindings, List mythrilFindings, List aderynFindings) {
    def aggregate = { List findings ->
        def bySeverity = findings.groupBy { it.severity }
            .collectEntries { sev, list -> [(sev): list.size()] }
        def byContract = findings.groupBy { it.file }
            .collectEntries { file, list ->
                [(file.replaceFirst(/^contracts\//, '')): list.size()]
            }
            .sort { -it.value }
        [
            total     : findings.size(),
            bySeverity: bySeverity,
            byContract: byContract,
        ]
    }

    def severityTable = { Map stats, String toolName ->
        def lines = ["### ${toolName} — ${stats.total} findings\n"]
        lines << "| Severity | Count |"
        lines << "| :------- | ----: |"
        findingSeverities.each { sev ->
            def count = stats.bySeverity[sev]
            if (count) lines << "| ${sev} | ${count} |"
        }
        lines << ""
        lines << "| Contract | Findings |"
        lines << "| :------- | -------: |"
        stats.byContract.each { contract, count ->
            lines << "| `${contract}` | ${count} |"
        }
        lines.join('\n')
    }

    def slither = aggregate(slitherFindings)
    def mythril = aggregate(mythrilFindings)
    def aderyn = aggregate(aderynFindings)

    return [
        slither        : slither,
        mythril        : mythril,
        aderyn         : aderyn,
        slitherMarkdown: severityTable(slither, 'Slither'),
        mythrilMarkdown: severityTable(mythril, 'Mythril'),
        aderynMarkdown : severityTable(aderyn, 'Aderyn'),
        markdown       : severityTable(slither, 'Slither') + '\n\n' + severityTable(mythril, 'Mythril') + '\n\n' + severityTable(aderyn, 'Aderyn'),
    ]
}

def prioritizeFindings(List findings, int limit = 50) {
    def high = []
    def medium = []
    def other = []

    findings.each { f ->
        switch (f.severity?.toLowerCase()) {
            case 'high':
                high << f
                break
            case 'medium':
                medium << f
                break
            default:
                other << f
                break
        }
    }

    def ordered = []
    [high, medium, other].each { bucket ->
        bucket.each { f ->
            if (ordered.size() < limit) {
                ordered << f
            }
        }
    }

    return ordered
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
                sh 'forge build --build-info'
                sh 'forge config --json > .forge-config.json'
            }
        }
        stage('Analysis') {
            parallel {
                stage('Forge Format') {
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
                stage('Forge Lint') {
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
                stage('Forge Tests') {
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
                            args '--entrypoint='
                            reuseNode true
                        }
                    }
                    steps {
                        reportCheck {
                            sh 'mkdir -p reports'
                            sh '''
                                slither . \
                                    --ignore-compile --exclude-dependencies \
                                    --no-fail-pedantic --json reports/slither.json
                            '''
                            stash name: 'slither-report', includes: 'reports/slither.json', allowEmpty: true
                        }
                    }
                }
                stage('Mythril') {
                    agent {
                        docker {
                            image images.mythril
                            args '--entrypoint='
                            reuseNode true
                        }
                    }
                    steps {
                        script {
                            def config = readFile file: '.forge-config.json'
                            writeFile file: '.solc-config.json', text: extractSettingsJson(config)
                        }
                        sh 'mkdir -p reports/mythril'
                        script {
                            def files = sh(script: "find contracts/ -name '*.sol' -print0", returnStdout: true)
                                .split('\0')
                                .findAll { it }

                            def branches = [:]
                            files.each { filePath ->
                                def safePath = "'" + filePath.replace("'", "'\"'\"'") + "'"
                                def shortName = filePath.replaceFirst(/^contracts[\\/]/, '')
                                def safeName  = shortName.replaceAll(/[^A-Za-z0-9_.-]/, '_')

                                branches[shortName] = {
                                    reportCheck {
                                        script {
                                            def exitCode = sh(
                                                script: """
                                                    myth analyze ${safePath} \
                                                        --solv 0.8.26 --solc-json .solc-config.json \
                                                        --outform jsonv2 | tee reports/mythril/${safeName}.json
                                                """,
                                                returnStatus: true
                                            )
                                            println "Mythril reports for ${filePath}: ${exitCode}"
                                        }
                                    }
                                }
                            }

                            if (!branches.isEmpty()) {
                                parallel branches
                            }
                        }
                        stash name: 'mythril-report', includes: 'reports/mythril/*.json', allowEmpty: true
                    }
                }
                stage('Aderyn') {
                    agent {
                        docker {
                            image images.aderyn
                            args '--entrypoint='
                            reuseNode true
                        }
                    }
                    steps {
                        reportCheck {
                            sh 'mkdir -p reports'
                            sh 'aderyn --output reports/aderyn.json'
                            stash name: 'aderyn-report', includes: 'reports/aderyn.json', allowEmpty: true
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
            catchError { unstash 'aderyn-report' }

            script {
                def slitherFindings = []
                if (fileExists('reports/slither.json')) {
                    slitherFindings = parseSlitherReport(readFile('reports/slither.json'))
                }

                def mythrilEntries = []
                findFiles(glob: 'reports/mythril/*.json').each { f ->
                    def text = readFile(f.path).trim()
                    if (text) {
                        mythrilEntries << [name: f.name, content: text]
                    } else {
                        echo "Skipping empty mythril report: ${f.path}"
                    }
                }
                def mythrilFindings = parseMythrilReports(mythrilEntries)

                def aderynFindings = []
                if (fileExists('reports/aderyn.json')) {
                    aderynFindings = parseAderynReport(readFile('reports/aderyn.json'))
                }

                def summary = buildSummary(slitherFindings, mythrilFindings, aderynFindings)

                echo "=== SAST Results ===\n${summary.markdown}"

                if (slitherFindings) {
                    publishChecks(
                        name      : 'Slither SAST',
                        title     : "Slither: ${summary.slither.total} findings",
                        summary   : summary.slitherMarkdown,
                        conclusion: 'NEUTRAL',
                        annotations: prioritizeFindings(slitherFindings, maxAnnotations).collect { f -> [
                            path            : f.file,
                            startLine       : f.startLine,
                            endLine         : f.endLine,
                            annotationLevel : mapSeverity(f.severity),
                            title           : f.detector,
                            message         : f.message,
                            rawDetails      : "Confidence: ${f.confidence}",
                        ]}
                    )
                }

                if (mythrilFindings) {
                    publishChecks(
                        name      : 'Mythril SAST',
                        title     : "Mythril: ${summary.mythril.total} findings",
                        summary   : summary.mythrilMarkdown,
                        conclusion: 'NEUTRAL',
                        annotations: prioritizeFindings(mythrilFindings, maxAnnotations).collect { f -> [
                            path            : f.file,
                            startLine       : f.startLine,
                            endLine         : f.endLine,
                            annotationLevel : mapSeverity(f.severity),
                            title           : f.detector,
                            message         : f.message,
                        ]}
                    )
                }

                if (aderynFindings) {
                    publishChecks(
                        name      : 'Aderyn SAST',
                        title     : "Aderyn: ${summary.aderyn.total} findings",
                        summary   : summary.aderynMarkdown,
                        conclusion: 'NEUTRAL',
                        annotations: prioritizeFindings(aderynFindings, maxAnnotations).collect { f -> [
                            path            : f.file,
                            startLine       : f.startLine,
                            endLine         : f.endLine,
                            annotationLevel : mapSeverity(f.severity),
                            title           : f.detector,
                            message         : f.message,
                        ]}
                    )
                }

                def contracts = findFiles(glob: 'contracts/**/*.sol')
                    .collect { it.path.replaceFirst(/^contracts\//, '') }
                def commonLabels = [
                    branch: env.BRANCH_NAME,
                    job: env.JOB_NAME,
                    build_number: env.BUILD_NUMBER,
                ]
                def metricLines = []
                if (slitherFindings) {
                    metricLines += buildSecurityMetricLines(slitherFindings, contracts, 'slither', commonLabels)
                }
                if (mythrilFindings) {
                    metricLines += buildSecurityMetricLines(mythrilFindings, contracts, 'mythril', commonLabels)
                }
                if (aderynFindings) {
                    metricLines += buildSecurityMetricLines(aderynFindings, contracts, 'aderyn', commonLabels)
                }
                if (metricLines) {
                    pushMetrics('http://victoriametrics:8428/api/v1/import/prometheus', metricLines.join('\n'))
                }

                def previousFindings = loadPreviousFindings()
                def newSlitherFindings = countNewFindings(slitherFindings, previousFindings.slither)
                def newMythrilFindings = countNewFindings(mythrilFindings, previousFindings.mythril)
                def newAderynFindings = countNewFindings(aderynFindings, previousFindings.aderyn)
                def hasNewFindings = newSlitherFindings > 0 || newMythrilFindings > 0 || newAderynFindings > 0
                def buildResult = currentBuild.currentResult ?: 'SUCCESS'

                if (buildResult != 'SUCCESS' || hasNewFindings) {
                    def buildUrl = env.BUILD_URL ?: ''
                    def lines = [
                        "Build: ${currentBuild.fullDisplayName}",
                        "Result: ${buildResult}",
                        "Slither findings: ${summary.slither.total} (new: ${newSlitherFindings})",
                        "Mythril findings: ${summary.mythril.total} (new: ${newMythrilFindings})",
                        "Aderyn findings: ${summary.aderyn.total} (new: ${newAderynFindings})",
                    ]

                    if (buildUrl) {
                        lines += [
                            '',
                            "Build URL: ${env.RUN_DISPLAY_URL ?: buildUrl}",
                            "Console log: ${buildUrl}console",
                            "Artifacts: ${buildUrl}artifact/reports/",
                        ]
                    }

                    sendNotification(
                        "${buildResult}: ${currentBuild.fullDisplayName}",
                        lines.join('\n'),
                    )
                }
            }

            archiveArtifacts artifacts: 'reports/**', allowEmptyArchive: true
            cleanWs()
        }
    }
}
