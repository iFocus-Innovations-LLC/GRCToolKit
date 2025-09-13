# GRCToolKit

A comprehensive Governance, Risk, and Compliance (GRC) toolkit that provides AI-powered analysis of compliance scenarios and suggests relevant NIST 800-53 R.5 controls. The application is containerized and ready for deployment to Google Cloud Platform (GCP) Kubernetes environments.

## 🚀 Quick Start

### Local Development
1. Open `grctoolkit.html` in your web browser
2. Enter a GRC scenario in the text area
3. Click "Analyze Scenario" to get AI-powered NIST control recommendations

### Containerized Deployment
For production deployment to GCP Kubernetes, see the [Deployment Guide](DEPLOYMENT.md).

```bash
# Quick deployment to GCP
./scripts/setup-gcp.sh
./scripts/deploy.sh production
```

## 🏗️ Architecture

This web application provides a user interface for interacting with a simulated AI GRC agent. When you enter a scenario and click "Analyze Scenario," it will send your prompt to the gemini-2.0-flash model, which is instructed to act as a GRC expert and return relevant NIST 800-53 R.5 controls.

## ✨ Key Features

### Enhanced User Interface
- **Responsive Design**: Clean, mobile-first layout using Tailwind CSS
- **Structured JSON Output**: AI responses formatted as structured data for better parsing
- **Advanced Filtering**: Filter controls by priority and category
- **Smart Sorting**: Sort by priority, control ID, or title
- **NIST Documentation Links**: Direct links to official NIST 800-53 documentation
- **Export Functionality**: Download analysis results as JSON

### AI Integration
- **Gemini 2.0 Flash**: Advanced AI model for GRC analysis
- **Structured Responses**: JSON-formatted output with controls, CSF mappings, and recommendations
- **Context-Aware Analysis**: AI acts as a GRC expert with domain-specific knowledge
- **Error Handling**: Graceful fallback for API failures

### Production-Ready Deployment
- **Containerized**: Docker-based deployment with nginx
- **Kubernetes Ready**: Complete K8s manifests for GCP deployment
- **CI/CD Pipeline**: Automated testing and deployment with GitHub Actions
- **Auto-scaling**: Horizontal Pod Autoscaler for dynamic scaling
- **Security**: Non-root containers, security headers, and vulnerability scanning
- **Monitoring**: Health checks, logging, and observability features

Next Steps & Potential Enhancements:

Refine AI Prompting: Experiment with more detailed prompts to get more precise and structured responses from the AI, potentially including specific CSF 2.0 mappings.

Structured Output: Modify the generationConfig to request a JSON schema for the AI's response (e.g., an array of objects, each containing a control ID, name, and explanation). This would make parsing and displaying the results much easier and more consistent.

Actual GRC Data Integration: For a real grctoolkit.ai, you would need to ingest the actual NIST 800-53 and CSF 2.0 data into a database (like Firestore) and use a more sophisticated backend to perform the control mapping and reasoning, rather than relying solely on the LLM for direct recall.

User Authentication & Data Persistence: Integrate Firebase Authentication to manage users and Firestore to save user queries, generated reports, or custom GRC data.

Advanced UI: Add features like filtering controls, linking to official NIST documentation, and allowing users to mark controls as implemented.

Backend AI Logic: Develop a dedicated backend service to host more complex AI models (e.g., fine-tuned models for GRC, knowledge graphs) and integrate with other GRC tools.
