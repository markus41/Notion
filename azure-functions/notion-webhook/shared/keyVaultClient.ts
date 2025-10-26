/**
 * Azure Key Vault client for secure secret retrieval using Managed Identity.
 * Establishes centralized credential management without hardcoded secrets.
 *
 * Best for: Azure Functions requiring secure access to sensitive configuration
 */

import { DefaultAzureCredential } from '@azure/identity';
import { SecretClient } from '@azure/keyvault-secrets';
import type { KeyVaultSecrets } from './types';

// Cache secrets in memory for function lifetime (serverless optimization)
let secretsCache: KeyVaultSecrets | null = null;

/**
 * Retrieve Notion API key and webhook secret from Azure Key Vault.
 * Uses Managed Identity for authentication (no credentials in code).
 * Caches secrets for function lifetime to minimize Key Vault API calls.
 *
 * @param keyVaultName - Name of Key Vault (kv-brookside-secrets)
 * @returns Notion API key and webhook secret
 * @throws Error if Key Vault access fails or secrets not found
 *
 * @example
 * ```typescript
 * const secrets = await getNotionSecrets('kv-brookside-secrets');
 * const notion = new Client({ auth: secrets.notionApiKey });
 * ```
 */
export async function getNotionSecrets(keyVaultName: string): Promise<KeyVaultSecrets> {
  // Return cached secrets if available (warm start optimization)
  if (secretsCache) {
    return secretsCache;
  }

  try {
    const keyVaultUrl = `https://${keyVaultName}.vault.azure.net`;

    // Use DefaultAzureCredential for automatic authentication
    // Works with: Managed Identity (production), Azure CLI (local dev), VS Code
    const credential = new DefaultAzureCredential();
    const client = new SecretClient(keyVaultUrl, credential);

    // Retrieve both secrets in parallel for efficiency
    const [notionApiKeySecret, notionWebhookSecret] = await Promise.all([
      client.getSecret('notion-api-key'),
      client.getSecret('notion-webhook-secret')
    ]);

    if (!notionApiKeySecret.value || !notionWebhookSecret.value) {
      throw new Error('Notion secrets not found in Key Vault');
    }

    // Cache for function lifetime
    secretsCache = {
      notionApiKey: notionApiKeySecret.value,
      notionWebhookSecret: notionWebhookSecret.value
    };

    return secretsCache;
  } catch (error: any) {
    console.error('Failed to retrieve secrets from Key Vault:', error);
    throw new Error(`Key Vault access failed: ${error.message}`);
  }
}

/**
 * Clear secrets cache (useful for testing or forced refresh).
 * In production, cache persists for function instance lifetime.
 */
export function clearSecretsCache(): void {
  secretsCache = null;
}
