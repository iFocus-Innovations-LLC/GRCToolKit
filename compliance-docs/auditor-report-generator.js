/**
 * Automated Compliance Documentation Generator
 * Creates auditor-ready documentation using OSCAL format
 * Integrates with NIST OSCAL framework for standardized compliance reporting
 */

class AuditorReportGenerator {
    constructor() {
        this.oscalVersion = "1.0.0";
        this.reportTemplates = new Map();
        this.initializeTemplates();
    }

    /**
     * Initialize report templates for different compliance frameworks
     */
    initializeTemplates() {
        this.reportTemplates.set('nist-800-53', {
            framework: 'NIST SP 800-53 Rev. 5',
            controls: 'Security and Privacy Controls',
            format: 'OSCAL Assessment Results'
        });

        this.reportTemplates.set('iso-27001', {
            framework: 'ISO/IEC 27001:2013',
            controls: 'Information Security Management',
            format: 'OSCAL Assessment Results'
        });

        this.reportTemplates.set('sox', {
            framework: 'Sarbanes-Oxley Act',
            controls: 'Financial Controls',
            format: 'OSCAL Assessment Results'
        });
    }

    /**
     * Generate comprehensive auditor report
     */
    async generateAuditorReport(assessmentResults, options = {}) {
        try {
            console.log('📊 Generating auditor report...');
            
            const report = {
                metadata: this.generateReportMetadata(options),
                executiveSummary: await this.generateExecutiveSummary(assessmentResults),
                complianceStatus: this.analyzeComplianceStatus(assessmentResults),
                controlAssessments: this.generateControlAssessments(assessmentResults),
                findings: this.categorizeFindings(assessmentResults),
                recommendations: this.generateRecommendations(assessmentResults),
                evidence: this.collectEvidence(assessmentResults),
                appendices: this.generateAppendices(assessmentResults)
            };

            // Generate OSCAL-compliant report
            const oscalReport = this.generateOSCALReport(report, assessmentResults);
            
            // Generate human-readable report
            const humanReadableReport = this.generateHumanReadableReport(report);
            
            return {
                oscalReport: oscalReport,
                humanReadableReport: humanReadableReport,
                metadata: report.metadata
            };
            
        } catch (error) {
            console.error('Error generating auditor report:', error);
            throw error;
        }
    }

    /**
     * Generate report metadata
     */
    generateReportMetadata(options) {
        return {
            reportId: this.generateReportId(),
            title: options.title || 'GRC Compliance Assessment Report',
            framework: options.framework || 'NIST SP 800-53 Rev. 5',
            assessmentDate: new Date().toISOString(),
            assessor: options.assessor || 'GRC Toolkit AI Agent',
            organization: options.organization || 'Target Organization',
            scope: options.scope || 'Information System Security Controls',
            methodology: 'Automated Assessment using Ansible Playbooks and OSCAL',
            version: '1.0.0',
            classification: options.classification || 'Internal Use'
        };
    }

    /**
     * Generate executive summary
     */
    async generateExecutiveSummary(assessmentResults) {
        const totalControls = assessmentResults.playbookResults.length;
        const passedControls = assessmentResults.playbookResults.filter(r => r.status === 'completed').length;
        const failedControls = totalControls - passedControls;
        const compliancePercentage = Math.round((passedControls / totalControls) * 100);

        return {
            overview: `This report presents the results of an automated compliance assessment conducted using the GRC Toolkit AI Agent. The assessment evaluated ${totalControls} security controls across the organization's information systems.`,
            keyFindings: [
                `Overall compliance rate: ${compliancePercentage}%`,
                `Controls assessed: ${totalControls}`,
                `Controls passed: ${passedControls}`,
                `Controls failed: ${failedControls}`,
                `Assessment methodology: Automated validation using Ansible playbooks`
            ],
            riskLevel: this.calculateRiskLevel(compliancePercentage),
            recommendations: [
                'Address failed controls within 30 days',
                'Implement continuous monitoring for critical controls',
                'Establish regular compliance assessment schedule',
                'Document remediation actions for audit trail'
            ]
        };
    }

    /**
     * Analyze compliance status
     */
    analyzeComplianceStatus(assessmentResults) {
        const status = {
            overall: assessmentResults.overallStatus,
            controls: {},
            trends: {},
            riskAssessment: {}
        };

        // Analyze each control
        for (const result of assessmentResults.playbookResults) {
            status.controls[result.playbook] = {
                status: result.status,
                lastAssessed: result.timestamp,
                findings: result.findings.length,
                criticalIssues: result.findings.filter(f => f.status === 'FAIL').length
            };
        }

        // Calculate trends (if historical data available)
        status.trends = this.calculateTrends(assessmentResults);
        
        // Risk assessment
        status.riskAssessment = this.performRiskAssessment(status.controls);

        return status;
    }

    /**
     * Generate control assessments
     */
    generateControlAssessments(assessmentResults) {
        const assessments = [];

        for (const result of assessmentResults.playbookResults) {
            const controlId = this.extractControlId(result.playbook);
            const controlInfo = this.getControlInfo(controlId);
            
            assessments.push({
                controlId: controlId,
                title: controlInfo.title,
                description: controlInfo.description,
                assessmentStatus: result.status,
                evidence: result.findings,
                remediationRequired: result.findings.some(f => f.status === 'FAIL'),
                priority: this.determineControlPriority(controlId),
                nextAssessment: this.calculateNextAssessment(controlId, result.status)
            });
        }

        return assessments;
    }

    /**
     * Categorize findings
     */
    categorizeFindings(assessmentResults) {
        const findings = {
            critical: [],
            high: [],
            medium: [],
            low: [],
            informational: []
        };

        for (const result of assessmentResults.playbookResults) {
            for (const finding of result.findings) {
                const severity = this.determineFindingSeverity(finding);
                findings[severity].push({
                    controlId: this.extractControlId(result.playbook),
                    finding: finding.message,
                    evidence: finding.evidence,
                    severity: severity,
                    timestamp: result.timestamp
                });
            }
        }

        return findings;
    }

    /**
     * Generate recommendations
     */
    generateRecommendations(assessmentResults) {
        const recommendations = [];

        // Critical findings recommendations
        const criticalFindings = this.getCriticalFindings(assessmentResults);
        if (criticalFindings.length > 0) {
            recommendations.push({
                priority: 'Critical',
                title: 'Address Critical Security Issues',
                description: 'Immediate action required to address critical security findings',
                timeline: 'Within 24 hours',
                controls: criticalFindings.map(f => f.controlId)
            });
        }

        // Process improvements
        recommendations.push({
            priority: 'High',
            title: 'Implement Continuous Monitoring',
            description: 'Establish automated monitoring for all critical controls',
            timeline: 'Within 30 days',
            controls: ['All critical controls']
        });

        // Documentation improvements
        recommendations.push({
            priority: 'Medium',
            title: 'Enhance Documentation',
            description: 'Improve control documentation and evidence collection',
            timeline: 'Within 60 days',
            controls: ['All controls']
        });

        return recommendations;
    }

    /**
     * Collect evidence
     */
    collectEvidence(assessmentResults) {
        const evidence = {
            automatedTests: [],
            configurationFiles: [],
            logFiles: [],
            screenshots: [],
            documentation: []
        };

        for (const result of assessmentResults.playbookResults) {
            evidence.automatedTests.push({
                playbook: result.playbook,
                executionTime: result.timestamp,
                status: result.status,
                output: result.output
            });

            // Collect specific evidence based on control type
            const controlId = this.extractControlId(result.playbook);
            evidence.configurationFiles.push(...this.getConfigurationEvidence(controlId));
            evidence.logFiles.push(...this.getLogEvidence(controlId));
        }

        return evidence;
    }

    /**
     * Generate appendices
     */
    generateAppendices(assessmentResults) {
        return {
            appendixA: {
                title: 'Control Mapping',
                content: this.generateControlMapping(assessmentResults)
            },
            appendixB: {
                title: 'Ansible Playbook Details',
                content: this.generatePlaybookDetails(assessmentResults)
            },
            appendixC: {
                title: 'Evidence Collection',
                content: this.generateEvidenceDetails(assessmentResults)
            },
            appendixD: {
                title: 'OSCAL Assessment Results',
                content: this.generateOSCALAppendix(assessmentResults)
            }
        };
    }

    /**
     * Generate OSCAL-compliant report
     */
    generateOSCALReport(report, assessmentResults) {
        return {
            "assessment-results": {
                "uuid": `urn:uuid:${this.generateUUID()}`,
                "metadata": {
                    "title": report.metadata.title,
                    "last-modified": new Date().toISOString(),
                    "version": report.metadata.version,
                    "oscal-version": this.oscalVersion,
                    "roles": [
                        {
                            "id": "assessor",
                            "title": "Compliance Assessor"
                        },
                        {
                            "id": "auditor",
                            "title": "External Auditor"
                        }
                    ]
                },
                "import-ap": {
                    "href": "/oscal/assessment-plans/grc-assessment-plan.json"
                },
                "results": [
                    {
                        "uuid": `urn:uuid:${this.generateUUID()}`,
                        "title": "GRC Compliance Assessment Results",
                        "description": "Automated compliance assessment using GRC Toolkit AI Agent",
                        "start": assessmentResults.startTime,
                        "end": assessmentResults.endTime,
                        "reviewed-controls": {
                            "control-selections": assessmentResults.playbookResults.map(result => ({
                                "include-controls": [
                                    {
                                        "control-id": this.extractControlId(result.playbook)
                                    }
                                ]
                            }))
                        },
                        "findings": this.generateOSCALFindings(assessmentResults),
                        "observations": this.generateOSCALObservations(assessmentResults)
                    }
                ]
            }
        };
    }

    /**
     * Generate human-readable report
     */
    generateHumanReadableReport(report) {
        return {
            title: report.metadata.title,
            date: report.metadata.assessmentDate,
            executiveSummary: report.executiveSummary,
            complianceStatus: report.complianceStatus,
            controlAssessments: report.controlAssessments,
            findings: report.findings,
            recommendations: report.recommendations,
            evidence: report.evidence,
            appendices: report.appendices
        };
    }

    // Helper methods
    generateReportId() {
        return `GRC-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
    }

    calculateRiskLevel(compliancePercentage) {
        if (compliancePercentage >= 90) return 'Low';
        if (compliancePercentage >= 70) return 'Medium';
        if (compliancePercentage >= 50) return 'High';
        return 'Critical';
    }

    calculateTrends(assessmentResults) {
        // In a real implementation, this would analyze historical data
        return {
            trend: 'stable',
            improvement: '0%',
            period: '30 days'
        };
    }

    performRiskAssessment(controls) {
        const totalControls = Object.keys(controls).length;
        const failedControls = Object.values(controls).filter(c => c.status === 'failed').length;
        
        return {
            riskScore: Math.round((failedControls / totalControls) * 100),
            riskLevel: this.calculateRiskLevel(Math.round(((totalControls - failedControls) / totalControls) * 100)),
            criticalControls: Object.keys(controls).filter(id => controls[id].criticalIssues > 0)
        };
    }

    extractControlId(playbookName) {
        const parts = playbookName.split('-');
        if (parts.length >= 2) {
            return parts[0].toUpperCase() + '-' + parts[1];
        }
        return playbookName;
    }

    getControlInfo(controlId) {
        // In a real implementation, this would query the OSCAL catalog
        return {
            title: `${controlId} Control`,
            description: `Description for ${controlId} control`
        };
    }

    determineControlPriority(controlId) {
        const highPriorityControls = ['AC-3', 'AC-6', 'SC-7', 'AU-2'];
        return highPriorityControls.includes(controlId) ? 'High' : 'Medium';
    }

    calculateNextAssessment(controlId, status) {
        const baseDate = new Date();
        const daysToAdd = status === 'completed' ? 90 : 30; // More frequent for failed controls
        baseDate.setDate(baseDate.getDate() + daysToAdd);
        return baseDate.toISOString();
    }

    determineFindingSeverity(finding) {
        if (finding.status === 'FAIL' && finding.message.includes('critical')) return 'critical';
        if (finding.status === 'FAIL') return 'high';
        if (finding.status === 'WARN') return 'medium';
        return 'low';
    }

    getCriticalFindings(assessmentResults) {
        const critical = [];
        for (const result of assessmentResults.playbookResults) {
            for (const finding of result.findings) {
                if (finding.status === 'FAIL' && finding.message.includes('critical')) {
                    critical.push({
                        controlId: this.extractControlId(result.playbook),
                        finding: finding.message
                    });
                }
            }
        }
        return critical;
    }

    getConfigurationEvidence(controlId) {
        // Return relevant configuration files for the control
        const evidenceMap = {
            'AC-3': ['/etc/pam.d/system-auth', '/etc/ssh/sshd_config'],
            'AC-6': ['/etc/sudoers', '/etc/passwd'],
            'AU-2': ['/etc/audit/auditd.conf', '/etc/audit/rules.d/audit.rules'],
            'SC-7': ['/etc/iptables/rules.v4', '/etc/ufw/ufw.conf']
        };
        return evidenceMap[controlId] || [];
    }

    getLogEvidence(controlId) {
        // Return relevant log files for the control
        const logMap = {
            'AC-3': ['/var/log/auth.log', '/var/log/secure'],
            'AC-6': ['/var/log/sudo.log'],
            'AU-2': ['/var/log/audit/audit.log'],
            'SC-7': ['/var/log/iptables.log', '/var/log/ufw.log']
        };
        return logMap[controlId] || [];
    }

    generateControlMapping(assessmentResults) {
        return assessmentResults.playbookResults.map(result => ({
            controlId: this.extractControlId(result.playbook),
            playbook: result.playbook,
            status: result.status,
            findings: result.findings.length
        }));
    }

    generatePlaybookDetails(assessmentResults) {
        return assessmentResults.playbookResults.map(result => ({
            name: result.playbook,
            path: `/ansible/playbooks/${result.playbook}.yml`,
            executionTime: result.timestamp,
            status: result.status,
            output: result.output
        }));
    }

    generateEvidenceDetails(assessmentResults) {
        const evidence = [];
        for (const result of assessmentResults.playbookResults) {
            const controlId = this.extractControlId(result.playbook);
            evidence.push({
                controlId: controlId,
                configurationFiles: this.getConfigurationEvidence(controlId),
                logFiles: this.getLogEvidence(controlId),
                automatedTests: [result.playbook]
            });
        }
        return evidence;
    }

    generateOSCALAppendix(assessmentResults) {
        return this.generateOSCALReport({ metadata: {} }, assessmentResults);
    }

    generateOSCALFindings(assessmentResults) {
        const findings = [];
        for (const result of assessmentResults.playbookResults) {
            for (const finding of result.findings) {
                findings.push({
                    "uuid": `urn:uuid:${this.generateUUID()}`,
                    "title": finding.message,
                    "description": finding.evidence,
                    "props": [
                        {
                            "name": "status",
                            "value": finding.status
                        },
                        {
                            "name": "control-id",
                            "value": finding.control
                        }
                    ]
                });
            }
        }
        return findings;
    }

    generateOSCALObservations(assessmentResults) {
        return assessmentResults.playbookResults.map(result => ({
            "uuid": `urn:uuid:${this.generateUUID()}`,
            "title": `Assessment of ${this.extractControlId(result.playbook)}`,
            "description": `Automated assessment using ${result.playbook}`,
            "methods": ["automated-testing"],
            "subjects": [
                {
                    "type": "system",
                    "title": "Target System"
                }
            ],
            "props": [
                {
                    "name": "assessment-method",
                    "value": "ansible-playbook"
                }
            ]
        }));
    }

    generateUUID() {
        return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
            const r = Math.random() * 16 | 0;
            const v = c === 'x' ? r : (r & 0x3 | 0x8);
            return v.toString(16);
        });
    }
}

// Export for use in the main application
window.AuditorReportGenerator = AuditorReportGenerator;
