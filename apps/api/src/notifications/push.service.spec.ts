import { ConfigService } from '@nestjs/config';
import { PushDevice } from '@prisma/client';
import { FcmPushProvider, NoopPushProvider } from './push.service';
import { GoogleAuth } from 'google-auth-library';

jest.mock('google-auth-library', () => ({
  GoogleAuth: jest.fn().mockImplementation(() => ({
    getClient: jest.fn().mockResolvedValue({
      getAccessToken: jest.fn().mockResolvedValue({ token: 'test-oauth-token' }),
    }),
  })),
}));

describe('push presentation contract', () => {
  afterEach(() => jest.restoreAllMocks());

  it('sends visible Android alerts promptly with a valid small icon and sound', async () => {
    const fetchMock = jest.spyOn(global, 'fetch').mockResolvedValue({ ok: true } as Response);
    const provider = new FcmPushProvider(new ConfigService({ FCM_PROJECT_ID: 'test-project' }));
    expect(await provider.send({ token: 'test-device-token' } as PushDevice, {
      notificationId: 'n1', type: 'SYSTEM_ANNOUNCEMENT', groupingKey: 'announcement:1',
      deepLink: 'keihatsu://inbox', title: 'Test', body: 'Open Inbox',
    })).toBe('sent');
    const request = JSON.parse(fetchMock.mock.calls[0][1]!.body as string).message;
    expect(request.android).toMatchObject({
      priority: 'HIGH', notification: {
        channel_id: 'system_announcements', icon: 'ic_notification', sound: 'default',
      },
    });
    expect(request.data.notificationId).toBe('n1');
    expect(GoogleAuth).toHaveBeenCalled();
  });

  it('does not report a no-op delivery as sent to a phone', async () => {
    expect(await new NoopPushProvider().send()).toBe('skipped');
  });
});
