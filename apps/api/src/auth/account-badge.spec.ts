import { accountBadge } from './account-badge';
describe('authenticated profile badge policy', () => {
  it('identifies only the developer, not every administrator', () => {
    expect(accountBadge({email: '404khai@gmail.com', role: 'ADMIN'})).toBe('developer');
    expect(accountBadge({email: 'another@example.com', role: 'ADMIN'})).toBeNull();
    expect(accountBadge({email: '404khai@gmail.com', role: 'USER'})).toBeNull();
  });
  it('assigns dex the Android tester badge, never developer privileges', () => {
    expect(accountBadge({email: 'DexGamingAcct@gmail.com', role: 'USER'})).toBe('android_beta_tester');
    expect(accountBadge({email: 'reader@example.com', role: 'USER'})).toBeNull();
  });
});
