// AccountsStore — shared configured-account store (Preferences-backed).
// AccountsPage reads it; AddAccountsPage appends to it (spec 持久化约束).

import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

const STORE = 'readyou_accounts';

export interface AccountEntry {
  id: string;
  name: string;
  type: string;
}

interface AccountsData {
  accounts: AccountEntry[];
}

export class AccountsStore {
  static async load(ctx: object): Promise<AccountEntry[]> {
    const s = await preferences.getPreferences(getContext(ctx) as common.UIAbilityContext, { name: STORE });
    const j = await s.get('accounts_json', '') as string;
    if (j.length > 0) {
      return (JSON.parse(j) as AccountsData).accounts;
    }
    // First launch auto-creates a local account (spec 场景一 step 4).
    const def: AccountEntry = { id: 'local_default', name: 'Local', type: 'Local account' };
    return [def];
  }

  static async add(ctx: object, entry: AccountEntry): Promise<void> {
    const cur = await AccountsStore.load(ctx);
    cur.push(entry);
    const s = await preferences.getPreferences(getContext(ctx) as common.UIAbilityContext, { name: STORE });
    const d: AccountsData = { accounts: cur };
    await s.put('accounts_json', JSON.stringify(d));
    await s.flush();
  }
}
