/**
 * GET /api/app/barbers — lista barbeiros ativos do tenant
 */

import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';
import { getTenantFromRequest } from '@/lib/auth';

export async function GET(request: NextRequest) {
  const tenant = await getTenantFromRequest(request);
  if (!tenant) {
    return NextResponse.json({ error: 'Não autorizado' }, { status: 401 });
  }

  const barbers = await prisma.barber.findMany({
    where: { tenant_id: tenant.id, active: true },
    select: {
      id: true,
      name: true,
      phone: true,
      avatar_url: true,
    },
    orderBy: { name: 'asc' },
  });

  return NextResponse.json(barbers);
}
