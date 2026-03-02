import { NextRequest, NextResponse } from 'next/server';
import bcrypt from 'bcryptjs';
import { prisma } from '@/lib/prisma';
import { cookies } from 'next/headers';

export async function POST(request: NextRequest) {
  try {
    const { username, password } = await request.json();
    if (!username || !password) {
      return NextResponse.json({ error: 'Usuário e senha obrigatórios' }, { status: 400 });
    }

    const user = await prisma.user.findUnique({
      where: { username },
      include: { tenant: true, barber: true },
    });

    if (!user || !(await bcrypt.compare(password, user.password))) {
      return NextResponse.json({ error: 'Credenciais inválidas' }, { status: 401 });
    }

    // Sessão: tenant + barber_id quando for login de barbeiro
    const session = Buffer.from(
      JSON.stringify({
        userId: user.id,
        username: user.username,
        tenantId: user.tenant_id,
        role: user.role,
        barberId: user.barber_id ?? undefined,
      })
    ).toString('base64');

    (await cookies()).set('session', session, {
      httpOnly: true,
      secure: process.env.NODE_ENV === 'production',
      sameSite: 'lax',
      maxAge: 60 * 60 * 24 * 7,
      path: '/',
    });

    return NextResponse.json({
      success: true,
      user: {
        id: user.id,
        username: user.username,
        name: user.name,
        role: user.role,
        tenant_id: user.tenant_id,
        barber_id: user.barber_id ?? null,
        tenant: user.tenant ? { id: user.tenant.id, name: user.tenant.name, slug: user.tenant.slug } : null,
        barber: user.barber ? { id: user.barber.id, name: user.barber.name } : null,
      },
      api_key: user.tenant?.api_key ?? null,
    });
  } catch (error) {
    console.error('[Login]', error);
    return NextResponse.json({ error: 'Erro interno' }, { status: 500 });
  }
}
