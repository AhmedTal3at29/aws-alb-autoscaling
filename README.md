# AWS Load Balancer & Auto Scaling 🚀

A hands-on AWS project demonstrating how to build a highly available and self-healing web infrastructure using:

- Application Load Balancer (ALB)
- Auto Scaling Group (ASG)
- CloudWatch Alarms
- EC2 Launch Templates
- nginx
- Multi-AZ deployment

The infrastructure automatically scales EC2 instances based on CPU utilization and replaces unhealthy instances automatically.

---

# 📐 Architecture

```text
                        ┌─────────────────────────────────┐
                        │         CloudWatch Alarms        │
                        │  CPU > 75% → Scale Out (+1)      │
                        │  CPU < 45% → Scale In  (-1)      │
                        └────────────┬────────────────────┘
                                     │ triggers
Internet ──► ALB (HTTP:80) ──────────▼──────────────────────
                │             Auto Scaling Group
                │         ┌──────────┬──────────┐
                └────────►│  EC2 #1  │  EC2 #2  │  (+ EC2 #3 on scale-out)
                          │  nginx   │  nginx   │
                          └──────────┴──────────┘
                          Min: 1 | Desired: 2 | Max: 3
```

---

# 🧩 What Was Built

## 1. VPC & Networking

- VPC with **2 public subnets** in different Availability Zones
- Internet Gateway attached with Route Table:
  
```text
0.0.0.0/0 → Internet Gateway
```

- Auto-assign public IPv4 enabled on subnets

### Security Group Rules

| Rule | Port | Source |
|---|---|---|
| HTTP | 80 | 0.0.0.0/0 |
| SSH | 22 | Trusted IP |

---

# ⚖️ Application Load Balancer (ALB)

| Setting | Value |
|---|---|
| Type | Application Load Balancer |
| Scheme | Internet-facing |
| Listener | HTTP:80 |
| Health Check | `/` |
| Target Type | Instance |

### Features

- Distributes traffic across EC2 instances
- Performs health checks automatically
- Removes unhealthy instances
- Works across multiple AZs

---

# 🖥️ Launch Template

| Component | Value |
|---|---|
| AMI | Amazon Linux 2023 |
| Instance Type | t3.micro |
| Web Server | nginx |
| Key Pair | Enabled |
| User Data | Enabled |

---

# 📈 Auto Scaling Group (ASG)

| Setting | Value |
|---|---|
| Minimum Capacity | 1 |
| Desired Capacity | 2 |
| Maximum Capacity | 3 |
| Health Check Type | ELB |
| Scale-Out Cooldown | 60s |
| Scale-In Cooldown | 300s |

### Features

- Dynamic scaling
- Self-healing infrastructure
- Automatic unhealthy instance replacement
- Multi-AZ balancing

---

# 📊 CloudWatch Alarms

| Alarm | Metric | Threshold | Action |
|---|---|---|---|
| scale-out-cpu-75 | CPUUtilization | > 75% | Add 1 instance |
| scale-in-cpu-45 | CPUUtilization | < 45% | Remove 1 instance |

> CloudWatch monitors the **average CPU utilization across all EC2 instances** inside the Auto Scaling Group.

---

# 🧠 Scaling Logic

## Scale-Out

```text
CPU > 75%
→ CloudWatch Alarm Triggered
→ ASG launches new EC2 instance
→ ALB registers target automatically
```

---

## Scale-In

```text
CPU < 45%
→ CloudWatch Alarm Triggered
→ ASG terminates extra EC2 instance
→ ALB deregisters target gracefully
```

---

# 🖥️ EC2 User Data Script

Every EC2 instance launched by the Auto Scaling Group automatically:

- Installs nginx
- Installs stress testing package
- Starts nginx service
- Retrieves instance metadata using IMDSv2
- Generates a dynamic HTML page displaying:
  - Instance ID
  - Availability Zone
  - Instance Type
  - ALB information
  - Scaling policies

The complete script is available in:

```text
user-data-final.sh
```

---

# 🧪 Testing Performed

---

## ✅ Load Balancing Test

Refreshing the ALB DNS endpoint displayed different Instance IDs.

### Result

- Verified ALB traffic distribution
- Verified Multi-AZ balancing

---

## ✅ Health Check Test

Stopped one EC2 instance manually.

### Result

```text
ALB detected unhealthy target
→ ASG launched replacement instance
→ New target registered automatically
→ Service restored successfully
```

---

## ✅ Self-Healing Test

Terminated EC2 instances manually.

### Result

```text
ASG recreated instances automatically
without manual intervention
```

---

## ✅ Scale-Out Test

Generated CPU load using:

```bash
yes > /dev/null &
yes > /dev/null &
```

Or:

```bash
sudo stress --cpu 2 --vm 1 --vm-bytes 400M --timeout 300
```

### Result

```text
CPU exceeded 75%
→ CloudWatch alarm triggered
→ ASG launched additional EC2 instance
```

---

## ✅ Scale-In Test

Stopped stress testing.

### Result

```text
CPU dropped below 45%
→ CloudWatch alarm triggered
→ ASG terminated extra EC2 instance
```

---

# 🔥 Issues Encountered & Solutions

---

## 🔴 Infinite Replacement Loop

### Problem

ASG continuously launched and terminated instances.

### Root Cause

Instances had no internet access, causing:

```bash
dnf install nginx
```

to fail during User Data execution.

nginx never started, so ALB health checks failed.

### Solution

- Enabled Auto-assign Public IPv4
- Added Route Table entry:

```text
0.0.0.0/0 → Internet Gateway
```

---

## 🔴 Scale-Out Not Triggering

### Problem

CPU stress test on one instance only showed ~50% utilization.

### Root Cause

CloudWatch measures the **average CPU across all instances**.

Example:

| Instance | CPU |
|---|---|
| EC2 #1 | 100% |
| EC2 #2 | 0% |

Average = 50%

### Solution

Run stress test on both instances simultaneously.

Result:

```text
Average CPU exceeded 75%
→ Scale-Out triggered successfully

---

# 🔑 Key Concepts Demonstrated

| Concept | Description |
|---|---|
| ALB | Distributes traffic across EC2 targets |
| Target Group | Backend EC2 instances |
| Health Checks | Detect unhealthy instances |
| Launch Template | Blueprint for EC2 instances |
| Auto Scaling Group | Automatic scaling & recovery |
| IMDSv2 | Secure EC2 metadata access |
| Connection Draining | Graceful target deregistration |
| Cooldown | Prevents rapid scaling fluctuations |

---

# 📁 Repository Structure

```text
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

- nginx application page
- ALB Resource Map
- Auto Scaling activity logs
- Target Group health checks
- Launch Template configuration
- CloudWatch alarms
- Scaling events

---


# 🏆 Final Outcome

A production-style AWS architecture capable of:

✅ Dynamic traffic distribution  
✅ Automatic scaling  
✅ Self-healing recovery  
✅ Multi-AZ high availability  
✅ Automated EC2 provisioning  
✅ Cloud-based monitoring & alerting  

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