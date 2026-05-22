// ====================================================================
// Page: Index (ReadYou L0 Home — Feeds main)
// Android baseline: D:/OH-Appforge/_doc_screenshots_v2/ReadYou/L0_home.png
// Layout contract:
//   - Top action row: gear ⚙ (left) + add ＋ (right)
//   - Large title "Read You"
//   - Filter chip card "Unread" / "10 unread items" / "›"
//   - Section header "Feeds" + expand-collapse ⌃⌄
//   - Feed group card "Default" with expanded child:
//       favicon + "ReadYou Releases" + count "10"
//   - Bottom nav 3 tabs: ★ (Starred) | ● (Articles, active) | ☰ (Feeds)
// Navigation:
//   - Gear ⚙ → AccountsPage   (account/settings hub entry)
//   - Add ＋ → ColorStylePage  (style/personalization entry)
//   - "ReadYou Releases" row → FeedArticlesPage
// ====================================================================

import { router } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { MockDataSource } from '../common/MockDataSource';

const TAG = 'ReadYouIndex';

interface FeedRow {
  id: string;
  title: string;
  unread: number;
}

interface FeedGroup {
  name: string;
  expanded: boolean;
  feeds: FeedRow[];
}

interface HomeFile {
  unreadCount: number;
  groups: FeedGroup[];
}

@Entry
@Component
struct Index {
  @State private unreadCount: number = 10;
  @State private groups: FeedGroup[] = [];
  @State private feedsExpanded: boolean = true;
  @State private groupExpanded: Map<string, boolean> = new Map<string, boolean>();

  aboutToAppear(): void {
    hilog.info(0x0000, TAG, 'ReadYou L0 home mounted');
    this.loadHome();
  }

  private async loadHome(): Promise<void> {
    try {
      const data = await MockDataSource.loadJson<HomeFile>(this, 'mock_home.json');
      this.unreadCount = data.unreadCount;
      this.groups = data.groups;
    } catch (e) {
      hilog.error(0x0000, TAG, 'load failed: %{public}s', String(e));
      this.groups = [{
        name: 'Default', expanded: true,
        feeds: [{ id: 'rels', title: 'ReadYou Releases', unread: 10 }],
      }];
    }
  }

  private openFeed(feed: FeedRow): void {
    hilog.info(0x0000, TAG, 'open feed → FeedArticlesPage id=%{public}s', feed.id);
    router.pushUrl({ url: 'pages/FeedArticlesPage', params: { feedId: feed.id, feedTitle: feed.title } });
  }

  private openUnreadFilter(): void {
    hilog.info(0x0000, TAG, 'unread filter → FeedArticlesPage (filter=unread)');
    router.pushUrl({ url: 'pages/FeedArticlesPage', params: { feedId: 'all', feedTitle: 'Unread', filter: 'unread' } });
  }

  private toggleGroup(name: string): void {
    const cur: boolean = this.groupExpanded.get(name) ?? true;
    const next = new Map<string, boolean>();
    this.groupExpanded.forEach((v: boolean, k: string) => next.set(k, v));
    next.set(name, !cur);
    this.groupExpanded = next;
    hilog.info(0x0000, TAG, 'toggle group %{public}s -> %{public}s', name, String(!cur));
  }

  private isGroupExpanded(name: string): boolean {
    return this.groupExpanded.get(name) ?? true;
  }

  @Builder
  private TopActions() {
    Row() {
      Text('⚙').fontSize(22).fontColor('#1F1F1F').width(48).height(48).textAlign(TextAlign.Center)
        .accessibilityText('Accounts and settings')
        .onClick(() => {
          hilog.info(0x0000, TAG, 'gear → AccountsPage');
          router.pushUrl({ url: 'pages/AccountsPage' });
        });
      Blank().layoutWeight(1);
      Text('＋').fontSize(22).fontColor('#1F1F1F').width(48).height(48).textAlign(TextAlign.Center)
        .accessibilityText('Personalize colors')
        .onClick(() => {
          hilog.info(0x0000, TAG, 'add → ColorStylePage');
          router.pushUrl({ url: 'pages/ColorStylePage' });
        });
    }
    .width('100%').height(56).padding({ left: 8, right: 8 });
  }

  @Builder
  private BigTitle() {
    Text('Read You')
      .fontSize(40)
      .fontWeight(FontWeight.Normal)
      .fontColor('#1F1F1F')
      .padding({ left: 16, top: 32, bottom: 24 })
      .width('100%')
      .onClick(() => {
        hilog.info(0x0000, TAG, 'TODO: scroll-to-top / refresh feeds');
      });
  }

  @Builder
  private UnreadCard() {
    Row() {
      Text('○').fontSize(22).fontColor('#3A4CA8').width(40).textAlign(TextAlign.Center);
      Column() {
        Text('Unread').fontSize(20).fontColor('#1F1F1F');
        Text(`${this.unreadCount} unread items`).fontSize(13).fontColor('#666666').margin({ top: 4 });
      }
      .alignItems(HorizontalAlign.Start).layoutWeight(1).margin({ left: 4 });
      Text('›').fontSize(22).fontColor('#1F1F1F').margin({ right: 16 });
    }
    .width('92%').height(80)
    .alignItems(VerticalAlign.Center)
    .backgroundColor('#DCE3F7').borderRadius(40)
    .margin({ left: 16, right: 16, bottom: 16 })
    .onClick(() => this.openUnreadFilter());
  }

  @Builder
  private FeedsHeader() {
    Row() {
      Text('Feeds').fontSize(14).fontColor('#3A4CA8').layoutWeight(1);
      Text(this.feedsExpanded ? '⌃' : '⌄')
        .fontSize(16).fontColor('#3A4CA8')
        .onClick(() => { this.feedsExpanded = !this.feedsExpanded; });
    }
    .width('100%').padding({ left: 16, right: 24, top: 8, bottom: 8 })
    .onClick(() => { this.feedsExpanded = !this.feedsExpanded; });
  }

  @Builder
  private FeedGroupCard(group: FeedGroup) {
    Column() {
      Row() {
        Text(group.name).fontSize(18).fontColor('#1F1F1F').layoutWeight(1);
        Text(this.isGroupExpanded(group.name) ? '⌃' : '⌄').fontSize(14).fontColor('#1F1F1F')
          .width(28).height(28).textAlign(TextAlign.Center)
          .borderRadius(14).backgroundColor('#D8DEEF')
          .onClick(() => this.toggleGroup(group.name));
      }
      .width('100%').padding({ left: 16, right: 16, top: 14, bottom: 10 })
      .onClick(() => this.toggleGroup(group.name));

      if (this.feedsExpanded && this.isGroupExpanded(group.name)) {
        ForEach(group.feeds, (feed: FeedRow) => {
          Row() {
            // favicon dot
            Text('★').fontSize(12).fontColor('#1F1F1F')
              .width(28).height(28).textAlign(TextAlign.Center)
              .backgroundColor('#FFFFFF').borderRadius(14)
              .margin({ left: 16, right: 12 });
            Text(feed.title).fontSize(16).fontColor('#1F1F1F').layoutWeight(1);
            Text(`${feed.unread}`).fontSize(13).fontColor('#666666')
              .padding({ left: 8, right: 8, top: 2, bottom: 2 })
              .backgroundColor('#FFFFFF').borderRadius(10)
              .margin({ right: 16 });
          }
          .width('100%').height(56).alignItems(VerticalAlign.Center)
          .onClick(() => this.openFeed(feed));
        }, (feed: FeedRow) => feed.id);
      }
    }
    .width('92%').backgroundColor('#E9E9EE').borderRadius(16).margin({ left: 16, right: 16, bottom: 12 });
  }

  @Builder
  private BottomNav() {
    Row() {
      Column() { Text('★').fontSize(20).fontColor('#1F1F1F'); }
        .layoutWeight(1).height(56).justifyContent(FlexAlign.Center)
        .onClick(() => console.info('TODO: starred'));
      Column() {
        Text('●').fontSize(20).fontColor('#1F1F1F')
          .width(48).height(32).textAlign(TextAlign.Center)
          .backgroundColor('#DCE3F7').borderRadius(16);
      }
      .layoutWeight(1).height(56).justifyContent(FlexAlign.Center)
      .onClick(() => console.info('TODO: feeds tab (current)'));
      Column() { Text('☰').fontSize(20).fontColor('#1F1F1F'); }
        .layoutWeight(1).height(56).justifyContent(FlexAlign.Center)
        .onClick(() => console.info('TODO: feeds list'));
    }
    .width('100%').height(60).backgroundColor('#F2F1F4');
  }

  build() {
    Column() {
      this.TopActions();
      this.BigTitle();
      this.UnreadCard();
      this.FeedsHeader();
      Scroll() {
        Column() {
          ForEach(this.groups, (g: FeedGroup) => {
            this.FeedGroupCard(g);
          }, (g: FeedGroup) => g.name);
        }
        .width('100%');
      }
      .layoutWeight(1).width('100%');
      this.BottomNav();
    }
    .width('100%').height('100%').backgroundColor('#F2F1F4');
  }
}
