# AWS High Availability Web Architecture 🚀

A production-style AWS infrastructure project implementing:

- High Availability (HA)
- Application Load Balancer (ALB)
- Auto Scaling Group (ASG)
- CloudWatch Monitoring & Alarms
- Self-Healing Infrastructure
- Multi-AZ Deployment
- Dynamic CPU-based Scaling
- Automated EC2 provisioning using User Data

Built completely on AWS using:

- VPC
- EC2
- ALB
- Auto Scaling
- CloudWatch
- nginx
- Launch Templates

---

# 📐 Architecture Overview

```text
                     Internet
                         │
                         ▼
           ┌─────────────────────────┐
           │  Application Load       │
           │     Balancer (ALB)      │
           └──────────┬──────────────┘
                      │
          ┌───────────┴───────────┐
          ▼                       ▼
 ┌────────────────┐     ┌────────────────┐
 │ EC2 Instance   │     │ EC2 Instance   │
 │ AZ-1           │     │ AZ-2           │
 │ nginx          │     │ nginx          │
 └────────────────┘     └────────────────┘
          ▲                       ▲
          └───────────┬───────────┘
                      │
              Auto Scaling Group
                      │
               CloudWatch Alarms
         CPU > 75%  → Scale Out
         CPU < 45%  → Scale In
```

---

# 🧩 AWS Services Used

| Service | Purpose |
|---|---|
| VPC | Isolated AWS network |
| Public Subnets | Internet-facing resources |
| Internet Gateway | Internet access |
| Security Groups | Firewall rules |
| EC2 | Web servers |
| nginx | Web application |
| Application Load Balancer | Traffic distribution |
| Target Groups | Backend registration |
| Auto Scaling Group | Dynamic scaling |
| Launch Template | EC2 standardization |
| CloudWatch | Monitoring & alarms |

---

# ⚙️ Infrastructure Components

## VPC Configuration

| Component | CIDR |
|---|---|
| VPC | `10.0.0.0/16` |
| Public Subnet AZ-1 | `10.0.1.0/24` |
| Public Subnet AZ-2 | `10.0.3.0/24` |

---

# 🔒 Security Groups

## ALB Security Group

| Type | Port | Source |
|---|---|---|
| HTTP | 80 | 0.0.0.0/0 |

---

## EC2 Security Group

| Type | Port | Source |
|---|---|---|
| HTTP | 80 | ALB Security Group |
| SSH | 22 | My IP |
| ICMP | All | My IP |

---

# 🚀 Project Features

## ✅ Application Load Balancer (ALB)

- Internet-facing ALB
- Routes traffic to healthy EC2 instances
- Performs automatic health checks
- Supports fault tolerance

---

## ✅ Auto Scaling Group (ASG)

| Setting | Value |
|---|---|
| Minimum Capacity | 1 |
| Desired Capacity | 2 |
| Maximum Capacity | 3 |

### Features

- Automatic scaling
- Self-healing infrastructure
- Multi-AZ balancing
- Automatic unhealthy instance replacement

---

# 📈 CloudWatch Dynamic Scaling

## Scale-Out Policy

```text
CPU > 75%
→ Launch 1 new EC2 instance
```

---

## Scale-In Policy

```text
CPU < 45%
→ Terminate 1 EC2 instance
```

---

# 📊 Scaling Workflow

```text
High CPU Load
      │
      ▼
CloudWatch Alarm Triggered
      │
      ▼
Auto Scaling Group
      │
      ▼
Launch New EC2 Instance
      │
      ▼
ALB Registers Target
      │
      ▼
Traffic Distributed Automatically
```

---

# 🖥️ EC2 User Data Automation

Each EC2 instance automatically:

- Installs nginx
- Installs stress testing tool
- Starts nginx service
- Generates dynamic HTML page
- Displays:
  - Instance ID
  - Availability Zone
  - Instance Type
  - ALB information
  - Scaling policy details

---

# 📜 User Data Script

The complete EC2 bootstrap script is available in:

```text
user-data-final.sh
```

This script automatically:

- Installs nginx
- Installs stress package
- Enables and starts nginx
- Retrieves EC2 metadata using IMDSv2
- Generates a dynamic web page displaying:
  - Instance ID
  - Availability Zone
  - Instance Type
  - ALB information
  - Scaling policies

---

# 🧪 Testing Performed

---

## ✅ Load Balancing Test

Refreshing the ALB DNS endpoint displays different instance IDs.

### Result

- Verified ALB distributes traffic correctly.
- Verified Multi-AZ routing.

---

## ✅ Health Check Test

Stopped one EC2 instance manually.

### Result

```text
ALB detected unhealthy target
→ ASG launched replacement instance
→ New instance registered automatically
→ Target became healthy
```

---

## ✅ Self-Healing Test

Terminated EC2 instances manually.

### Result

```text
ASG automatically recreated instances
without manual intervention
```

---

## ✅ Scale-Out Test

Generated CPU load:

```bash
stress --cpu 2 --timeout 300
```

### Expected Result

```text
CPU > 75%
→ CloudWatch alarm triggered
→ ASG launched new EC2 instance
```

---

## ✅ Scale-In Test

After stress test completed:

```text
CPU < 45%
→ CloudWatch alarm triggered
→ ASG terminated extra EC2 instance
```

---

# 🔥 Concepts Demonstrated

- High Availability
- Fault Tolerance
- Self-Healing Infrastructure
- Elastic Scaling
- Health Checks
- Connection Draining
- Multi-AZ Architecture
- Cloud Monitoring
- Dynamic Scaling
- Infrastructure Automation

---

# 📁 Repository Structure

```text
aws-ha-web-architecture/
│
├── LICENSE
├── README.md                        ← This file
├── user-data-final.sh               ← EC2 launch script (nginx + HTML page)
│
└── screenshots/
    ├── App.png                      ← nginx page showing Instance ID
    ├── ALB-Resource map.png         ← ALB resource map with targets
    ├── ALP-Activity.png             ← Auto Scaling Group activity log
    ├── Autoscaling-group.png        ← ASG configuration overview
    ├── Launch template.png          ← Launch template details
    ├── Target-group.png             ← Target group health status
    ├── cloudwatch-alarm1.png        ← Scale-out alarm (CPU > 75%)
    └── cloudwatch-alarm2.png        ← Scale-in alarm (CPU < 45%)
```

---

# 📸 Screenshots Included

- Application running behind ALB
- ALB Resource Map
- Auto Scaling activity logs
- Launch Template configuration
- Target Group health checks
- CloudWatch alarms
- Dynamic EC2 scaling events

---

# 🧠 Key Learnings

This project demonstrates practical experience with:

- AWS Networking
- EC2 Operations
- Load Balancing
- Auto Scaling
- Monitoring & Alerting
- Infrastructure Resiliency
- Production-style Cloud Architecture

---

# 🚀 Future Improvements

- HTTPS using ACM
- Route53 Domain
- AWS WAF
- CloudFront CDN
- Terraform Infrastructure as Code
- CI/CD Pipeline
- Docker Containers
- ECS / Kubernetes

---

# 🏆 Final Outcome

A fully functional production-style AWS architecture capable of:

✅ Handling traffic dynamically  
✅ Recovering from failures automatically  
✅ Scaling based on CPU utilization  
✅ Distributing traffic across multiple Availability Zones  
✅ Automatically replacing unhealthy instances  

---

# 👨‍💻 Author

Ahmed Talaat

### Network Engineer → DevOps & Cloud Journey

Skills:

- AWS
- Linux
- Networking
- Automation
- Cloud Infrastructure
- High Availability Architectures

---