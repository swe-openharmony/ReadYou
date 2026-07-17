// Page: ReaderPage — in-app article reader (FeedArticles 场景五)

import { router } from '@kit.ArkUI';

@Entry
@Component
struct ReaderPage {
  @State private title: string = '';
  @State private content: string = '';

  aboutToAppear(): void {
    const p = router.getParams() as Record<string, string> | undefined;
    if (p) {
      if (p.title) { this.title = p.title; }
      if (p.content) { this.content = p.content; }
    }
  }

  build() {
    Column() {
      Row() {
        Button({ type: ButtonType.Circle, stateEffect: true }) {
          Text('←').fontSize(22).fontColor('#1F1F1F');
        }.width(40).height(40).backgroundColor(Color.Transparent).accessibilityText('Back')
          .onClick(() => router.back());
        Text('Reading').fontSize(16).fontColor('#666666').margin({ left: 8 });
      }.width('100%').height(56).padding({ left: 8 }).alignItems(VerticalAlign.Center).backgroundColor('#FFFFFF');

      Scroll() {
        Column() {
          Text(this.title).fontSize(24).fontWeight(FontWeight.Bold).fontColor('#1F1F1F')
            .width('100%').margin({ bottom: 16 });
          Text(this.content).fontSize(15).fontColor('#333333').width('100%');
        }.width('100%').padding(24).alignItems(HorizontalAlign.Start);
      }.layoutWeight(1).width('100%');
    }
    .width('100%').height('100%').backgroundColor('#FFFFFF');
  }
}
