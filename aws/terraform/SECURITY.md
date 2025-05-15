# Security & Incident Response

## Automated Security Assessment
- **Terraform:** `tfsec` and `checkov` run on every PR and main branch push (see GitHub Actions).
- **AWS Inspector:** Enabled for EC2/ECS instances for runtime vulnerability scanning.
- **Dependency Scans:** `npm audit` and `dependabot` enabled for backend and Lambda code.

## Incident Response Plan
1. **Detection:** CloudWatch alarms for error rates, unauthorized access, and cost spikes.
2. **Alerting:** Alerts sent to Slack (via webhook) and email for critical incidents.
3. **Escalation:** On-call engineer notified for high-severity incidents.
4. **Remediation:** Triage, mitigate, and resolve; rollback via Terraform if needed.
5. **Post-Mortem:** Document incident, root cause, and action items in shared incident log.

## Logging & Monitoring
- **CloudWatch:** Centralized logs for API, Lambda, and infrastructure.
- **Retention:** Logs retained for 90 days (configurable).
- **Alerting:** Alarms for 5xx errors, high latency, and cost budget exceedance.

## Compliance
- **IAM:** All roles are least privilege.
- **Data:** No sensitive data stored in logs.
- **Audit:** All changes tracked via GitHub and Terraform state.
