# AWS Load Balancer & Auto Scaling

A hands-on AWS project demonstrating how to set up an **Application Load Balancer (ALB)** with an **Auto Scaling Group (ASG)** to automatically manage EC2 instances based on CPU load.

---

## Architecture

```
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

## What Was Built

### 1. VPC & Networking
- VPC with **2 public subnets** in different Availability Zones
- **Internet Gateway** attached with correct Route Table (`0.0.0.0/0 → igw-xxx`)
- **Auto-assign public IPv4** enabled on subnets
- Security Group allowing:
  - Inbound HTTP port **80** from `0.0.0.0/0`
  - Inbound SSH port **22** from trusted IP

### 2. Application Load Balancer (ALB)
- Type: **Application Load Balancer**
- Scheme: Internet-facing
- Listener: **HTTP:80**
- Target Group: Instance type, HTTP:80, health check on `/`
- DNS: `alb-test-193350384.us-east-1.elb.amazonaws.com`

### 3. Launch Template
- AMI: **Amazon Linux 2023**
- Instance type: `t3.micro`
- Key pair for SSH access
- Security group attached
- **User Data** script (see below)

### 4. Auto Scaling Group
| Setting | Value |
|---|---|
| Minimum | 1 |
| Desired | 2 |
| Maximum | 3 |
| Health check | ELB |
| Cooldown (scale-out) | 60s |
| Cooldown (scale-in) | 300s |

### 5. CloudWatch Alarms
| Alarm | Metric | Threshold | Action |
|---|---|---|---|
| `scale-out-cpu-75` | CPUUtilization (avg) | > 75% for 1 min | Add 1 instance |
| `scale-in-cpu-45` | CPUUtilization (avg) | < 45% for 1 min | Remove 1 instance |

> **Important:** CloudWatch measures the **average CPU across all instances** in the ASG — not per instance. To trigger scale-out, all instances must be under load simultaneously.

---

## User Data Script

Runs automatically on every new EC2 instance launched by the ASG:

```bash
#!/bin/bash

# Install nginx
dnf install nginx stress -y
systemctl enable nginx
systemctl start nginx

# Fetch instance metadata using IMDSv2
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/instance-id)

AZ=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/placement/availability-zone)

INSTANCE_TYPE=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/instance-type)

# Write custom HTML page showing instance info
cat > /usr/share/nginx/html/index.html << HTMLEOF
...
HTMLEOF
```

Full script: [`user-data-final.sh`](./user-data-final.sh)

---

## CPU Load Test (Scale-Out)

To trigger Auto Scaling, connect to **all running instances** via EC2 Instance Connect and run:

```bash
# Option 1: yes command (instant 100% CPU)
yes > /dev/null & yes > /dev/null &

# Option 2: stress tool
sudo stress --cpu 2 --vm 1 --vm-bytes 400M --timeout 300
```

To stop the load:
```bash
pkill yes
# or
pkill stress
```

### To verify ALB distributes traffic across instances:
```bash
for i in {1..10}; do
  curl -s http://alb-test-193350384.us-east-1.elb.amazonaws.com/ | grep -o 'i-[a-z0-9]*'
done
```

---

## Issues Encountered & Solutions

### 🔴 Infinite Replacement Loop
**Problem:** ASG kept launching and terminating instances in a loop.

**Root Cause:** Instances launched without internet access — `dnf install nginx` failed silently, nginx never started, ALB health checks failed.

**Fix:**
- Enabled **Auto-assign public IPv4** on the subnet
- Added `0.0.0.0/0 → igw-xxx` route to the Route Table

### 🔴 EC2 Instance Connect Unavailable
**Problem:** Could not connect to instances — no public IP assigned.

**Fix:** Enabled public IP in both the subnet settings and the Launch Template network configuration.

### 🔴 Scale-Out Not Triggering
**Problem:** stress running at 100% on one instance but CloudWatch showed ~50%.

**Root Cause:** CloudWatch averages CPU across **all instances** — with 2 instances (one at 100%, one at 0%), average = 50%, below the 75% threshold.

**Fix:** Ran stress on both instances simultaneously → average hit 100% → alarm triggered → scale-out to 3 instances ✅

### 🔴 CloudWatch Alarm Not Linked to ASG
**Problem:** Could not find ASG in CloudWatch alarm actions dropdown.

**Root Cause:** ASG had no scaling policy yet, so it didn't appear in the list.

**Fix:** Created the Dynamic Scaling Policy from **ASG → Automatic Scaling** first, then the alarm was automatically linked.

---

## Key Concepts

| Concept | Description |
|---|---|
| **ALB** | Distributes HTTP/HTTPS traffic across registered targets |
| **Target Group** | Group of EC2 instances receiving traffic from ALB |
| **Health Check** | ALB periodically pings each instance; unhealthy ones are replaced |
| **Launch Template** | Blueprint for new EC2 instances (AMI, type, SG, user data) |
| **Auto Scaling Group** | Maintains desired capacity and scales based on policies |
| **IMDSv2** | Token-based secure access to EC2 instance metadata |
| **Connection Draining** | ALB waits for active connections to finish before deregistering |
| **Cooldown Period** | Wait time between scaling actions to avoid rapid fluctuations |

---

## Prerequisites

- AWS Account with IAM permissions for EC2, ELB, Auto Scaling, CloudWatch
- VPC with at least **2 public subnets** in different AZs
- Internet Gateway attached and Route Table configured

---

## Repo Structure

```
├── LICENSE
├── README.md                        ← This file
├── user-data-final.sh               ← EC2 launch script (nginx + HTML page)
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