-- AlterTable
ALTER TABLE "User" ADD COLUMN "barber_id" TEXT;

-- CreateUniqueIndex
CREATE UNIQUE INDEX "User_barber_id_key" ON "User"("barber_id");

-- AddForeignKey
ALTER TABLE "User" ADD CONSTRAINT "User_barber_id_fkey" FOREIGN KEY ("barber_id") REFERENCES "Barber"("id") ON DELETE SET NULL ON UPDATE CASCADE;
