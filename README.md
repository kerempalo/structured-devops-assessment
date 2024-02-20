# Structured DevOps Assessment
Design an automated pipeline to create aload balanced simple nginx hosted on 1 or mote ec2 instances on AWS


- 1. CIDR retrieve from REST API https://FDQN/vend_ip return {
"ip_address":"192.168.0.0",
"subnet_size":"/16" }
- 2. Create subnets with size /24
- 3. Generate SSH key for VM credential
- 4. Take into consideration CSP Best Practices such as security and resiliency
- 5. Take into consideration coding/scripting practices
- 6. Leverage on native cloud metrics/logging for error handling
- 7. Can use bash/terraform/python/powershell for the stack, github or github for the
IAC pipeline

## Deploymeny Guide
### Prerequisites
- An AWS account configured for programmatic access
- Environment secrets required to run this workflow 
    - AWS_ACCESS_KEY_ID
    - AWS_REGION
    - AWS_SECRET_ACCESS_KEY
    - AWS_SESSION_TOKEN
    - SSH_PUBLIC_KEY

### How to deploy ?
- Deployment can be triggered manually by "run workflow" trigger in the Actions tab.

## Results

![Result](https://i.ibb.co/0jh1RVJ/Screenshot-2024-02-18-at-7-03-12-PM.png)