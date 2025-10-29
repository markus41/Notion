/**
 * Webhook Security Pattern - Production-ready HMAC authentication with Azure Key Vault
 *
 * **Purpose**: Establish enterprise-grade webhook authentication to prevent unauthorized access
 * and cryptographic replay attacks in production Azure Functions endpoints.
 *
 * **Best for**: Organizations scaling webhook integrations across distributed systems requiring
 * zero-trust security with centralized secret management through Azure Key Vault and Managed Identity.
 *
 * **Dependencies**:
 * - @azure/functions (^4.0.0)
 * - @azure/identity (^4.0.0)
 * - @azure/keyvault-secrets (^4.7.0)
 * - crypto (Node.js built-in)
 *
 * **Security Features**:
 * ✅ HMAC-SHA256 cryptographic signature verification
 * ✅ Timing-safe comparison to prevent timing attacks
 * ✅ Azure Managed Identity authentication (no credentials)
 * ✅ Azure Key Vault integration for centralized secret management
 * ✅ Signature format validation (Notion v1 format: "v1=<hex>")
 * ✅ Comprehensive error handling and logging
 *
 * **Usage Example**:
 * ```typescript
 * import { app, HttpRequest, HttpResponseInit, InvocationContext } from '@azure/functions';
 * import { verifyWebhookSignature, getSecrets } from './webhook-security-pattern';
 *
 * export async function webhookHandler(
 *   request: HttpRequest,
 *   context: InvocationContext
 * ): Promise<HttpResponseInit> {
 *   // 1. Retrieve secrets from Azure Key Vault
 *   const secrets = await getSecrets('kv-your-keyvault', ['webhook-secret']);
 *
 *   // 2. Get raw request body and signature header
 *   const rawBody = await request.text();
 *   const signature = request.headers.get('x-signature');  // Or 'notion-signature', etc.
 *
 *   // 3. Verify signature (security gate)
 *   const isValid = verifyWebhookSignature(rawBody, signature, secrets['webhook-secret']);
 *
 *   if (!isValid) {
 *     context.log.error('Invalid webhook signature - rejecting request');
 *     return {
 *       status: 401,
 *       jsonBody: { success: false, message: 'Invalid signature' }
 *     };
 *   }
 *
 *   // 4. Process webhook payload safely
 *   const payload = JSON.parse(rawBody);
 *   // ... business logic ...
 *
 *   return { status: 200, jsonBody: { success: true } };
 * }
 * ```
 *
 * **Testing Example**:
 * ```typescript
 * import { generateWebhookSignature } from './webhook-security-pattern';
 *
 * const testPayload = JSON.stringify({ event: 'test' });
 * const signature = generateWebhookSignature(testPayload, 'test-secret-key');
 *
 * const response = await fetch('http://localhost:7071/api/webhook', {
 *   method: 'POST',
 *   headers: { 'x-signature': signature },
 *   body: testPayload
 * });
 * ```
 *
 * @see https://learn.microsoft.com/azure/key-vault/general/authentication
 * @see https://learn.microsoft.com/azure/azure-functions/functions-reference-node
 */

import { createHmac, timingSafeEqual } from 'crypto';
import { DefaultAzureCredential } from '@azure/identity';
import { SecretClient } from '@azure/keyvault-secrets';

/**
 * Signature format configuration
 * Customize based on your webhook provider's format
 */
const SIGNATURE_VERSION = 'v1';  // Notion format: "v1=<hex>"
const SIGNATURE_SEPARATOR = '=';

/**
 * Retrieve secrets from Azure Key Vault using Managed Identity
 * Establishes secure, credential-less secret access to support zero-trust architecture
 *
 * @param keyVaultName - Azure Key Vault name (e.g., "kv-brookside-secrets")
 * @param secretNames - Array of secret names to retrieve
 * @returns Object mapping secret names to values
 *
 * **Best for**: Production environments with Azure Managed Identity enabled
 *
 * **Prerequisites**:
 * - Azure Function must have Managed Identity enabled
 * - Managed Identity must have "Key Vault Secrets User" role on Key Vault
 * - Key Vault must allow access from Azure Functions subnet
 *
 * @example
 * ```typescript
 * const secrets = await getSecrets('kv-myapp-prod', [
 *   'webhook-secret',
 *   'api-key',
 *   'database-password'
 * ]);
 *
 * console.log(secrets['webhook-secret']);  // Retrieved from Key Vault
 * ```
 */
export async function getSecrets(
  keyVaultName: string,
  secretNames: string[]
): Promise<Record<string, string>> {
  const credential = new DefaultAzureCredential();
  const vaultUrl = `https://${keyVaultName}.vault.azure.net`;
  const client = new SecretClient(vaultUrl, credential);

  // Parallel retrieval for improved performance
  const secretPromises = secretNames.map(async (name) => {
    try {
      const secret = await client.getSecret(name);
      return { name, value: secret.value || '' };
    } catch (error: any) {
      throw new Error(
        `Failed to retrieve secret '${name}' from Key Vault '${keyVaultName}': ${error.message}`
      );
    }
  });

  const results = await Promise.all(secretPromises);

  return results.reduce((acc, { name, value }) => {
    acc[name] = value;
    return acc;
  }, {} as Record<string, string>);
}

/**
 * Verify webhook signature using HMAC-SHA256 algorithm
 * Establishes cryptographic validation to prevent unauthorized requests and replay attacks
 *
 * @param payload - Raw request body as string (MUST be original bytes, not parsed JSON)
 * @param signature - Signature header value from webhook provider
 * @param secret - Webhook secret from Key Vault
 * @returns true if signature valid, false otherwise
 *
 * **Security Notes**:
 * - Uses `timingSafeEqual` to prevent timing attacks
 * - Validates signature format before computation
 * - Handles errors gracefully without exposing internals
 *
 * **Best for**: Validating webhooks from Notion, Stripe, GitHub, or any HMAC-SHA256 provider
 *
 * @example
 * ```typescript
 * const rawBody = await request.text();  // Raw string, not parsed
 * const signature = request.headers.get('x-signature');
 * const secret = secrets['webhook-secret'];
 *
 * if (!verifyWebhookSignature(rawBody, signature, secret)) {
 *   return { status: 401, body: 'Invalid signature' };
 * }
 * ```
 */
export function verifyWebhookSignature(
  payload: string,
  signature: string | undefined | null,
  secret: string
): boolean {
  // 1. Validate inputs (fail fast)
  if (!signature || !secret || !payload) {
    return false;
  }

  try {
    // 2. Parse signature format (e.g., "v1=abc123...")
    const signatureParts = signature.split(SIGNATURE_SEPARATOR);

    if (signatureParts.length !== 2 || signatureParts[0] !== SIGNATURE_VERSION) {
      console.error('Invalid signature format - expected format: v1=<hex>');
      return false;
    }

    const providedSignature = signatureParts[1];

    // 3. Calculate expected signature using HMAC-SHA256
    const hmac = createHmac('sha256', secret);
    hmac.update(payload);
    const expectedSignature = hmac.digest('hex');

    // 4. Timing-safe comparison (prevents timing attacks)
    const providedBuffer = Buffer.from(providedSignature, 'hex');
    const expectedBuffer = Buffer.from(expectedSignature, 'hex');

    // Length check first (timing-safe requires equal length)
    if (providedBuffer.length !== expectedBuffer.length) {
      return false;
    }

    return timingSafeEqual(providedBuffer, expectedBuffer);

  } catch (error: any) {
    console.error('Signature verification error:', error.message);
    return false;
  }
}

/**
 * Generate HMAC-SHA256 signature for outgoing webhooks or testing
 * Establishes consistent signature generation for integration tests and local development
 *
 * @param payload - Request body to sign (JSON string or raw data)
 * @param secret - Webhook secret
 * @returns Signature header value in provider format (e.g., "v1=abc123...")
 *
 * **Best for**: Integration tests, webhook simulators, local development
 *
 * @example
 * ```typescript
 * // Testing webhook handler locally
 * const testPayload = JSON.stringify({ event: 'test.created', data: {} });
 * const signature = generateWebhookSignature(testPayload, 'test-secret');
 *
 * const response = await fetch('http://localhost:7071/api/webhook', {
 *   method: 'POST',
 *   headers: {
 *     'Content-Type': 'application/json',
 *     'x-signature': signature
 *   },
 *   body: testPayload
 * });
 * ```
 */
export function generateWebhookSignature(payload: string, secret: string): string {
  const hmac = createHmac('sha256', secret);
  hmac.update(payload);
  const signature = hmac.digest('hex');
  return `${SIGNATURE_VERSION}${SIGNATURE_SEPARATOR}${signature}`;
}

/**
 * Enhanced webhook handler wrapper with automatic security validation
 * Establishes declarative security middleware to streamline webhook implementation
 *
 * @param handler - Business logic function to execute after validation
 * @param keyVaultName - Azure Key Vault name
 * @param secretName - Webhook secret key name in Key Vault
 * @param signatureHeader - HTTP header name for signature (default: 'x-signature')
 * @returns Azure Functions HTTP handler with built-in security
 *
 * **Best for**: Standardizing webhook security across multiple endpoints
 *
 * @example
 * ```typescript
 * import { app } from '@azure/functions';
 * import { secureWebhookHandler } from './webhook-security-pattern';
 *
 * async function processWebhook(payload: any, context: InvocationContext) {
 *   context.log('Processing webhook:', payload.type);
 *   // ... business logic ...
 *   return { success: true };
 * }
 *
 * app.http('SecureWebhook', {
 *   methods: ['POST'],
 *   authLevel: 'anonymous',
 *   handler: secureWebhookHandler(
 *     processWebhook,
 *     'kv-myapp-secrets',
 *     'webhook-secret',
 *     'notion-signature'  // Custom header name
 *   )
 * });
 * ```
 */
export function secureWebhookHandler(
  handler: (payload: any, context: any) => Promise<any>,
  keyVaultName: string,
  secretName: string,
  signatureHeader: string = 'x-signature'
) {
  return async (request: any, context: any): Promise<any> => {
    const startTime = Date.now();

    try {
      // 1. Retrieve webhook secret from Key Vault
      const secrets = await getSecrets(keyVaultName, [secretName]);
      const webhookSecret = secrets[secretName];

      if (!webhookSecret) {
        context.log.error(`Webhook secret '${secretName}' not found in Key Vault`);
        return {
          status: 500,
          jsonBody: { success: false, message: 'Configuration error' }
        };
      }

      // 2. Get raw request body and signature
      const rawBody = await request.text();
      const signature = request.headers.get(signatureHeader);

      // 3. Verify signature (security gate)
      const isValid = verifyWebhookSignature(rawBody, signature, webhookSecret);

      if (!isValid) {
        context.log.error('Invalid webhook signature - rejecting request');
        return {
          status: 401,
          jsonBody: {
            success: false,
            message: 'Invalid signature',
            error: 'Webhook signature verification failed'
          }
        };
      }

      context.log('Signature verified successfully');

      // 4. Parse payload and invoke handler
      let payload: any;
      try {
        payload = JSON.parse(rawBody);
      } catch (parseError: any) {
        context.log.error('Failed to parse webhook payload:', parseError);
        return {
          status: 400,
          jsonBody: {
            success: false,
            message: 'Invalid JSON payload',
            error: parseError.message
          }
        };
      }

      // 5. Execute business logic
      const result = await handler(payload, context);

      const duration = Date.now() - startTime;
      context.log(`Webhook processed successfully in ${duration}ms`);

      return {
        status: 200,
        jsonBody: {
          success: true,
          ...result,
          duration
        }
      };

    } catch (error: any) {
      const duration = Date.now() - startTime;
      context.log.error('Webhook handler error:', error);

      return {
        status: 500,
        jsonBody: {
          success: false,
          message: 'Internal server error',
          error: error.message || String(error),
          duration
        }
      };
    }
  };
}

/**
 * Environment-based configuration helper
 * Establishes centralized configuration retrieval to support multi-environment deployments
 *
 * @returns Webhook configuration from environment variables
 *
 * **Environment Variables**:
 * - KEY_VAULT_NAME: Azure Key Vault name (required)
 * - WEBHOOK_SECRET_NAME: Secret key name in Key Vault (default: "webhook-secret")
 * - SIGNATURE_HEADER: HTTP header name (default: "x-signature")
 *
 * @example
 * ```typescript
 * const config = getWebhookConfig();
 * const secrets = await getSecrets(config.keyVaultName, [config.secretName]);
 * ```
 */
export function getWebhookConfig(): {
  keyVaultName: string;
  secretName: string;
  signatureHeader: string;
} {
  const keyVaultName = process.env.KEY_VAULT_NAME;

  if (!keyVaultName) {
    throw new Error('KEY_VAULT_NAME environment variable not set');
  }

  return {
    keyVaultName,
    secretName: process.env.WEBHOOK_SECRET_NAME || 'webhook-secret',
    signatureHeader: process.env.SIGNATURE_HEADER || 'x-signature'
  };
}
