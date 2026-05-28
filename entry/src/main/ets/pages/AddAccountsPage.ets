// Page: AddAccountsPage — grouped add-account entries + dialogs (场景二/三/四)

import { router } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { MockDataSource } from '../common/MockDataSource';
import { AccountsStore, AccountEntry } from '../common/AccountsStore';

const TAG = 'AddAccountsPage';

interface AddRow {
  id: string;
  label: string;
  subtitle: string;
  iconSeed: string;
}

interface AddSection {
  id: string;
  title: string;
  rows: AddRow[];
}

interface AccountsFile {
  sections: AddSection[];
}

@Entry
@Component
struct AddAccountsPage {
  @State private sections: AddSection[] = [];
  @State private dialogOpen: boolean = false;
  @State private dialogId: string = '';
  @State private dialogLabel: string = '';
  @State private dialogLocal: boolean = false;
  @State private nameText: string = '';
  @State private serverText: string = '';
  @State private credText: string = '';
  @State private errorMsg: string = '';

  aboutToAppear(): void {
    this.load();
  }

  private async load(): Promise<void> {
    try {
      this.sections = (await MockDataSource.loadJson<AccountsFile>(this, 'mock_accounts.json')).sections;
    } catch (e) {
      hilog.error(0x0000, TAG, 'load failed: %{public}s', String(e));
    }
  }

  private openDialog(row: AddRow): void {
    this.dialogId = row.id;
    this.dialogLabel = row.label;
    this.dialogLocal = row.id === 'local';
    this.nameText = '';
    this.serverText = '';
    this.credText = '';
    this.errorMsg = '';
    this.dialogOpen = true;
  }

  private async confirm(): Promise<void> {
    if (this.nameText.trim().length === 0) {
      this.errorMsg = 'Name is required';
      return;
    }
    if (!this.dialogLocal) {
      if (this.serverText.trim().length === 0 || this.credText.trim().length === 0) {
        this.errorMsg = 'Server and credentials are required';
        return;
      }
      // (self-hosted) credential check would run here; mock treats filled as valid.
    }
    const entry: AccountEntry = { id: `${this.dialogId}_${Date.now()}`, name: this.nameText.trim(), type: this.dialogLabel };
    await AccountsStore.add(this, entry);
    this.dialogOpen = false;
    router.pushUrl({ url: 'pages/AccountDetailPage', params: { name: entry.name } });
  }

  @Builder
  private TopBar() {
    Row() {
      Button({ type: ButtonType.Circle, stateEffect: true }) {
        Text('←').fontSize(22).fontColor('#1F1F1F');
      }.width(40).height(40).backgroundColor(Color.Transparent).accessibilityText('Back')
        .onClick(() => router.back());
    }.width('100%').height(56).padding({ left: 8 }).alignItems(VerticalAlign.Center).backgroundColor('#FFFFFF');
  }

  @Builder
  private EntryRow(row: AddRow) {
    Row() {
      Column() {
        Text(row.label).fontSize(16).fontColor('#1F1F1F').fontWeight(FontWeight.Medium);
        Text(row.subtitle).fontSize(13).fontColor('#666666').margin({ top: 2 });
      }.alignItems(HorizontalAlign.Start).layoutWeight(1).margin({ left: 24 });
    }
    .width('100%').height(64).alignItems(VerticalAlign.Center).backgroundColor('#FFFFFF')
    .onClick(() => this.openDialog(row));
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Column() {
        this.TopBar();
        Scroll() {
          Column() {
            Text('Add accounts').fontSize(28).fontWeight(FontWeight.Medium).fontColor('#1F1F1F')
              .width('100%').padding({ left: 24, right: 24, top: 8, bottom: 16 });
            ForEach(this.sections, (sec: AddSection) => {
              // Group title — not clickable (场景二 step 4)
              Text(sec.title).fontSize(13).fontColor('#1976D2').fontWeight(FontWeight.Medium)
                .width('100%').padding({ left: 24, right: 24, top: 16, bottom: 8 });
              ForEach(sec.rows, (row: AddRow) => {
                this.EntryRow(row);
              }, (row: AddRow) => row.id);
            }, (sec: AddSection) => sec.id);
          }.width('100%');
        }.layoutWeight(1).width('100%');
      }.width('100%').height('100%').backgroundColor('#FFFFFF');

      if (this.dialogOpen) {
        Column() {
          Text(`Add ${this.dialogLabel}`).fontSize(18).fontWeight(FontWeight.Bold).fontColor('#1F1F1F').padding(16);
          TextInput({ placeholder: 'Name', text: this.nameText })
            .margin({ left: 16, right: 16, bottom: 8 }).onChange((v: string) => { this.nameText = v; });
          if (!this.dialogLocal) {
            TextInput({ placeholder: 'Server address', text: this.serverText })
              .margin({ left: 16, right: 16, bottom: 8 }).onChange((v: string) => { this.serverText = v; });
            TextInput({ placeholder: 'Credentials', text: this.credText })
              .margin({ left: 16, right: 16, bottom: 8 }).onChange((v: string) => { this.credText = v; });
          }
          if (this.errorMsg.length > 0) {
            Text(this.errorMsg).fontSize(13).fontColor('#D32F2F').padding({ left: 16, right: 16, bottom: 8 });
          }
          Row() {
            Text('Cancel').fontSize(15).fontColor('#1976D2').padding(16)
              .onClick(() => { this.dialogOpen = false; });
            Text('Confirm').fontSize(15).fontColor('#1976D2').padding(16)
              .onClick(() => this.confirm());
          }.justifyContent(FlexAlign.End).width('100%');
        }
        .width(340).backgroundColor('#FFFFFF').borderRadius(12).shadow({ radius: 12, color: '#40000000' });
      }
    }
    .width('100%').height('100%');
  }
}
