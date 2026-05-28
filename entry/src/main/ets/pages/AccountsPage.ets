// Page: AccountsPage — configured-account list + "Add accounts" entry (场景一)

import { router } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AccountsStore, AccountEntry } from '../common/AccountsStore';

const TAG = 'AccountsPage';
const HINT = 'You can switch accounts by tapping on the account name on the feed page';

@Entry
@Component
struct AccountsPage {
  @State private accounts: AccountEntry[] = [];

  aboutToAppear(): void {
    this.reload();
  }

  onPageShow(): void {
    // Reflect accounts added on the Add-accounts page after returning (场景三/四).
    this.reload();
  }

  private async reload(): Promise<void> {
    try {
      this.accounts = await AccountsStore.load(this);
    } catch (e) {
      hilog.error(0x0000, TAG, 'load failed: %{public}s', String(e));
    }
  }

  private seedColor(seed: string): string {
    const palette: string[] = ['#1976D2', '#388E3C', '#F57C00', '#7B1FA2', '#D32F2F', '#0097A7'];
    let h = 0;
    for (let i = 0; i < seed.length; i++) { h = (h * 31 + seed.charCodeAt(i)) >>> 0; }
    return palette[h % palette.length];
  }

  @Builder
  private TopBar() {
    Row() {
      Button({ type: ButtonType.Circle, stateEffect: true }) {
        Text('←').fontSize(22).fontColor('#1F1F1F');
      }.width(40).height(40).backgroundColor(Color.Transparent).accessibilityText('Back')
        .onClick(() => router.back());
      Text('Accounts').fontSize(20).fontWeight(FontWeight.Medium).fontColor('#1F1F1F').margin({ left: 12 });
    }
    .width('100%').height(56).padding({ left: 8 }).alignItems(VerticalAlign.Center).backgroundColor('#FFFFFF');
  }

  @Builder
  private AccountRowView(acc: AccountEntry) {
    Row() {
      Column() {
        Text(acc.name.substring(0, 1)).fontSize(16).fontColor(Color.White).fontWeight(FontWeight.Medium);
      }.width(40).height(40).borderRadius(20).backgroundColor(this.seedColor(acc.id))
        .justifyContent(FlexAlign.Center).margin({ left: 24, right: 16 });
      Column() {
        Text(acc.name).fontSize(16).fontColor('#1F1F1F').fontWeight(FontWeight.Medium);
        Text(acc.type).fontSize(13).fontColor('#666666').margin({ top: 2 });
      }.alignItems(HorizontalAlign.Start).layoutWeight(1);
    }
    .width('100%').height(72).alignItems(VerticalAlign.Center).backgroundColor('#FFFFFF')
    .onClick(() => router.pushUrl({ url: 'pages/AccountDetailPage', params: { name: acc.name } }));
  }

  build() {
    Column() {
      this.TopBar();
      Scroll() {
        Column() {
          ForEach(this.accounts, (acc: AccountEntry) => {
            this.AccountRowView(acc);
          }, (acc: AccountEntry) => acc.id);

          // Non-clickable hint (场景一 step 2)
          Text(HINT).fontSize(13).fontColor('#9AA0A6')
            .width('100%').padding({ left: 24, right: 24, top: 16, bottom: 16 });

          // "Add accounts" entry (场景一 step 3)
          Row() {
            Column() {
              Text('Add accounts').fontSize(16).fontColor('#1F1F1F').fontWeight(FontWeight.Medium);
              Text('Local, services, self-hosted').fontSize(13).fontColor('#666666').margin({ top: 2 });
            }.alignItems(HorizontalAlign.Start).layoutWeight(1).margin({ left: 24 });
          }
          .width('100%').height(72).alignItems(VerticalAlign.Center).backgroundColor('#FFFFFF')
          .onClick(() => router.pushUrl({ url: 'pages/AddAccountsPage' }));
        }.width('100%');
      }.layoutWeight(1).width('100%');
    }
    .width('100%').height('100%').backgroundColor('#FFFFFF');
  }
}
