#!/bin/bash

# ── Install packages ──────────────────────────────────────────
dnf install nginx stress -y

# ── Start nginx ───────────────────────────────────────────────
systemctl enable nginx
systemctl start nginx

# ── Get instance metadata (IMDSv2) ────────────────────────────
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/instance-id)

AZ=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/placement/availability-zone)

INSTANCE_TYPE=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/instance-type)

ALB_URL="http://alb-test-193350384.us-east-1.elb.amazonaws.com"

# ── Write HTML page ───────────────────────────────────────────
cat > /usr/share/nginx/html/index.html << HTMLEOF
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>AWS Auto Scaling Demo</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: 'Segoe UI', sans-serif;
      background: #0f1117;
      color: #e2e8f0;
      min-height: 100vh;
      display: flex;
      flex-direction: column;
      align-items: center;
      padding: 40px 20px;
    }
    .header { text-align: center; margin-bottom: 40px; }
    .header h1 { font-size: 2rem; color: #63b3ed; margin-bottom: 8px; }
    .header p { color: #718096; font-size: 0.95rem; }

    .card {
      background: #1a1d27;
      border: 1px solid #2d3748;
      border-radius: 12px;
      padding: 28px 32px;
      width: 100%;
      max-width: 640px;
      margin-bottom: 20px;
    }
    .card h2 {
      font-size: 0.75rem;
      text-transform: uppercase;
      letter-spacing: 0.1em;
      color: #718096;
      margin-bottom: 16px;
    }

    .instance-id {
      font-size: 1.4rem;
      font-weight: 700;
      color: #68d391;
      font-family: 'Courier New', monospace;
      background: #0f1117;
      border: 1px solid #2d3748;
      border-radius: 8px;
      padding: 14px 20px;
      word-break: break-all;
    }

    .badge {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      background: #1c3a2a;
      color: #68d391;
      border: 1px solid #276749;
      border-radius: 20px;
      padding: 4px 12px;
      font-size: 0.8rem;
      margin-top: 12px;
    }
    .dot {
      width: 7px; height: 7px;
      background: #68d391;
      border-radius: 50%;
      animation: pulse 1.5s infinite;
    }
    @keyframes pulse { 0%,100%{opacity:1} 50%{opacity:0.3} }

    .info-grid {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 12px;
      margin-top: 16px;
    }
    .info-item {
      background: #0f1117;
      border: 1px solid #2d3748;
      border-radius: 8px;
      padding: 12px 16px;
    }
    .info-item .label {
      font-size: 0.72rem;
      color: #718096;
      text-transform: uppercase;
      letter-spacing: 0.08em;
      margin-bottom: 4px;
    }
    .info-item .value {
      font-size: 0.95rem;
      color: #e2e8f0;
      font-weight: 600;
    }

    .alb-link {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      color: #63b3ed;
      font-size: 0.85rem;
      text-decoration: none;
      margin-top: 16px;
    }
    .alb-link:hover { text-decoration: underline; }

    .arch-grid {
      display: flex;
      flex-direction: column;
      gap: 10px;
    }
    .arch-row {
      display: flex;
      align-items: center;
      gap: 10px;
      font-size: 0.88rem;
      color: #a0aec0;
    }
    .arch-icon {
      font-size: 1.1rem;
      width: 28px;
      text-align: center;
    }
    .arch-label { color: #63b3ed; font-weight: 600; min-width: 160px; }
    .arch-arrow { color: #4a5568; font-size: 1rem; }

    .scaling-row {
      display: flex;
      justify-content: space-between;
      gap: 10px;
      margin-top: 4px;
    }
    .scale-item {
      flex: 1;
      background: #0f1117;
      border: 1px solid #2d3748;
      border-radius: 8px;
      padding: 12px;
      text-align: center;
    }
    .scale-item .s-label { font-size: 0.72rem; color: #718096; text-transform: uppercase; margin-bottom: 6px; }
    .scale-item .s-value { font-size: 1.1rem; font-weight: 700; }
    .s-out  { color: #fc8181; }
    .s-in   { color: #68d391; }
    .s-curr { color: #63b3ed; }
  </style>
</head>
<body>

  <div class="header">
    <h1>AWS Auto Scaling Demo</h1>
    <p>Application Load Balancer &middot; EC2 &middot; Auto Scaling Group</p>
  </div>

  <!-- Instance Info -->
  <div class="card">
    <h2>Current EC2 Instance</h2>
    <div class="instance-id">$INSTANCE_ID</div>
    <div class="badge"><div class="dot"></div>Healthy &middot; InService</div>
    <div class="info-grid">
      <div class="info-item">
        <div class="label">Instance Type</div>
        <div class="value">$INSTANCE_TYPE</div>
      </div>
      <div class="info-item">
        <div class="label">Availability Zone</div>
        <div class="value">$AZ</div>
      </div>
      <div class="info-item">
        <div class="label">Region</div>
        <div class="value">us-east-1</div>
      </div>
      <div class="info-item">
        <div class="label">Load Balancer</div>
        <div class="value">ALB-Test</div>
      </div>
    </div>
    <a class="alb-link" href="$ALB_URL" target="_blank">&#8594; $ALB_URL</a>
  </div>

  <!-- Architecture -->
  <div class="card">
    <h2>Architecture</h2>
    <div class="arch-grid">
      <div class="arch-row">
        <span class="arch-icon">🌐</span>
        <span class="arch-label">Internet</span>
        <span class="arch-arrow">&#8594;</span>
        <span>HTTP traffic hits the ALB endpoint</span>
      </div>
      <div class="arch-row">
        <span class="arch-icon">⚖️</span>
        <span class="arch-label">ALB</span>
        <span class="arch-arrow">&#8594;</span>
        <span>Distributes requests across healthy EC2 instances</span>
      </div>
      <div class="arch-row">
        <span class="arch-icon">🖥️</span>
        <span class="arch-label">EC2 + nginx</span>
        <span class="arch-arrow">&#8594;</span>
        <span>Serves this page with unique Instance ID per host</span>
      </div>
      <div class="arch-row">
        <span class="arch-icon">📈</span>
        <span class="arch-label">CloudWatch</span>
        <span class="arch-arrow">&#8594;</span>
        <span>Monitors CPU and triggers ASG scaling policies</span>
      </div>
      <div class="arch-row">
        <span class="arch-icon">⚡</span>
        <span class="arch-label">Auto Scaling</span>
        <span class="arch-arrow">&#8594;</span>
        <span>Adds or removes instances based on CPU alarms</span>
      </div>
    </div>
  </div>

  <!-- Scaling Policy -->
  <div class="card">
    <h2>Scaling Policy</h2>
    <div class="scaling-row">
      <div class="scale-item">
        <div class="s-label">Min</div>
        <div class="s-value s-in">1</div>
      </div>
      <div class="scale-item">
        <div class="s-label">Desired</div>
        <div class="s-value s-curr">2</div>
      </div>
      <div class="scale-item">
        <div class="s-label">Max</div>
        <div class="s-value s-out">3</div>
      </div>
      <div class="scale-item">
        <div class="s-label">Scale Out</div>
        <div class="s-value s-out">CPU &gt;75%</div>
      </div>
      <div class="scale-item">
        <div class="s-label">Scale In</div>
        <div class="s-value s-in">CPU &lt;45%</div>
      </div>
    </div>
  </div>

</body>
</html>
HTMLEOF
