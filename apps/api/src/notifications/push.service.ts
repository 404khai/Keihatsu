import { Injectable, Logger, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { GoogleAuth } from 'google-auth-library';
import { connect } from 'http2';
import { readFileSync } from 'fs';
import { Notification, PushDevice } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

export type PushResult = 'sent' | 'invalid' | 'retry' | 'skipped';
export interface PushProvider {
  send(device: PushDevice, payload: Record<string, unknown>): Promise<PushResult>;
}

@Injectable()
export class NoopPushProvider implements PushProvider {
  async send(): Promise<PushResult> { return 'skipped'; }
}

@Injectable()
export class ApnsPushProvider implements PushProvider {
  constructor(private config: ConfigService) {}

  async send(device: PushDevice, payload: Record<string, unknown>): Promise<PushResult> {
    const keyPath = this.config.get<string>('APNS_PRIVATE_KEY_PATH');
    const keyId = this.config.get<string>('APNS_KEY_ID');
    const teamId = this.config.get<string>('APNS_TEAM_ID');
    const topic = this.config.get<string>('APNS_BUNDLE_ID');
    if (!keyPath || !keyId || !teamId || !topic) return 'retry';
    // APNs provider tokens are short lived; generate a fresh one per batch/send.
    const crypto = await import('crypto');
    const header = Buffer.from(JSON.stringify({ alg: 'ES256', kid: keyId })).toString('base64url');
    const claims = Buffer.from(JSON.stringify({ iss: teamId, iat: Math.floor(Date.now() / 1000) })).toString('base64url');
    const unsigned = `${header}.${claims}`;
    const signature = crypto.sign('sha256', Buffer.from(unsigned), {
      key: readFileSync(keyPath), dsaEncoding: 'ieee-p1363',
    }).toString('base64url');
    const host = this.config.get('APNS_ENV') === 'production'
      ? 'https://api.push.apple.com' : 'https://api.sandbox.push.apple.com';
    const client = connect(host);
    try {
      const body = JSON.stringify({
        aps: { alert: { title: payload.title, body: payload.body }, sound: 'default',
          'thread-id': payload.groupingKey, 'mutable-content': 0 },
        notificationId: payload.notificationId, type: payload.type,
        deepLink: payload.deepLink, groupingKey: payload.groupingKey,
        sourceId: payload.sourceId, mangaId: payload.mangaId,
        chapterId: payload.chapterId, commentId: payload.commentId, threadId: payload.threadId,
      });
      if (Buffer.byteLength(body) > 4096) return 'retry';
      return await new Promise<PushResult>((resolve) => {
        const request = client.request({
          ':method': 'POST', ':path': `/3/device/${device.token}`,
          authorization: `bearer ${unsigned}.${signature}`, 'apns-topic': topic,
          'apns-push-type': 'alert', 'apns-collapse-id': String(payload.groupingKey || payload.notificationId).slice(0, 64),
          'content-type': 'application/json',
        });
        let status = 500;
        request.on('response', (headers) => { status = Number(headers[':status']); });
        request.on('error', () => resolve('retry'));
        request.on('end', () => resolve(status === 200 ? 'sent' : [400, 404, 410].includes(status) ? 'invalid' : 'retry'));
        request.end(body);
      });
    } finally { client.close(); }
  }
}

@Injectable()
export class FcmPushProvider implements PushProvider {
  private readonly auth = new GoogleAuth({ scopes: ['https://www.googleapis.com/auth/firebase.messaging'] });
  constructor(private config: ConfigService) {}
  async send(device: PushDevice, payload: Record<string, unknown>): Promise<PushResult> {
    const project = this.config.get<string>('FCM_PROJECT_ID');
    if (!project) return 'retry';
    try {
      const client = await this.auth.getClient();
      const token = await client.getAccessToken();
      const data = Object.fromEntries(Object.entries(payload)
        .filter(([, value]) => value != null)
        .map(([key, value]) => [key, String(value)]));
      const response = await fetch(`https://fcm.googleapis.com/v1/projects/${encodeURIComponent(project)}/messages:send`, {
        method: 'POST', headers: { authorization: `Bearer ${token.token}`, 'content-type': 'application/json' },
        body: JSON.stringify({ message: { token: device.token,
          notification: { title: payload.title, body: payload.body }, data,
          android: { collapse_key: String(payload.groupingKey || payload.notificationId),
            // Visible pushes should reach the phone promptly, including during Doze.
            // Channel importance still controls how prominently Android presents them.
            priority: 'HIGH',
            notification: { channel_id: payload.type === 'CHAPTER_UPDATE' ? 'library_updates' :
              String(payload.type).startsWith('COMMENT_') ? 'comments_social' : 'system_announcements',
              icon: 'ic_notification', sound: 'default',
              tag: String(payload.groupingKey || payload.notificationId) } } } }),
      });
      if (response.ok) return 'sent';
      const error = await response.json() as { error?: { details?: Array<{ errorCode?: string }> } };
      const code = error.error?.details?.[0]?.errorCode;
      return response.status === 404 || code === 'UNREGISTERED' || code === 'INVALID_ARGUMENT' ? 'invalid' : 'retry';
    } catch { return 'retry'; }
  }
}

@Injectable()
export class PushService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(PushService.name);
  private timer?: NodeJS.Timeout;
  constructor(private prisma: PrismaService, private config: ConfigService,
    private apns: ApnsPushProvider, private fcm: FcmPushProvider,
    private noop: NoopPushProvider) {}

  onModuleInit() {
    const mode = this.config.get('PUSH_PROVIDER') || 'noop';
    this.logger.log(`Push provider mode=${mode}`);
    this.timer = setInterval(() => void this.processPending(), 15000);
  }
  onModuleDestroy() { if (this.timer) clearInterval(this.timer); }

  async deliver(notification: Notification, pushEnabled: boolean): Promise<void> {
    if (!pushEnabled) return;
    const devices = await this.prisma.pushDevice.findMany({ where: { userId: notification.userId, enabled: true, invalidatedAt: null } });
    await this.prisma.pushDelivery.createMany({ data: devices.map((device) => ({
      notificationId: notification.id, deviceId: device.id,
    })), skipDuplicates: true });
    await this.processPending();
  }

  async processPending(): Promise<void> {
    const deliveries = await this.prisma.pushDelivery.findMany({
      where: { status: { in: ['PENDING', 'PROCESSING'] }, nextAttemptAt: { lte: new Date() } },
      include: { device: true }, take: 100,
    });
    for (const delivery of deliveries) {
      const claimed = await this.prisma.pushDelivery.updateMany({
        where: { id: delivery.id, status: delivery.status, nextAttemptAt: { lte: new Date() } },
        data: { status: 'PROCESSING', nextAttemptAt: new Date(Date.now() + 120000) },
      });
      if (!claimed.count) continue;
      const notification = await this.prisma.notification.findUnique({ where: { id: delivery.notificationId } });
      if (!notification || !delivery.device.enabled) {
        await this.prisma.pushDelivery.update({ where: { id: delivery.id }, data: { status: 'CANCELLED' } });
        continue;
      }
      await this.sendOne(delivery.id, delivery.attempts, delivery.device, notification);
    }
  }

  private async sendOne(deliveryId: string, attempts: number, device: PushDevice, notification: Notification) {
    const payload = {
      notificationId: notification.id, type: notification.type, deepLink: notification.deepLink,
      groupingKey: notification.groupingKey || notification.id,
      sourceId: notification.sourceId, mangaId: notification.mangaId,
      chapterId: notification.chapterId, commentId: notification.commentId, threadId: notification.threadId,
      title: notification.title.slice(0, 120), body: notification.body.slice(0, 200),
    };
      const provider = this.config.get('PUSH_PROVIDER') === 'noop' || !this.config.get('PUSH_PROVIDER')
        ? this.noop : device.platform === 'IOS' ? this.apns : this.fcm;
      const result = await provider.send(device, payload);
      if (result === 'invalid') await this.prisma.pushDevice.update({ where: { id: device.id }, data: { enabled: false, invalidatedAt: new Date() } });
      await this.prisma.pushDelivery.update({ where: { id: deliveryId }, data: {
        attempts: attempts + 1, status: result === 'sent' ? 'SENT' : result === 'skipped' ? 'SKIPPED' : result === 'invalid' || attempts >= 7 ? 'FAILED' : 'PENDING',
        deliveredAt: result === 'sent' ? new Date() : null,
        nextAttemptAt: new Date(Date.now() + Math.min(3600000, 15000 * 2 ** attempts)),
      } });
      this.logger.log(`Push delivery ${result} notification=${notification.id} platform=${device.platform}`);
  }
}
