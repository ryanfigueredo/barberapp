-- CreateTable
CREATE TABLE "WhatsAppContactName" (
    "id" TEXT NOT NULL,
    "tenant_id" TEXT NOT NULL,
    "customer_phone" TEXT NOT NULL,
    "display_name" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "WhatsAppContactName_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "WhatsAppContactName_tenant_id_customer_phone_key" ON "WhatsAppContactName"("tenant_id", "customer_phone");

-- CreateIndex
CREATE INDEX "WhatsAppContactName_tenant_id_idx" ON "WhatsAppContactName"("tenant_id");

-- AddForeignKey
ALTER TABLE "WhatsAppContactName" ADD CONSTRAINT "WhatsAppContactName_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "Tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;
