# Human-in-the-Loop (HITL) Framework for GRCToolKit

## Overview

This document outlines the Human-in-the-Loop (HITL) framework integration for GRCToolKit v2.0.0-dev. The HITL framework ensures human oversight, validation, and feedback in AI-powered GRC compliance workflows, particularly for critical decisions and high-risk scenarios.

**Version**: 2.0.0-dev  
**Status**: Framework Design  
**Last Updated**: 2025-01-18  

---

## 🎯 HITL Framework Objectives

### Core Principles
1. **Human Oversight**: Critical AI decisions require human review and approval
2. **Transparency**: AI recommendations must be explainable and auditable
3. **Feedback Loops**: Human feedback improves AI accuracy over time
4. **Confidence Thresholds**: Automated actions only when confidence is high
5. **Error Handling**: Human intervention for edge cases and errors
6. **Compliance Assurance**: Human validation for regulatory compliance

### Benefits for GRCToolKit
- **Reduced Risk**: Human review prevents incorrect compliance recommendations
- **Regulatory Compliance**: Audit trail of human validation for compliance
- **AI Improvement**: Feedback loops enhance AI accuracy
- **Trust Building**: Transparency builds user confidence in AI recommendations
- **Error Correction**: Human oversight catches and corrects AI errors

---

## 🏗️ HITL Architecture

### Three-Tier HITL Model

#### Tier 1: Automated (Low Risk)
- **Criteria**: High confidence (>90%), low-risk controls, standard scenarios
- **Action**: Fully automated AI recommendations
- **Human Involvement**: None (with audit trail)

#### Tier 2: Human Review (Medium Risk)
- **Criteria**: Medium confidence (70-90%), medium-risk controls, complex scenarios
- **Action**: AI generates recommendations, human reviews and approves
- **Human Involvement**: Review and approval required

#### Tier 3: Human-Guided (High Risk)
- **Criteria**: Low confidence (<70%), high-risk controls, critical scenarios
- **Action**: Human expert guides AI, collaborative decision-making
- **Human Involvement**: Active collaboration required

---

## 🔄 HITL Workflow Integration

### Scenario Analysis Workflow

```
┌─────────────────────────────────────────────────────────────┐
│                    Scenario Submission                       │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────┐
│              AI Analysis (Gemini 2.0 Flash)                  │
│  - Extract keywords                                          │
│  - Map to NIST controls                                      │
│  - Generate recommendations                                  │
│  - Calculate confidence score                                │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        ▼
            ┌───────────┴───────────┐
            │  Confidence Score?    │
            └───────────┬───────────┘
                        │
        ┌───────────────┼───────────────┐
        │               │               │
    < 70%          70-90%           > 90%
        │               │               │
        ▼               ▼               ▼
┌─────────────┐  ┌─────────────┐  ┌─────────────┐
│  Tier 3:    │  │  Tier 2:    │  │  Tier 1:    │
│  Human-     │  │  Human      │  │  Automated  │
│  Guided     │  │  Review     │  │             │
└──────┬──────┘  └──────┬──────┘  └──────┬──────┘
       │                │                │
       ▼                ▼                ▼
┌─────────────────────────────────────────────────────────────┐
│              Human Review/Approval                           │
│  - Expert review                                              │
│  - Adjust recommendations                                     │
│  - Approve or reject                                          │
│  - Provide feedback                                           │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────┐
│              Final Recommendations                           │
│  - Approved controls                                          │
│  - Audit trail                                                │
│  - Feedback stored for AI training                           │
└─────────────────────────────────────────────────────────────┘
```

---

## 🎯 HITL Integration Points

### 1. AI Confidence Scoring

**Location**: `ai-agent/grc-compliance-engine.js`

**Implementation**:
```javascript
/**
 * Calculate confidence score for AI recommendations
 */
calculateConfidenceScore(analysis) {
    const factors = {
        keywordMatch: this.calculateKeywordMatch(analysis.keywords),
        controlRelevance: this.calculateControlRelevance(analysis.controls),
        scenarioComplexity: this.calculateScenarioComplexity(analysis.scenario),
        historicalAccuracy: this.getHistoricalAccuracy(analysis)
    };
    
    // Weighted confidence calculation
    const confidence = (
        factors.keywordMatch * 0.3 +
        factors.controlRelevance * 0.3 +
        factors.scenarioComplexity * 0.2 +
        factors.historicalAccuracy * 0.2
    ) * 100;
    
    return Math.round(confidence);
}
```

**Confidence Thresholds**:
- **High (>90%)**: Automated approval
- **Medium (70-90%)**: Human review required
- **Low (<70%)**: Human-guided analysis

### 2. Human Review Interface

**Location**: `grctoolkit.html`

**Features**:
- Approval/rejection buttons for each recommendation
- Comment field for human feedback
- Confidence score display
- Expert override capabilities
- Audit trail tracking

**UI Components**:
```html
<!-- Human Review Panel -->
<div id="humanReviewPanel" class="hidden">
    <h3>Review Required - Confidence: {{confidence}}%</h3>
    <div class="recommendations-list">
        <!-- Each control recommendation -->
        <div class="control-item" data-confidence="{{confidence}}">
            <h4>{{control.id}}: {{control.title}}</h4>
            <p>{{control.rationale}}</p>
            <div class="review-actions">
                <button onclick="approveControl('{{control.id}}')">✅ Approve</button>
                <button onclick="rejectControl('{{control.id}}')">❌ Reject</button>
                <button onclick="modifyControl('{{control.id}}')">✏️ Modify</button>
            </div>
            <textarea placeholder="Feedback (optional)"></textarea>
        </div>
    </div>
    <button onclick="submitReview()">Submit Review</button>
</div>
```

### 3. Feedback Loop System

**Location**: New module `ai-agent/hitl-feedback-manager.js`

**Functions**:
- Store human feedback for each recommendation
- Track approval/rejection rates
- Calculate AI accuracy improvements
- Feed back into AI training data

**Data Structure**:
```javascript
{
    scenarioId: "uuid",
    timestamp: "ISO8601",
    aiRecommendation: {...},
    humanDecision: "approved|rejected|modified",
    confidence: 75,
    reviewerId: "user-id",
    feedback: "Free-form feedback text",
    corrections: [...]
}
```

### 4. Audit Trail

**Location**: `compliance-docs/audit-trail-generator.js`

**Requirements**:
- Track all human interactions
- Store approval/rejection history
- Record confidence scores
- Maintain OSCAL-compliant audit logs

**OSCAL Integration**:
```json
{
    "assessment-results": {
        "observations": [{
            "uuid": "urn:uuid:...",
            "title": "Human Review of AI Recommendation",
            "description": "AI recommendation reviewed by human expert",
            "methods": ["human-review"],
            "subjects": [{
                "type": "person",
                "title": "Reviewer Name",
                "props": [{
                    "name": "confidence-score",
                    "value": "75"
                }]
            }],
            "props": [{
                "name": "review-action",
                "value": "approved"
            }]
        }]
    }
}
```

---

## 🔍 HITL Use Cases

### Use Case 1: High-Risk Compliance Scenario

**Scenario**: "We need to secure access to classified information systems containing national security data."

**HITL Flow**:
1. AI analyzes scenario (confidence: 65% - Low)
2. **Tier 3 Triggered**: Human-guided analysis required
3. Security expert reviews AI recommendations
4. Expert adjusts recommendations based on classification requirements
5. Expert approves final recommendations
6. Feedback stored for future scenarios

**Controls**:
- Requires highest confidence threshold (>95% for automated)
- Mandatory human review for classified scenarios
- Additional security controls recommended

### Use Case 2: PQC Migration Decision

**Scenario**: "Financial services organization with 20-year data retention needs PQC migration strategy."

**HITL Flow**:
1. AI generates PQC migration plan (confidence: 82% - Medium)
2. **Tier 2 Triggered**: Human review required
3. Compliance officer reviews migration roadmap
4. Officer verifies timeline against regulatory requirements
5. Officer approves plan with minor adjustments
6. Feedback improves future PQC recommendations

**Controls**:
- PQC migration always requires human review
- Financial regulations require human validation
- Long-term data protection needs expert oversight

### Use Case 3: Standard Compliance Scenario

**Scenario**: "Implement basic access control for internal employee database."

**HITL Flow**:
1. AI analyzes scenario (confidence: 94% - High)
2. **Tier 1 Triggered**: Automated approval
3. Recommendations displayed immediately
4. User can request human review if desired
5. Audit trail records automated decision

**Controls**:
- Low-risk scenarios can be automated
- User retains option for human review
- Audit trail maintains compliance

---

## 📊 HITL Metrics and Monitoring

### Key Performance Indicators (KPIs)

#### 1. Human Review Rate
- **Target**: 20-30% of recommendations require review
- **Calculation**: (Reviews Required / Total Recommendations) * 100
- **Goal**: Balance automation with oversight

#### 2. Approval Rate
- **Target**: >85% AI recommendations approved
- **Calculation**: (Approved / Reviewed) * 100
- **Goal**: High AI accuracy

#### 3. Feedback Impact
- **Target**: 10% improvement in accuracy per quarter
- **Calculation**: Compare accuracy before/after feedback incorporation
- **Goal**: Continuous AI improvement

#### 4. Review Time
- **Target**: <5 minutes per review
- **Calculation**: Average time from review request to completion
- **Goal**: Efficient human review process

### Monitoring Dashboard

**Metrics to Track**:
- Total recommendations generated
- Recommendations requiring review
- Approval/rejection rates
- Average confidence scores
- Feedback submission rate
- AI accuracy trends
- Review processing time

---

## 🔐 Security and Compliance

### Access Control
- **Role-Based Access**: Different roles for reviewers
  - **Compliance Officer**: Can approve standard recommendations
  - **Security Expert**: Required for high-risk scenarios
  - **Auditor**: Read-only access to review history

### Audit Requirements
- **Full Audit Trail**: All human actions logged
- **OSCAL Compliance**: Audit logs in OSCAL format
- **Retention**: 7 years for compliance records
- **Immutability**: Audit logs cannot be modified

### Data Privacy
- **Anonymization**: Reviewer names can be anonymized in reports
- **Access Control**: Only authorized personnel can view reviews
- **Encryption**: Review data encrypted at rest and in transit

---

## 🛠️ Implementation Roadmap

### Phase 1: Foundation (Q1 2026)
- [ ] Implement confidence scoring algorithm
- [ ] Create human review UI components
- [ ] Build feedback storage system
- [ ] Design audit trail structure

### Phase 2: Integration (Q2 2026)
- [ ] Integrate HITL workflow into scenario analysis
- [ ] Connect feedback loop to AI training
- [ ] Implement approval workflows
- [ ] Create review dashboard

### Phase 3: Enhancement (Q3 2026)
- [ ] Advanced confidence scoring with ML
- [ ] Predictive review requirements
- [ ] Automated feedback processing
- [ ] Multi-user review collaboration

### Phase 4: Optimization (Q4 2026)
- [ ] Continuous learning from feedback
- [ ] Personalized confidence thresholds
- [ ] Advanced analytics and reporting
- [ ] Enterprise-grade review workflows

---

## 📚 HITL Best Practices

### 1. Clear Confidence Indicators
- Display confidence scores prominently
- Use color coding (green/yellow/red)
- Explain what confidence means to users

### 2. Efficient Review Process
- Group similar recommendations for batch review
- Provide context and rationale for each recommendation
- Allow quick approve/reject with optional comments

### 3. Continuous Improvement
- Regularly analyze feedback patterns
- Update confidence thresholds based on accuracy
- Incorporate feedback into AI training

### 4. User Education
- Explain when human review is required
- Provide guidance on reviewing recommendations
- Train users on providing effective feedback

---

## 🔄 Feedback Loop Architecture

### Feedback Collection
```
AI Recommendation → Human Review → Feedback → Storage → Analysis → AI Training
```

### Feedback Types
1. **Explicit Feedback**: Approval/rejection with comments
2. **Implicit Feedback**: Time spent reviewing, corrections made
3. **Outcome Feedback**: Results after implementation
4. **Expert Feedback**: Subject matter expert reviews

### Feedback Storage
- **Database**: Store feedback in Firestore or PostgreSQL
- **Format**: Structured JSON with metadata
- **Indexing**: Index by scenario type, confidence, reviewer
- **Retention**: Permanent for compliance and training

---

## 🎯 Integration with Existing Features

### OSCAL Integration
- Human reviews stored as OSCAL observations
- Review history in OSCAL assessment results
- Audit trail in OSCAL format

### PQC Migration
- PQC scenarios always require human review (high risk)
- Expert validation of quantum risk assessments
- Human approval for migration plans

### Ansible Automation
- Human approval before running playbooks in production
- Review of automation results
- Feedback on playbook effectiveness

---

## 📞 Support and Resources

### Documentation
- **HITL Framework**: This document
- **API Documentation**: HITL API endpoints
- **User Guide**: How to use HITL features
- **Training Materials**: Reviewer training guides

### Tools and Resources
- **Review Dashboard**: Monitor HITL metrics
- **Feedback Analytics**: Analyze feedback patterns
- **Training Portal**: Reviewer training and certification
- **Support Channel**: HITL-related questions and issues

---

## ✅ Success Criteria

### Short-term (3 months)
- HITL framework implemented for critical scenarios
- >85% approval rate for AI recommendations
- <5 minute average review time
- Feedback system operational

### Long-term (12 months)
- 20% improvement in AI accuracy from feedback
- 30% reduction in review requirements (higher confidence)
- Full integration with all GRC workflows
- Enterprise-grade review capabilities

---

**Document Version**: 1.0  
**Last Updated**: 2025-01-XX  
**Status**: Framework Design - Ready for Implementation  

---

## Next Steps

1. **Review Framework**: Validate HITL design with stakeholders
2. **Prioritize Features**: Determine implementation priority
3. **Design UI/UX**: Create human review interface mockups
4. **Begin Implementation**: Start with Phase 1 foundation work
5. **Test and Iterate**: Pilot with select users and refine

For questions or feedback on the HITL framework, please contact the development team.

