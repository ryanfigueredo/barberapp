import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function main() {
  // Criar tenant demo
  const tenant = await prisma.tenant.upsert({
    where: { slug: 'barbearia-demo' },
    update: {},
    create: {
      name: 'Barbearia Demo',
      slug: 'barbearia-demo',
      business_name: 'Barbearia Premium Demo',
      address: 'Rua das Flores, 123',
      opening_time: '09:00',
      closing_time: '20:00',
      slot_duration_minutes: 60,
      plan_type: 'free',
      plan_active: true,
    },
  });

  // Criar usuário admin
  const hashedPassword = await bcrypt.hash('admin123', 10);
  await prisma.user.deleteMany({ where: { username: 'admin@barbearia-demo.com' } }).catch(() => {});
  await prisma.user.upsert({
    where: { username: 'ryan@dmtn.com.br' },
    update: {},
    create: {
      username: 'ryan@dmtn.com.br',
      password: hashedPassword,
      name: 'Admin Demo',
      role: 'owner',
      tenant_id: tenant.id,
    },
  });

  // Criar barbeiros
  const barber1 = await prisma.barber.upsert({
    where: { id: '00000000-0000-0000-0000-000000000001' },
    update: {},
    create: {
      id: '00000000-0000-0000-0000-000000000001',
      tenant_id: tenant.id,
      name: 'João Silva',
      phone: '+5511999990001',
      active: true,
    },
  });

  const barber2 = await prisma.barber.upsert({
    where: { id: '00000000-0000-0000-0000-000000000002' },
    update: {},
    create: {
      id: '00000000-0000-0000-0000-000000000002',
      tenant_id: tenant.id,
      name: 'Pedro Santos',
      phone: '+5511999990002',
      active: true,
    },
  });

  // Login do barbeiro João (cada barbeiro pode ter seu usuário e ver só sua agenda)
  const barberPassword = await bcrypt.hash('barber123', 10);
  await prisma.user.upsert({
    where: { username: 'joao@barbearia-demo.com' },
    update: { barber_id: barber1.id, role: 'barber' },
    create: {
      username: 'joao@barbearia-demo.com',
      password: barberPassword,
      name: 'João Silva',
      role: 'barber',
      tenant_id: tenant.id,
      barber_id: barber1.id,
    },
  });

  // Criar serviços (apenas se não existirem)
  const existingServices = await prisma.service.count({ where: { tenant_id: tenant.id } });
  if (existingServices === 0) {
    const services = [
      { name: 'Corte', price: 35, duration_minutes: 45 },
      { name: 'Barba', price: 25, duration_minutes: 30 },
      { name: 'Corte + Barba', price: 55, duration_minutes: 60 },
      { name: 'Degradê', price: 40, duration_minutes: 50 },
      { name: 'Sobrancelha', price: 15, duration_minutes: 15 },
    ];
    await prisma.service.createMany({
      data: services.map((s) => ({
        tenant_id: tenant.id,
        name: s.name,
        price: s.price,
        duration_minutes: s.duration_minutes,
        active: true,
      })),
    });
  }

  // Gerar slots para a próxima semana (demo) - apenas se não existirem
  const existingSlots = await prisma.slot.count({ where: { tenant_id: tenant.id } });
  if (existingSlots === 0) {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    for (let day = 0; day < 7; day++) {
      const date = new Date(today);
      date.setDate(date.getDate() + day);
      const dayOfWeek = date.getDay(); // 0=dom, 6=sab
      if (dayOfWeek === 0) continue; // Pular domingo
      for (const barber of [barber1, barber2]) {
        let hour = 9;
        while (hour < 20) {
          const startTime = new Date(date);
          startTime.setHours(hour, 0, 0, 0);
          const endTime = new Date(date);
          endTime.setHours(hour + 1, 0, 0, 0);
          if (hour === 12) {
            hour++;
            continue;
          }
          await prisma.slot.create({
            data: {
              tenant_id: tenant.id,
              barber_id: barber.id,
              start_time: startTime,
              end_time: endTime,
              status: 'available',
            },
          });
          hour++;
        }
      }
    }
  } else {
    console.log('Slots já existem, pulando criação');
  }

  // Criar agendamentos demo (apenas se não existirem)
  const existingAppts = await prisma.appointment.count({ where: { tenant_id: tenant.id } });
  if (existingAppts === 0) {
    const services = await prisma.service.findMany({ where: { tenant_id: tenant.id }, take: 3 });
    const availableSlots = await prisma.slot.findMany({
      where: { tenant_id: tenant.id, status: 'available' },
      take: 6,
      orderBy: { start_time: 'asc' },
    });
    const names = ['Carlos Souza', 'Miguel Costa', 'Rafael Lima', 'Lucas Oliveira', 'Gabriel Santos', 'Bruno Alves'];
    for (let i = 0; i < Math.min(5, availableSlots.length); i++) {
      const slot = availableSlots[i];
      const appt = await prisma.appointment.create({
        data: {
          tenant_id: tenant.id,
          barber_id: slot.barber_id,
          service_id: services[i % services.length]?.id ?? null,
          slot_id: slot.id,
          customer_name: names[i],
          customer_phone: '551199999900' + (i + 1),
          appointment_date: slot.start_time,
          status: i < 3 ? 'confirmed' : 'pending',
          confirmed: i < 3,
          origin: i % 2 === 0 ? 'whatsapp' : 'app',
        },
      });
      await prisma.slot.update({
        where: { id: slot.id },
        data: { status: 'booked', appointment_id: appt.id },
      });
    }
    console.log('Criados 5 agendamentos demo');
  }

  console.log('✅ Seed concluído: 1 tenant, 1 admin, 2 barbeiros, 5 serviços, slots, agendamentos');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
