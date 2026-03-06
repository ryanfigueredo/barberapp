

import { NextRequest } from 'next/server';
import { GET as botGet, POST as botPost } from '@/app/api/bot/webhook/route';

export async function GET(request: NextRequest) {
  return botGet(request);
}

export async function POST(request: NextRequest) {
  return botPost(request);
}
