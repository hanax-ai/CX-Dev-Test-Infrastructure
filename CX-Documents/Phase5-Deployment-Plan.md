# Citadel Alpha Project: Infrastructure Deployment Plan - Phase 5

**Report Date:** August 2, 2025  
**Project:** Citadel Alpha  
**Phase:** 5 - API Gateway & Web Services  
**Timeline:** August 3-10, 2025  

---

## 📋 Executive Summary

**Purpose:** With Phase 4 (AI Processing Tier) successfully completed as confirmed in the updated status report, this document outlines the deployment plan for Phase 5: API Gateway & Web Services. The phase focuses on creating a production-ready web interface and API gateway layer that integrates with the existing AI processing infrastructure.

**Key Achievement from Phase 4:** 6 models deployed, dual GPU parallelism (32GB VRAM), Ollama 0.10.1 operational across three servers with Jenkins integration complete.

---

## 🎯 Phase 5 Objectives

### Primary Goals
1. **Web Interface Deployment:** Open WebUI for LLM interaction
2. **API Gateway Implementation:** FastAPI routing to LLM endpoints
3. **Database Optimization:** PostgreSQL/Redis for conversation history and caching
4. **Vector Database Integration:** Qdrant for RAG (Retrieval-Augmented Generation) pipelines
5. **Load Balancing:** Nginx proxy for traffic distribution
6. **Security Implementation:** TLS 1.3 and authentication integration

### Integration Flow
```
User Request → CX-Web (.38) → CX-API Gateway (.39) → Load Balancer
                                                   ↓
Embeddings (.31) → Qdrant (.30) → Inference (.28/.29) → Response
```

---

## 🏢 Target Infrastructure - Phase 5

### Server Allocation (IP Corrected)
| Server | IP Address | Role | Primary Function |
|--------|------------|------|------------------|
| **CX-Web** | 192.168.10.38 | Web Interface | Open WebUI for LLM interaction |
| **CX-API Gateway** | 192.168.10.39 | API Router | FastAPI + Nginx load balancing |
| **CX-Database** | 192.168.10.35 | Data Storage | PostgreSQL + Redis optimization |
| **CX-Vector Database** | 192.168.10.30 | Vector Search | Qdrant for RAG pipelines |

### Dependencies (Phase 4 - Already Deployed)
| Server | IP Address | Status | Function |
|--------|------------|--------|----------|
| CX-Orchestration | 192.168.10.31 | ✅ Operational | Embedding generation |
| CX-LLM Server 01 (Chat) | 192.168.10.29 | ✅ Operational | Conversational AI |
| CX-LLM Server 02 (Instruct) | 192.168.10.28 | ✅ Operational | Instruction following |

---

## 🔧 Technical Stack - Phase 5

### CX-Web Server (192.168.10.38)
- **Framework:** Open WebUI (latest stable)
- **Runtime:** Node.js 18+ with PM2 process manager
- **Web Server:** Nginx reverse proxy
- **Port Configuration:** 3000 (app), 80/443 (web)
- **Dependencies:** Docker for containerized deployment

### CX-API Gateway (192.168.10.39)
- **Framework:** FastAPI with async support
- **Load Balancer:** Nginx with upstream configuration
- **Authentication:** Clerk integration for user management
- **Monitoring:** Prometheus metrics collection
- **Port Configuration:** 8000 (FastAPI), 80/443 (Nginx)

### CX-Database (192.168.10.35)
- **Primary DB:** PostgreSQL 15+ for conversation history
- **Cache Layer:** Redis 7+ for session and response caching
- **Backup Strategy:** Automated daily backups
- **Optimization:** Connection pooling and indexing

### CX-Vector Database (192.168.10.30)
- **Engine:** Qdrant vector database
- **Configuration:** High-performance vector search
- **Integration:** REST API for RAG operations
- **Storage:** Optimized for embedding vectors

---

## 🚀 Deployment Strategy

### Execution Approach
**Method:** Grouped Ansible playbook for Phase 5 with dedicated roles per server  
**Orchestration:** Jenkins pipeline trigger from CX-DevOps (192.168.10.36)  
**Deployment Order:** Database → Vector DB → API Gateway → Web Interface

### Ansible Playbook Structure
```
configs/ansible/
├── deploy-phase5.yml                 # Main orchestration playbook
├── roles/
│   ├── web-interface/               # Open WebUI deployment
│   ├── api-gateway/                 # FastAPI + Nginx configuration
│   ├── database-optimization/       # PostgreSQL + Redis setup
│   └── vector-database/             # Qdrant deployment
└── group_vars/
    └── phase5_servers.yml           # Configuration variables
```

---

## 📊 RAG Pipeline Integration

### Data Flow Architecture
1. **Data Ingestion:** Content crawling and preprocessing
2. **Embedding Generation:** CX-Orchestration (192.168.10.31)
3. **Vector Storage:** Qdrant on CX-Vector Database (192.168.10.30)
4. **Query Processing:** FastAPI on CX-API Gateway (192.168.10.39)
5. **Retrieval & Generation:** LLM Servers (192.168.10.28/29)
6. **Response Delivery:** Open WebUI (192.168.10.38)

### Performance Optimization
- **Vector Search:** Optimized HNSW indexing in Qdrant
- **Caching Strategy:** Redis for frequent queries
- **Load Balancing:** Round-robin across LLM servers
- **Connection Pooling:** Database connection optimization

---

## 🔐 Security Implementation

### Transport Security
- **TLS 1.3:** All inter-service communication
- **Certificate Management:** Let's Encrypt automation
- **API Authentication:** JWT tokens with Clerk integration

### Network Security
- **Firewall Rules:** UFW configuration for internal access only
- **Port Management:** Selective port exposure
- **Access Control:** Role-based permissions

### Data Protection
- **Database Encryption:** At-rest encryption for PostgreSQL
- **Session Security:** Secure cookie configuration
- **API Rate Limiting:** DDoS protection

---

## 📅 Implementation Timeline

### Week 1: August 3-6, 2025
- **Day 1:** CX-Database deployment (PostgreSQL + Redis)
- **Day 2:** CX-Vector Database setup (Qdrant)
- **Day 3:** CX-API Gateway implementation (FastAPI)
- **Day 4:** Initial integration testing

### Week 2: August 7-10, 2025
- **Day 5:** CX-Web deployment (Open WebUI)
- **Day 6:** Load balancing configuration
- **Day 7:** Security hardening and TLS setup
- **Day 8:** End-to-end testing and validation

---

## ✅ Success Criteria

### Functional Requirements
- [ ] Open WebUI accessible and responsive
- [ ] FastAPI routing to all LLM endpoints
- [ ] PostgreSQL storing conversation history
- [ ] Redis caching active and performant
- [ ] Qdrant vector search operational
- [ ] RAG pipeline end-to-end functional

### Performance Requirements
- [ ] Web interface response time < 2 seconds
- [ ] API gateway latency < 100ms
- [ ] Vector search query time < 500ms
- [ ] Database query optimization verified
- [ ] Load balancing distributing traffic evenly

### Security Requirements
- [ ] TLS 1.3 encryption active
- [ ] Authentication working via Clerk
- [ ] Firewall rules properly configured
- [ ] All services isolated and secured

---

## 🔍 Testing & Validation

### Integration Testing
1. **RAG Pipeline Test:** Complete flow from query to response
2. **Load Testing:** Multiple concurrent users
3. **Failover Testing:** Service redundancy validation
4. **Security Testing:** Authentication and encryption verification

### Performance Benchmarking
- **Throughput:** Requests per second capacity
- **Latency:** Response time measurements
- **Resource Usage:** CPU, memory, and storage utilization
- **Scalability:** Concurrent user capacity

---

## 📋 Prerequisites & Assumptions

### Infrastructure Assumptions
- **Base OS:** Ubuntu Server 24.04 LTS installed on all target servers
- **Network Access:** SSH connectivity as agent0 user with sudo privileges
- **Internet Connectivity:** Package downloads (apt, pip, npm) available
- **Phase 4 Dependencies:** All AI processing tier services operational

### Configuration Requirements
- **Ansible Control:** CX-DevOps server ready for deployment orchestration
- **Git Repository:** Latest configurations pulled and synchronized
- **Jenkins Integration:** Pipeline ready for automated deployment
- **Monitoring:** Health check scripts prepared for validation

---

## 🚨 Risk Mitigation

### Technical Risks
- **Service Dependencies:** Graceful degradation if LLM servers unavailable
- **Database Performance:** Query optimization and connection pooling
- **Network Latency:** Load balancing and caching strategies
- **Security Vulnerabilities:** Regular security updates and scanning

### Operational Risks
- **Deployment Rollback:** Automated rollback procedures
- **Service Monitoring:** Comprehensive health checks
- **Backup Strategy:** Data protection and recovery procedures
- **Performance Degradation:** Auto-scaling and alerting

---

## 📞 Support & Documentation

**Primary Contact:** CX-DevOps Team  
**Repository:** `/opt/CX-Dev-Test-Infrastructure`  
**Documentation:** `/opt/CX-Dev-Test-Infrastructure/CX-Documents/Phase5/`  
**Deployment Scripts:** `/opt/CX-Dev-Test-Infrastructure/configs/ansible/`  
**Monitoring:** Jenkins pipeline and health check scripts  

---

**Plan Status:** READY FOR EXECUTION  
**Next Action:** Create Ansible playbooks and roles for Phase 5 deployment  
**Approval Required:** Development team sign-off before production deployment  

**Phase 4 Validation:** ✅ COMPLETE - 6 models operational, dual GPU active, Jenkins integrated  
**Phase 5 Readiness:** ✅ READY - Infrastructure planned, dependencies verified, timeline established
