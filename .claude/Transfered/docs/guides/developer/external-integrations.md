---
title: External Integrations Guide
description: Connect Agent Studio with GitHub, Slack, webhooks, and custom APIs. Build resilient integrations with retry logic, authentication, and error handling.
tags:
  - integrations
  - webhooks
  - github
  - slack
  - api
  - authentication
  - resilience
lastUpdated: 2025-10-09
author: Agent Studio Team
audience: developers
---

# External Integrations

**Target Audience**: Integration Developers, Solution Architects
**Estimated Reading Time**: 30-35 minutes
**Last Updated**: 2025-10-09

## Table of Contents

1. [Overview](#overview)
2. [GitHub Integration](#github-integration)
3. [Slack Integration](#slack-integration)
4. [Webhook Integration](#webhook-integration)
5. [Custom API Integration](#custom-api-integration)
6. [Microsoft Teams Integration](#microsoft-teams-integration)
7. [Email Integration](#email-integration)
8. [SMS Integration](#sms-integration)
9. [Storage Integration](#storage-integration)
10. [Message Queue Integration](#message-queue-integration)
11. [Database Integration](#database-integration)
12. [Monitoring Integration](#monitoring-integration)
13. [Best Practices](#best-practices)
14. [Complete Examples](#complete-examples)
15. [Troubleshooting](#troubleshooting)

---

## Overview

Agent Studio provides a comprehensive integration framework for connecting with external services and platforms. This guide covers authentication patterns, webhook handling, error recovery, and best practices for building resilient integrations.

### Integration Patterns

Agent Studio supports four primary integration patterns:

1. **Webhook-Based Integration**: Receive events from external systems via HTTP webhooks
2. **API Client Integration**: Make outbound requests to external REST/GraphQL APIs
3. **Event-Driven Integration**: Publish/subscribe to message queues and event streams
4. **Scheduled Integration**: Periodic polling and synchronization with external systems

### Authentication Architecture

All external integrations use a centralized authentication system:

- **Azure Key Vault**: Secure credential storage
- **Managed Identity**: Azure service-to-service authentication
- **OAuth2/OIDC**: Third-party service authentication
- **API Keys**: Simple key-based authentication with rotation support
- **JWT Tokens**: Short-lived tokens with automatic refresh

### Security Principles

- **Credential Encryption**: All secrets encrypted at rest and in transit
- **Signature Verification**: HMAC/JWT signature validation for incoming webhooks
- **Rate Limiting**: Per-integration rate limits with exponential backoff
- **Audit Logging**: Comprehensive logging of all integration activity
- **Secret Rotation**: Automated credential rotation policies

---

## GitHub Integration

Integrate Agent Studio workflows with GitHub repositories for automated code review, PR management, issue tracking, and CI/CD automation.

### Repository Events

Monitor GitHub repository events and trigger workflows automatically.

#### Webhook Setup

**1. Configure GitHub Webhook**

Navigate to your repository settings and create a webhook:

```
Payload URL: https://your-agent-studio.azurewebsites.net/api/webhooks/github
Content Type: application/json
Secret: <your-webhook-secret>
Events:
  - Pull requests
  - Push
  - Issues
  - Release
```

**2. Webhook Handler (TypeScript)**

```typescript
import { Request, Response } from 'express';
import * as crypto from 'crypto';

interface GitHubWebhookPayload {
  action: string;
  repository: {
    name: string;
    full_name: string;
    html_url: string;
  };
  pull_request?: {
    number: number;
    title: string;
    head: { sha: string };
    base: { ref: string };
  };
  issue?: {
    number: number;
    title: string;
    body: string;
  };
}

export class GitHubWebhookHandler {
  private readonly secret: string;

  constructor(secret: string) {
    this.secret = secret;
  }

  /**
   * Verify GitHub webhook signature
   */
  private verifySignature(payload: string, signature: string): boolean {
    if (!signature) {
      return false;
    }

    const hmac = crypto.createHmac('sha256', this.secret);
    const digest = 'sha256=' + hmac.update(payload).digest('hex');

    // Use timing-safe comparison to prevent timing attacks
    return crypto.timingSafeEqual(
      Buffer.from(signature),
      Buffer.from(digest)
    );
  }

  /**
   * Handle incoming GitHub webhook
   */
  async handleWebhook(req: Request, res: Response): Promise<void> {
    const signature = req.headers['x-hub-signature-256'] as string;
    const event = req.headers['x-github-event'] as string;
    const payload = JSON.stringify(req.body);

    // Verify signature
    if (!this.verifySignature(payload, signature)) {
      res.status(401).json({ error: 'Invalid signature' });
      return;
    }

    const body: GitHubWebhookPayload = req.body;

    try {
      switch (event) {
        case 'pull_request':
          await this.handlePullRequest(body);
          break;
        case 'push':
          await this.handlePush(body);
          break;
        case 'issues':
          await this.handleIssue(body);
          break;
        default:
          console.log(`Unhandled event type: ${event}`);
      }

      res.status(200).json({ status: 'processed' });
    } catch (error) {
      console.error('Error processing webhook:', error);
      res.status(500).json({ error: 'Processing failed' });
    }
  }

  private async handlePullRequest(payload: GitHubWebhookPayload): Promise<void> {
    if (!payload.pull_request) return;

    const { action, pull_request, repository } = payload;

    if (action === 'opened' || action === 'synchronize') {
      // Trigger code review workflow
      await this.triggerWorkflow('code-review-workflow', {
        repository: repository.full_name,
        prNumber: pull_request.number,
        headSha: pull_request.head.sha,
        baseBranch: pull_request.base.ref
      });
    }
  }

  private async handlePush(payload: GitHubWebhookPayload): Promise<void> {
    // Trigger CI/CD workflow on push to main
    const ref = (payload as any).ref;
    if (ref === 'refs/heads/main') {
      await this.triggerWorkflow('deploy-workflow', {
        repository: payload.repository.full_name,
        sha: (payload as any).after
      });
    }
  }

  private async handleIssue(payload: GitHubWebhookPayload): Promise<void> {
    if (!payload.issue) return;

    const { action, issue, repository } = payload;

    if (action === 'opened') {
      // Trigger issue triage workflow
      await this.triggerWorkflow('issue-triage-workflow', {
        repository: repository.full_name,
        issueNumber: issue.number,
        title: issue.title,
        body: issue.body
      });
    }
  }

  private async triggerWorkflow(workflowId: string, context: any): Promise<void> {
    // Integration with Agent Studio workflow engine
    const workflowClient = new WorkflowClient();
    await workflowClient.executeWorkflow(workflowId, context);
  }
}
```

**3. Webhook Handler (Python)**

```python
import hmac
import hashlib
import json
from typing import Dict, Any
from flask import Request, Response

class GitHubWebhookHandler:
    def __init__(self, secret: str):
        self.secret = secret.encode('utf-8')

    def verify_signature(self, payload: bytes, signature: str) -> bool:
        """Verify GitHub webhook signature using HMAC-SHA256"""
        if not signature:
            return False

        expected_signature = 'sha256=' + hmac.new(
            self.secret,
            payload,
            hashlib.sha256
        ).hexdigest()

        # Timing-safe comparison
        return hmac.compare_digest(signature, expected_signature)

    def handle_webhook(self, request: Request) -> Response:
        """Handle incoming GitHub webhook"""
        signature = request.headers.get('X-Hub-Signature-256')
        event = request.headers.get('X-GitHub-Event')
        payload = request.get_data()

        # Verify signature
        if not self.verify_signature(payload, signature):
            return Response(
                json.dumps({'error': 'Invalid signature'}),
                status=401,
                mimetype='application/json'
            )

        body = json.loads(payload)

        try:
            if event == 'pull_request':
                self.handle_pull_request(body)
            elif event == 'push':
                self.handle_push(body)
            elif event == 'issues':
                self.handle_issue(body)

            return Response(
                json.dumps({'status': 'processed'}),
                status=200,
                mimetype='application/json'
            )
        except Exception as e:
            print(f'Error processing webhook: {e}')
            return Response(
                json.dumps({'error': 'Processing failed'}),
                status=500,
                mimetype='application/json'
            )

    def handle_pull_request(self, payload: Dict[str, Any]) -> None:
        """Handle pull request events"""
        action = payload.get('action')
        pr = payload.get('pull_request', {})
        repo = payload.get('repository', {})

        if action in ['opened', 'synchronize']:
            self.trigger_workflow('code-review-workflow', {
                'repository': repo['full_name'],
                'prNumber': pr['number'],
                'headSha': pr['head']['sha'],
                'baseBranch': pr['base']['ref']
            })

    def trigger_workflow(self, workflow_id: str, context: Dict[str, Any]) -> None:
        """Trigger Agent Studio workflow"""
        # Integration with Agent Studio workflow engine
        from workflow_client import WorkflowClient
        client = WorkflowClient()
        client.execute_workflow(workflow_id, context)
```

### GitHub Actions Integration

Trigger Agent Studio workflows from GitHub Actions.

**GitHub Actions Workflow**

```yaml
name: Agent Studio Integration

on:
  pull_request:
    types: [opened, synchronize]
  push:
    branches: [main]

jobs:
  trigger-agent-studio:
    runs-on: ubuntu-latest
    steps:
      - name: Trigger Code Review
        uses: actions/github-script@v6
        with:
          script: |
            const response = await fetch('https://your-agent-studio.azurewebsites.net/api/workflows/execute', {
              method: 'POST',
              headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${{ secrets.AGENT_STUDIO_TOKEN }}`
              },
              body: JSON.stringify({
                workflowId: 'code-review-workflow',
                context: {
                  repository: context.payload.repository.full_name,
                  prNumber: context.payload.pull_request?.number,
                  sha: context.sha
                }
              })
            });

            const result = await response.json();
            console.log('Workflow triggered:', result);
```

### API Integration

Interact with GitHub API from Agent Studio workflows.

**TypeScript GitHub Client**

```typescript
import { Octokit } from '@octokit/rest';

export class GitHubClient {
  private octokit: Octokit;

  constructor(token: string) {
    this.octokit = new Octokit({ auth: token });
  }

  /**
   * Create a pull request comment
   */
  async createPRComment(
    owner: string,
    repo: string,
    prNumber: number,
    body: string
  ): Promise<void> {
    await this.octokit.issues.createComment({
      owner,
      repo,
      issue_number: prNumber,
      body
    });
  }

  /**
   * Create a review on a pull request
   */
  async createReview(
    owner: string,
    repo: string,
    prNumber: number,
    commitId: string,
    event: 'APPROVE' | 'REQUEST_CHANGES' | 'COMMENT',
    body: string,
    comments: Array<{
      path: string;
      position: number;
      body: string;
    }> = []
  ): Promise<void> {
    await this.octokit.pulls.createReview({
      owner,
      repo,
      pull_number: prNumber,
      commit_id: commitId,
      event,
      body,
      comments
    });
  }

  /**
   * Create an issue
   */
  async createIssue(
    owner: string,
    repo: string,
    title: string,
    body: string,
    labels: string[] = []
  ): Promise<number> {
    const response = await this.octokit.issues.create({
      owner,
      repo,
      title,
      body,
      labels
    });

    return response.data.number;
  }

  /**
   * Update issue labels
   */
  async updateIssueLabels(
    owner: string,
    repo: string,
    issueNumber: number,
    labels: string[]
  ): Promise<void> {
    await this.octokit.issues.setLabels({
      owner,
      repo,
      issue_number: issueNumber,
      labels
    });
  }

  /**
   * Get file content from repository
   */
  async getFileContent(
    owner: string,
    repo: string,
    path: string,
    ref?: string
  ): Promise<string> {
    const response = await this.octokit.repos.getContent({
      owner,
      repo,
      path,
      ref
    });

    if (Array.isArray(response.data)) {
      throw new Error('Path is a directory, not a file');
    }

    if ('content' in response.data) {
      return Buffer.from(response.data.content, 'base64').toString('utf-8');
    }

    throw new Error('File content not available');
  }
}
```

**Python GitHub Client**

```python
from github import Github, GithubException
from typing import List, Optional

class GitHubClient:
    def __init__(self, token: str):
        self.client = Github(token)

    def create_pr_comment(
        self,
        owner: str,
        repo: str,
        pr_number: int,
        body: str
    ) -> None:
        """Create a pull request comment"""
        repository = self.client.get_repo(f"{owner}/{repo}")
        pr = repository.get_pull(pr_number)
        pr.create_issue_comment(body)

    def create_review(
        self,
        owner: str,
        repo: str,
        pr_number: int,
        commit_id: str,
        event: str,  # 'APPROVE', 'REQUEST_CHANGES', 'COMMENT'
        body: str,
        comments: Optional[List[dict]] = None
    ) -> None:
        """Create a review on a pull request"""
        repository = self.client.get_repo(f"{owner}/{repo}")
        pr = repository.get_pull(pr_number)

        pr.create_review(
            commit_id=commit_id,
            event=event,
            body=body,
            comments=comments or []
        )

    def create_issue(
        self,
        owner: str,
        repo: str,
        title: str,
        body: str,
        labels: Optional[List[str]] = None
    ) -> int:
        """Create an issue"""
        repository = self.client.get_repo(f"{owner}/{repo}")
        issue = repository.create_issue(
            title=title,
            body=body,
            labels=labels or []
        )
        return issue.number

    def get_file_content(
        self,
        owner: str,
        repo: str,
        path: str,
        ref: Optional[str] = None
    ) -> str:
        """Get file content from repository"""
        repository = self.client.get_repo(f"{owner}/{repo}")
        content = repository.get_contents(path, ref=ref)

        if isinstance(content, list):
            raise ValueError('Path is a directory, not a file')

        return content.decoded_content.decode('utf-8')
```

---

## Slack Integration

Integrate Agent Studio with Slack for notifications, interactive commands, and bot-based workflows.

### Incoming Webhooks

Send notifications to Slack channels using incoming webhooks.

**TypeScript Implementation**

```typescript
import axios from 'axios';

export interface SlackMessage {
  text?: string;
  blocks?: Array<{
    type: string;
    text?: {
      type: string;
      text: string;
    };
    [key: string]: any;
  }>;
  attachments?: Array<{
    color?: string;
    title?: string;
    text?: string;
    fields?: Array<{
      title: string;
      value: string;
      short?: boolean;
    }>;
  }>;
}

export class SlackWebhookClient {
  constructor(private webhookUrl: string) {}

  /**
   * Send a simple text message
   */
  async sendMessage(text: string): Promise<void> {
    await axios.post(this.webhookUrl, { text });
  }

  /**
   * Send a rich message with blocks
   */
  async sendRichMessage(message: SlackMessage): Promise<void> {
    await axios.post(this.webhookUrl, message);
  }

  /**
   * Send workflow status update
   */
  async sendWorkflowUpdate(
    workflowName: string,
    status: 'started' | 'completed' | 'failed',
    details: string
  ): Promise<void> {
    const color = status === 'completed' ? 'good' : status === 'failed' ? 'danger' : 'warning';
    const emoji = status === 'completed' ? ':white_check_mark:' : status === 'failed' ? ':x:' : ':hourglass:';

    const message: SlackMessage = {
      blocks: [
        {
          type: 'header',
          text: {
            type: 'plain_text',
            text: `${emoji} Workflow: ${workflowName}`
          }
        },
        {
          type: 'section',
          fields: [
            {
              type: 'mrkdwn',
              text: `*Status:*\n${status}`
            },
            {
              type: 'mrkdwn',
              text: `*Time:*\n${new Date().toLocaleString()}`
            }
          ]
        },
        {
          type: 'section',
          text: {
            type: 'mrkdwn',
            text: `*Details:*\n${details}`
          }
        }
      ]
    };

    await this.sendRichMessage(message);
  }

  /**
   * Send code review notification
   */
  async sendCodeReviewNotification(
    prUrl: string,
    findings: {
      critical: number;
      major: number;
      minor: number;
    }
  ): Promise<void> {
    const message: SlackMessage = {
      blocks: [
        {
          type: 'header',
          text: {
            type: 'plain_text',
            text: ':mag: Code Review Complete'
          }
        },
        {
          type: 'section',
          text: {
            type: 'mrkdwn',
            text: `Code review completed for <${prUrl}|Pull Request>`
          }
        },
        {
          type: 'section',
          fields: [
            {
              type: 'mrkdwn',
              text: `:red_circle: *Critical:* ${findings.critical}`
            },
            {
              type: 'mrkdwn',
              text: `:orange_circle: *Major:* ${findings.major}`
            },
            {
              type: 'mrkdwn',
              text: `:yellow_circle: *Minor:* ${findings.minor}`
            }
          ]
        },
        {
          type: 'actions',
          elements: [
            {
              type: 'button',
              text: {
                type: 'plain_text',
                text: 'View Pull Request'
              },
              url: prUrl
            }
          ]
        }
      ]
    };

    await this.sendRichMessage(message);
  }
}
```

**Python Implementation**

```python
import requests
from typing import Dict, List, Any, Literal
from datetime import datetime

class SlackWebhookClient:
    def __init__(self, webhook_url: str):
        self.webhook_url = webhook_url

    def send_message(self, text: str) -> None:
        """Send a simple text message"""
        requests.post(self.webhook_url, json={'text': text})

    def send_rich_message(self, message: Dict[str, Any]) -> None:
        """Send a rich message with blocks"""
        requests.post(self.webhook_url, json=message)

    def send_workflow_update(
        self,
        workflow_name: str,
        status: Literal['started', 'completed', 'failed'],
        details: str
    ) -> None:
        """Send workflow status update"""
        emoji = {
            'started': ':hourglass:',
            'completed': ':white_check_mark:',
            'failed': ':x:'
        }[status]

        message = {
            'blocks': [
                {
                    'type': 'header',
                    'text': {
                        'type': 'plain_text',
                        'text': f'{emoji} Workflow: {workflow_name}'
                    }
                },
                {
                    'type': 'section',
                    'fields': [
                        {
                            'type': 'mrkdwn',
                            'text': f'*Status:*\n{status}'
                        },
                        {
                            'type': 'mrkdwn',
                            'text': f'*Time:*\n{datetime.now().strftime("%Y-%m-%d %H:%M:%S")}'
                        }
                    ]
                },
                {
                    'type': 'section',
                    'text': {
                        'type': 'mrkdwn',
                        'text': f'*Details:*\n{details}'
                    }
                }
            ]
        }

        self.send_rich_message(message)
```

### Slash Commands

Create interactive Slack commands that trigger Agent Studio workflows.

**Slash Command Handler (TypeScript)**

```typescript
import { Request, Response } from 'express';
import * as crypto from 'crypto';

export class SlackCommandHandler {
  private readonly signingSecret: string;

  constructor(signingSecret: string) {
    this.signingSecret = signingSecret;
  }

  /**
   * Verify Slack request signature
   */
  private verifySignature(
    timestamp: string,
    body: string,
    signature: string
  ): boolean {
    const baseString = `v0:${timestamp}:${body}`;
    const hmac = crypto.createHmac('sha256', this.signingSecret);
    const computedSignature = 'v0=' + hmac.update(baseString).digest('hex');

    return crypto.timingSafeEqual(
      Buffer.from(signature),
      Buffer.from(computedSignature)
    );
  }

  /**
   * Handle slash command
   */
  async handleCommand(req: Request, res: Response): Promise<void> {
    const timestamp = req.headers['x-slack-request-timestamp'] as string;
    const signature = req.headers['x-slack-signature'] as string;
    const body = new URLSearchParams(req.body as any).toString();

    // Verify signature
    if (!this.verifySignature(timestamp, body, signature)) {
      res.status(401).json({ error: 'Invalid signature' });
      return;
    }

    const command = req.body.command;
    const text = req.body.text;
    const userId = req.body.user_id;
    const channelId = req.body.channel_id;

    // Acknowledge request immediately
    res.status(200).json({
      response_type: 'in_channel',
      text: `Processing command: ${command} ${text}...`
    });

    // Process command asynchronously
    this.processCommand(command, text, userId, channelId, req.body.response_url);
  }

  private async processCommand(
    command: string,
    text: string,
    userId: string,
    channelId: string,
    responseUrl: string
  ): Promise<void> {
    try {
      let result: string;

      switch (command) {
        case '/review-code':
          result = await this.handleReviewCode(text);
          break;
        case '/deploy':
          result = await this.handleDeploy(text);
          break;
        case '/workflow-status':
          result = await this.handleWorkflowStatus(text);
          break;
        default:
          result = `Unknown command: ${command}`;
      }

      // Send result back to Slack
      await axios.post(responseUrl, {
        response_type: 'in_channel',
        text: result
      });
    } catch (error) {
      await axios.post(responseUrl, {
        response_type: 'ephemeral',
        text: `Error: ${error.message}`
      });
    }
  }

  private async handleReviewCode(repoUrl: string): Promise<string> {
    // Trigger code review workflow
    const workflowClient = new WorkflowClient();
    const execution = await workflowClient.executeWorkflow('code-review-workflow', {
      repository: repoUrl
    });

    return `Code review started. Execution ID: ${execution.id}`;
  }

  private async handleDeploy(environment: string): Promise<string> {
    // Trigger deployment workflow
    const workflowClient = new WorkflowClient();
    const execution = await workflowClient.executeWorkflow('deploy-workflow', {
      environment
    });

    return `Deployment to ${environment} started. Execution ID: ${execution.id}`;
  }

  private async handleWorkflowStatus(executionId: string): Promise<string> {
    // Get workflow status
    const workflowClient = new WorkflowClient();
    const status = await workflowClient.getExecutionStatus(executionId);

    return `Workflow ${executionId} status: ${status.state}`;
  }
}
```

### Bot Integration

Build a Slack bot with OAuth and event subscriptions.

**Bot Event Handler (TypeScript)**

```typescript
import { App, ExpressReceiver } from '@slack/bolt';

export class SlackBotHandler {
  private app: App;

  constructor(
    signingSecret: string,
    botToken: string,
    appToken: string
  ) {
    this.app = new App({
      signingSecret,
      token: botToken,
      appToken,
      socketMode: true
    });

    this.setupEventHandlers();
  }

  private setupEventHandlers(): void {
    // Handle app mentions
    this.app.event('app_mention', async ({ event, client }) => {
      const text = event.text;
      const channel = event.channel;

      if (text.includes('review')) {
        await client.chat.postMessage({
          channel,
          text: 'Starting code review workflow...'
        });

        // Trigger workflow
        const workflowClient = new WorkflowClient();
        await workflowClient.executeWorkflow('code-review-workflow', {});
      }
    });

    // Handle direct messages
    this.app.message(async ({ message, say }) => {
      const text = (message as any).text;

      if (text.includes('help')) {
        await say({
          blocks: [
            {
              type: 'section',
              text: {
                type: 'mrkdwn',
                text: '*Available Commands:*\n' +
                      '• `review <repo>` - Start code review\n' +
                      '• `deploy <env>` - Deploy to environment\n' +
                      '• `status <id>` - Check workflow status'
              }
            }
          ]
        });
      }
    });

    // Handle button clicks
    this.app.action('approve_deployment', async ({ ack, body, client }) => {
      await ack();

      const workflowId = (body as any).actions[0].value;

      // Approve deployment
      const workflowClient = new WorkflowClient();
      await workflowClient.approveWorkflow(workflowId);

      await client.chat.update({
        channel: (body as any).channel.id,
        ts: (body as any).message.ts,
        text: 'Deployment approved!',
        blocks: [
          {
            type: 'section',
            text: {
              type: 'mrkdwn',
              text: ':white_check_mark: Deployment approved and started'
            }
          }
        ]
      });
    });
  }

  async start(): Promise<void> {
    await this.app.start();
    console.log('Slack bot is running');
  }
}
```

---

## Webhook Integration

Build robust webhook receivers and senders with signature verification, retry logic, and error handling.

### Receiving Webhooks

**Webhook Endpoint with Signature Verification (TypeScript)**

```typescript
import { Request, Response, NextFunction } from 'express';
import * as crypto from 'crypto';

export interface WebhookConfig {
  secret: string;
  algorithm: 'sha256' | 'sha1';
  headerName: string;
  prefix?: string;
}

export class WebhookReceiver {
  private config: WebhookConfig;

  constructor(config: WebhookConfig) {
    this.config = config;
  }

  /**
   * Middleware to verify webhook signatures
   */
  verifySignature() {
    return (req: Request, res: Response, next: NextFunction) => {
      const signature = req.headers[this.config.headerName.toLowerCase()] as string;
      const payload = JSON.stringify(req.body);

      if (!this.isValidSignature(payload, signature)) {
        res.status(401).json({ error: 'Invalid signature' });
        return;
      }

      next();
    };
  }

  private isValidSignature(payload: string, signature: string): boolean {
    if (!signature) {
      return false;
    }

    const hmac = crypto.createHmac(this.config.algorithm, this.config.secret);
    const digest = hmac.update(payload).digest('hex');
    const expectedSignature = this.config.prefix
      ? `${this.config.prefix}=${digest}`
      : digest;

    return crypto.timingSafeEqual(
      Buffer.from(signature),
      Buffer.from(expectedSignature)
    );
  }

  /**
   * Replay attack prevention using timestamp
   */
  preventReplayAttacks(maxAgeSeconds: number = 300) {
    return (req: Request, res: Response, next: NextFunction) => {
      const timestamp = req.headers['x-webhook-timestamp'] as string;

      if (!timestamp) {
        res.status(400).json({ error: 'Missing timestamp' });
        return;
      }

      const requestTime = parseInt(timestamp, 10);
      const currentTime = Math.floor(Date.now() / 1000);

      if (Math.abs(currentTime - requestTime) > maxAgeSeconds) {
        res.status(400).json({ error: 'Request too old' });
        return;
      }

      next();
    };
  }

  /**
   * Rate limiting middleware
   */
  rateLimit(maxRequests: number, windowSeconds: number) {
    const requests = new Map<string, number[]>();

    return (req: Request, res: Response, next: NextFunction) => {
      const clientId = req.headers['x-client-id'] as string || req.ip;
      const now = Date.now();
      const windowStart = now - windowSeconds * 1000;

      // Get existing requests for this client
      const clientRequests = requests.get(clientId) || [];

      // Remove old requests outside the window
      const recentRequests = clientRequests.filter(time => time > windowStart);

      if (recentRequests.length >= maxRequests) {
        res.status(429).json({
          error: 'Rate limit exceeded',
          retryAfter: Math.ceil((recentRequests[0] - windowStart) / 1000)
        });
        return;
      }

      // Add current request
      recentRequests.push(now);
      requests.set(clientId, recentRequests);

      next();
    };
  }
}
```

**Python Webhook Receiver**

```python
import hmac
import hashlib
import time
from typing import Callable, Optional
from flask import Request, Response
from functools import wraps

class WebhookReceiver:
    def __init__(
        self,
        secret: str,
        algorithm: str = 'sha256',
        header_name: str = 'X-Webhook-Signature',
        prefix: Optional[str] = None
    ):
        self.secret = secret.encode('utf-8')
        self.algorithm = algorithm
        self.header_name = header_name
        self.prefix = prefix

    def verify_signature(self, f: Callable) -> Callable:
        """Decorator to verify webhook signatures"""
        @wraps(f)
        def decorated_function(request: Request, *args, **kwargs):
            signature = request.headers.get(self.header_name)
            payload = request.get_data()

            if not self._is_valid_signature(payload, signature):
                return Response(
                    '{"error": "Invalid signature"}',
                    status=401,
                    mimetype='application/json'
                )

            return f(request, *args, **kwargs)

        return decorated_function

    def _is_valid_signature(self, payload: bytes, signature: str) -> bool:
        """Verify HMAC signature"""
        if not signature:
            return False

        hasher = hmac.new(self.secret, payload, getattr(hashlib, self.algorithm))
        digest = hasher.hexdigest()
        expected_signature = f'{self.prefix}={digest}' if self.prefix else digest

        return hmac.compare_digest(signature, expected_signature)

    def prevent_replay_attacks(self, max_age_seconds: int = 300) -> Callable:
        """Decorator to prevent replay attacks"""
        def decorator(f: Callable) -> Callable:
            @wraps(f)
            def decorated_function(request: Request, *args, **kwargs):
                timestamp = request.headers.get('X-Webhook-Timestamp')

                if not timestamp:
                    return Response(
                        '{"error": "Missing timestamp"}',
                        status=400,
                        mimetype='application/json'
                    )

                request_time = int(timestamp)
                current_time = int(time.time())

                if abs(current_time - request_time) > max_age_seconds:
                    return Response(
                        '{"error": "Request too old"}',
                        status=400,
                        mimetype='application/json'
                    )

                return f(request, *args, **kwargs)

            return decorated_function

        return decorator
```

### Sending Webhooks

**Webhook Sender with Retry Logic (TypeScript)**

```typescript
import axios, { AxiosError } from 'axios';
import * as crypto from 'crypto';

export interface WebhookEvent {
  id: string;
  type: string;
  timestamp: number;
  data: any;
}

export interface RetryConfig {
  maxAttempts: number;
  initialDelay: number;
  maxDelay: number;
  backoffMultiplier: number;
}

export class WebhookSender {
  private readonly secret: string;
  private readonly retryConfig: RetryConfig;

  constructor(
    secret: string,
    retryConfig: RetryConfig = {
      maxAttempts: 3,
      initialDelay: 1000,
      maxDelay: 30000,
      backoffMultiplier: 2
    }
  ) {
    this.secret = secret;
    this.retryConfig = retryConfig;
  }

  /**
   * Send webhook with exponential backoff retry
   */
  async sendWebhook(
    url: string,
    event: WebhookEvent
  ): Promise<void> {
    let attempt = 0;
    let delay = this.retryConfig.initialDelay;

    while (attempt < this.retryConfig.maxAttempts) {
      try {
        await this.sendWebhookRequest(url, event);
        return; // Success
      } catch (error) {
        attempt++;

        if (attempt >= this.retryConfig.maxAttempts) {
          // Max attempts reached, send to dead letter queue
          await this.sendToDeadLetterQueue(url, event, error);
          throw error;
        }

        if (!this.isRetryableError(error as AxiosError)) {
          // Non-retryable error
          throw error;
        }

        // Wait before retry
        await this.sleep(delay);

        // Exponential backoff
        delay = Math.min(
          delay * this.retryConfig.backoffMultiplier,
          this.retryConfig.maxDelay
        );
      }
    }
  }

  private async sendWebhookRequest(
    url: string,
    event: WebhookEvent
  ): Promise<void> {
    const payload = JSON.stringify(event);
    const signature = this.generateSignature(payload);

    await axios.post(url, event, {
      headers: {
        'Content-Type': 'application/json',
        'X-Webhook-Signature': `sha256=${signature}`,
        'X-Webhook-Id': event.id,
        'X-Webhook-Timestamp': event.timestamp.toString()
      },
      timeout: 30000
    });
  }

  private generateSignature(payload: string): string {
    const hmac = crypto.createHmac('sha256', this.secret);
    return hmac.update(payload).digest('hex');
  }

  private isRetryableError(error: AxiosError): boolean {
    if (!error.response) {
      // Network error - retry
      return true;
    }

    const status = error.response.status;

    // Retry on 5xx errors and 429 (rate limit)
    return status >= 500 || status === 429;
  }

  private async sendToDeadLetterQueue(
    url: string,
    event: WebhookEvent,
    error: any
  ): Promise<void> {
    // Send failed webhook to dead letter queue for manual processing
    console.error('Webhook delivery failed after all retries', {
      url,
      eventId: event.id,
      error: error.message
    });

    // Integration with Azure Service Bus or similar
    // await serviceBus.sendMessage({
    //   url,
    //   event,
    //   error: error.message,
    //   failedAt: new Date()
    // });
  }

  private sleep(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}
```

### Circuit Breaker Pattern

**Circuit Breaker Implementation (TypeScript)**

```typescript
export enum CircuitState {
  CLOSED = 'CLOSED',
  OPEN = 'OPEN',
  HALF_OPEN = 'HALF_OPEN'
}

export interface CircuitBreakerConfig {
  failureThreshold: number;
  successThreshold: number;
  timeout: number;
  monitoringPeriod: number;
}

export class CircuitBreaker {
  private state: CircuitState = CircuitState.CLOSED;
  private failures: number = 0;
  private successes: number = 0;
  private lastFailureTime?: number;
  private config: CircuitBreakerConfig;

  constructor(config: CircuitBreakerConfig) {
    this.config = config;
  }

  async execute<T>(operation: () => Promise<T>): Promise<T> {
    if (this.state === CircuitState.OPEN) {
      if (this.shouldAttemptReset()) {
        this.state = CircuitState.HALF_OPEN;
      } else {
        throw new Error('Circuit breaker is OPEN');
      }
    }

    try {
      const result = await operation();
      this.onSuccess();
      return result;
    } catch (error) {
      this.onFailure();
      throw error;
    }
  }

  private onSuccess(): void {
    this.failures = 0;

    if (this.state === CircuitState.HALF_OPEN) {
      this.successes++;

      if (this.successes >= this.config.successThreshold) {
        this.state = CircuitState.CLOSED;
        this.successes = 0;
      }
    }
  }

  private onFailure(): void {
    this.failures++;
    this.lastFailureTime = Date.now();
    this.successes = 0;

    if (this.failures >= this.config.failureThreshold) {
      this.state = CircuitState.OPEN;
    }
  }

  private shouldAttemptReset(): boolean {
    return (
      this.lastFailureTime !== undefined &&
      Date.now() - this.lastFailureTime >= this.config.timeout
    );
  }

  getState(): CircuitState {
    return this.state;
  }
}
```

---

## Custom API Integration

Integrate with any REST or GraphQL API using a flexible HTTP client with authentication, retry logic, and error handling.

### REST API Integration

**HTTP Client with OAuth2 (TypeScript)**

```typescript
import axios, { AxiosInstance, AxiosRequestConfig, AxiosError } from 'axios';

export interface OAuth2Config {
  clientId: string;
  clientSecret: string;
  tokenUrl: string;
  scopes: string[];
}

export class OAuth2Client {
  private accessToken?: string;
  private tokenExpiry?: number;
  private config: OAuth2Config;

  constructor(config: OAuth2Config) {
    this.config = config;
  }

  /**
   * Get access token (with automatic refresh)
   */
  async getAccessToken(): Promise<string> {
    if (this.accessToken && this.tokenExpiry && Date.now() < this.tokenExpiry) {
      return this.accessToken;
    }

    const response = await axios.post(
      this.config.tokenUrl,
      new URLSearchParams({
        grant_type: 'client_credentials',
        client_id: this.config.clientId,
        client_secret: this.config.clientSecret,
        scope: this.config.scopes.join(' ')
      }),
      {
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded'
        }
      }
    );

    this.accessToken = response.data.access_token;
    this.tokenExpiry = Date.now() + (response.data.expires_in - 60) * 1000;

    return this.accessToken;
  }
}

export class RestApiClient {
  private client: AxiosInstance;
  private oauth2Client?: OAuth2Client;
  private circuitBreaker: CircuitBreaker;

  constructor(
    baseUrl: string,
    oauth2Config?: OAuth2Config
  ) {
    this.client = axios.create({
      baseURL: baseUrl,
      timeout: 30000
    });

    if (oauth2Config) {
      this.oauth2Client = new OAuth2Client(oauth2Config);
    }

    this.circuitBreaker = new CircuitBreaker({
      failureThreshold: 5,
      successThreshold: 2,
      timeout: 60000,
      monitoringPeriod: 300000
    });

    this.setupInterceptors();
  }

  private setupInterceptors(): void {
    // Request interceptor for authentication
    this.client.interceptors.request.use(async (config) => {
      if (this.oauth2Client) {
        const token = await this.oauth2Client.getAccessToken();
        config.headers.Authorization = `Bearer ${token}`;
      }
      return config;
    });

    // Response interceptor for error handling
    this.client.interceptors.response.use(
      (response) => response,
      async (error: AxiosError) => {
        if (error.response?.status === 401 && this.oauth2Client) {
          // Token expired, retry with new token
          const token = await this.oauth2Client.getAccessToken();
          if (error.config) {
            error.config.headers.Authorization = `Bearer ${token}`;
            return this.client.request(error.config);
          }
        }
        throw error;
      }
    );
  }

  /**
   * GET request with circuit breaker
   */
  async get<T>(path: string, config?: AxiosRequestConfig): Promise<T> {
    return this.circuitBreaker.execute(async () => {
      const response = await this.client.get<T>(path, config);
      return response.data;
    });
  }

  /**
   * POST request with circuit breaker
   */
  async post<T>(
    path: string,
    data?: any,
    config?: AxiosRequestConfig
  ): Promise<T> {
    return this.circuitBreaker.execute(async () => {
      const response = await this.client.post<T>(path, data, config);
      return response.data;
    });
  }

  /**
   * PUT request with circuit breaker
   */
  async put<T>(
    path: string,
    data?: any,
    config?: AxiosRequestConfig
  ): Promise<T> {
    return this.circuitBreaker.execute(async () => {
      const response = await this.client.put<T>(path, data, config);
      return response.data;
    });
  }

  /**
   * DELETE request with circuit breaker
   */
  async delete<T>(path: string, config?: AxiosRequestConfig): Promise<T> {
    return this.circuitBreaker.execute(async () => {
      const response = await this.client.delete<T>(path, config);
      return response.data;
    });
  }
}
```

### GraphQL Integration

**GraphQL Client (TypeScript)**

```typescript
import { GraphQLClient, gql } from 'graphql-request';

export class GraphQLApiClient {
  private client: GraphQLClient;

  constructor(
    endpoint: string,
    private apiKey: string
  ) {
    this.client = new GraphQLClient(endpoint, {
      headers: {
        Authorization: `Bearer ${apiKey}`
      }
    });
  }

  /**
   * Execute GraphQL query
   */
  async query<T>(
    query: string,
    variables?: Record<string, any>
  ): Promise<T> {
    try {
      return await this.client.request<T>(query, variables);
    } catch (error) {
      console.error('GraphQL query error:', error);
      throw error;
    }
  }

  /**
   * Execute GraphQL mutation
   */
  async mutate<T>(
    mutation: string,
    variables?: Record<string, any>
  ): Promise<T> {
    try {
      return await this.client.request<T>(mutation, variables);
    } catch (error) {
      console.error('GraphQL mutation error:', error);
      throw error;
    }
  }

  /**
   * Batch multiple queries
   */
  async batchQuery<T>(
    queries: Array<{ query: string; variables?: Record<string, any> }>
  ): Promise<T[]> {
    const results = await Promise.all(
      queries.map(({ query, variables }) =>
        this.client.request<T>(query, variables)
      )
    );

    return results;
  }
}

// Example usage
const client = new GraphQLApiClient(
  'https://api.example.com/graphql',
  'your-api-key'
);

const QUERY = gql`
  query GetUser($id: ID!) {
    user(id: $id) {
      id
      name
      email
    }
  }
`;

const user = await client.query(QUERY, { id: '123' });
```

---

## Microsoft Teams Integration

Integrate with Microsoft Teams using incoming webhooks and adaptive cards.

**Teams Webhook Client (TypeScript)**

```typescript
export interface AdaptiveCard {
  type: 'message';
  attachments: Array<{
    contentType: 'application/vnd.microsoft.card.adaptive';
    content: {
      type: 'AdaptiveCard';
      version: '1.4';
      body: any[];
      actions?: any[];
    };
  }>;
}

export class TeamsWebhookClient {
  constructor(private webhookUrl: string) {}

  /**
   * Send adaptive card notification
   */
  async sendAdaptiveCard(
    title: string,
    message: string,
    facts: Array<{ title: string; value: string }> = []
  ): Promise<void> {
    const card: AdaptiveCard = {
      type: 'message',
      attachments: [
        {
          contentType: 'application/vnd.microsoft.card.adaptive',
          content: {
            type: 'AdaptiveCard',
            version: '1.4',
            body: [
              {
                type: 'TextBlock',
                text: title,
                weight: 'Bolder',
                size: 'Large'
              },
              {
                type: 'TextBlock',
                text: message,
                wrap: true
              },
              {
                type: 'FactSet',
                facts: facts.map(f => ({
                  title: f.title,
                  value: f.value
                }))
              }
            ]
          }
        }
      ]
    };

    await axios.post(this.webhookUrl, card);
  }

  /**
   * Send workflow notification
   */
  async sendWorkflowNotification(
    workflowName: string,
    status: 'started' | 'completed' | 'failed',
    duration?: number
  ): Promise<void> {
    const color = status === 'completed' ? 'Good' : status === 'failed' ? 'Attention' : 'Default';

    const facts = [
      { title: 'Status', value: status },
      { title: 'Time', value: new Date().toLocaleString() }
    ];

    if (duration) {
      facts.push({ title: 'Duration', value: `${duration}s` });
    }

    await this.sendAdaptiveCard(
      `Workflow: ${workflowName}`,
      `Workflow ${status}`,
      facts
    );
  }
}
```

---

## Email Integration

Send transactional emails using SendGrid.

**SendGrid Client (TypeScript)**

```typescript
import sgMail from '@sendgrid/mail';

export class EmailClient {
  constructor(apiKey: string) {
    sgMail.setApiKey(apiKey);
  }

  /**
   * Send workflow notification email
   */
  async sendWorkflowNotification(
    to: string,
    workflowName: string,
    status: 'completed' | 'failed',
    details: string
  ): Promise<void> {
    const msg = {
      to,
      from: 'noreply@agentstudio.com',
      subject: `Workflow ${workflowName}: ${status}`,
      text: `Workflow ${workflowName} has ${status}.\n\nDetails: ${details}`,
      html: `
        <h2>Workflow ${workflowName}</h2>
        <p>Status: <strong>${status}</strong></p>
        <p>Details: ${details}</p>
      `
    };

    await sgMail.send(msg);
  }
}
```

---

## SMS Integration

Send SMS notifications using Twilio.

**Twilio Client (TypeScript)**

```typescript
import twilio from 'twilio';

export class SmsClient {
  private client: twilio.Twilio;

  constructor(accountSid: string, authToken: string, private fromNumber: string) {
    this.client = twilio(accountSid, authToken);
  }

  /**
   * Send SMS notification
   */
  async sendNotification(
    to: string,
    message: string
  ): Promise<void> {
    await this.client.messages.create({
      body: message,
      from: this.fromNumber,
      to
    });
  }
}
```

---

## Storage Integration

Integrate with Azure Blob Storage, AWS S3, and Google Cloud Storage.

**Azure Blob Storage Client (TypeScript)**

```typescript
import { BlobServiceClient, ContainerClient } from '@azure/storage-blob';

export class AzureStorageClient {
  private containerClient: ContainerClient;

  constructor(connectionString: string, containerName: string) {
    const blobServiceClient = BlobServiceClient.fromConnectionString(connectionString);
    this.containerClient = blobServiceClient.getContainerClient(containerName);
  }

  async uploadFile(fileName: string, content: Buffer | string): Promise<string> {
    const blockBlobClient = this.containerClient.getBlockBlobClient(fileName);
    await blockBlobClient.upload(content, content.length);
    return blockBlobClient.url;
  }

  async downloadFile(fileName: string): Promise<Buffer> {
    const blockBlobClient = this.containerClient.getBlockBlobClient(fileName);
    const downloadResponse = await blockBlobClient.download();
    return await this.streamToBuffer(downloadResponse.readableStreamBody!);
  }

  private async streamToBuffer(readableStream: NodeJS.ReadableStream): Promise<Buffer> {
    return new Promise((resolve, reject) => {
      const chunks: Buffer[] = [];
      readableStream.on('data', (data) => chunks.push(data));
      readableStream.on('end', () => resolve(Buffer.concat(chunks)));
      readableStream.on('error', reject);
    });
  }
}
```

---

## Message Queue Integration

Integrate with Azure Service Bus for asynchronous messaging.

**Azure Service Bus Client (TypeScript)**

```typescript
import { ServiceBusClient, ServiceBusMessage } from '@azure/service-bus';

export class MessageQueueClient {
  private client: ServiceBusClient;

  constructor(connectionString: string) {
    this.client = new ServiceBusClient(connectionString);
  }

  async sendMessage(queueName: string, message: any): Promise<void> {
    const sender = this.client.createSender(queueName);

    try {
      const sbMessage: ServiceBusMessage = {
        body: message,
        contentType: 'application/json'
      };

      await sender.sendMessages(sbMessage);
    } finally {
      await sender.close();
    }
  }

  async receiveMessages(
    queueName: string,
    maxMessages: number = 10
  ): Promise<any[]> {
    const receiver = this.client.createReceiver(queueName);

    try {
      const messages = await receiver.receiveMessages(maxMessages, {
        maxWaitTimeInMs: 5000
      });

      const results = messages.map(msg => msg.body);

      // Complete messages
      for (const message of messages) {
        await receiver.completeMessage(message);
      }

      return results;
    } finally {
      await receiver.close();
    }
  }
}
```

---

## Database Integration

Connect to external databases for data persistence.

**PostgreSQL Client (TypeScript)**

```typescript
import { Pool, QueryResult } from 'pg';

export class PostgresClient {
  private pool: Pool;

  constructor(config: {
    host: string;
    port: number;
    database: string;
    user: string;
    password: string;
  }) {
    this.pool = new Pool(config);
  }

  async query<T>(sql: string, params: any[] = []): Promise<T[]> {
    const result: QueryResult = await this.pool.query(sql, params);
    return result.rows;
  }

  async close(): Promise<void> {
    await this.pool.end();
  }
}
```

---

## Monitoring Integration

Integrate with Datadog for custom metrics and monitoring.

**Datadog Client (TypeScript)**

```typescript
import { StatsD } from 'hot-shots';

export class DatadogClient {
  private client: StatsD;

  constructor(host: string = 'localhost', port: number = 8125) {
    this.client = new StatsD({ host, port });
  }

  recordWorkflowExecution(workflowName: string, duration: number, status: string): void {
    this.client.histogram('workflow.duration', duration, {
      workflow: workflowName,
      status
    });

    this.client.increment('workflow.executions', 1, {
      workflow: workflowName,
      status
    });
  }

  recordApiCall(endpoint: string, statusCode: number, duration: number): void {
    this.client.histogram('api.response_time', duration, {
      endpoint,
      status_code: statusCode.toString()
    });

    this.client.increment('api.calls', 1, {
      endpoint,
      status_code: statusCode.toString()
    });
  }
}
```

---

## Best Practices

### Security

1. **Credential Management**
   - Store all secrets in Azure Key Vault
   - Use Managed Identity for Azure service authentication
   - Implement automatic secret rotation
   - Never log sensitive data

2. **Signature Verification**
   - Always verify webhook signatures
   - Use timing-safe comparison functions
   - Implement replay attack prevention with timestamps

3. **Rate Limiting**
   - Implement per-client rate limits
   - Use exponential backoff for retries
   - Monitor and alert on rate limit violations

### Reliability

1. **Retry Logic**
   - Implement exponential backoff
   - Set maximum retry attempts
   - Only retry on transient errors
   - Use dead letter queues for failed messages

2. **Circuit Breakers**
   - Prevent cascading failures
   - Monitor circuit breaker state
   - Implement graceful degradation

3. **Timeouts**
   - Set appropriate timeouts for all operations
   - Use connection pooling
   - Implement request cancellation

### Performance

1. **Connection Pooling**
   - Reuse HTTP connections
   - Configure appropriate pool sizes
   - Monitor connection health

2. **Caching**
   - Cache authentication tokens
   - Implement response caching where appropriate
   - Use ETags for conditional requests

3. **Batching**
   - Batch API requests when possible
   - Use bulk operations
   - Implement request coalescing

### Observability

1. **Logging**
   - Log all integration events
   - Include correlation IDs
   - Structured logging with context

2. **Metrics**
   - Track success/failure rates
   - Monitor latency
   - Alert on anomalies

3. **Tracing**
   - Distributed tracing across services
   - Track request flow
   - Identify bottlenecks

---

## Complete Examples

### Example 1: GitHub PR Automation

Complete workflow that automatically reviews pull requests and posts feedback.

```typescript
import { GitHubWebhookHandler, GitHubClient } from './integrations';

// Initialize GitHub integration
const webhookHandler = new GitHubWebhookHandler(process.env.GITHUB_WEBHOOK_SECRET!);
const githubClient = new GitHubClient(process.env.GITHUB_TOKEN!);

// Webhook endpoint
app.post('/api/webhooks/github', async (req, res) => {
  await webhookHandler.handleWebhook(req, res);
});

// Code review workflow
async function executeCodeReview(context: {
  repository: string;
  prNumber: number;
  headSha: string;
}): Promise<void> {
  const [owner, repo] = context.repository.split('/');

  // Trigger Agent Studio code review workflow
  const workflowClient = new WorkflowClient();
  const result = await workflowClient.executeWorkflow('code-review-workflow', {
    repository: context.repository,
    pr: context.prNumber
  });

  // Post results as PR comment
  const findings = result.outputs.findings;
  const comment = formatCodeReviewComment(findings);

  await githubClient.createPRComment(owner, repo, context.prNumber, comment);

  // Create review if there are issues
  if (findings.critical > 0 || findings.major > 0) {
    await githubClient.createReview(
      owner,
      repo,
      context.prNumber,
      context.headSha,
      'REQUEST_CHANGES',
      'Code review identified issues that need attention.'
    );
  } else {
    await githubClient.createReview(
      owner,
      repo,
      context.prNumber,
      context.headSha,
      'APPROVE',
      'Code review looks good!'
    );
  }
}

function formatCodeReviewComment(findings: any): string {
  return `
## Code Review Complete

- Critical Issues: ${findings.critical}
- Major Issues: ${findings.major}
- Minor Issues: ${findings.minor}

${findings.details}
  `;
}
```

### Example 2: Slack Notification Bot

Complete Slack integration with interactive notifications.

```typescript
import { SlackWebhookClient, SlackCommandHandler } from './integrations';

const slackWebhook = new SlackWebhookClient(process.env.SLACK_WEBHOOK_URL!);
const slackCommands = new SlackCommandHandler(process.env.SLACK_SIGNING_SECRET!);

// Slash command endpoint
app.post('/api/slack/commands', async (req, res) => {
  await slackCommands.handleCommand(req, res);
});

// Send workflow notifications
async function notifyWorkflowComplete(
  workflowName: string,
  status: 'completed' | 'failed',
  duration: number
): Promise<void> {
  await slackWebhook.sendWorkflowUpdate(
    workflowName,
    status,
    `Workflow executed in ${duration}s`
  );
}
```

### Example 3: Webhook Receiver Service

Complete webhook receiver with security and reliability.

```typescript
import express from 'express';
import { WebhookReceiver, WebhookSender } from './integrations';

const app = express();
app.use(express.json());

const receiver = new WebhookReceiver({
  secret: process.env.WEBHOOK_SECRET!,
  algorithm: 'sha256',
  headerName: 'X-Webhook-Signature',
  prefix: 'sha256'
});

// Webhook endpoint with all security measures
app.post(
  '/api/webhooks/external',
  receiver.verifySignature(),
  receiver.preventReplayAttacks(300),
  receiver.rateLimit(100, 60),
  async (req, res) => {
    try {
      const event = req.body;

      // Process webhook event
      await processWebhookEvent(event);

      res.status(200).json({ status: 'processed' });
    } catch (error) {
      console.error('Webhook processing error:', error);
      res.status(500).json({ error: 'Processing failed' });
    }
  }
);

async function processWebhookEvent(event: any): Promise<void> {
  // Trigger workflow based on event type
  const workflowClient = new WorkflowClient();
  await workflowClient.executeWorkflow(event.type, event.data);
}
```

---

## Troubleshooting

### Common Issues

**1. Webhook Signature Verification Fails**

```typescript
// Ensure payload is exactly as received (no parsing before verification)
const rawBody = req.body; // Use raw body middleware

// Verify algorithm matches
const algorithm = 'sha256'; // Must match sender's algorithm

// Check secret is correct
const secret = process.env.WEBHOOK_SECRET; // Ensure secret matches
```

**2. OAuth2 Token Expired**

```typescript
// Implement automatic token refresh
class OAuth2Client {
  async getAccessToken(): Promise<string> {
    if (this.isTokenExpired()) {
      await this.refreshToken();
    }
    return this.accessToken!;
  }

  private isTokenExpired(): boolean {
    return !this.tokenExpiry || Date.now() >= this.tokenExpiry;
  }
}
```

**3. Rate Limit Exceeded**

```typescript
// Implement exponential backoff
async function retryWithBackoff<T>(
  operation: () => Promise<T>,
  maxAttempts: number = 5
): Promise<T> {
  let attempt = 0;
  let delay = 1000;

  while (attempt < maxAttempts) {
    try {
      return await operation();
    } catch (error) {
      if (error.response?.status === 429) {
        const retryAfter = error.response.headers['retry-after'];
        delay = retryAfter ? parseInt(retryAfter) * 1000 : delay * 2;
        await new Promise(resolve => setTimeout(resolve, delay));
        attempt++;
      } else {
        throw error;
      }
    }
  }

  throw new Error('Max retry attempts exceeded');
}
```

**4. Circuit Breaker Stuck Open**

```typescript
// Monitor circuit breaker state and manually reset if needed
const circuitBreaker = new CircuitBreaker(config);

// Add monitoring
setInterval(() => {
  const state = circuitBreaker.getState();
  if (state === CircuitState.OPEN) {
    console.warn('Circuit breaker is OPEN - service may be unhealthy');
    // Alert operations team
  }
}, 60000);
```

---

## Conclusion

This guide covered comprehensive integration patterns for Agent Studio with external services including GitHub, Slack, webhooks, custom APIs, and more. Key takeaways:

- **Security First**: Always verify signatures, encrypt credentials, and implement rate limiting
- **Reliability**: Use retry logic, circuit breakers, and dead letter queues
- **Performance**: Implement connection pooling, caching, and batching
- **Observability**: Comprehensive logging, metrics, and distributed tracing

For additional support, refer to the [Agent Studio documentation](../README.md) or contact the platform team.
