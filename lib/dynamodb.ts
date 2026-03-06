/**
 * DynamoDB client para sessões do bot e histórico de mensagens WhatsApp
 * Estrutura igual ao Pedidos Express
 */

import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import {
  DynamoDBDocumentClient,
  GetCommand,
  PutCommand,
  DeleteCommand,
  UpdateCommand,
} from '@aws-sdk/lib-dynamodb';

const client = new DynamoDBClient({
  region: process.env.AWS_REGION || 'us-east-1',
});

const docClient = DynamoDBDocumentClient.from(client);

const BOT_SESSIONS_TABLE = process.env.DYNAMODB_TABLE_BOT_SESSIONS || 'barberapp-bot-sessions';
const SESSION_TTL_SECONDS = 30 * 60; // 30 minutos

export interface BotSessionRecord {
  pk: string; // bot_session:{tenant_id}:{phone}
  sk: string; // "session"
  tenant_id: string;
  phone: string;
  state: string;
  data: Record<string, unknown>;
  expires_at: number; // Unix timestamp para TTL
  updated_at: number;
}

export async function getBotSession(tenantId: string, phone: string): Promise<BotSessionRecord | null> {
  const pk = `bot_session:${tenantId}:${phone}`;
  const result = await docClient.send(
    new GetCommand({
      TableName: BOT_SESSIONS_TABLE,
      Key: {
        pk,
        sk: 'session',
      },
    })
  );

  const item = result.Item as BotSessionRecord | undefined;
  if (!item || item.expires_at < Math.floor(Date.now() / 1000)) {
    return null;
  }
  return item;
}

export async function putBotSession(
  tenantId: string,
  phone: string,
  state: string,
  data: Record<string, unknown>
): Promise<void> {
  const pk = `bot_session:${tenantId}:${phone}`;
  const now = Math.floor(Date.now() / 1000);
  const expires_at = now + SESSION_TTL_SECONDS;

  // Remove undefined values — DynamoDB não aceita undefined
  const cleanData = Object.fromEntries(
    Object.entries(data).filter(([, v]) => v !== undefined)
  );

  await docClient.send(
    new PutCommand({
      TableName: BOT_SESSIONS_TABLE,
      Item: {
        pk,
        sk: 'session',
        tenant_id: tenantId,
        phone,
        state,
        data: cleanData,
        expires_at,
        updated_at: now,
        ttl: expires_at, // DynamoDB TTL attribute
      },
    })
  );
}

export async function deleteBotSession(tenantId: string, phone: string): Promise<void> {
  const pk = `bot_session:${tenantId}:${phone}`;
  await docClient.send(
    new DeleteCommand({
      TableName: BOT_SESSIONS_TABLE,
      Key: {
        pk,
        sk: 'session',
      },
    })
  );
}

export async function updateBotSessionState(
  tenantId: string,
  phone: string,
  state: string,
  data: Partial<Record<string, unknown>>
): Promise<void> {
  const existing = await getBotSession(tenantId, phone);
  const mergedData = { ...(existing?.data ?? {}), ...data };
  await putBotSession(tenantId, phone, state, mergedData);
}
