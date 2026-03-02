/**
 * POST /api/admin/upload/logo
 * Retorna URL pré-assinada (S3) para upload da logo da barbearia.
 * Body: { "contentType": "image/jpeg" } (opcional)
 * Response: { "uploadUrl": "...", "publicUrl": "..." }
 * O app faz PUT da imagem em uploadUrl e depois PATCH tenant-profile com logo_url = publicUrl.
 */

import { NextRequest, NextResponse } from 'next/server';
import { getTenantFromRequest } from '@/lib/auth';
import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';

const region = process.env.AWS_REGION || 'us-east-1';
const bucket = process.env.AWS_S3_BUCKET;

function getS3Client(): S3Client | null {
  if (!process.env.AWS_ACCESS_KEY_ID || !process.env.AWS_SECRET_ACCESS_KEY || !bucket) {
    return null;
  }
  return new S3Client({
    region,
    credentials: {
      accessKeyId: process.env.AWS_ACCESS_KEY_ID,
      secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
    },
  });
}

export async function POST(request: NextRequest) {
  const tenant = await getTenantFromRequest(request);
  if (!tenant) {
    return NextResponse.json({ error: 'Não autorizado' }, { status: 401 });
  }

  const client = getS3Client();
  if (!client) {
    return NextResponse.json(
      { error: 'Upload não configurado. Defina AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY e AWS_S3_BUCKET.' },
      { status: 503 }
    );
  }

  try {
    const body = await request.json().catch(() => ({}));
    const contentType = (body.contentType as string) || 'image/jpeg';
    const ext = contentType.includes('png') ? 'png' : 'jpg';
    const key = `logos/${tenant.id}/${crypto.randomUUID()}.${ext}`;

    const command = new PutObjectCommand({
      Bucket: bucket,
      Key: key,
      ContentType: contentType,
    });

    const uploadUrl = await getSignedUrl(client, command, { expiresIn: 300 });

    // URL pública: bucket na região padrão (configurar bucket policy para leitura pública em logos/*)
    const publicUrl = `https://${bucket}.s3.${region}.amazonaws.com/${key}`;

    return NextResponse.json({ uploadUrl, publicUrl });
  } catch (error) {
    console.error('[POST upload/logo]', error);
    return NextResponse.json({ error: 'Erro ao gerar URL de upload' }, { status: 500 });
  }
}
