-- CreateTable
CREATE TABLE "WhatsAppAttendantRequest" (
    "id" TEXT NOT NULL,
    "tenant_id" TEXT NOT NULL,
    "customer_phone" TEXT NOT NULL,
    "customer_name" TEXT,
    "requested_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "resolved_at" TIMESTAMP(3),

    CONSTRAINT "WhatsAppAttendantRequest_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "WhatsAppAttendantRequest_tenant_id_idx" ON "WhatsAppAttendantRequest"("tenant_id");

-- CreateIndex
CREATE INDEX "WhatsAppAttendantRequest_tenant_id_resolved_at_idx" ON "WhatsAppAttendantRequest"("tenant_id", "resolved_at");

-- AddForeignKey
ALTER TABLE "WhatsAppAttendantRequest" ADD CONSTRAINT "WhatsAppAttendantRequest_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "Tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;
