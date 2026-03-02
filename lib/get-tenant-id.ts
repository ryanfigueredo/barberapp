/**
 * getTenantIdFromRequest — Extrai tenant_id de forma segura para multi-tenant
 * NUNCA confiar em parâmetros do body para tenant_id.
 * Usa: Authorization (Basic/Bearer), header X-Tenant-ID, ou sessão.
 */

import { NextRequest } from 'next/server';
import { headers } from 'next/headers';

export async function getTenantIdFromRequest(request: NextRequest): Promise<string | null> {
  // 1. Header X-Tenant-ID (usado pelo app mobile com API key)
  const headersList = await headers();
  const xTenantId = headersList.get('x-tenant-id');
  if (xTenantId) {
    return xTenantId;
  }

  // 2. Basic Auth — username pode ser tenant_slug:username ou usar API key
  const authHeader = request.headers.get('authorization');
  if (authHeader?.startsWith('Basic ')) {
    const base64 = authHeader.slice(6);
    try {
      const decoded = Buffer.from(base64, 'base64').toString('utf-8');
      const [username, password] = decoded.split(':');
      // Formato: tenant_slug:username ou api_key como username
      if (username?.includes(':')) {
        const [tenantSlug] = username.split(':');
        return tenantSlug; // Retornar slug - API deve resolver para ID
      }
    } catch {
      // ignore
    }
  }

  // 3. Bearer token — JWT ou API key
  if (authHeader?.startsWith('Bearer ')) {
    const token = authHeader.slice(7);
    // API key = tenant's api_key no banco
    // TODO: validar contra Prisma Tenant
    return token;
  }

  // 4. Cookie/sessão (para dashboard web)
  // TODO: integrar com NextAuth ou sessão
  const sessionTenant = headersList.get('x-session-tenant-id');
  if (sessionTenant) {
    return sessionTenant;
  }

  return null;
}

/**
 * Resolve tenant_id a partir de slug ou api_key
 * Retorna o ID UUID do tenant para queries Prisma
 */
export type TenantResolution = { id: string; slug: string } | null;
