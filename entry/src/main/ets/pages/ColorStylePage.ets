// Page: ColorStylePage — color scheme / dark theme / font (4 scenarios)

import { router } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { preferences } from '@kit.ArkData';
import { common, ConfigurationConstant } from '@kit.AbilityKit';
import { picker } from '@kit.CoreFileKit';
import wallpaper from '@ohos.wallpaper';
import { MockDataSource } from '../common/MockDataSource';

const TAG = 'ColorStylePage';
const STORE = 'readyou_colorstyle';

interface Swatch { id: string; color?: string; custom?: boolean; }
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
  @State private fonts: string[] = ['Google Sans Flex', 'System', 'External fonts'];
  @State private accent: string = '#1976D2';
  @State private darkMode: string = 'system';   // system | on | off
  @State private font: string = 'Google Sans Flex';
  @StorageLink('systemColorMode') private systemColorMode: number =
    ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET;

  @State private fontDialogOpen: boolean = false;
  @State private darkDetailOpen: boolean = false;
  @State private blackDark: boolean = false;
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
      this.wallpaperSwatches = await this.loadWallpaperSwatches();
      if (data.fonts && data.fonts.length > 0) { this.fonts = data.fonts; }
      const s = await this.store();
      this.mode = (await s.get('mode', 'basic') as string) as ColorMode;
      this.accent = await s.get('accent', '#1976D2') as string;
      this.darkMode = await s.get('dark', 'system') as string;
      this.blackDark = await s.get('blackDark', false) as boolean;
      this.font = await s.get('font', 'Google Sans Flex') as string;
      this.applyDarkMode();
    } catch (e) {
      hilog.error(0x0000, TAG, 'load failed: %{public}s', String(e));
    }
  }

  private colorHex(value: number): string {
    return Math.max(0, Math.min(255, value)).toString(16).padStart(2, '0').toUpperCase();
  }

  private async loadWallpaperSwatches(): Promise<Swatch[]> {
    try {
      const colors: wallpaper.RgbaColor[] = await wallpaper.getColors(
        wallpaper.WallpaperType.WALLPAPER_SYSTEM
      );
      const distinct: Swatch[] = [];
      const seen: string[] = [];
      colors.forEach((color: wallpaper.RgbaColor, index: number) => {
        const hex: string = `#${this.colorHex(color.red)}${this.colorHex(color.green)}${this.colorHex(color.blue)}`;
        if (!seen.includes(hex)) {
          seen.push(hex);
          distinct.push({ id: `wallpaper_${index}`, color: hex });
        }
      });
      if (distinct.length > 0) {
        return distinct;
      }
      hilog.error(0x0000, TAG, 'system wallpaper returned no colors');
    } catch (e) {
      hilog.error(0x0000, TAG, 'system wallpaper colors failed: %{public}s', String(e));
    }
    return [];
  }

  private applyDarkMode(): void {
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    if (this.darkMode === 'on') {
      context.setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_DARK);
    } else if (this.darkMode === 'off') {
      context.setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT);
    } else {
      context.setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    }
  }

  private async persist(): Promise<void> {
    const s = await this.store();
    await s.put('mode', this.mode);
    await s.put('accent', this.accent);
    await s.put('dark', this.darkMode);
    await s.put('blackDark', this.blackDark);
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

  private async selectDark(mode: string): Promise<void> {
    this.darkMode = mode;
    this.applyDarkMode();
    try {
      await this.persist();
    } catch (e) {
      hilog.error(0x0000, TAG, 'dark-mode persistence failed: %{public}s', String(e));
    }
  }

  onBackPress(): boolean {
    if (this.hexDialogOpen) {
      this.hexDialogOpen = false;
      return true;
    }
    if (this.fontDialogOpen) {
      this.fontDialogOpen = false;
      return true;
    }
    if (this.darkDetailOpen) {
      this.darkDetailOpen = false;
      return true;
    }
    return false;
  }

  private async pickSwatch(s: Swatch): Promise<void> {
    if (this.mode === 'basic' && s.custom === true) {
      this.hexText = this.accent.startsWith('#') ? this.accent.substring(1) : this.accent;
      this.hexError = '';
      this.hexDialogOpen = true;
      return;
    }
    if (s.color) {
      this.accent = s.color;
      try {
        await this.persist();
      } catch (e) {
        hilog.error(0x0000, TAG, 'swatch persistence failed: %{public}s', String(e));
      }
    }
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

  private async confirmHex(): Promise<void> {
    if (!this.isHex6(this.hexText)) {
      this.hexError = 'Enter 6 hex digits (e.g. 666666)';
      return;
    }
    this.accent = `#${this.hexText.toUpperCase()}`;
    this.mode = 'basic';
    this.hexDialogOpen = false;
    try {
      await this.persist();
    } catch (e) {
      hilog.error(0x0000, TAG, 'custom-color persistence failed: %{public}s', String(e));
    }
  }

  private async pickFont(f: string): Promise<void> {
    if (f === 'External fonts') {
      const previousFont = this.font;
      this.fontDialogOpen = false;
      this.pickExternalFont(previousFont);
      return;
    }
    this.font = f;
    this.fontDialogOpen = false;
    try {
      await this.persist();
    } catch (e) {
      hilog.error(0x0000, TAG, 'font persistence failed: %{public}s', String(e));
    }
  }

  private async pickExternalFont(previousFont: string): Promise<void> {
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      const documentPicker = new picker.DocumentViewPicker(context);
      const options = new picker.DocumentSelectOptions();
      options.maxSelectNumber = 1;
      options.fileSuffixFilters = ['.ttf', '.otf'];
      const uris = await documentPicker.select(options);
      if (uris.length === 0) {
        this.font = previousFont;
        return;
      }
      this.font = 'External fonts';
      await this.persist();
    } catch (e) {
      this.font = previousFont;
      hilog.error(0x0000, TAG, 'external font picker failed or cancelled: %{public}s', String(e));
    }
  }

  private isDarkSurface(): boolean {
    return this.darkMode === 'on' || (
      this.darkMode === 'system' &&
      this.systemColorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK
    );
  }

  private pageBackground(): string {
    if (this.isDarkSurface()) {
      return this.blackDark ? '#000000' : '#121212';
    }
    return '#FFFFFF';
  }

  private primaryTextColor(): string {
    return this.isDarkSurface() ? '#F5F5F5' : '#1F1F1F';
  }

  private secondaryTextColor(): string {
    return this.isDarkSurface() ? '#BDBDBD' : '#666666';
  }

  @Builder
  private ModeChip(label: string, m: ColorMode) {
    Text(label).fontSize(14).fontColor(this.mode === m ? '#FFFFFF' : '#1F1F1F')
      .height(40).padding({ left: 20, right: 20 }).borderRadius(20)
      .backgroundColor(this.mode === m ? this.accent : '#F1F1F1')
      .textAlign(TextAlign.Center)
      .onClick(async () => {
        this.mode = m;
        try {
          await this.persist();
        } catch (e) {
          hilog.error(0x0000, TAG, 'color-mode persistence failed: %{public}s', String(e));
        }
      });
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Column() {
        Row() {
          Button({ type: ButtonType.Circle, stateEffect: true }) {
            Text('←').fontSize(22).fontColor(this.primaryTextColor());
          }.width(40).height(40).backgroundColor(Color.Transparent).accessibilityText('Back')
            .onClick(() => router.back());
        }.width('100%').height(56).padding({ left: 8 }).alignItems(VerticalAlign.Center).backgroundColor(this.pageBackground());

        Scroll() {
          Column() {
            Text('Color & style').fontSize(28).fontWeight(FontWeight.Medium).fontColor(this.primaryTextColor())
              .width('100%').padding({ left: 24, right: 24, top: 8, bottom: 8 });

            // Preview card + current accent hex (the hex doubles as a test signal).
            Column() {
              Column().width('60%').height(120).borderRadius(16).backgroundColor(this.accent)
                .margin({ top: 16, bottom: 8 });
              Text(this.accent).fontSize(13).fontColor(this.secondaryTextColor());
            }.width('100%').alignItems(HorizontalAlign.Center).margin({ bottom: 8 });

            Row() {
              this.ModeChip('Wallpaper colors', 'wallpaper');
              this.ModeChip('Basic colors', 'basic');
            }.width('100%').padding({ left: 24, right: 24, top: 8, bottom: 8 }).justifyContent(FlexAlign.SpaceBetween);

            // Swatch row — each carries its hex caption so it is findable/tappable.
            Scroll() {
              Row() {
                ForEach(this.currentSwatches(), (s: Swatch, index: number) => {
                  Column() {
                    if (s.custom === true) {
                      Text('+').width(44).height(44).borderRadius(22).backgroundColor('#F1F1F1')
                        .fontSize(24).fontColor(this.primaryTextColor()).textAlign(TextAlign.Center)
                        .borderColor('#79747E').borderWidth(1);
                      Text('Custom').fontSize(10).fontColor(this.secondaryTextColor()).margin({ top: 2 });
                    } else {
                      Column().width(44).height(44).borderRadius(22).backgroundColor(s.color ?? '#F1F1F1')
                        .borderColor(this.accent === s.color ? '#1F1F1F' : Color.Transparent)
                        .borderWidth(this.accent === s.color ? 3 : 0);
                      Text(s.color ?? '').fontSize(10).fontColor('#888888').margin({ top: 2 });
                    }
                  }.padding(8)
                    .accessibilityText(s.custom === true ? 'Custom basic palette' : `${this.mode} palette ${index + 1}`)
                    .onClick(async () => { await this.pickSwatch(s); });
                }, (s: Swatch) => s.id);
              }.padding({ left: 16, right: 16 });
            }.scrollable(ScrollDirection.Horizontal).width('100%').height(80);

            Text('Appearance').fontSize(13).fontColor('#1976D2').fontWeight(FontWeight.Medium)
              .width('100%').padding({ left: 24, right: 24, top: 16, bottom: 8 });

            // Dark theme row — 3-mode cycle (场景三)
            Row() {
              Column() {
                Text('Dark theme').fontSize(16).fontColor(this.primaryTextColor()).fontWeight(FontWeight.Medium);
                Text(this.darkDesc()).fontSize(13).fontColor(this.secondaryTextColor()).margin({ top: 2 });
              }.alignItems(HorizontalAlign.Start).layoutWeight(1);
              Toggle({ type: ToggleType.Switch, isOn: this.darkMode === 'on' }).hitTestBehavior(HitTestMode.None);
            }.width('100%').padding({ left: 24, right: 24, top: 12, bottom: 12 }).alignItems(VerticalAlign.Center)
              .onClick(() => { this.darkDetailOpen = true; });

            // Basic fonts row → font dialog (场景四)
            Row() {
              Column() {
                Text('Basic fonts').fontSize(16).fontColor(this.primaryTextColor()).fontWeight(FontWeight.Medium);
                Text(this.font).fontSize(13).fontColor(this.secondaryTextColor()).margin({ top: 2 });
              }.alignItems(HorizontalAlign.Start).layoutWeight(1);
            }.width('100%').padding({ left: 24, right: 24, top: 12, bottom: 12 }).alignItems(VerticalAlign.Center)
              .onClick(() => { this.fontDialogOpen = true; });
          }.width('100%');
        }.layoutWeight(1).width('100%');
      }.width('100%').height('100%').backgroundColor(this.pageBackground());

      if (this.darkDetailOpen) {
        Column() {
          Row() {
            Text('←').fontSize(22).fontColor(this.primaryTextColor()).padding(16)
              .onClick(() => { this.darkDetailOpen = false; });
            Text('Dark theme').fontSize(20).fontWeight(FontWeight.Medium).fontColor(this.primaryTextColor());
          }.width('100%').alignItems(VerticalAlign.Center);
          ForEach(['Use device theme', 'On', 'Off'], (label: string) => {
            Row() {
              Text(label).fontSize(16).fontColor(this.primaryTextColor()).layoutWeight(1);
              if (this.darkDesc() === label) { Text('✓').fontSize(16).fontColor('#1976D2'); }
            }.width('100%').padding({ left: 24, right: 24, top: 16, bottom: 16 })
              .onClick(async () => {
                await this.selectDark(
                  label === 'Use device theme' ? 'system' : label.toLowerCase()
                );
              });
          }, (label: string) => label);
          Row() {
            Text('Black dark theme').fontSize(16).fontColor(this.primaryTextColor()).layoutWeight(1);
            Toggle({ type: ToggleType.Switch, isOn: this.blackDark }).onChange(async (v: boolean) => {
              this.blackDark = v;
              try {
                await this.persist();
              } catch (e) {
                hilog.error(0x0000, TAG, 'black-theme persistence failed: %{public}s', String(e));
              }
            });
          }.width('100%').padding({ left: 24, right: 24, top: 16, bottom: 16 });
        }.width('100%').height('100%').backgroundColor(this.pageBackground());
      }

      if (this.fontDialogOpen) {
        Column() {
          Text('Basic fonts').fontSize(18).fontWeight(FontWeight.Bold).fontColor(this.primaryTextColor()).padding(16);
          ForEach(this.fonts, (f: string) => {
            Row() {
              Text(f).fontSize(15).fontColor(this.primaryTextColor()).layoutWeight(1);
              if (this.font === f) { Text('✓').fontSize(16).fontColor('#1976D2'); }
            }.width('100%').padding({ left: 20, right: 20, top: 14, bottom: 14 })
              .onClick(async () => { await this.pickFont(f); });
          }, (f: string) => f);
          Text('Cancel').fontSize(15).fontColor('#1976D2').padding(16).alignSelf(ItemAlign.End)
            .onClick(() => { this.fontDialogOpen = false; });
        }.width(320).backgroundColor(this.pageBackground()).borderRadius(12).shadow({ radius: 12, color: '#40000000' });
      }

      if (this.hexDialogOpen) {
        Column() {
          Text('Primary color').fontSize(18).fontWeight(FontWeight.Bold).fontColor(this.primaryTextColor()).padding(16);
          TextInput({ placeholder: 'Primary color e.g. 666666', text: this.hexText })
            .margin({ left: 16, right: 16, bottom: 8 }).onChange((v: string) => { this.hexText = v; });
          if (this.hexError.length > 0) {
            Text(this.hexError).fontSize(13).fontColor('#D32F2F').padding({ left: 16, right: 16, bottom: 8 });
          }
          Row() {
            Text('Cancel').fontSize(15).fontColor('#1976D2').padding(16)
              .onClick(() => { this.hexDialogOpen = false; });
            Text('Confirm').fontSize(15).fontColor('#1976D2').padding(16)
              .onClick(async () => { await this.confirmHex(); });
          }.justifyContent(FlexAlign.End).width('100%');
        }.width(320).backgroundColor(this.pageBackground()).borderRadius(12).shadow({ radius: 12, color: '#40000000' });
      }
    }.width('100%').height('100%');
  }
}
