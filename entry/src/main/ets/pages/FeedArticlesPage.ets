// Page: FeedArticlesPage

import { router } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { common, Want } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { MockDataSource } from '../common/MockDataSource';

const SWIPE_STORE = 'readyou_article_list';

const TAG = 'FeedArticlesPage';

interface ArticleRow {
  id: string;
  feedName: string;
  timeText: string;
  title: string;
  excerpt: string;
  link: string;
  ageDays: number;
  read: boolean;
  starred: boolean;
}

interface ArticleGroup {
  dateLabel: string;
  rows: ArticleRow[];
}

interface ArticlesFile {
  groups: ArticleGroup[];
}

type FilterTab = 'starred' | 'unread' | 'all';

@Entry
@Component
struct FeedArticlesPage {
  @State private filter: FilterTab = 'unread';
  @State private allGroups: ArticleGroup[] = [];
  @State private readIds: string[] = [];
  @State private starredIds: string[] = [];
  @State private batchBarOpen: boolean = false;
  @State private contextOpen: boolean = false;
  @State private contextId: string = '';
  @State private feedTitle: string = 'Feed';
  @State private browserFeed: boolean = false;
  @State private browserOpenedTitle: string = '';
  @State private swipeLeft: string = 'Toggle starred';
  @State private swipeRight: string = 'Toggle read';
  private listScroller: Scroller = new Scroller();

  aboutToAppear(): void {
    const p = router.getParams() as Record<string, string> | undefined;
    if (p && p.feedTitle) { this.feedTitle = p.feedTitle; }
    if (p && p.browserFeed === 'true') { this.browserFeed = true; }
    this.loadGroups();
    this.loadSwipeSettings();
  }

  private async loadSwipeSettings(): Promise<void> {
    const store = await preferences.getPreferences(
      getContext(this) as common.UIAbilityContext, { name: SWIPE_STORE },
    );
    this.swipeLeft = await store.get('swipeLeft', 'Toggle starred') as string;
    this.swipeRight = await store.get('swipeRight', 'Toggle read') as string;
  }

  private async loadGroups(): Promise<void> {
    try {
      const data = await MockDataSource.loadJson<ArticlesFile>(this, 'mock_articles.json');
      this.allGroups = data.groups;
      const rd: string[] = [];
      const st: string[] = [];
      for (const g of data.groups) {
        for (const r of g.rows) {
          if (r.read) { rd.push(r.id); }
          if (r.starred) { st.push(r.id); }
        }
      }
      this.readIds = rd;
      this.starredIds = st;
    } catch (e) {
      hilog.error(0x0000, TAG, 'load failed: %{public}s', String(e));
      this.allGroups = [];
    }
  }

  private isRead(id: string): boolean { return this.readIds.includes(id); }
  private isStarred(id: string): boolean { return this.starredIds.includes(id); }

  private rowVisible(r: ArticleRow): boolean {
    if (this.filter === 'starred') { return this.isStarred(r.id); }
    if (this.filter === 'unread') { return !this.isRead(r.id); }
    return true;
  }

  private displayGroups(): ArticleGroup[] {
    const out: ArticleGroup[] = [];
    for (const g of this.allGroups) {
      const rows = g.rows.filter((r: ArticleRow) => this.rowVisible(r));
      if (rows.length > 0) {
        const ng: ArticleGroup = { dateLabel: g.dateLabel, rows: rows };
        out.push(ng);
      }
    }
    return out;
  }

  private headline(): string {
    if (this.filter === 'starred') { return 'Starred'; }
    if (this.filter === 'all') { return 'All'; }
    return 'Unread';
  }

  private flatIds(): string[] {
    const ids: string[] = [];
    for (const g of this.allGroups) {
      for (const r of g.rows) { ids.push(r.id); }
    }
    return ids;
  }

  private toggleRead(id: string): void {
    if (this.readIds.includes(id)) {
      this.readIds = this.readIds.filter((x: string) => x !== id);
    } else {
      this.readIds = this.readIds.concat([id]);
    }
    this.contextOpen = false;
  }

  private toggleStar(id: string): void {
    if (this.starredIds.includes(id)) {
      this.starredIds = this.starredIds.filter((x: string) => x !== id);
    } else {
      this.starredIds = this.starredIds.concat([id]);
    }
    this.contextOpen = false;
  }

  private markAboveBelow(id: string, above: boolean): void {
    const ids = this.flatIds();
    const idx = ids.indexOf(id);
    if (idx < 0) { return; }
    const slice = above ? ids.slice(0, idx) : ids.slice(idx + 1);
    let acc = this.readIds.slice();
    for (const x of slice) { if (!acc.includes(x)) { acc = acc.concat([x]); } }
    this.readIds = acc;
    this.contextOpen = false;
  }

  private markAllInRange(maxAgeDays: number): void {
    let next = this.readIds.slice();
    for (const group of this.allGroups) {
      for (const row of group.rows) {
        if (maxAgeDays === 0 || row.ageDays >= maxAgeDays) {
          if (!next.includes(row.id)) { next = next.concat([row.id]); }
        }
      }
    }
    this.readIds = next;
    this.batchBarOpen = false;
  }

  private openExternal(row: ArticleRow): void {
    const ctx = getContext(this) as common.UIAbilityContext;
    const want: Want = { action: 'ohos.want.action.viewData', uri: row.link };
    this.browserOpenedTitle = row.title;
    ctx.startAbility(want).catch((e: Object) => {
      hilog.error(0x0000, TAG, 'open browser failed: %{public}s', String(e));
    });
  }

  private onArticleTap(row: ArticleRow): void {
    if (!this.readIds.includes(row.id)) { this.readIds = this.readIds.concat([row.id]); }
    if (this.browserFeed) {
      this.openExternal(row);
      return;
    }
    router.pushUrl({ url: 'pages/ReaderPage', params: { title: row.title, content: row.excerpt } });
  }

  private applySwipeAction(row: ArticleRow, action: string): void {
    if (action === 'Toggle read') {
      this.toggleRead(row.id);
    } else if (action === 'Toggle starred') {
      this.toggleStar(row.id);
    }
  }

  private onSwipe(row: ArticleRow, offsetX: number): void {
    if (offsetX < -80) {
      this.applySwipeAction(row, this.swipeLeft);
    } else if (offsetX > 80) {
      this.applySwipeAction(row, this.swipeRight);
    }
  }

  private selectFilter(tab: FilterTab): void {
    this.batchBarOpen = false;
    if (this.filter === tab) {
      this.listScroller.scrollToIndex(0);
      return;
    }
    this.filter = tab;
    this.listScroller.scrollToIndex(0);
  }

  private rangeDays(label: string): number {
    if (label === '7 Days') { return 7; }
    if (label === '3 Days') { return 3; }
    if (label === '1 Day') { return 1; }
    return 0;
  }

  onBackPress(): boolean {
    if (this.contextOpen) { this.contextOpen = false; return true; }
    if (this.batchBarOpen) { this.batchBarOpen = false; return true; }
    return false;
  }

  @Builder
  private TopBar() {
    Row() {
      Button({ type: ButtonType.Circle, stateEffect: true }) {
        Text('←').fontSize(22).fontColor('#1F1F1F');
      }.width(40).height(40).backgroundColor(Color.Transparent).accessibilityText('Back')
        .onClick(() => router.back());

      Text(this.feedTitle).fontSize(16).fontColor('#666666').layoutWeight(1).margin({ left: 8 })
        .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis });

      if (this.filter !== 'starred') {
        Button({ type: ButtonType.Circle, stateEffect: true }) {
          Text('✓').fontSize(20).fontColor('#1F1F1F');
        }.width(40).height(40).backgroundColor(Color.Transparent).accessibilityText('Mark all as read')
          .id('mark_all_action').onClick(() => {
            this.contextOpen = false;
            this.batchBarOpen = !this.batchBarOpen;
            if (this.batchBarOpen) { this.listScroller.scrollToIndex(0); }
          });
      }
      Button({ type: ButtonType.Circle, stateEffect: true }) {
        Text('\u{1F50D}').fontSize(18).fontColor('#1F1F1F');
      }.width(40).height(40).backgroundColor(Color.Transparent).margin({ left: 4 }).accessibilityText('Search');
    }
    .width('100%').height(56).padding({ left: 8, right: 8 }).alignItems(VerticalAlign.Center).backgroundColor('#FFFFFF');
  }

  @Builder
  private BatchBar() {
    Row() {
      ForEach(['7 Days', '3 Days', '1 Day', 'Mark All as Read'], (label: string) => {
        Text(label).fontSize(13).fontColor('#1976D2')
          .padding({ left: 12, right: 12, top: 8, bottom: 8 })
          .id(`mark_range_${this.rangeDays(label)}`)
          .onClick(() => this.markAllInRange(this.rangeDays(label)));
      }, (label: string) => label);
    }
    .width('100%').justifyContent(FlexAlign.SpaceAround).alignItems(VerticalAlign.Center)
    .height(44).backgroundColor('#EAF2FB');
  }

  @Builder
  private DateHeader(label: string) {
    Row() {
      Text(label).fontSize(14).fontWeight(FontWeight.Medium).fontColor('#444444');
    }.width('100%').padding({ left: 48, right: 24, top: 16, bottom: 8 }).backgroundColor('#FFFFFF');
  }

  @Builder
  private ArticleCard(row: ArticleRow) {
    Row() {
      Column() {
        Row() {
          if (this.isStarred(row.id)) {
            Text('★').fontSize(13).fontColor('#F5A623').margin({ right: 4 });
          }
          Text(row.feedName).fontSize(13).fontColor('#666666').layoutWeight(1).maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis });
          Text(row.timeText).fontSize(13).fontColor('#888888').margin({ left: 8 });
        }.width('100%').margin({ bottom: 8 });

        Text(row.title).id(`article_${row.id}`).accessibilityText(`${row.title} ${this.isRead(row.id) ? 'read' : 'unread'} ${this.isStarred(row.id) ? 'starred' : 'not starred'}`).fontSize(18)
          .fontWeight(this.isRead(row.id) ? FontWeight.Regular : FontWeight.Medium)
          .fontColor(this.isRead(row.id) ? '#9AA0A6' : '#1F1F1F')
          .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis });
        Text(row.excerpt).fontSize(13).fontColor('#666666').margin({ top: 6 })
          .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis });
      }.layoutWeight(1).alignItems(HorizontalAlign.Start);
    }
    .width('100%').padding({ left: 24, right: 24, top: 12, bottom: 16 })
    .alignItems(VerticalAlign.Top).backgroundColor('#FFFFFF')
    .onClick(() => this.onArticleTap(row))
    // Both long-press (context menu) and horizontal swipe (toggle) must work →
    // combine in a parallel GestureGroup (a 2nd bare .gesture() would be ignored).
    .gesture(GestureGroup(GestureMode.Parallel,
      LongPressGesture({ repeat: false }).onAction(() => { this.contextId = row.id; this.contextOpen = true; }),
      PanGesture({ direction: PanDirection.Horizontal }).onActionEnd((e: GestureEvent) => this.onSwipe(row, e.offsetX))
    ));
  }

  @Builder
  private FilterChip(tab: FilterTab, glyph: string, label: string) {
    Row() {
      Text(glyph).fontSize(16).fontColor(this.filter === tab ? '#FFFFFF' : '#1F1F1F');
      Text(label).fontSize(14).fontWeight(FontWeight.Medium)
        .fontColor(this.filter === tab ? '#FFFFFF' : '#1F1F1F').margin({ left: 6 });
    }
    .padding({ left: 16, right: 16, top: 8, bottom: 8 }).borderRadius(20)
    .backgroundColor(this.filter === tab ? '#1976D2' : Color.Transparent)
    .id(`filter_${tab}`).accessibilityText(`${label} filter ${this.filter === tab ? 'selected' : 'not selected'}`)
    .onClick(() => this.selectFilter(tab));
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Column() {
        this.TopBar();

        List({ scroller: this.listScroller }) {
          if (this.batchBarOpen) {
            ListItem() { this.BatchBar(); }
          }
          ListItem() {
            Column() {
              Text(this.headline()).fontSize(36).fontWeight(FontWeight.Bold).fontColor('#1F1F1F')
                .id('feed_page_signature');
            }.width('100%').padding({ left: 24, right: 24, top: 8, bottom: 24 }).alignItems(HorizontalAlign.Start);
          }
          ForEach(this.displayGroups(), (g: ArticleGroup) => {
            ListItem() { this.DateHeader(g.dateLabel); }
            ForEach(g.rows, (row: ArticleRow) => {
              ListItem() { this.ArticleCard(row); }
            }, (row: ArticleRow) => row.id);
          }, (g: ArticleGroup) => g.dateLabel);
        }
        .layoutWeight(1).width('100%').divider({ strokeWidth: 0.5, color: '#EEEEEE', startMargin: 24, endMargin: 24 })
        .onTouch((event: TouchEvent) => {
          if (this.batchBarOpen && event.type === TouchType.Move) {
            this.batchBarOpen = false;
          }
        });

        Row() {
          this.FilterChip('starred', '★', 'Starred');
          this.FilterChip('unread', '○', 'Unread');
          this.FilterChip('all', '☰', 'All');
        }
        .width('100%').height(64).padding({ left: 24, right: 24 })
        .justifyContent(FlexAlign.SpaceAround).alignItems(VerticalAlign.Center).backgroundColor('#F4F4F4');
      }
      .width('100%').height('100%').backgroundColor('#FFFFFF');

      if (this.contextOpen) {
        Column() {
          this.CtxItem('Toggle read', () => this.toggleRead(this.contextId));
          this.CtxItem('Toggle starred', () => this.toggleStar(this.contextId));
          if (this.flatIds().indexOf(this.contextId) > 0) {
            this.CtxItem('Mark above as read', () => this.markAboveBelow(this.contextId, true));
          }
          if (this.flatIds().indexOf(this.contextId) < this.flatIds().length - 1) {
            this.CtxItem('Mark below as read', () => this.markAboveBelow(this.contextId, false));
          }
          this.CtxItem('Share', () => { this.contextOpen = false; });
        }
        .id('article_context_menu').width(260).backgroundColor('#FFFFFF').borderRadius(8)
        .shadow({ radius: 8, color: '#40000000' });
      }
      if (this.browserOpenedTitle.length > 0) {
        Text(`Opened in browser: ${this.browserOpenedTitle}`).id('browser_open_signal')
          .fontSize(12).fontColor('#666666').position({ x: 8, y: 8 });
      }
    }
    .width('100%').height('100%');
  }

  @Builder
  private CtxItem(label: string, onTap: () => void) {
    Text(label).width('100%').fontSize(15).fontColor('#1F1F1F')
      .padding({ left: 20, right: 20, top: 14, bottom: 14 }).onClick(() => onTap());
  }
}
