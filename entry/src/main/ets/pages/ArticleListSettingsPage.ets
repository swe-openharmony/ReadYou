import { router } from '@kit.ArkUI';
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

const STORE = 'readyou_article_list';
const OPTIONS: string[] = ['None', 'Toggle read', 'Toggle starred'];

@Entry
@Component
struct ArticleListSettingsPage {
  @State private swipeLeft: string = 'Toggle starred';
  @State private swipeRight: string = 'Toggle read';
  @State private pickerDirection: string = '';

  aboutToAppear(): void {
    this.load();
  }

  private async store(): Promise<preferences.Preferences> {
    return await preferences.getPreferences(
      getContext(this) as common.UIAbilityContext, { name: STORE },
    );
  }

  private async load(): Promise<void> {
    const store = await this.store();
    this.swipeLeft = await store.get('swipeLeft', 'Toggle starred') as string;
    this.swipeRight = await store.get('swipeRight', 'Toggle read') as string;
  }

  private selectOption(value: string): void {
    const direction = this.pickerDirection;
    if (direction === 'Swipe left') {
      this.swipeLeft = value;
    } else {
      this.swipeRight = value;
    }
    this.pickerDirection = '';
    this.persistOption(direction, value);
  }

  private async persistOption(direction: string, value: string): Promise<void> {
    const store = await this.store();
    if (direction === 'Swipe left') {
      await store.put('swipeLeft', value);
    } else {
      await store.put('swipeRight', value);
    }
    await store.flush();
  }

  private swipeValue(direction: string): string {
    return direction === 'Swipe left' ? this.swipeLeft : this.swipeRight;
  }

  @Builder
  private SettingRow(direction: string) {
    Row() {
      Text(direction).fontSize(17).fontColor('#1F1F1F').layoutWeight(1);
      Text(this.swipeValue(direction)).fontSize(14).fontColor('#666666');
    }.width('100%').height(72).padding({ left: 24, right: 24 })
      .onClick(() => { this.pickerDirection = direction; });
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Column() {
        Row() {
          Button({ type: ButtonType.Circle, stateEffect: true }) {
            Text('←').fontSize(22).fontColor('#1F1F1F');
          }.width(40).height(40).backgroundColor(Color.Transparent).accessibilityText('Back')
            .onClick(() => router.back());
          Text('Article list').fontSize(20).fontWeight(FontWeight.Medium).fontColor('#1F1F1F').margin({ left: 12 });
        }.width('100%').height(56).padding({ left: 8 }).alignItems(VerticalAlign.Center);

        this.SettingRow('Swipe left');
        this.SettingRow('Swipe right');
      }.width('100%').height('100%').backgroundColor('#FFFFFF');

      if (this.pickerDirection.length > 0) {
        Column() {
          Text(this.pickerDirection).fontSize(17).fontWeight(FontWeight.Medium).fontColor('#1F1F1F')
            .width('100%').padding({ left: 20, right: 20, top: 18, bottom: 10 });
          ForEach(OPTIONS, (option: string) => {
            Text(option).fontSize(16).fontColor('#1F1F1F').width('100%')
              .padding({ left: 20, right: 20, top: 14, bottom: 14 })
              .onClick(() => this.selectOption(option));
          }, (option: string) => option);
        }.width(320).backgroundColor('#FFFFFF').borderRadius(12)
          .shadow({ radius: 10, color: '#40000000' });
      }
    }.width('100%').height('100%');
  }
}
