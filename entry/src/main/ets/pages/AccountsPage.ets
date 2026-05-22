// ====================================================================
// Page: AccountsPage
// App: ReadYou
// Reference samples:
//   - D:/OH-Appforge/_hmos_samples/ComponentUXExamples (List/ListItem)
//   - D:/OH-Appforge/spec_to_app/harmony/opus-4.7/Catima/entry/src/main/ets/pages/
//     BarcodeSelectorPage.ets (proven layout pattern)
// Android baseline screenshot:
//   - D:/OH-Appforge/_doc_screenshots_v2/ReadYou/L2_1_accounts.png
// Android view tree:
//   - D:/OH-Appforge/_doc_screenshots_v2/ReadYou/L2_1_accounts.xml
// Layout contract (from Android view.xml):
//   - Top app bar: Back button (no inline title)
//   - Heading "Add accounts" (display title beneath the app bar)
//   - Section "Local" header + row "Local / On this device"
//   - Section "Self-hosted" header + rows:
//       FreshRSS / freshrss.org
//       Google Reader / Google Reader API
//       Fever / Deprecated. Not recommended.
// Status: ALIGNED to Android baseline.
// ====================================================================

import { router } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { MockDataSource } from '../common/MockDataSource';

const TAG = 'AccountsPage';

interface AccountRow {
  id: string;
  label: string;
  subtitle: string;
  iconSeed: string;     // deterministic colour seed (since we avoid sys.media.*)
}

interface AccountSection {
  id: string;
  title: string;
  rows: AccountRow[];
}

interface AccountsFile {
  sections: AccountSection[];
}

@Entry
@Component
struct AccountsPage {
  // Loaded from rawfile/mock_accounts.json at aboutToAppear.
  @State private sections: AccountSection[] = [];

  aboutToAppear(): void {
    hilog.info(0x0000, TAG, 'AccountsPage mounted');
    this.loadSections();
  }

  private async loadSections(): Promise<void> {
    try {
      const data = await MockDataSource.loadJson<AccountsFile>(this, 'mock_accounts.json');
      this.sections = data.sections;
      hilog.info(0x0000, TAG, 'loaded %{public}d account sections from rawfile', this.sections.length);
    } catch (e) {
      hilog.error(0x0000, TAG, 'load failed: %{public}s', String(e));
      this.sections = [];
    }
  }

  private onBackClick(): void {
    router.back();
  }

  private onRowClick(row: AccountRow): void {
    hilog.info(0x0000, TAG, 'pick account type %{public}s', row.id);
  }

  // Deterministic colour from seed letter — avoids missing sys.media.* refs.
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
      }
      .width(40).height(40).backgroundColor(Color.Transparent)
      .accessibilityText('Back')
      .onClick(() => this.onBackClick());
    }
    .width('100%')
    .height(56)
    .padding({ left: 8, right: 8 })
    .alignItems(VerticalAlign.Center)
    .backgroundColor('#FFFFFF');
  }

  @Builder
  private SectionHeader(title: string) {
    Text(title)
      .fontSize(13)
      .fontColor('#1976D2')
      .fontWeight(FontWeight.Medium)
      .width('100%')
      .padding({ left: 24, right: 24, top: 16, bottom: 8 });
  }

  @Builder
  private AccountRowView(row: AccountRow) {
    Row() {
      // Leading circular icon — coloured seed avatar (no sys.media.*)
      Column() {
        Text(row.label.substring(0, 1))
          .fontSize(16)
          .fontColor(Color.White)
          .fontWeight(FontWeight.Medium);
      }
      .width(40).height(40)
      .borderRadius(20)
      .backgroundColor(this.seedColor(row.iconSeed))
      .justifyContent(FlexAlign.Center)
      .margin({ left: 24, right: 16 });

      Column() {
        Text(row.label)
          .fontSize(16)
          .fontColor('#1F1F1F')
          .fontWeight(FontWeight.Medium);
        Text(row.subtitle)
          .fontSize(13)
          .fontColor('#666666')
          .margin({ top: 2 });
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1);
    }
    .width('100%')
    .height(72)
    .alignItems(VerticalAlign.Center)
    .backgroundColor('#FFFFFF')
    .onClick(() => this.onRowClick(row));
  }

  build() {
    Column() {
      this.TopBar();

      Scroll() {
        Column() {
          // Display heading — Android "Add accounts" large text at top of content.
          Text('Add accounts')
            .fontSize(28)
            .fontWeight(FontWeight.Medium)
            .fontColor('#1F1F1F')
            .width('100%')
            .padding({ left: 24, right: 24, top: 8, bottom: 16 });

          ForEach(this.sections, (section: AccountSection) => {
            this.SectionHeader(section.title);
            ForEach(section.rows, (row: AccountRow) => {
              this.AccountRowView(row);
            }, (row: AccountRow) => row.id);
          }, (section: AccountSection) => section.id);
        }
        .width('100%');
      }
      .layoutWeight(1)
      .width('100%');
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF');
  }
}
