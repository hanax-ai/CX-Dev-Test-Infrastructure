# Contributing to CX Dev & Test Infrastructure

Thank you for your interest in contributing to the CX Dev & Test Infrastructure! This document provides guidelines and information for contributors.

## Table of Contents

- [Getting Started](#getting-started)
- [Development Environment](#development-environment)
- [Contribution Workflow](#contribution-workflow)
- [Code Standards](#code-standards)
- [Testing Requirements](#testing-requirements)
- [Security Guidelines](#security-guidelines)
- [Documentation](#documentation)
- [Review Process](#review-process)

## Getting Started

### Prerequisites

Before contributing, ensure you have:

- **VPN Access** to the CX network (192.168.10.0/24)
- **SSH Access** to development servers
- **Python 3.12.3** development environment
- **Git** configured with proper credentials
- **Docker** for containerized development

### Initial Setup

1. **Fork the Repository**
   ```bash
   # Fork the repo on GitHub
   git clone https://github.com/YOUR_USERNAME/CX-Dev-Test-Infrastructure.git
   cd CX-Dev-Test-Infrastructure
   ```

2. **Connect to Development Environment**
   ```bash
   ssh agent0@192.168.10.33
   cd /opt/citadel/workspace
   ```

3. **Setup Python Environment**
   ```bash
   source /opt/citadel/env/bin/activate
   pip install -r requirements-dev.txt
   ```

4. **Install Pre-commit Hooks**
   ```bash
   pre-commit install
   pre-commit install --hook-type commit-msg
   ```

## Development Environment

### Development Server Access

- **Primary Dev Server:** 192.168.10.33 (8-core Xeon, 125GB RAM)
- **Test Server:** 192.168.10.34 (12-core Xeon, 125GB RAM)
- **DevOps Server:** 192.168.10.36 (CI/CD automation)

### Environment Variables

Create a `.env` file with required configurations:

```bash
# Database Connections
POSTGRES_HOST=192.168.10.35
POSTGRES_PORT=5432
POSTGRES_DB=citadel_db
REDIS_HOST=192.168.10.35
REDIS_PORT=6379

# Vector Database
QDRANT_HOST=192.168.10.30
QDRANT_PORT=6333

# AI Services
LLAMA_CHAT_ENDPOINT=http://192.168.10.28:8000
LLAMA_INSTRUCT_ENDPOINT=http://192.168.10.29:8000
EMBEDDING_ENDPOINT=http://192.168.10.31:11434

# Monitoring
PROMETHEUS_URL=http://192.168.10.37:9090
GRAFANA_URL=http://192.168.10.37:3000
```

## Contribution Workflow

### 1. Create Feature Branch

```bash
git checkout -b feature/your-feature-name
```

### 2. Development Cycle

```bash
# Make your changes
git add .
git commit -m "feat: add amazing feature"

# Run tests locally
pytest tests/
python -m mypy src/
black src/ tests/
flake8 src/ tests/

# Push to your fork
git push origin feature/your-feature-name
```

### 3. Pull Request

1. Open a Pull Request from your fork
2. Fill out the PR template completely
3. Ensure all CI checks pass
4. Request review from maintainers

## Code Standards

### Python Code Style

- **Formatter:** Black (line length: 88)
- **Linter:** Flake8 with custom config
- **Type Checker:** MyPy with strict mode
- **Import Sorting:** isort

### Configuration Files

**.pre-commit-config.yaml**
```yaml
repos:
  - repo: https://github.com/psf/black
    rev: 23.3.0
    hooks:
      - id: black
        language_version: python3.12
  
  - repo: https://github.com/pycqa/flake8
    rev: 6.0.0
    hooks:
      - id: flake8
  
  - repo: https://github.com/pre-commit/mirrors-mypy
    rev: v1.3.0
    hooks:
      - id: mypy
        additional_dependencies: [types-all]
```

### Naming Conventions

- **Functions/Variables:** `snake_case`
- **Classes:** `PascalCase`
- **Constants:** `UPPER_SNAKE_CASE`
- **Modules:** `lowercase` or `snake_case`
- **Packages:** `lowercase`

### Documentation Standards

- **Docstrings:** Google style
- **Type Hints:** Required for all public functions
- **Comments:** Explain WHY, not WHAT

Example:
```python
def process_llama_request(
    prompt: str, 
    model_type: str = "chat",
    max_tokens: int = 1000
) -> Dict[str, Any]:
    """Process a request to Llama models with optimized routing.
    
    Args:
        prompt: The input text prompt for the model
        model_type: Type of model (chat, instruct, embedding)
        max_tokens: Maximum number of tokens to generate
        
    Returns:
        Dictionary containing model response and metadata
        
    Raises:
        ValueError: If model_type is not supported
        ConnectionError: If unable to reach model server
    """
    # Implementation details...
```

## Testing Requirements

### Test Coverage

- **Minimum Coverage:** 80% overall
- **Critical Components:** 95% coverage required
- **Integration Tests:** All API endpoints must have tests

### Test Categories

1. **Unit Tests** (`tests/unit/`)
   ```bash
   pytest tests/unit/ -v --cov=src/
   ```

2. **Integration Tests** (`tests/integration/`)
   ```bash
   pytest tests/integration/ -v --tb=short
   ```

3. **Performance Tests** (`tests/performance/`)
   ```bash
   pytest tests/performance/ -v --benchmark-only
   ```

4. **Security Tests** (`tests/security/`)
   ```bash
   pytest tests/security/ -v --strict-markers
   ```

### Test Data

- Use factories for test data generation
- Mock external dependencies
- Clean up test data after each test

Example Test:
```python
import pytest
from unittest.mock import patch, MagicMock
from src.ai.llama_client import LlamaClient

class TestLlamaClient:
    @pytest.fixture
    def client(self):
        return LlamaClient(endpoint="http://test-endpoint:8000")
    
    @patch('src.ai.llama_client.requests.post')
    def test_chat_completion_success(self, mock_post, client):
        # Arrange
        mock_response = MagicMock()
        mock_response.json.return_value = {"response": "Hello, world!"}
        mock_response.status_code = 200
        mock_post.return_value = mock_response
        
        # Act
        result = client.chat_completion("Hello")
        
        # Assert
        assert result["response"] == "Hello, world!"
        mock_post.assert_called_once()
```

## Security Guidelines

### Code Security

1. **No Hardcoded Secrets**
   - Use environment variables
   - Use Azure Key Vault for production
   - Scan with `bandit` security linter

2. **Input Validation**
   - Validate all user inputs
   - Use Pydantic models for API requests
   - Sanitize SQL queries

3. **Authentication/Authorization**
   - Implement proper JWT validation
   - Use role-based access control
   - Log all authentication attempts

### Infrastructure Security

1. **Network Security**
   - All connections must use TLS 1.3
   - Implement network segmentation
   - Regular security scans

2. **Data Protection**
   - Encrypt data at rest (AES-256)
   - Encrypt data in transit
   - Implement data retention policies

## Documentation

### Required Documentation

1. **Code Documentation**
   - Comprehensive docstrings
   - Type hints for all functions
   - Inline comments for complex logic

2. **API Documentation**
   - OpenAPI/Swagger specifications
   - Example requests/responses
   - Error code documentation

3. **Architecture Documentation**
   - System design documents
   - Database schemas
   - Integration diagrams

### Documentation Tools

- **API Docs:** FastAPI automatic documentation
- **Code Docs:** Sphinx with Google style
- **Diagrams:** Mermaid or PlantUML

## Review Process

### Automated Checks

All PRs must pass:

- [ ] **CI/CD Pipeline** (Azure DevOps)
- [ ] **Code Quality** (SonarQube)
- [ ] **Security Scan** (Bandit, Safety)
- [ ] **Test Coverage** (>80%)
- [ ] **Performance Tests** (no regression)

### Manual Review

1. **Code Review Checklist**
   - [ ] Code follows style guidelines
   - [ ] Adequate test coverage
   - [ ] Security considerations addressed
   - [ ] Documentation updated
   - [ ] Performance impact assessed

2. **Review Timeline**
   - **Small PRs** (<100 lines): 24 hours
   - **Medium PRs** (100-500 lines): 48 hours
   - **Large PRs** (>500 lines): 72 hours

### Approval Process

- **2 approvals** required from core maintainers
- **1 approval** from security team (for security-related changes)
- **All CI checks** must pass
- **Conflicts resolved** and branch up-to-date

## Getting Help

### Communication Channels

- **Technical Discussions:** GitHub Issues
- **Quick Questions:** Slack #cx-infrastructure
- **Security Issues:** security@citadel-ai.com (private)
- **General Help:** infrastructure@citadel-ai.com

### Resources

- **Internal Wiki:** https://wiki.citadel-ai.com/infrastructure
- **API Documentation:** http://192.168.10.39:8000/docs
- **Monitoring Dashboards:** http://192.168.10.37:3000
- **Code Examples:** `/examples` directory in repo

## Recognition

Contributors will be recognized in:

- **Monthly Team Meetings**
- **Release Notes** for significant contributions
- **Internal Blog Posts** for innovative solutions
- **Conference Presentations** for major features

Thank you for contributing to the CX Dev & Test Infrastructure! 🚀

---

**Document Version:** 1.0  
**Last Updated:** July 28, 2025  
**Maintainers:** CX Infrastructure Team
