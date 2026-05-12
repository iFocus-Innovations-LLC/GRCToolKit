# PQC Database Schema Documentation

This document outlines the database schema for Post-Quantum Cryptography (PQC) migration features in GRCToolKit.

## Overview

The PQC database schema extends the existing GRC database with tables for:
- Cryptographic asset inventory
- Quantum risk assessments
- Migration roadmap tracking
- Vendor solution catalog
- Timeline and milestone management

## Database Technology

**Recommended**: Firestore (NoSQL) for flexible schema and real-time updates
**Alternative**: PostgreSQL for relational data with complex queries

## Schema Definitions

### 1. PQC Assets Table

Stores discovered cryptographic assets and their quantum vulnerability status.

```sql
-- SQL Schema (PostgreSQL)
CREATE TABLE pqc_assets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    asset_name VARCHAR(255) NOT NULL,
    asset_type VARCHAR(50) NOT NULL, -- 'certificate', 'key', 'encryption', 'signature'
    algorithm_type VARCHAR(50) NOT NULL, -- 'RSA', 'ECC', 'DSA', 'ML-KEM', 'ML-DSA', 'SLH-DSA'
    algorithm_details JSONB, -- Additional algorithm-specific details
    quantum_vulnerability VARCHAR(20) NOT NULL, -- 'none', 'low', 'medium', 'high', 'critical'
    vulnerability_level VARCHAR(20) NOT NULL,
    data_shelf_life INTEGER, -- Years of data retention requirement
    business_criticality VARCHAR(20) NOT NULL, -- 'low', 'medium', 'high', 'critical'
    migration_priority VARCHAR(20) NOT NULL, -- 'low', 'medium', 'high', 'critical'
    location VARCHAR(255), -- System/path where asset is located
    system_name VARCHAR(255), -- System identifier
    discovered_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_assessed TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    assessment_status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'assessed', 'migrated'
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_pqc_assets_vulnerability ON pqc_assets(quantum_vulnerability);
CREATE INDEX idx_pqc_assets_priority ON pqc_assets(migration_priority);
CREATE INDEX idx_pqc_assets_algorithm ON pqc_assets(algorithm_type);
```

```javascript
// Firestore Schema
pqc_assets: {
  id: string (auto-generated),
  assetName: string,
  assetType: string, // 'certificate', 'key', 'encryption', 'signature'
  algorithmType: string, // 'RSA', 'ECC', 'DSA', 'ML-KEM', 'ML-DSA', 'SLH-DSA'
  algorithmDetails: {
    keySize: number,
    curve: string,
    standard: string
  },
  quantumVulnerability: string, // 'none', 'low', 'medium', 'high', 'critical'
  vulnerabilityLevel: string,
  dataShelfLife: number, // Years
  businessCriticality: string, // 'low', 'medium', 'high', 'critical'
  migrationPriority: string, // 'low', 'medium', 'high', 'critical'
  location: string,
  systemName: string,
  discoveredDate: timestamp,
  lastAssessed: timestamp,
  assessmentStatus: string, // 'pending', 'assessed', 'migrated'
  createdAt: timestamp,
  updatedAt: timestamp
}
```

### 2. PQC Risks Table

Stores quantum risk assessment results for each asset.

```sql
-- SQL Schema (PostgreSQL)
CREATE TABLE pqc_risks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    asset_id UUID NOT NULL REFERENCES pqc_assets(id) ON DELETE CASCADE,
    risk_score DECIMAL(5,2) NOT NULL, -- 0.0 to 10.0
    risk_level VARCHAR(20) NOT NULL, -- 'low', 'medium', 'high', 'critical'
    algorithm_risk INTEGER NOT NULL, -- 1-10
    data_sensitivity VARCHAR(20) NOT NULL, -- 'public', 'internal', 'confidential', 'classified'
    system_criticality VARCHAR(20) NOT NULL, -- 'low', 'medium', 'high', 'critical'
    timeline_to_threat VARCHAR(50), -- Estimated timeline to quantum threat
    harvest_now_risk VARCHAR(20) NOT NULL, -- 'low', 'medium', 'high'
    migration_priority VARCHAR(20) NOT NULL, -- 'low', 'medium', 'high', 'critical'
    assessment_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    assessed_by VARCHAR(255), -- User or system identifier
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_pqc_risks_asset ON pqc_risks(asset_id);
CREATE INDEX idx_pqc_risks_level ON pqc_risks(risk_level);
CREATE INDEX idx_pqc_risks_priority ON pqc_risks(migration_priority);
```

```javascript
// Firestore Schema
pqc_risks: {
  id: string (auto-generated),
  assetId: string, // Reference to pqc_assets
  riskScore: number, // 0.0 to 10.0
  riskLevel: string, // 'low', 'medium', 'high', 'critical'
  algorithmRisk: number, // 1-10
  dataSensitivity: string, // 'public', 'internal', 'confidential', 'classified'
  systemCriticality: string, // 'low', 'medium', 'high', 'critical'
  timelineToThreat: string, // Estimated timeline
  harvestNowRisk: string, // 'low', 'medium', 'high'
  migrationPriority: string, // 'low', 'medium', 'high', 'critical'
  assessmentDate: timestamp,
  assessedBy: string,
  createdAt: timestamp,
  updatedAt: timestamp
}
```

### 3. PQC Milestones Table

Tracks migration roadmap milestones and deadlines.

```sql
-- SQL Schema (PostgreSQL)
CREATE TABLE pqc_milestones (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    roadmap_phase VARCHAR(50) NOT NULL, -- 'phase1', 'phase2', 'phase3', 'phase4'
    phase_name VARCHAR(100) NOT NULL, -- 'Preparation', 'Baseline Understanding', etc.
    milestone_name VARCHAR(255) NOT NULL,
    milestone_description TEXT,
    target_date DATE NOT NULL,
    actual_date DATE,
    status VARCHAR(20) NOT NULL DEFAULT 'pending', -- 'pending', 'in_progress', 'completed', 'blocked'
    progress_percentage INTEGER DEFAULT 0, -- 0-100
    dependencies JSONB, -- Array of milestone IDs this depends on
    assigned_to VARCHAR(255), -- User or team identifier
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_pqc_milestones_phase ON pqc_milestones(roadmap_phase);
CREATE INDEX idx_pqc_milestones_status ON pqc_milestones(status);
CREATE INDEX idx_pqc_milestones_date ON pqc_milestones(target_date);
```

```javascript
// Firestore Schema
pqc_milestones: {
  id: string (auto-generated),
  roadmapPhase: string, // 'phase1', 'phase2', 'phase3', 'phase4'
  phaseName: string, // 'Preparation', 'Baseline Understanding', etc.
  milestoneName: string,
  milestoneDescription: string,
  targetDate: timestamp,
  actualDate: timestamp,
  status: string, // 'pending', 'in_progress', 'completed', 'blocked'
  progressPercentage: number, // 0-100
  dependencies: array, // Array of milestone IDs
  assignedTo: string,
  createdAt: timestamp,
  updatedAt: timestamp
}
```

### 4. PQC Vendors Table

Catalog of PQC-ready vendors and solutions.

```sql
-- SQL Schema (PostgreSQL)
CREATE TABLE pqc_vendors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vendor_name VARCHAR(255) NOT NULL,
    solution_name VARCHAR(255) NOT NULL,
    solution_type VARCHAR(50) NOT NULL, -- 'library', 'service', 'hardware', 'software'
    fips_compliance JSONB, -- Array of FIPS standards supported ['FIPS-203', 'FIPS-204', 'FIPS-205']
    integration_type VARCHAR(50), -- 'API', 'SDK', 'library', 'service'
    cost_estimate JSONB, -- Pricing information
    roi_analysis JSONB, -- ROI calculations
    certification_status VARCHAR(50), -- 'certified', 'pending', 'not_certified'
    certification_details JSONB, -- Certification information
    contact_info JSONB, -- Vendor contact information
    documentation_url VARCHAR(500),
    api_endpoint VARCHAR(500),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_pqc_vendors_name ON pqc_vendors(vendor_name);
CREATE INDEX idx_pqc_vendors_compliance ON pqc_vendors USING GIN(fips_compliance);
```

```javascript
// Firestore Schema
pqc_vendors: {
  id: string (auto-generated),
  vendorName: string,
  solutionName: string,
  solutionType: string, // 'library', 'service', 'hardware', 'software'
  fipsCompliance: array, // ['FIPS-203', 'FIPS-204', 'FIPS-205']
  integrationType: string, // 'API', 'SDK', 'library', 'service'
  costEstimate: {
    licenseType: string,
    price: number,
    currency: string,
    period: string // 'monthly', 'yearly', 'one-time'
  },
  roiAnalysis: {
    implementationCost: number,
    annualSavings: number,
    paybackPeriod: number
  },
  certificationStatus: string, // 'certified', 'pending', 'not_certified'
  certificationDetails: object,
  contactInfo: {
    email: string,
    phone: string,
    website: string
  },
  documentationUrl: string,
  apiEndpoint: string,
  createdAt: timestamp,
  updatedAt: timestamp
}
```

### 5. PQC Timeline Table

Tracks critical deadlines (2030 deprecation, 2035 disallowance).

```sql
-- SQL Schema (PostgreSQL)
CREATE TABLE pqc_timeline (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    deadline_type VARCHAR(50) NOT NULL, -- 'deprecation', 'disallowance', 'migration', 'compliance'
    deadline_name VARCHAR(255) NOT NULL,
    target_date DATE NOT NULL,
    days_remaining INTEGER, -- Calculated field
    status VARCHAR(20) NOT NULL DEFAULT 'active', -- 'active', 'warning', 'critical', 'passed'
    organization_id UUID, -- Reference to organization
    affected_assets JSONB, -- Array of asset IDs affected by this deadline
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_pqc_timeline_date ON pqc_timeline(target_date);
CREATE INDEX idx_pqc_timeline_type ON pqc_timeline(deadline_type);
CREATE INDEX idx_pqc_timeline_status ON pqc_timeline(status);
```

```javascript
// Firestore Schema
pqc_timeline: {
  id: string (auto-generated),
  deadlineType: string, // 'deprecation', 'disallowance', 'migration', 'compliance'
  deadlineName: string,
  targetDate: timestamp,
  daysRemaining: number, // Calculated
  status: string, // 'active', 'warning', 'critical', 'passed'
  organizationId: string,
  affectedAssets: array, // Array of asset IDs
  createdAt: timestamp,
  updatedAt: timestamp
}
```

## Relationships

1. **pqc_assets** → **pqc_risks**: One-to-many (one asset can have multiple risk assessments over time)
2. **pqc_assets** → **pqc_timeline**: Many-to-many (assets affected by deadlines)
3. **pqc_milestones** → **pqc_milestones**: Self-referential (dependencies)

## Indexes

All tables include indexes on:
- Primary keys (automatic)
- Foreign keys
- Frequently queried fields (vulnerability, priority, status, dates)
- JSONB fields (using GIN indexes for PostgreSQL)

## Data Migration

When migrating from existing GRC database:
1. Identify existing cryptographic assets
2. Run PQC inventory discovery
3. Perform initial risk assessment
4. Create migration roadmap milestones
5. Set up timeline tracking

## Security Considerations

- All tables should have row-level security (RLS) for multi-tenant support
- Sensitive data (keys, certificates) should be encrypted at rest
- Access control based on organization/tenant
- Audit logging for all PQC-related operations

## Performance Optimization

- Use materialized views for complex queries (risk dashboards)
- Implement caching for frequently accessed data
- Partition large tables by date or organization
- Use connection pooling for database connections


