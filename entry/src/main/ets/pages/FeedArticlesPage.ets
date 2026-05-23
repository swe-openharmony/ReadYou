// Page: FeedArticlesPage

import { router } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { MockDataSource } from '../common/MockDataSource';

const TAG = 'FeedArticlesPage';

interface ArticleRow {
  id: string;
  feedName: string;
  timeText: string;
  title: string;
  excerpt: string;
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
  @State private groups: ArticleGroup[] = [];

  aboutToAppear(): void {
    hilog.info(0x0000, TAG, 'FeedArticlesPage mounted');
    this.loadGroups();
  }

  private async loadGroups(): Promise<void> {
    try {
      const data = await MockDataSource.loadJson<ArticlesFile>(this, 'mock_articles.json');
      this.groups = data.groups;
      hilog.info(0x0000, TAG, 'loaded %{public}d article groups from rawfile', this.groups.length);
    } catch (e) {
      hilog.error(0x0000, TAG, 'load failed: %{public}s', String(e));
      this.groups = [];
    }
  }

  private onBack(): void {
    router.back();
  }

  private onMarkAllRead(): void {
    hilog.info(0x0000, TAG, 'TODO mark all as read');
  }

  private onSearch(): void {
    hilog.info(0x0000, TAG, 'TODO open search');
  }

  private onArticleClick(row: ArticleRow): void {
    hilog.info(0x0000, TAG, 'open article %{public}s', row.id);
    // TODO: router.pushUrl({ url: 'pages/ReadingPage', params: { articleId: row.id } });
  }

  @Builder
  private TopBar() {
    Row() {
      Button({ type: ButtonType.Circle, stateEffect: true }) {
        Text('←').fontSize(22).fontColor('#1F1F1F');
      }
      .width(40).height(40).backgroundColor(Color.Transparent)
      .accessibilityText('Back')
      .onClick(() => this.onBack());

      Blank().layoutWeight(1);

      Button({ type: ButtonType.Circle, stateEffect: true }) {
        Text('✓').fontSize(20).fontColor('#1F1F1F');
      }
      .width(40).height(40).backgroundColor(Color.Transparent)
      .accessibilityText('Mark all as read')
      .onClick(() => this.onMarkAllRead());

      Button({ type: ButtonType.Circle, stateEffect: true }) {
        Text('\u{1F50D}').fontSize(18).fontColor('#1F1F1F');
      }
      .width(40).height(40).backgroundColor(Color.Transparent)
      .margin({ left: 4 })
      .accessibilityText('Search')
      .onClick(() => this.onSearch());
    }
    .width('100%')
    .height(56)
    .padding({ left: 8, right: 8 })
    .alignItems(VerticalAlign.Center)
    .backgroundColor('#FFFFFF');
  }

  @Builder
  private Headline() {
    Column() {
      Text('Unread')
        .fontSize(36)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1F1F1F');
    }
    .width('100%')
    .padding({ left: 24, right: 24, top: 8, bottom: 24 })
    .alignItems(HorizontalAlign.Start);
  }

  @Builder
  private DateHeader(label: string) {
    Row() {
      Text(label)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor('#444444');
    }
    .width('100%')
    .padding({ left: 48, right: 24, top: 16, bottom: 8 })
    .backgroundColor('#FFFFFF');
  }

  @Builder
  private ArticleCard(row: ArticleRow) {
    Row() {
      Column() {
        Row() {
          Text(row.feedName)
            .fontSize(13)
            .fontColor('#666666')
            .layoutWeight(1)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis });
          Text(row.timeText)
            .fontSize(13)
            .fontColor('#888888')
            .margin({ left: 8 });
        }
        .width('100%')
        .margin({ bottom: 8 });

        // Small feed icon stripe + title
        Row() {
          Column()
            .width(20)
            .height(20)
            .borderRadius(10)
            .backgroundColor('#1976D2')
            .margin({ right: 12 });
          Text(row.title)
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor('#1F1F1F')
            .layoutWeight(1)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis });
        }
        .width('100%')
        .alignItems(VerticalAlign.Center);

        Text(row.excerpt)
          .fontSize(13)
          .fontColor('#666666')
          .margin({ top: 6, left: 32 })
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis });
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start);

      // Thumbnail placeholder square on the right
      Column()
        .width(72)
        .height(72)
        .borderRadius(8)
        .backgroundColor('#E0E0E0')
        .margin({ left: 12 });
    }
    .width('100%')
    .padding({ left: 24, right: 24, top: 12, bottom: 16 })
    .alignItems(VerticalAlign.Top)
    .backgroundColor('#FFFFFF')
    .onClick(() => this.onArticleClick(row));
  }

  @Builder
  private FilterSegment() {
    Row() {
      this.FilterChip('starred', '★', 'Starred');
      this.FilterChip('unread', '○', 'Unread');
      this.FilterChip('all', '☰', 'All');
    }
    .width('100%')
    .height(64)
    .padding({ left: 24, right: 24 })
    .justifyContent(FlexAlign.SpaceAround)
    .alignItems(VerticalAlign.Center)
    .backgroundColor('#F4F4F4');
  }

  @Builder
  private FilterChip(tab: FilterTab, glyph: string, label: string) {
    Row() {
      Text(glyph).fontSize(16).fontColor(this.filter === tab ? '#FFFFFF' : '#1F1F1F');
      Text(label)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.filter === tab ? '#FFFFFF' : '#1F1F1F')
        .margin({ left: 6 });
    }
    .padding({ left: 16, right: 16, top: 8, bottom: 8 })
    .borderRadius(20)
    .backgroundColor(this.filter === tab ? '#1976D2' : Color.Transparent)
    .onClick(() => { this.filter = tab; });
  }

  build() {
    Column() {
      this.TopBar();

      List() {
        ListItem() {
          this.Headline();
        }

        ForEach(this.groups, (g: ArticleGroup) => {
          ListItem() {
            this.DateHeader(g.dateLabel);
          }
          ForEach(g.rows, (row: ArticleRow) => {
            ListItem() {
              this.ArticleCard(row);
            }
          }, (row: ArticleRow) => row.id);
        }, (g: ArticleGroup) => g.dateLabel);
      }
      .layoutWeight(1)
      .width('100%')
      .divider({ strokeWidth: 0.5, color: '#EEEEEE', startMargin: 24, endMargin: 24 });

      this.FilterSegment();
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF');
  }
}
