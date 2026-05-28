// Page: ColorStylePage — color scheme / dark theme / font (4 scenarios)

import { router } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { MockDataSource } from '../common/MockDataSource';

const TAG = 'ColorStylePage';
const STORE = 'readyou_colorstyle';

interface Swatch { id: string; color: string; }
interface ColorStyleFile {
  basicSwatches: Swatch[];
  wallpaperSwatches: Swatch[];
  fonts: string[];
}

type ColorMode = 'wallpaper' | 'basic';

@Entry
@Component
struct ColorStylePage {
  @State private mode: ColorMode = 'basic';
  @State private basicSwatches: Swatch[] = [];
  @State private wallpaperSwatches: Swatch[] = [];
  @State private fonts: string[] = ['Google Sans Flex', 'System', 'External'];
  @State private accent: string = '#1976D2';
  @State private darkMode: string = 'system';   // system | on | off
  @State private font: string = 'Google Sans Flex';

  @State private fontDialogOpen: boolean = false;
  @State private hexDialogOpen: boolean = false;
  @State private hexText: string = '';
  @State private hexError: string = '';

  aboutToAppear(): void {
    this.load();
  }

  private async store(): Promise<preferences.Preferences> {
    return await preferences.getPreferences(getContext(this) as common.UIAbilityContext, { name: STORE });
  }

  private async load(): Promise<void> {
    try {
      const data = await MockDataSource.loadJson<ColorStyleFile>(this, 'mock_color_style.json');
      this.basicSwatches = data.basicSwatches;
      this.wallpaperSwatches = data.wallpaperSwatches;
      if (data.fonts && data.fonts.length > 0) { this.fonts = data.fonts; }
      const s = await this.store();
      this.mode = (await s.get('mode', 'basic') as string) as ColorMode;
      this.accent = await s.get('accent', '#1976D2') as string;
      this.darkMode = await s.get('dark', 'system') as string;
      this.font = await s.get('font', 'Google Sans Flex') as string;
    } catch (e) {
      hilog.error(0x0000, TAG, 'load failed: %{public}s', String(e));
    }
  }

  private async persist(): Promise<void> {
    const s = await this.store();
    await s.put('mode', this.mode);
    await s.put('accent', this.accent);
    await s.put('dark', this.darkMode);
    await s.put('font', this.font);
    await s.flush();
  }

  private currentSwatches(): Swatch[] {
    return this.mode === 'basic' ? this.basicSwatches : this.wallpaperSwatches;
  }

  private darkDesc(): string {
    if (this.darkMode === 'on') { return 'On'; }
    if (this.darkMode === 'off') { return 'Off'; }
    return 'Use device theme';
  }

  private cycleDark(): void {
    this.darkMode = this.darkMode === 'system' ? 'on' : (this.darkMode === 'on' ? 'off' : 'system');
    this.persist();
  }

  private pickSwatch(s: Swatch): void {
    this.accent = s.color;
    this.persist();
  }

  private isHex6(v: string): boolean {
    if (v.length !== 6) { return false; }
    for (let i = 0; i < v.length; i++) {
      const c = v.charCodeAt(i);
      const ok = (c >= 48 && c <= 57) || (c >= 65 && c <= 70) || (c >= 97 && c <= 102);
      if (!ok) { return false; }
    }
    return true;
  }

  private confirmHex(): void {
    if (!this.isHex6(this.hexText)) {
      this.hexError = 'Enter 6 hex digits (e.g. 666666)';
      return;
    }
    this.accent = `#${this.hexText}`;
    this.hexDialogOpen = false;
    this.persist();
  }

  private pickFont(f: string): void {
    this.font = f;
    this.fontDialogOpen = false;
    this.persist();
  }

  @Builder
  private ModeChip(label: string, m: ColorMode) {
    Text(label).fontSize(14).fontColor(this.mode === m ? '#FFFFFF' : '#1F1F1F')
      .height(40).padding({ left: 20, right: 20 }).borderRadius(20)
      .backgroundColor(this.mode === m ? this.accent : '#F1F1F1')
      .textAlign(TextAlign.Center)
      .onClick(() => { this.mode = m; this.persist(); });
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Column() {
        Row() {
          Button({ type: ButtonType.Circle, stateEffect: true }) {
            Text('←').fontSize(22).fontColor('#1F1F1F');
          }.width(40).height(40).backgroundColor(Color.Transparent).accessibilityText('Back')
            .onClick(() => router.back());
        }.width('100%').height(56).padding({ left: 8 }).alignItems(VerticalAlign.Center).backgroundColor('#FFFFFF');

        Scroll() {
          Column() {
            Text('Color & style').fontSize(28).fontWeight(FontWeight.Medium).fontColor('#1F1F1F')
              .width('100%').padding({ left: 24, right: 24, top: 8, bottom: 8 });

            // Preview card + current accent hex (the hex doubles as a test signal).
            Column() {
              Column().width('60%').height(120).borderRadius(16).backgroundColor(this.accent)
                .margin({ top: 16, bottom: 8 });
              Text(this.accent).fontSize(13).fontColor('#666666');
            }.width('100%').alignItems(HorizontalAlign.Center).margin({ bottom: 8 });

            Row() {
              this.ModeChip('Wallpaper colors', 'wallpaper');
              this.ModeChip('Basic colors', 'basic');
            }.width('100%').padding({ left: 24, right: 24, top: 8, bottom: 8 }).justifyContent(FlexAlign.SpaceBetween);

            // Swatch row — each carries its hex caption so it is findable/tappable.
            Scroll() {
              Row() {
                ForEach(this.currentSwatches(), (s: Swatch) => {
                  Column() {
                    Column().width(44).height(44).borderRadius(22).backgroundColor(s.color)
                      .borderColor(this.accent === s.color ? '#1F1F1F' : Color.Transparent)
                      .borderWidth(this.accent === s.color ? 3 : 0);
                    Text(s.color).fontSize(10).fontColor('#888888').margin({ top: 2 });
                  }.padding(8)
                    .gesture(GestureGroup(GestureMode.Parallel,
                      TapGesture().onAction(() => this.pickSwatch(s)),
                      LongPressGesture({ repeat: false }).onAction(() => {
                        if (this.mode === 'basic') { this.hexText = ''; this.hexError = ''; this.hexDialogOpen = true; }
                      })
                    ));
                }, (s: Swatch) => s.id);
              }.padding({ left: 16, right: 16 });
            }.scrollable(ScrollDirection.Horizontal).width('100%').height(80);

            Text('Appearance').fontSize(13).fontColor('#1976D2').fontWeight(FontWeight.Medium)
              .width('100%').padding({ left: 24, right: 24, top: 16, bottom: 8 });

            // Dark theme row — 3-mode cycle (场景三)
            Row() {
              Column() {
                Text('Dark theme').fontSize(16).fontColor('#1F1F1F').fontWeight(FontWeight.Medium);
                Text(this.darkDesc()).fontSize(13).fontColor('#666666').margin({ top: 2 });
              }.alignItems(HorizontalAlign.Start).layoutWeight(1);
              Toggle({ type: ToggleType.Switch, isOn: this.darkMode === 'on' }).hitTestBehavior(HitTestMode.None);
            }.width('100%').padding({ left: 24, right: 24, top: 12, bottom: 12 }).alignItems(VerticalAlign.Center)
              .onClick(() => this.cycleDark());

            // Basic fonts row → font dialog (场景四)
            Row() {
              Column() {
                Text('Basic fonts').fontSize(16).fontColor('#1F1F1F').fontWeight(FontWeight.Medium);
                Text(this.font).fontSize(13).fontColor('#666666').margin({ top: 2 });
              }.alignItems(HorizontalAlign.Start).layoutWeight(1);
            }.width('100%').padding({ left: 24, right: 24, top: 12, bottom: 12 }).alignItems(VerticalAlign.Center)
              .onClick(() => { this.fontDialogOpen = true; });
          }.width('100%');
        }.layoutWeight(1).width('100%');
      }.width('100%').height('100%').backgroundColor('#FFFFFF');

      if (this.fontDialogOpen) {
        Column() {
          Text('Basic fonts').fontSize(18).fontWeight(FontWeight.Bold).fontColor('#1F1F1F').padding(16);
          ForEach(this.fonts, (f: string) => {
            Row() {
              Text(f).fontSize(15).fontColor('#1F1F1F').layoutWeight(1);
              if (this.font === f) { Text('✓').fontSize(16).fontColor('#1976D2'); }
            }.width('100%').padding({ left: 20, right: 20, top: 14, bottom: 14 })
              .onClick(() => this.pickFont(f));
          }, (f: string) => f);
          Text('Cancel').fontSize(15).fontColor('#1976D2').padding(16).alignSelf(ItemAlign.End)
            .onClick(() => { this.fontDialogOpen = false; });
        }.width(320).backgroundColor('#FFFFFF').borderRadius(12).shadow({ radius: 12, color: '#40000000' });
      }

      if (this.hexDialogOpen) {
        Column() {
          Text('Custom color').fontSize(18).fontWeight(FontWeight.Bold).fontColor('#1F1F1F').padding(16);
          TextInput({ placeholder: 'Hex e.g. 666666', text: this.hexText })
            .margin({ left: 16, right: 16, bottom: 8 }).onChange((v: string) => { this.hexText = v; });
          if (this.hexError.length > 0) {
            Text(this.hexError).fontSize(13).fontColor('#D32F2F').padding({ left: 16, right: 16, bottom: 8 });
          }
          Row() {
            Text('Cancel').fontSize(15).fontColor('#1976D2').padding(16)
              .onClick(() => { this.hexDialogOpen = false; });
            Text('Confirm').fontSize(15).fontColor('#1976D2').padding(16)
              .onClick(() => this.confirmHex());
          }.justifyContent(FlexAlign.End).width('100%');
        }.width(320).backgroundColor('#FFFFFF').borderRadius(12).shadow({ radius: 12, color: '#40000000' });
      }
    }.width('100%').height('100%');
  }
}
