# Architecture Diagrams

Visual representations of AWS architecture patterns using Mermaid.

## High-Level Architecture

### Complete Serverless Stack

```mermaid
graph TB
    subgraph "Frontend"
        CloudFront[CloudFront CDN]
        S3Web[S3 Static Website]
    end
    
    subgraph "API Layer"
        APIGW[API Gateway<br/>REST API]
        Cognito[Cognito<br/>User Pool]
        WAF[AWS WAF]
    end
    
    subgraph "Compute"
        Lambda1[Lambda<br/>API Handler]
        Lambda2[Lambda<br/>Stream Processor]
        Lambda3[Lambda<br/>Async Worker]
    end
    
    subgraph "Event Bus"
        EventBridge[EventBridge]
        SQS[SQS Queue]
        SNS[SNS Topic]
    end
    
    subgraph "Data Layer"
        DynamoDB[(DynamoDB)]
        RDS[(RDS Aurora<br/>Serverless)]
        S3Data[(S3 Data Lake)]
        ElastiCache[(ElastiCache)]
    end
    
    subgraph "Monitoring"
        CloudWatch[CloudWatch]
        XRay[X-Ray]
        Logs[CloudWatch Logs]
    end
    
    CloudFront --> S3Web
    CloudFront --> WAF
    WAF --> APIGW
    APIGW --> Cognito
    Cognito --> Lambda1
    
    Lambda1 --> DynamoDB
    Lambda1 --> ElastiCache
    Lambda1 --> EventBridge
    
    EventBridge --> Lambda2
    EventBridge --> SQS
    SQS --> Lambda3
    
    Lambda2 --> RDS
    Lambda3 --> S3Data
    
    Lambda1 --> CloudWatch
    Lambda2 --> CloudWatch
    Lambda3 --> CloudWatch
    Lambda1 --> XRay
    
    style CloudFront fill:#FF9900,color:#000
    style APIGW fill:#FF9900,color:#000
    style EventBridge fill:#FF9900,color:#000
```

## Data Flow Diagrams

### Request Flow with Caching

```mermaid
sequenceDiagram
    participant Client
    participant CloudFront
    participant APIGW as API Gateway
    participant Lambda
    participant Cache as ElastiCache
    participant DB as DynamoDB
    
    Client->>CloudFront: HTTP Request
    
    alt Cache Hit (CloudFront)
        CloudFront-->>Client: Cached Response
    else Cache Miss
        CloudFront->>APIGW: Forward Request
        
        alt Cache Hit (API Gateway)
            APIGW-->>CloudFront: Cached Response
            CloudFront-->>Client: Response
        else Cache Miss
            APIGW->>Lambda: Invoke Function
            Lambda->>Cache: Check Cache
            
            alt Cache Hit (ElastiCache)
                Cache-->>Lambda: Cached Data
                Lambda-->>APIGW: Response
            else Cache Miss
                Cache-->>Lambda: Cache Miss
                Lambda->>DB: Query
                DB-->>Lambda: Data
                Lambda->>Cache: Update Cache
                Lambda-->>APIGW: Response
            end
            
            APIGW-->>CloudFront: Response + Cache
            CloudFront-->>Client: Response
        end
    end
```

### Event Processing Pipeline

```mermaid
flowchart LR
    A[Event Source] -->|Publish| B[EventBridge]
    B -->|Rule 1| C[Lambda 1<br/>Real-time]
    B -->|Rule 2| D[SQS Queue]
    B -->|Rule 3| E[Kinesis<br/>Stream]
    
    D --> F[Lambda 2<br/>Batch]
    E --> G[Lambda 3<br/>Analytics]
    
    C --> H[(DynamoDB)]
    F --> I[(S3)]
    G --> J[(Redshift)]
    
    C -.Failed.-> K[DLQ]
    F -.Failed.-> K
    G -.Failed.-> K
    
    K --> L[Lambda<br/>Error Handler]
    L --> M[SNS Alert]
    
    style B fill:#FF9900,color:#000
    style K fill:#e74c3c,color:#fff
```

## Infrastructure Diagrams

### Multi-Region Active-Active

```mermaid
graph TB
    subgraph "Global"
        R53[Route 53<br/>Latency-based Routing]
        CloudFront[CloudFront<br/>Global CDN]
    end
    
    subgraph "Region 1: us-east-1"
        API1[API Gateway]
        Lambda1[Lambda Functions]
        DDB1[(DynamoDB<br/>Global Table)]
        S31[(S3<br/>Cross-Region Replication)]
    end
    
    subgraph "Region 2: eu-west-1"
        API2[API Gateway]
        Lambda2[Lambda Functions]
        DDB2[(DynamoDB<br/>Global Table)]
        S32[(S3<br/>Cross-Region Replication)]
    end
    
    R53 --> CloudFront
    CloudFront --> API1
    CloudFront --> API2
    
    API1 --> Lambda1
    API2 --> Lambda2
    
    Lambda1 --> DDB1
    Lambda2 --> DDB2
    
    DDB1 <-.Bi-directional<br/>Replication.-> DDB2
    S31 <-.Cross-Region<br/>Replication.-> S32
    
    Lambda1 --> S31
    Lambda2 --> S32
```

### VPC Architecture

```mermaid
graph TB
    subgraph "VPC: 10.0.0.0/16"
        subgraph "Public Subnets"
            NAT1[NAT Gateway<br/>10.0.1.0/24]
            NAT2[NAT Gateway<br/>10.0.2.0/24]
        end
        
        subgraph "Private Subnets"
            Lambda1[Lambda<br/>10.0.11.0/24]
            Lambda2[Lambda<br/>10.0.12.0/24]
        end
        
        subgraph "Database Subnets"
            RDS1[RDS Primary<br/>10.0.21.0/24]
            RDS2[RDS Standby<br/>10.0.22.0/24]
        end
        
        IGW[Internet Gateway]
    end
    
    Internet[Internet] --> IGW
    IGW --> NAT1
    IGW --> NAT2
    
    NAT1 --> Lambda1
    NAT2 --> Lambda2
    
    Lambda1 --> RDS1
    Lambda2 --> RDS2
    
    RDS1 <-.Replication.-> RDS2
```

## Deployment Diagrams

### CI/CD Pipeline

```mermaid
graph LR
    subgraph "Source"
        GitHub[GitHub<br/>Repository]
    end
    
    subgraph "CI/CD"
        CodePipeline[CodePipeline]
        CodeBuild[CodeBuild]
    end
    
    subgraph "Testing"
        Unit[Unit Tests]
        Integration[Integration Tests]
        Security[Security Scan]
    end
    
    subgraph "Deploy Dev"
        TFPlan[Terraform Plan]
        TFApply[Terraform Apply]
    end
    
    subgraph "Deploy Prod"
        Approval[Manual Approval]
        ProdDeploy[Production Deploy]
    end
    
    GitHub -->|Webhook| CodePipeline
    CodePipeline --> CodeBuild
    
    CodeBuild --> Unit
    Unit --> Integration
    Integration --> Security
    
    Security -->|Pass| TFPlan
    TFPlan --> TFApply
    
    TFApply --> Approval
    Approval -->|Approved| ProdDeploy
    
    style Security fill:#2ecc71,color:#fff
    style Approval fill:#f39c12,color:#fff
```

### Blue-Green Deployment

```mermaid
graph TB
    subgraph "API Gateway"
        APIGW[API Gateway]
    end
    
    subgraph "Blue Environment (Current)"
        BlueAlias[Lambda Alias: blue]
        BlueV1[Lambda v1]
        BlueDDB[(DynamoDB)]
    end
    
    subgraph "Green Environment (New)"
        GreenAlias[Lambda Alias: green]
        GreenV2[Lambda v2]
        GreenDDB[(DynamoDB)]
    end
    
    APIGW -->|100% Traffic| BlueAlias
    APIGW -.0% Traffic.-> GreenAlias
    
    BlueAlias --> BlueV1
    GreenAlias --> GreenV2
    
    BlueV1 --> BlueDDB
    GreenV2 --> GreenDDB
    
    BlueDDB <-.Shared Data.-> GreenDDB
    
    style BlueAlias fill:#3498db,color:#fff
    style GreenAlias fill:#2ecc71,color:#fff
```

## Security Diagrams

### IAM Roles and Policies

```mermaid
graph TB
    subgraph "Lambda Execution"
        Lambda[Lambda Function]
        Role[IAM Role]
    end
    
    subgraph "Managed Policies"
        Basic[AWSLambdaBasicExecution]
        VPC[AWSLambdaVPCAccess]
    end
    
    subgraph "Custom Policies"
        DDBPolicy[DynamoDB Access]
        S3Policy[S3 Access]
        SecretsPolicy[Secrets Manager]
    end
    
    subgraph "Resources"
        DDB[(DynamoDB)]
        S3[(S3)]
        Secrets[Secrets Manager]
    end
    
    Lambda --> Role
    Role --> Basic
    Role --> VPC
    Role --> DDBPolicy
    Role --> S3Policy
    Role --> SecretsPolicy
    
    DDBPolicy --> DDB
    S3Policy --> S3
    SecretsPolicy --> Secrets
    
    style Role fill:#FF9900,color:#000
```

### Network Security

```mermaid
graph TB
    subgraph "Internet"
        User[Users]
        Attacker[Potential Threats]
    end
    
    subgraph "Edge Security"
        Shield[AWS Shield]
        WAF[AWS WAF]
        CloudFront[CloudFront]
    end
    
    subgraph "API Security"
        APIGW[API Gateway]
        Cognito[Cognito]
        ApiKey[API Keys]
    end
    
    subgraph "Application Security"
        Lambda[Lambda]
        SG[Security Groups]
        NACL[Network ACLs]
    end
    
    subgraph "Data Security"
        KMS[AWS KMS]
        DDB[(DynamoDB<br/>Encrypted)]
        S3[(S3<br/>Encrypted)]
    end
    
    User --> Shield
    Attacker -.Blocked.-> Shield
    Shield --> WAF
    WAF --> CloudFront
    CloudFront --> APIGW
    
    APIGW --> Cognito
    APIGW --> ApiKey
    Cognito --> Lambda
    
    Lambda --> SG
    Lambda --> NACL
    Lambda --> KMS
    
    KMS --> DDB
    KMS --> S3
    
    style Shield fill:#e74c3c,color:#fff
    style WAF fill:#e74c3c,color:#fff
    style KMS fill:#9b59b6,color:#fff
```

## Monitoring Dashboards

### Observability Stack

```mermaid
graph TB
    subgraph "Application"
        Services[Microservices]
        APIs[API Gateway]
        Functions[Lambda Functions]
    end
    
    subgraph "Data Collection"
        Metrics[CloudWatch Metrics]
        Logs[CloudWatch Logs]
        Traces[X-Ray Traces]
    end
    
    subgraph "Analysis"
        Insights[CloudWatch Insights]
        Dashboard[CloudWatch Dashboards]
        ServiceMap[X-Ray Service Map]
    end
    
    subgraph "Alerting"
        Alarms[CloudWatch Alarms]
        SNS[SNS]
        Lambda[Alert Lambda]
    end
    
    subgraph "Notification"
        Email[Email]
        Slack[Slack]
        PagerDuty[PagerDuty]
    end
    
    Services --> Metrics
    APIs --> Metrics
    Functions --> Metrics
    
    Services --> Logs
    APIs --> Logs
    Functions --> Logs
    
    Services --> Traces
    APIs --> Traces
    Functions --> Traces
    
    Metrics --> Dashboard
    Logs --> Insights
    Traces --> ServiceMap
    
    Metrics --> Alarms
    Alarms --> SNS
    SNS --> Lambda
    
    Lambda --> Email
    Lambda --> Slack
    Lambda --> PagerDuty
```

---

## Cost Optimization

### Cost Allocation

```mermaid
pie title Monthly AWS Costs ($5,000)
    "Lambda Compute" : 1500
    "API Gateway" : 800
    "DynamoDB" : 1200
    "Data Transfer" : 600
    "CloudWatch" : 400
    "S3 Storage" : 300
    "Other" : 200
```

### Savings Opportunities

```mermaid
graph LR
    subgraph "Current State"
        C1[Lambda<br/>$1,500/mo]
        C2[DynamoDB<br/>On-Demand<br/>$1,200/mo]
        C3[Data Transfer<br/>$600/mo]
    end
    
    subgraph "Optimizations"
        O1[Right-sizing<br/>Save 30%]
        O2[Reserved Capacity<br/>Save 40%]
        O3[CloudFront<br/>Save 50%]
    end
    
    subgraph "Optimized State"
        N1[Lambda<br/>$1,050/mo]
        N2[DynamoDB<br/>Reserved<br/>$720/mo]
        N3[Data Transfer<br/>$300/mo]
    end
    
    C1 --> O1 --> N1
    C2 --> O2 --> N2
    C3 --> O3 --> N3
    
    style O1 fill:#2ecc71,color:#fff
    style O2 fill:#2ecc71,color:#fff
    style O3 fill:#2ecc71,color:#fff
```

---

For implementation details, refer to the corresponding Terraform modules in the `terraform/modules/` directory.
