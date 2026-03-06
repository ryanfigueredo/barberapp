-- CreateTable
CREATE TABLE "TenantWhatsApp" (
    "id" TEXT NOT NULL,
    "tenant_id" TEXT NOT NULL,
    "barber_id" TEXT,
    "whatsapp_phone" TEXT,
    "meta_phone_number_id" TEXT NOT NULL,
    "meta_access_token" TEXT NOT NULL,
    "meta_business_account_id" TEXT,
    "bot_configured" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "TenantWhatsApp_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "TenantWhatsApp_meta_phone_number_id_key" ON "TenantWhatsApp"("meta_phone_number_id");

-- CreateIndex
CREATE INDEX "TenantWhatsApp_tenant_id_idx" ON "TenantWhatsApp"("tenant_id");

-- CreateIndex
CREATE INDEX "TenantWhatsApp_meta_phone_number_id_idx" ON "TenantWhatsApp"("meta_phone_number_id");

-- CreateIndex: one general (barber_id null) per tenant
CREATE UNIQUE INDEX "TenantWhatsApp_tenant_id_general_key" ON "TenantWhatsApp"("tenant_id") WHERE "barber_id" IS NULL;

-- CreateIndex: one connection per barber per tenant
CREATE UNIQUE INDEX "TenantWhatsApp_tenant_id_barber_id_key" ON "TenantWhatsApp"("tenant_id", "barber_id") WHERE "barber_id" IS NOT NULL;

-- AddForeignKey
ALTER TABLE "TenantWhatsApp" ADD CONSTRAINT "TenantWhatsApp_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "Tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TenantWhatsApp" ADD CONSTRAINT "TenantWhatsApp_barber_id_fkey" FOREIGN KEY ("barber_id") REFERENCES "Barber"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- Backfill: one TenantWhatsApp per Tenant that has meta_phone_number_id set (barber_id = null)
INSERT INTO "TenantWhatsApp" (
  "id",
  "tenant_id",
  "barber_id",
  "whatsapp_phone",
  "meta_phone_number_id",
  "meta_access_token",
  "meta_business_account_id",
  "bot_configured",
  "created_at",
  "updated_at"
)
SELECT
  gen_random_uuid(),
  "id",
  NULL,
  "whatsapp_phone",
  "meta_phone_number_id",
  COALESCE("meta_access_token", ''),
  "meta_business_account_id",
  COALESCE("bot_configured", false),
  NOW(),
  NOW()
FROM "Tenant"
WHERE "meta_phone_number_id" IS NOT NULL AND "meta_phone_number_id" != '';
