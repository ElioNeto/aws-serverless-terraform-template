# AWS Architecture Patterns

Comprehensive guide to different architectural patterns implemented with Terraform.

## Table of Contents

- [Event-Driven Architecture](#event-driven-architecture)
- [Microservices Architecture](#microservices-architecture)
- [CQRS Pattern](#cqrs-pattern)
- [Saga Pattern](#saga-pattern)
- [API Gateway Patterns](#api-gateway-patterns)
- [Data Patterns](#data-patterns)

---

## Event-Driven Architecture

### Overview

Event-driven architecture using Amazon EventBridge, SNS, and SQS for asynchronous communication between services.

### Architecture Diagram

```mermaid
graph LR
    subgraph "Producers"
        API[API Gateway]
        Lambda1[Order Service]
        Lambda2[Payment Service]
    end
    
    subgraph "Event Bus"
        EB[EventBridge<br/>Custom Bus]
    end
    
    subgraph "Consumers"
        Lambda3[Inventory Service]
        Lambda4[Notification Service]
        Lambda5[Analytics Service]
    end
    
    subgraph "Dead Letter"
        DLQ[SQS DLQ]
        S3[S3 Archive]
    end
    
    API --> Lambda1
    API --> Lambda2
    Lambda1 -->|OrderCreated| EB
    Lambda2 -->|PaymentProcessed| EB
    
    EB -->|Rule: order.*| Lambda3
    EB -->|Rule: payment.*| Lambda4
    EB -->|Rule: *| Lambda5
    
    Lambda3 -.Failed.-> DLQ
    Lambda4 -.Failed.-> DLQ
    DLQ --> S3
    
    style EB fill:#FF9900,color:#fff
    style DLQ fill:#e74c3c,color:#fff
```

### Key Components

#### 1. EventBridge Custom Bus
```hcl
resource "aws_cloudwatch_event_bus" "main" {
  name = "${var.project_name}-event-bus"
  
  tags = {
    Environment = var.environment
    Pattern     = "event-driven"
  }
}
```

#### 2. Event Rules
```hcl
resource "aws_cloudwatch_event_rule" "order_events" {
  name           = "order-events-rule"
  event_bus_name = aws_cloudwatch_event_bus.main.name
  
  event_pattern = jsonencode({
    source      = ["order.service"]
    detail-type = ["OrderCreated", "OrderUpdated"]
  })
}
```

#### 3. Event Targets
```hcl
resource "aws_cloudwatch_event_target" "inventory_lambda" {
  rule           = aws_cloudwatch_event_rule.order_events.name
  event_bus_name = aws_cloudwatch_event_bus.main.name
  arn            = aws_lambda_function.inventory_service.arn
  
  dead_letter_config {
    arn = aws_sqs_queue.dlq.arn
  }
  
  retry_policy {
    maximum_event_age       = 3600
    maximum_retry_attempts  = 3
  }
}
```

### Benefits

- ✅ **Loose Coupling**: Services don't know about each other
- ✅ **Scalability**: Each consumer scales independently
- ✅ **Resilience**: Built-in retry and DLQ
- ✅ **Extensibility**: Easy to add new consumers

### Use Cases

- E-commerce order processing
- Real-time data pipeline
- Microservices communication
- IoT data ingestion

---

## Microservices Architecture

### Overview

Independent, deployable services with their own data stores and APIs.

### Architecture Diagram

```mermaid
graph TB
    subgraph "API Layer"
        APIGW[API Gateway<br/>HTTP API]
        Auth[Cognito<br/>User Pool]
    end
    
    subgraph "Order Service"
        OrderLambda[Lambda<br/>Order API]
        OrderDB[(DynamoDB<br/>Orders)]
        OrderQueue[SQS<br/>Order Queue]
    end
    
    subgraph "Payment Service"
        PaymentLambda[Lambda<br/>Payment API]
        PaymentDB[(DynamoDB<br/>Payments)]
    end
    
    subgraph "Inventory Service"
        InventoryLambda[Lambda<br/>Inventory API]
        InventoryDB[(DynamoDB<br/>Inventory)]
        InventoryCache[(ElastiCache<br/>Redis)]
    end
    
    subgraph "Notification Service"
        NotifLambda[Lambda<br/>Notification]
        SNS[SNS Topic]
        SES[SES]
    end
    
    APIGW --> Auth
    Auth --> OrderLambda
    Auth --> PaymentLambda
    Auth --> InventoryLambda
    
    OrderLambda --> OrderDB
    OrderLambda --> OrderQueue
    OrderQueue --> PaymentLambda
    
    PaymentLambda --> PaymentDB
    PaymentLambda --> SNS
    
    InventoryLambda --> InventoryDB
    InventoryLambda --> InventoryCache
    
    SNS --> NotifLambda
    NotifLambda --> SES
    
    style OrderLambda fill:#3498db,color:#fff
    style PaymentLambda fill:#2ecc71,color:#fff
    style InventoryLambda fill:#9b59b6,color:#fff
    style NotifLambda fill:#e67e22,color:#fff
```

### Service Template

#### Directory Structure
```
microservices/
├── order-service/
│   ├── terraform/
│   │   ├── main.tf
│   │   ├── lambda.tf
│   │   ├── dynamodb.tf
│   │   └── api.tf
│   └── src/
│       ├── handlers/
│       ├── models/
│       └── utils/
├── payment-service/
├── inventory-service/
└── shared/
    ├── modules/
    │   ├── lambda/
    │   ├── api/
    │   └── database/
    └── policies/
```

#### Service Module
```hcl
module "order_service" {
  source = "./modules/microservice"
  
  service_name = "order"
  environment  = var.environment
  
  # Lambda configuration
  lambda_config = {
    runtime     = "nodejs18.x"
    memory_size = 512
    timeout     = 30
  }
  
  # Database configuration
  database_config = {
    billing_mode = "PAY_PER_REQUEST"
    hash_key     = "orderId"
    range_key    = "createdAt"
  }
  
  # API Gateway routes
  api_routes = [
    {
      path   = "/orders"
      method = "POST"
    },
    {
      path   = "/orders/{id}"
      method = "GET"
    }
  ]
  
  # Environment variables
  environment_variables = {
    PAYMENT_QUEUE_URL = module.payment_service.queue_url
    TABLE_NAME        = module.order_service.table_name
  }
}
```

### Communication Patterns

#### Synchronous (HTTP)
```typescript
// Order Service → Payment Service
const response = await fetch(
  `${process.env.PAYMENT_API_URL}/validate`,
  {
    method: 'POST',
    headers: { 'Authorization': `Bearer ${token}` },
    body: JSON.stringify({ amount, currency })
  }
);
```

#### Asynchronous (SQS)
```typescript
// Order Service → Payment Service
await sqs.sendMessage({
  QueueUrl: process.env.PAYMENT_QUEUE_URL,
  MessageBody: JSON.stringify({
    orderId: order.id,
    amount: order.total,
    timestamp: Date.now()
  })
}).promise();
```

### Benefits

- ✅ **Independent Deployment**: Each service deploys separately
- ✅ **Technology Diversity**: Different runtimes per service
- ✅ **Team Autonomy**: Teams own entire service lifecycle
- ✅ **Fault Isolation**: Service failures don't cascade

---

## CQRS Pattern

### Overview

Command Query Responsibility Segregation - separate read and write models for optimal performance.

### Architecture Diagram

```mermaid
graph TB
    subgraph "Write Side (Commands)"
        API[API Gateway]
        CmdLambda[Command Handler<br/>Lambda]
        WriteDB[(DynamoDB<br/>Write Model)]
        Stream[DynamoDB Streams]
    end
    
    subgraph "Event Processing"
        StreamLambda[Stream Processor<br/>Lambda]
    end
    
    subgraph "Read Side (Queries)"
        ReadDB1[(DynamoDB<br/>Read Model 1<br/>Optimized for List)]
        ReadDB2[(ElastiCache<br/>Read Model 2<br/>Hot Data)]
        ReadDB3[(OpenSearch<br/>Read Model 3<br/>Full-Text Search)]
        QueryLambda[Query Handler<br/>Lambda]
    end
    
    API -->|POST/PUT| CmdLambda
    CmdLambda --> WriteDB
    WriteDB --> Stream
    Stream --> StreamLambda
    
    StreamLambda --> ReadDB1
    StreamLambda --> ReadDB2
    StreamLambda --> ReadDB3
    
    API -->|GET| QueryLambda
    QueryLambda --> ReadDB1
    QueryLambda --> ReadDB2
    QueryLambda --> ReadDB3
    
    style CmdLambda fill:#e74c3c,color:#fff
    style QueryLambda fill:#2ecc71,color:#fff
    style StreamLambda fill:#3498db,color:#fff
```

### Implementation

#### Write Model (Commands)
```hcl
resource "aws_dynamodb_table" "write_model" {
  name           = "${var.project_name}-write-model"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"
  range_key      = "version"
  
  attribute {
    name = "id"
    type = "S"
  }
  
  attribute {
    name = "version"
    type = "N"
  }
  
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"
  
  point_in_time_recovery {
    enabled = true
  }
}
```

#### Read Model Projections
```hcl
# Read Model 1: List View
resource "aws_dynamodb_table" "read_model_list" {
  name         = "${var.project_name}-read-list"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "userId"
  range_key    = "createdAt"
  
  global_secondary_index {
    name            = "StatusIndex"
    hash_key        = "status"
    range_key       = "createdAt"
    projection_type = "ALL"
  }
}

# Read Model 2: Cache
resource "aws_elasticache_cluster" "read_cache" {
  cluster_id           = "${var.project_name}-read-cache"
  engine               = "redis"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
}
```

#### Stream Processor
```typescript
export const handler: DynamoDBStreamHandler = async (event) => {
  for (const record of event.Records) {
    if (record.eventName === 'INSERT' || record.eventName === 'MODIFY') {
      const newImage = record.dynamodb?.NewImage;
      
      // Project to read model 1
      await projectToListView(newImage);
      
      // Project to cache
      await projectToCache(newImage);
      
      // Project to search
      await projectToSearch(newImage);
    }
  }
};
```

### Benefits

- ✅ **Performance**: Optimized read models
- ✅ **Scalability**: Read/write scale independently
- ✅ **Flexibility**: Multiple read models for different use cases
- ✅ **Eventually Consistent**: Acceptable for most scenarios

---

## Saga Pattern

### Overview

Distributed transaction management using orchestration or choreography.

### Orchestration Pattern

```mermaid
sequenceDiagram
    participant Client
    participant Orchestrator
    participant Order
    participant Payment
    participant Inventory
    participant Shipping
    
    Client->>Orchestrator: Create Order
    
    Orchestrator->>Order: Create Order
    Order-->>Orchestrator: Order Created
    
    Orchestrator->>Payment: Process Payment
    Payment-->>Orchestrator: Payment Success
    
    Orchestrator->>Inventory: Reserve Items
    Inventory-->>Orchestrator: Items Reserved
    
    Orchestrator->>Shipping: Schedule Delivery
    Shipping-->>Orchestrator: Delivery Scheduled
    
    Orchestrator-->>Client: Order Completed
    
    Note over Orchestrator: If any step fails,<br/>compensating transactions<br/>are executed in reverse
```

### Choreography Pattern

```mermaid
sequenceDiagram
    participant API
    participant Order
    participant EventBus
    participant Payment
    participant Inventory
    participant Shipping
    
    API->>Order: Create Order
    Order->>EventBus: OrderCreated Event
    
    EventBus->>Payment: Receive Event
    Payment->>Payment: Process Payment
    Payment->>EventBus: PaymentProcessed Event
    
    EventBus->>Inventory: Receive Event
    Inventory->>Inventory: Reserve Items
    Inventory->>EventBus: ItemsReserved Event
    
    EventBus->>Shipping: Receive Event
    Shipping->>Shipping: Schedule Delivery
    Shipping->>EventBus: DeliveryScheduled Event
    
    EventBus->>Order: Receive Event
    Order->>API: Order Completed
```

### Implementation

#### Saga State Machine (Step Functions)
```hcl
resource "aws_sfn_state_machine" "order_saga" {
  name     = "${var.project_name}-order-saga"
  role_arn = aws_iam_role.step_functions.arn
  
  definition = jsonencode({
    Comment = "Order Processing Saga"
    StartAt = "CreateOrder"
    States = {
      CreateOrder = {
        Type     = "Task"
        Resource = aws_lambda_function.create_order.arn
        Catch = [{
          ErrorEquals = ["States.ALL"]
          Next        = "HandleFailure"
        }]
        Next = "ProcessPayment"
      }
      ProcessPayment = {
        Type     = "Task"
        Resource = aws_lambda_function.process_payment.arn
        Catch = [{
          ErrorEquals = ["States.ALL"]
          Next        = "CompensateOrder"
        }]
        Next = "ReserveInventory"
      }
      ReserveInventory = {
        Type     = "Task"
        Resource = aws_lambda_function.reserve_inventory.arn
        Catch = [{
          ErrorEquals = ["States.ALL"]
          Next        = "CompensatePayment"
        }]
        Next = "ScheduleShipping"
      }
      ScheduleShipping = {
        Type     = "Task"
        Resource = aws_lambda_function.schedule_shipping.arn
        Catch = [{
          ErrorEquals = ["States.ALL"]
          Next        = "CompensateInventory"
        }]
        Next = "Success"
      }
      Success = {
        Type = "Succeed"
      }
      CompensateInventory = {
        Type     = "Task"
        Resource = aws_lambda_function.compensate_inventory.arn
        Next     = "CompensatePayment"
      }
      CompensatePayment = {
        Type     = "Task"
        Resource = aws_lambda_function.compensate_payment.arn
        Next     = "CompensateOrder"
      }
      CompensateOrder = {
        Type     = "Task"
        Resource = aws_lambda_function.compensate_order.arn
        Next     = "HandleFailure"
      }
      HandleFailure = {
        Type = "Fail"
      }
    }
  })
}
```

### Benefits

- ✅ **Consistency**: Distributed transactions with compensations
- ✅ **Visibility**: Clear workflow visualization
- ✅ **Reliability**: Automatic retries and error handling
- ✅ **Auditability**: Complete execution history

---

## API Gateway Patterns

### Pattern Comparison

| Pattern | Use Case | Components |
|---------|----------|------------|
| **BFF** | Mobile + Web apps with different needs | Multiple API Gateways |
| **API Aggregation** | Combining multiple backend calls | Lambda aggregator |
| **Rate Limiting** | Protect backend from abuse | Usage plans + API keys |
| **Request Validation** | Input validation | API Gateway models |
| **Caching** | Reduce backend load | API Gateway cache |

### Backend for Frontend (BFF)

```mermaid
graph TB
    subgraph "Clients"
        Web[Web App]
        Mobile[Mobile App]
        Partner[Partner API]
    end
    
    subgraph "BFF Layer"
        WebBFF[Web BFF<br/>API Gateway]
        MobileBFF[Mobile BFF<br/>API Gateway]
        PartnerBFF[Partner BFF<br/>API Gateway]
    end
    
    subgraph "Backend Services"
        Service1[User Service]
        Service2[Order Service]
        Service3[Payment Service]
    end
    
    Web --> WebBFF
    Mobile --> MobileBFF
    Partner --> PartnerBFF
    
    WebBFF --> Service1
    WebBFF --> Service2
    MobileBFF --> Service1
    MobileBFF --> Service2
    PartnerBFF --> Service3
    
    style WebBFF fill:#3498db,color:#fff
    style MobileBFF fill:#2ecc71,color:#fff
    style PartnerBFF fill:#9b59b6,color:#fff
```

### API Aggregation

```typescript
// Lambda aggregator
export const handler = async (event: APIGatewayProxyEvent) => {
  const userId = event.requestContext.authorizer?.userId;
  
  // Parallel calls to multiple services
  const [user, orders, payments] = await Promise.all([
    fetchUser(userId),
    fetchOrders(userId),
    fetchPayments(userId)
  ]);
  
  // Aggregate response
  return {
    statusCode: 200,
    body: JSON.stringify({
      user: user,
      recentOrders: orders.slice(0, 5),
      paymentMethods: payments
    })
  };
};
```

---

## Data Patterns

### Single Table Design

```mermaid
graph TB
    subgraph "DynamoDB Table"
        PK[PK: Entity#ID]
        SK[SK: Type#Timestamp]
        GSI1[GSI1: Type#Status]
        GSI2[GSI2: UserId#CreatedAt]
    end
    
    subgraph "Access Patterns"
        P1[Get User by ID]
        P2[Get Orders by User]
        P3[Get Orders by Status]
        P4[Get Payments by Date]
    end
    
    P1 --> PK
    P2 --> GSI2
    P3 --> GSI1
    P4 --> SK
```

### Example Terraform

```hcl
resource "aws_dynamodb_table" "single_table" {
  name         = "${var.project_name}-data"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "PK"
  range_key    = "SK"
  
  attribute {
    name = "PK"
    type = "S"
  }
  
  attribute {
    name = "SK"
    type = "S"
  }
  
  attribute {
    name = "GSI1PK"
    type = "S"
  }
  
  attribute {
    name = "GSI1SK"
    type = "S"
  }
  
  global_secondary_index {
    name            = "GSI1"
    hash_key        = "GSI1PK"
    range_key       = "GSI1SK"
    projection_type = "ALL"
  }
  
  ttl {
    attribute_name = "expiresAt"
    enabled        = true
  }
}
```

### Data Structure Example

```json
// User Entity
{
  "PK": "USER#123",
  "SK": "METADATA",
  "type": "User",
  "email": "user@example.com",
  "name": "John Doe",
  "GSI1PK": "USER",
  "GSI1SK": "2026-02-26T20:00:00Z"
}

// Order Entity
{
  "PK": "USER#123",
  "SK": "ORDER#2026-02-26#456",
  "type": "Order",
  "orderId": "456",
  "total": 99.99,
  "status": "completed",
  "GSI1PK": "ORDER#completed",
  "GSI1SK": "2026-02-26T20:00:00Z"
}
```

---

## Performance Optimization Patterns

### Caching Strategy

```mermaid
graph LR
    Client[Client] --> CDN[CloudFront<br/>Edge Cache]
    CDN --> APIGW[API Gateway<br/>Cache]
    APIGW --> Lambda[Lambda]
    Lambda --> Redis[ElastiCache<br/>Redis]
    Redis --> DDB[(DynamoDB<br/>DAX)]
    DDB --> S3[(S3)]
    
    style CDN fill:#FF9900,color:#000
    style APIGW fill:#FF9900,color:#000
    style Redis fill:#DC382D,color:#fff
```

### Lambda Optimization

```hcl
resource "aws_lambda_function" "optimized" {
  function_name = "${var.project_name}-optimized"
  
  # Provisioned concurrency for predictable latency
  reserved_concurrent_executions = 10
  
  # Environment variables
  environment {
    variables = {
      # Connection pooling
      DB_POOL_SIZE = "10"
      
      # Cache TTL
      CACHE_TTL = "300"
      
      # Enable X-Ray
      AWS_XRAY_DAEMON_ADDRESS = "xray-daemon:2000"
    }
  }
  
  # VPC configuration for database access
  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [aws_security_group.lambda.id]
  }
  
  # Layers for shared dependencies
  layers = [
    aws_lambda_layer_version.shared_deps.arn
  ]
}

resource "aws_lambda_provisioned_concurrency_config" "optimized" {
  function_name                     = aws_lambda_function.optimized.function_name
  provisioned_concurrent_executions = 5
  qualifier                         = aws_lambda_alias.live.name
}
```

---

## Monitoring & Observability

### Comprehensive Observability

```mermaid
graph TB
    subgraph "Application"
        Lambda[Lambda Functions]
        API[API Gateway]
        DDB[(DynamoDB)]
    end
    
    subgraph "Metrics"
        CW[CloudWatch<br/>Metrics]
        Dashboard[CloudWatch<br/>Dashboards]
    end
    
    subgraph "Logs"
        Logs[CloudWatch Logs]
        Insights[CloudWatch<br/>Insights]
    end
    
    subgraph "Tracing"
        XRay[X-Ray]
        ServiceMap[Service Map]
    end
    
    subgraph "Alerts"
        Alarms[CloudWatch Alarms]
        SNS[SNS Topics]
        PagerDuty[PagerDuty]
    end
    
    Lambda --> CW
    API --> CW
    DDB --> CW
    
    Lambda --> Logs
    API --> Logs
    
    Lambda --> XRay
    API --> XRay
    
    CW --> Dashboard
    Logs --> Insights
    XRay --> ServiceMap
    
    CW --> Alarms
    Alarms --> SNS
    SNS --> PagerDuty
```

---

## Cost Optimization

### Strategies

1. **Right-sizing**
   - Use Lambda power tuning
   - DynamoDB on-demand vs provisioned
   - ElastiCache node sizing

2. **Reserved Capacity**
   - DynamoDB reserved capacity
   - Savings Plans for Lambda

3. **Data Lifecycle**
   - S3 lifecycle policies
   - DynamoDB TTL
   - CloudWatch Logs retention

4. **Caching**
   - API Gateway caching
   - Lambda@Edge
   - ElastiCache

---

## Security Best Practices

### Defense in Depth

```mermaid
graph TB
    subgraph "Edge"
        WAF[AWS WAF]
        Shield[AWS Shield]
    end
    
    subgraph "API Layer"
        APIGW[API Gateway]
        Cognito[Cognito]
    end
    
    subgraph "Application"
        Lambda[Lambda]
        Secrets[Secrets Manager]
    end
    
    subgraph "Data"
        DDB[(DynamoDB<br/>Encrypted)]
        S3[(S3<br/>Encrypted)]
    end
    
    subgraph "Network"
        VPC[VPC]
        SG[Security Groups]
        NACL[Network ACLs]
    end
    
    WAF --> APIGW
    Shield --> APIGW
    APIGW --> Cognito
    Cognito --> Lambda
    Lambda --> Secrets
    Lambda --> DDB
    Lambda --> S3
    Lambda --> VPC
    VPC --> SG
    VPC --> NACL
```

---

## Next Steps

Refer to the `examples/` directory for complete working implementations of each pattern.
