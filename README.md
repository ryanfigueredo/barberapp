# BarberApp — Sistema de Agendamento para Barbearias

Sistema standalone de agendamento via WhatsApp Bot (Meta Cloud API), app iOS nativo e dashboard web Next.js 14. Multi-tenant — cada barbearia = 1 tenant.

## Stack

- **Backend:** Next.js 14 App Router + TypeScript
- **DB:** PostgreSQL via Prisma ORM
- **Auth:** Sessão (web) + Basic Auth (mobile)
- **WhatsApp:** Meta Cloud API (webhooks + Cloud API handler)
- **Storage:** AWS S3 (logos/assets)
- **NoSQL:** DynamoDB (histórico de conversas WhatsApp, sessões do bot)
- **Mobile:** Swift + UIKit (iOS)

## Setup

### 1. Instalar dependências

```bash
cd barber && npm install
```

### 2. Configurar .env

```bash
cp .env.example .env
# Preencher: DATABASE_URL, AWS_*, META_*, NEXTAUTH_SECRET
```

### 3. Gerar Prisma + migrar

```bash
npx prisma generate
npx prisma migrate dev --name init_barberapp
```

### 4. Seed inicial

```bash
npx prisma db seed
```

Cria: 1 tenant demo, 1 admin (admin@barbearia-demo.com / admin123), 2 barbeiros, 5 serviços, slots da semana.

### 5. Rodar

```bash
npm run dev
```

Acesse: [http://localhost:3000](http://localhost:3000)

- **Dashboard:** `/dashboard/login` — login com admin@barbearia-demo.com / admin123  
- **Webhook WhatsApp:** `/api/bot/webhook` — configurar no Meta Developers

## APIs

### App (mobile) — Headers: `X-API-Key` ou `Authorization: Bearer <api_key>`

| Método | Endpoint | Descrição |
|--------|----------|-----------|
| GET | /api/app/appointments?date=YYYY-MM-DD | Agendamentos do dia |
| GET | /api/app/appointments?upcoming=true | Próximos 7 dias |
| GET | /api/app/appointments/month?month=YYYY-MM | Dias com agendamentos (dots calendário) |
| POST | /api/app/appointments | Criar agendamento |
| GET | /api/app/appointments/[id] | Detalhe |
| PATCH | /api/app/appointments/[id]/status | Alterar status |
| DELETE | /api/app/appointments/[id] | Cancelar |
| GET | /api/app/barbers | Lista barbeiros |
| GET | /api/app/slots/available?date=YYYY-MM-DD&barber_id= | Slots disponíveis |

### Admin (dashboard)

| Método | Endpoint | Descrição |
|--------|----------|-----------|
| GET | /api/admin/stats | Estatísticas |
| GET/POST | /api/admin/barbers | CRUD barbeiros |
| GET/POST | /api/admin/services | CRUD serviços |
| GET/POST | /api/admin/slots | Slots |
| POST | /api/admin/slots/generate | Gerar slots em massa |
| GET/PATCH | /api/admin/tenant-profile | Perfil da barbearia |

### Bot

| Método | Endpoint | Descrição |
|--------|----------|-----------|
| GET | /api/bot/webhook | Verificação Meta |
| POST | /api/bot/webhook | Eventos WhatsApp |

## App iOS

Os arquivos Swift estão em `ios/BarberApp/`:

- `Models/Appointment.swift` — modelos Appointment, BarberInfo, ServiceInfo
- `ViewControllers/CalendarViewController.swift` — calendário com UICollectionView, dots por dia, filtro por barbeiro

Configure `baseURL` e `apiKey` no `CalendarViewController` ou via injeção de dependência. Use `X-API-Key` nas requisições.

### CocoaPods (opcional — FSCalendar)

Se quiser usar FSCalendar em vez do grid nativo:

```ruby
# Podfile
pod 'FSCalendar'
```

## GSD Workflow

```bash
npx get-shit-done-cc@latest
/gsd:map-codebase
/gsd:new-project
# Responder: "App de agendamento para barbearia via WhatsApp + iOS + dashboard web"
/gsd:discuss-phase 1
/gsd:plan-phase 1
/gsd:execute-phase 1
/gsd:verify-work 1
# ... repetir para cada fase
```

## Pontos críticos

- **Multi-tenant:** `getTenantFromRequest` em toda rota — nunca confiar em tenant_id do body.
- **Calendário iOS:** Usar `GET /api/app/appointments/month` para carregar dots de uma vez.
- **Timezone:** DateTime em UTC no banco; exibir em America/Sao_Paulo no app/dashboard.
- **Slots:** Usar transação Prisma ao reservar para evitar double-booking.
- **Bot:** Sessão expira em 30min; armazenar em DynamoDB.
