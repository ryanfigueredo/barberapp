/**
 * Login mobile (app iOS) — email/usuário + senha
 * Retorna api_key do tenant + user (barber_id, role) para o app enviar nas requisições.
 * Cada barbeiro entra com seu login; admin vê tudo, barber vê só o seu.
 */

import { NextRequest, NextResponse } from 'next/server';
import bcrypt from 'bcryptjs';
import { prisma } from '@/lib/prisma';

export async function POST(request: NextRequest) {
  try {
    const body = await request.json().catch(() => ({}));
    const username = (body.username ?? body.email ?? '').toString().trim();
    const password = body.password;

    if (!username || !password) {
      return NextResponse.json(
        { error: 'Usuário/email e senha obrigatórios' },
        { status: 400 }
      );
    }

    const user = await prisma.user.findUnique({
      where: { username },
      include: { tenant: true, barber: true },
    });

    if (!user || !user.tenant_id) {
      return NextResponse.json({ error: 'Credenciais inválidas' }, { status: 401 });
    }

    const valid = await bcrypt.compare(password, user.password);
    if (!valid) {
      return NextResponse.json({ error: 'Credenciais inválidas' }, { status: 401 });
    }

    const tenant = user.tenant!;

    return NextResponse.json({
      success: true,
      api_key: tenant.api_key,
      tenant: {
        id: tenant.id,
        name: tenant.name,
        slug: tenant.slug,
      },
      user: {
        id: user.id,
        username: user.username,
        name: user.name,
        role: user.role,
        barber_id: user.barber_id ?? null,
        barber: user.barber ? { id: user.barber.id, name: user.barber.name } : null,
      },
    });
  } catch (error) {
    console.error('[MobileLogin]', error);
    return NextResponse.json({ error: 'Erro interno' }, { status: 500 });
  }
}
