import { ServiceUnavailableException } from '@nestjs/common';
import { HealthController } from './health.controller';
import { PrismaService } from './prisma/prisma.service';

describe('HealthController', () => {
  it('reports readiness only when the database query succeeds', async () => {
    const query = jest.fn().mockResolvedValue([{ '?column?': 1 }]);
    const controller = new HealthController({ $queryRaw: query } as unknown as PrismaService);
    await expect(controller.readiness()).resolves.toEqual({ status: 'ok' });
    query.mockRejectedValue(new Error('private connection details'));
    await expect(controller.readiness()).rejects.toThrow(ServiceUnavailableException);
    await expect(controller.readiness()).rejects.toThrow('Database unavailable');
  });
});
