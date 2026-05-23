// Page: ColorStylePage

import { router } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { MockDataSource } from '../common/MockDataSource';

const TAG = 'ColorStylePage';

interface Swatch {
  id: string;
  color: string;
}

interface ColorStyleFile {
  swatches: Swatch[];
}

type ColorMode = 'wallpaper' | 'basic';

@Entry
@Component
struct ColorStylePage {
  @State private mode: ColorMode = 'wallpaper';
  @State private selectedSwatchId: string = 'blue';
  @State private darkTheme: boolean = false;
  // Loaded from rawfile/mock_color_style.json at aboutToAppear.
  @State private swatches: Swatch[] = [];

  aboutToAppear(): void {
    hilog.info(0x0000, TAG, 'ColorStylePage mounted, mode=%{public}s', this.mode);
    this.loadSwatches();
  }

  private async loadSwatches(): Promise<void> {
    try {
      const data = await MockDataSource.loadJson<ColorStyleFile>(this, 'mock_color_style.json');
      this.swatches = data.swatches;
      hilog.info(0x0000, TAG, 'loaded %{public}d swatches from rawfile', this.swatches.length);
    } catch (e) {
      hilog.error(0x0000, TAG, 'load failed: %{public}s', String(e));
      this.swatches = [];
    }
  }

  private onBackClick(): void {
    router.back();
  }

  private onSelectMode(m: ColorMode): void {
    this.mode = m;
    hilog.info(0x0000, TAG, 'color mode -> %{public}s', m);
  }

  private onSwatchClick(id: string): void {
    this.selectedSwatchId = id;
    hilog.info(0x0000, TAG, 'swatch -> %{public}s', id);
  }

  private onBasicFontsClick(): void {
    hilog.info(0x0000, TAG, 'Basic fonts tapped');
  }

  private currentAccent(): string {
    const found = this.swatches.find((s: Swatch) => s.id === this.selectedSwatchId);
    return found ? found.color : '#1976D2';
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
  private PreviewCard() {
    // Material You preview — single rounded card with accent colour fill.
    Column() {
      Column()
        .width('60%').height(140)
        .borderRadius(16)
        .backgroundColor(this.currentAccent())
        .margin({ top: 24, bottom: 24 });
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center);
  }

  @Builder
  private ModeChip(label: string, m: ColorMode) {
    Row() {
      Text(label)
        .fontSize(14)
        .fontColor(this.mode === m ? '#FFFFFF' : '#1F1F1F');
    }
    .height(40)
    .padding({ left: 20, right: 20 })
    .borderRadius(20)
    .backgroundColor(this.mode === m ? this.currentAccent() : '#F1F1F1')
    .alignItems(VerticalAlign.Center)
    .justifyContent(FlexAlign.Center)
    .onClick(() => this.onSelectMode(m));
  }

  @Builder
  private SwatchRow() {
    Scroll() {
      Row() {
        ForEach(this.swatches, (s: Swatch) => {
          Column() {
            Column()
              .width(48).height(48)
              .borderRadius(24)
              .backgroundColor(s.color)
              .borderColor(this.selectedSwatchId === s.id ? '#1F1F1F' : Color.Transparent)
              .borderWidth(this.selectedSwatchId === s.id ? 2 : 0);
          }
          .padding(8)
          .onClick(() => this.onSwatchClick(s.id));
        }, (s: Swatch) => s.id);
      }
      .padding({ left: 16, right: 16 });
    }
    .scrollable(ScrollDirection.Horizontal)
    .width('100%')
    .height(80);
  }

  build() {
    Column() {
      this.TopBar();

      Scroll() {
        Column() {
          // Display heading.
          Text('Color & style')
            .fontSize(28)
            .fontWeight(FontWeight.Medium)
            .fontColor('#1F1F1F')
            .width('100%')
            .padding({ left: 24, right: 24, top: 8, bottom: 8 });

          this.PreviewCard();

          // Segmented chips: Wallpaper colors / Basic colors
          Row() {
            this.ModeChip('Wallpaper colors', 'wallpaper');
            this.ModeChip('Basic colors', 'basic');
          }
          .width('100%')
          .padding({ left: 24, right: 24, top: 8, bottom: 8 })
          .justifyContent(FlexAlign.SpaceBetween);

          this.SwatchRow();

          // Appearance section
          Text('Appearance')
            .fontSize(13)
            .fontColor('#1976D2')
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .padding({ left: 24, right: 24, top: 16, bottom: 8 });

          // Dark theme row + switch
          Row() {
            Column() {
              Text('Dark theme')
                .fontSize(16)
                .fontColor('#1F1F1F')
                .fontWeight(FontWeight.Medium);
              Text('Use device theme')
                .fontSize(13)
                .fontColor('#666666')
                .margin({ top: 2 });
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1);

            Toggle({ type: ToggleType.Switch, isOn: this.darkTheme })
              .onChange((on: boolean) => { this.darkTheme = on; });
          }
          .width('100%')
          .padding({ left: 24, right: 24, top: 12, bottom: 12 })
          .alignItems(VerticalAlign.Center);

          // Basic fonts row
          Row() {
            Column() {
              Text('Basic fonts')
                .fontSize(16)
                .fontColor('#1F1F1F')
                .fontWeight(FontWeight.Medium);
              Text('Google Sans Flex')
                .fontSize(13)
                .fontColor('#666666')
                .margin({ top: 2 });
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1);
          }
          .width('100%')
          .padding({ left: 24, right: 24, top: 12, bottom: 12 })
          .alignItems(VerticalAlign.Center)
          .onClick(() => this.onBasicFontsClick());
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
