/**
 * Auth helpers — resolve tenant a partir de headers
 * NUNCA usar tenant_id do body — sempre de getTenantFromRequest
 */

import { NextRequest } from 'next/server';
import { prisma } from '@/lib/prisma';

export interface TenantContext {
  id: string;
  slug: string;
  name: string;
}

/** Contexto completo do usuário logado (web session ou API key) */
export interface AuthContext {
  tenant: TenantContext | null;
  barberId: string | null; // quando role = barber
  role: string;
  userId?: string;
}

/**
 * Resolve tenant a partir de:
 * - Cookie de sessão (dashboard web após login)
 * - X-API-Key header (api_key do Tenant)
 * - Authorization: Basic base64(api_key:senha)
 * - X-Tenant-ID header (tenant id UUID)
 */
export async function getTenantFromRequest(request: NextRequest): Promise<TenantContext | null> {
  const auth = await getAuthFromRequest(request);
  return auth.tenant;
}

/**
 * Retorna tenant + barberId + role para filtrar por barbeiro quando necessário.
 * Se o usuário é barber (role barber com barber_id), barberId vem preenchido.
 */
export async function getAuthFromRequest(request: NextRequest): Promise<AuthContext> {
  const defaultAuth: AuthContext = { tenant: null, barberId: null, role: '' };

  // 1. Sessão web (cookie setado no login)
  const sessionCookie = request.cookies.get('session')?.value;
  if (sessionCookie) {
    try {
      const decoded = Buffer.from(sessionCookie, 'base64').toString('utf-8');
      const session = JSON.parse(decoded) as { tenantId?: string; barberId?: string; role?: string };
      if (session.tenantId) {
        const tenant = await prisma.tenant.findUnique({
          where: { id: session.tenantId, plan_active: true },
          select: { id: true, slug: true, name: true },
        });
        if (tenant) {
          return {
            tenant,
            barberId: session.barberId ?? null,
            role: session.role ?? 'admin',
            userId: (session as { userId?: string }).userId,
          };
        }
      }
    } catch {
      // ignore
    }
  }

  const apiKey = request.headers.get('x-api-key');
  if (apiKey) {
    const tenant = await prisma.tenant.findUnique({
      where: { api_key: apiKey, plan_active: true },
      select: { id: true, slug: true, name: true },
    });
    if (tenant) return { ...defaultAuth, tenant, role: 'api' };
  }

  const tenantId = request.headers.get('x-tenant-id');
  if (tenantId) {
    const tenant = await prisma.tenant.findUnique({
      where: { id: tenantId, plan_active: true },
      select: { id: true, slug: true, name: true },
    });
    if (tenant) return { ...defaultAuth, tenant, role: 'api' };
  }

  const authHeader = request.headers.get('authorization');
  if (authHeader?.startsWith('Basic ')) {
    try {
      const base64 = authHeader.slice(6);
      const decoded = Buffer.from(base64, 'base64').toString('utf-8');
      const [apiKeyOrUser] = decoded.split(':');
      const tenant = await prisma.tenant.findUnique({
        where: { api_key: apiKeyOrUser, plan_active: true },
        select: { id: true, slug: true, name: true },
      });
      if (tenant) return { ...defaultAuth, tenant, role: 'api' };
    } catch {
      // ignore
    }
  }

  if (authHeader?.startsWith('Bearer ')) {
    const token = authHeader.slice(7);
    const tenant = await prisma.tenant.findUnique({
      where: { api_key: token, plan_active: true },
      select: { id: true, slug: true, name: true },
    });
    if (tenant) return { ...defaultAuth, tenant, role: 'api' };
  }

  return defaultAuth;
}

export function requireTenant<T>(tenant: TenantContext | null): tenant is TenantContext {
  return tenant !== null;
}
