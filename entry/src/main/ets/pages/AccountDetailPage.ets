// Page: AccountDetailPage — account detail stub (out of spec scope; nav target only)

import { router } from '@kit.ArkUI';

@Entry
@Component
struct AccountDetailPage {
  @State private name: string = '';

  aboutToAppear(): void {
    const p = router.getParams() as Record<string, string> | undefined;
    if (p && p.name) { this.name = p.name; }
  }

  build() {
    Column() {
      Row() {
        Button({ type: ButtonType.Circle, stateEffect: true }) {
          Text('←').fontSize(22).fontColor('#1F1F1F');
        }.width(40).height(40).backgroundColor(Color.Transparent).accessibilityText('Back')
          .onClick(() => router.back());
        Text('Account detail').fontSize(20).fontWeight(FontWeight.Medium).fontColor('#1F1F1F').margin({ left: 12 });
      }.width('100%').height(56).padding({ left: 8 }).alignItems(VerticalAlign.Center).backgroundColor('#FFFFFF');

      Text(this.name).fontSize(18).fontColor('#1F1F1F').padding(24);
    }.width('100%').height('100%').backgroundColor('#FFFFFF');
  }
}
