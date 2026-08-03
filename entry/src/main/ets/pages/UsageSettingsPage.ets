import { router } from '@kit.ArkUI';

@Entry
@Component
struct UsageSettingsPage {
  build() {
    Column() {
      Row() {
        Button({ type: ButtonType.Circle, stateEffect: true }) {
          Text('←').fontSize(22).fontColor('#1F1F1F');
        }.width(40).height(40).backgroundColor(Color.Transparent).accessibilityText('Back')
          .onClick(() => router.back());
        Text('Usage').fontSize(20).fontWeight(FontWeight.Medium).fontColor('#1F1F1F').margin({ left: 12 });
      }.width('100%').height(56).padding({ left: 8 }).alignItems(VerticalAlign.Center);

      Row() {
        Text('Article list').fontSize(17).fontColor('#1F1F1F').layoutWeight(1);
        Text('›').fontSize(22).fontColor('#666666');
      }.width('100%').height(72).padding({ left: 24, right: 24 })
        .onClick(() => router.pushUrl({ url: 'pages/ArticleListSettingsPage' }));
    }.width('100%').height('100%').backgroundColor('#FFFFFF');
  }
}
