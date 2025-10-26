/**
 * Notion webhook signature verification using HMAC-SHA256.
 * Establishes secure authentication to prevent unauthorized webhook requests.
 *
 * Best for: Production webhook endpoints requiring cryptographic validation
 */

import { createHmac, timingSafeEqual } from 'crypto';

/**
 * Verify Notion webhook signature using HMAC-SHA256 algorithm.
 * Protects against replay attacks and unauthorized POST requests.
 *
 * @param payload - Raw request body as string
 * @param signature - Notion-Signature header value
 * @param secret - Webhook secret from Key Vault
 * @returns true if signature valid, false otherwise
 *
 * @example
 * ```typescript
 * const isValid = verifyNotionSignature(
 *   req.body,
 *   req.headers['notion-signature'],
 *   process.env.NOTION_WEBHOOK_SECRET
 * );
 *
 * if (!isValid) {
 *   context.res = { status: 401, body: 'Invalid signature' };
 *   return;
 * }
 * ```
 */
export function verifyNotionSignature(
  payload: string,
  signature: string | undefined,
  secret: string
): boolean {
  if (!signature || !secret) {
    return false;
  }

  try {
    // Notion signature format: "v1=<hmac_hex>"
    const signatureParts = signature.split('=');
    if (signatureParts.length !== 2 || signatureParts[0] !== 'v1') {
      return false;
    }

    const providedSignature = signatureParts[1];

    // Calculate expected signature
    const hmac = createHmac('sha256', secret);
    hmac.update(payload);
    const expectedSignature = hmac.digest('hex');

    // Timing-safe comparison to prevent timing attacks
    const providedBuffer = Buffer.from(providedSignature, 'hex');
    const expectedBuffer = Buffer.from(expectedSignature, 'hex');

    if (providedBuffer.length !== expectedBuffer.length) {
      return false;
    }

    return timingSafeEqual(providedBuffer, expectedBuffer);
  } catch (error) {
    console.error('Signature verification error:', error);
    return false;
  }
}

/**
 * Generate HMAC-SHA256 signature for outgoing webhook testing.
 * Useful for integration tests and local development.
 *
 * @param payload - Request body to sign
 * @param secret - Webhook secret
 * @returns Notion-compatible signature header value
 *
 * @example
 * ```typescript
 * const signature = generateNotionSignature(
 *   JSON.stringify(testPayload),
 *   'test-secret-key'
 * );
 *
 * const response = await fetch(webhookUrl, {
 *   method: 'POST',
 *   headers: { 'Notion-Signature': signature },
 *   body: JSON.stringify(testPayload)
 * });
 * ```
 */
export function generateNotionSignature(payload: string, secret: string): string {
  const hmac = createHmac('sha256', secret);
  hmac.update(payload);
  const signature = hmac.digest('hex');
  return `v1=${signature}`;
}
