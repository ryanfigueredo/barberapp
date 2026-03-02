/**
 * Mobile login — Basic Auth com api_key do tenant
 * Header: Authorization: Basic base64(api_key:password)
 * Ou: X-API-Key + X-Password (para facilitar)
 */

import { NextRequest, NextResponse } from 'next/server';
import bcrypt from 'bcryptjs';
import { prisma } from '@/lib/prisma';

export async function POST(request: NextRequest) {
  try {
    let apiKey: string | null = null;
    let password: string | null = null;

    const authHeader = request.headers.get('authorization');
    if (authHeader?.startsWith('Basic ')) {
      const base64 = authHeader.slice(6);
      const decoded = Buffer.from(base64, 'base64').toString('utf-8');
      [apiKey, password] = decoded.split(':');
    } else {
      apiKey = request.headers.get('x-api-key');
      password = request.headers.get('x-password');
    }

    const body = await request.json().catch(() => ({}));
    apiKey = apiKey || body.api_key;
    password = password || body.password;

    if (!apiKey || !password) {
      return NextResponse.json(
        { error: 'API Key e senha obrigatórios (header ou body)' },
        { status: 400 }
      );
    }

    const tenant = await prisma.tenant.findUnique({
      where: { api_key: apiKey, plan_active: true },
      include: { users: true },
    });

    if (!tenant) {
      return NextResponse.json({ error: 'API Key inválida' }, { status: 401 });
    }

    const user = tenant.users.find((u) => bcrypt.compareSync(password!, u.password));
    if (!user) {
      return NextResponse.json({ error: 'Senha inválida' }, { status: 401 });
    }

    return NextResponse.json({
      success: true,
      token: tenant.api_key,
      tenant: {
        id: tenant.id,
        name: tenant.name,
        slug: tenant.slug,
        business_name: tenant.business_name,
      },
      user: {
        id: user.id,
        name: user.name,
        role: user.role,
      },
    });
  } catch (error) {
    console.error('[MobileLogin]', error);
    return NextResponse.json({ error: 'Erro interno' }, { status: 500 });
  }
}
