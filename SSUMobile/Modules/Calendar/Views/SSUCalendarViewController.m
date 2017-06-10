//
//  SSUCalendarMonthViewController.m
//  SSUMobile
//
//  Created by Eric Amorde on 9/28/14.
//  Copyright (c) 2014 Sonoma State University Department of Computer Science. All rights reserved.
//

#import "SSUCalendarViewController.h"
#import "SSUSelectionController.h"
#import "SSUMobile-Swift.h"

#import <Masonry/Masonry.h>

static NSString * const SSUEventDetailSegue = @"event";
static NSString * const EventCellIdentifier = @"EventCell";

static CGFloat TABLE_HEADER_HEIGHT = 25.0;
static CGFloat CELL_ROW_HEIGHT = 50;

// Hack to get access to date property
@interface PDTSimpleCalendarViewController ()

- (NSDate *) dateForCellAtIndexPath:(NSIndexPath *)indexPath;
- (BOOL)isEnabledDate:(NSDate *)date;

@end

@interface SSUCalendarViewController () <PDTSimpleCalendarViewDelegate,UITableViewDataSource,UITableViewDelegate, SSUSelectionDelegate>

@property (nonatomic, strong) id selectedEvent;
@property (nonatomic) NSArray * unfilteredEvents;
@property (nonatomic) NSArray * events;
@property (nonatomic) NSArray * selectedEvents;
@property (nonatomic) NSPredicate * predicate;

@end

@implementation SSUCalendarViewController

- (void) loadEvents
{
    NSFetchRequest * fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"SSUEvent"];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"startDate" ascending:YES]];
    NSManagedObjectContext * context = [[SSUCalendarModule sharedInstance] backgroundContext];
    [context performBlock:^{
        self.unfilteredEvents = [context executeFetchRequest:fetchRequest error:nil];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self reloadEventTableView];
            [self.collectionView reloadData];
        });
    }];
}

- (void) viewDidLoad {
    // We have to do these two lines before [super viewDidLoad] for it to show up :/
    self.weekdayHeaderEnabled = YES;
    [self applyStyles];
    [super viewDidLoad];
    
    self.delegate = self;
    self.navigationItem.title = @"Seawolf Calendar";
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStylePlain];
    [self.view addSubview:self.tableView];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.hidden = YES;
    UINib * cellNib = [UINib nibWithNibName:NSStringFromClass([SSUCalendarEventCell class]) bundle:nil];
    [self.tableView registerNib:cellNib forCellReuseIdentifier:EventCellIdentifier];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(self.view.mas_height).multipliedBy(1/3.0);
        make.width.equalTo(self.view.mas_width);
        make.bottom.equalTo(self.view.mas_bottom);
    }];
    
    UIBarButtonItem * filterButton = [[UIBarButtonItem alloc] initWithTitle:@"Filter" style:UIBarButtonItemStyleDone target:self action:@selector(filterButtonPressed:)];
    self.navigationItem.rightBarButtonItem = filterButton;
    
    [self loadEvents];
    self.selectedDate = [NSDate date];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.selectedDate == nil) {
        self.selectedDate = [NSDate date];
    }
    
    const NSTimeInterval lastUpdate = [[[SSUConfiguration sharedInstance] calendarLastUpdate] timeIntervalSinceNow];
    const NSTimeInterval updateInterval = -1 * 60 * 5;
    if (lastUpdate <= updateInterval) {
        [[SSUCalendarModule sharedInstance] updateData:^{
            [self loadEvents];
        }];
    }
}

- (void) applyStyles {
    [[PDTSimpleCalendarViewCell appearance] setCircleTodayColor:[UIColor blackColor]];
    [[PDTSimpleCalendarViewCell appearance] setCircleSelectedColor:SSU_BLUE_COLOR];
    
    [[PDTSimpleCalendarViewHeader appearance] setTextColor:SSU_BLUE_COLOR];
    [[PDTSimpleCalendarViewHeader appearance] setSeparatorColor:[UIColor clearColor]];

    [[PDTSimpleCalendarViewWeekdayHeader appearance] setHeaderBackgroundColor:SSU_BLUE_COLOR];
    [[PDTSimpleCalendarViewWeekdayHeader appearance] setTextColor:[UIColor whiteColor]];
}

- (BOOL)tableViewVisible {
    return !self.tableView.hidden;
}

- (void) reloadEventTableView {
    self.selectedEvents = [self eventsForDate:self.selectedDate];
    [self.tableView reloadData];
    self.tableView.hidden = self.selectedEvents.count == 0;
}

#pragma mark - Filtering

- (void) setPredicate:(NSPredicate *)predicate {
    _predicate = predicate;
    [self.collectionView reloadData];
    [self reloadEventTableView];
}

- (NSArray *) events {
    if (self.predicate) {
        return [self.unfilteredEvents filteredArrayUsingPredicate:self.predicate];
    }
    else {
        return self.unfilteredEvents;
    }
}

#pragma mark - Helper

- (NSDateComponents *) nonTimeComponents:(NSDate *)date {
    static NSCalendarUnit options = NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear;
    NSDateComponents * components = [[NSCalendar currentCalendar] components:options fromDate:date];
    return components;
}

// Returns a date that is the same calendar date but with a time of 00:00:00
- (NSDate *) startOfDay:(NSDate *)date {
    NSDateComponents * components = [self nonTimeComponents:date];
    components.hour = 0;
    components.minute = 0;
    components.second = 0;

    return [[NSCalendar currentCalendar] dateFromComponents:components];;
}

// Returns a date that is the same calendar date but with a time of 23:59:59
- (NSDate *) endOfDay:(NSDate *)date {
    NSDateComponents * components = [self nonTimeComponents:date];
    components.hour = 23;
    components.minute = 59;
    components.second = 59;
    
    return [[NSCalendar currentCalendar] dateFromComponents:components];
}

// Returns an NSArray of event objects whos `startDate` is on the same day as date
- (NSArray *) eventsForDate:(NSDate *)date {
    if (date == nil) {
        return nil;
    }
    NSDate * start = [self startOfDay:date];
    NSDate * end = [self endOfDay:date];
    NSPredicate * predicate = [NSPredicate predicateWithFormat:@"startDate BETWEEN %@", @[start, end]];
    return [self.events filteredArrayUsingPredicate:predicate];
}

#pragma mark - PDTSimpleCalendarViewControllerDelegate

- (void) simpleCalendarViewController:(PDTSimpleCalendarViewController *)controller didSelectDate:(NSDate *)date {
    self.selectedEvents = [self eventsForDate:date];
    [self reloadEventTableView];
}

#pragma mark - UICollectionView

- (BOOL) indexPathIsLastWeek:(NSIndexPath *)indexPath {
    const NSInteger dayCount = [self.collectionView numberOfItemsInSection:indexPath.section] - 1;
    return (dayCount - indexPath.item) < 7;
}

- (BOOL) indexPathIsFirstWeek:(NSIndexPath *)indexPath {
    return indexPath.item < 7;
}

- (UICollectionViewCell *) collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    static const NSInteger labelTag = 1077;
    static const NSInteger separatorTag = 1099;
    PDTSimpleCalendarViewCell * cell = (id)[super collectionView:collectionView cellForItemAtIndexPath:indexPath];
    
    // PDTSimpleCalendar makes it somewhat difficult to use a cell subclass. So instead of making that work,
    // we will use tags to manually add subviews. Not nearly as clean, but it's better than trying to mess with
    // the inner workings of PDTSimpleCalendar. Maybe that will change in the future.
    
    NSDate * date = [self dateForCellAtIndexPath:indexPath];
    const NSUInteger count = [[self eventsForDate:date] count];
    UILabel * label = (UILabel *)[cell.contentView viewWithTag:labelTag];
    if (label == nil) {
        label = [[UILabel alloc] init];
        label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
        label.textColor = [UIColor lightGrayColor];
        label.tag = labelTag;
        label.minimumScaleFactor = .50;
        label.adjustsFontSizeToFitWidth = YES;
        label.textAlignment = NSTextAlignmentCenter;
        [cell.contentView addSubview:label];
        [label mas_makeConstraints:^(MASConstraintMaker *make) {
            const CGFloat margin = 1.0;
            UILabel * dayLabel = [cell valueForKey:@"dayLabel"];
            make.top.equalTo(label.superview.mas_top);
            make.right.equalTo(label.superview.mas_right).with.offset(-margin);
            make.bottom.greaterThanOrEqualTo(dayLabel.mas_top).with.offset(-margin);
            make.left.greaterThanOrEqualTo(dayLabel.mas_right).with.offset(margin);
        }];
        [cell.contentView bringSubviewToFront:label];
    }
    NSString * eventText = [NSString stringWithFormat:@"%lu", (unsigned long)count];
    label.text = (count > 0) ? eventText : @"";
    
    // If we are on the overflow days (ex. before first day of month or after last day of month)
    // then we shouldn't show the event label
    label.hidden = [cell valueForKey:@"date"] == nil; // If only we actually had access to this..
    
    SSUCollectionCellSeparatorView * separatorView = (id)[cell viewWithTag:separatorTag];
    if (separatorView == nil) {
        separatorView = [[SSUCollectionCellSeparatorView alloc] initWithFrame:cell.bounds];
        [cell addSubview:separatorView];
        [cell sendSubviewToBack:separatorView];
        separatorView.separatorColor = [UIColor lightGrayColor];
    }
    
    SSUCellSeparator separatorSides = SSUCellSeparatorTop;
    if ([self indexPathIsLastWeek:indexPath]) {
        separatorSides |= SSUCellSeparatorBottom;
    }
    if (!(indexPath.item % 7 == 0)) {
        // Don't draw a border on the first day if we don't need it
        separatorSides |= SSUCellSeparatorLeft;
    }
    separatorView.separator = separatorSides;
    
    return cell;
}

#pragma mark - UITableView

- (void) tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    UITableViewHeaderFooterView * header = (UITableViewHeaderFooterView *)view;
    header.tintColor = [UIColor whiteColor];
    header.contentView.backgroundColor = SSU_BLUE_COLOR;
    header.textLabel.textColor = [UIColor whiteColor];
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return TABLE_HEADER_HEIGHT;
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString * formattedDate = [NSDateFormatter localizedStringFromDate:self.selectedDate
                                                              dateStyle:NSDateFormatterShortStyle
                                                              timeStyle:NSDateFormatterNoStyle];
    
    return [NSString stringWithFormat:@"%lu events on %@",(unsigned long)self.selectedEvents.count,formattedDate];;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.selectedEvents.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SSUCalendarEventCell *eventCell = [tableView dequeueReusableCellWithIdentifier:EventCellIdentifier forIndexPath:indexPath];
    SSUEvent *event = self.selectedEvents[indexPath.row];
    eventCell.event = event;
    
    return eventCell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    self.selectedEvent = self.selectedEvents[indexPath.row];
    //[self performSegueWithIdentifier:SSUEventDetailSegue sender:self];
    
    UIStoryboard * storyboard = self.storyboard;
    SSUCalendarEventDetailController * detailViewController = [storyboard instantiateViewControllerWithIdentifier:NSStringFromClass([SSUCalendarEventDetailController class])];
    detailViewController.event = self.selectedEvent;
    [self.navigationController pushViewController:detailViewController animated:YES];
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return CELL_ROW_HEIGHT;
}

#pragma mark - SSUSelectionDelegate

- (void) userDidSelectItem:(id)item
               atIndexPath:(NSIndexPath *)indexPath
            fromController:(SSUSelectionController *)controller {
    if ([item isEqualToString:@"All Categories"]) {
        self.predicate = nil;
    }
    else {
        NSString * categoryName = item;
        self.predicate = [NSPredicate predicateWithFormat:@"category = %@", categoryName];
    }
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (void) selectionControllerDismissed:(SSUSelectionController *)controller {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Buttons

- (NSArray *) allCategories {
    NSFetchRequest * request = [NSFetchRequest fetchRequestWithEntityName:@"SSUEvent"];
    NSString * categoryKeyName = @"category";
    request.propertiesToFetch = @[categoryKeyName];
    request.returnsDistinctResults = YES;
    request.resultType = NSDictionaryResultType;
    
    NSArray * objects = [[SSUCalendarModule sharedInstance].context executeFetchRequest:request error:nil];
    NSMutableArray * categories = [NSMutableArray arrayWithCapacity:objects.count];
    for (NSDictionary * dict in objects) {
        if (dict[categoryKeyName] != nil) {
            [categories addObject:dict[categoryKeyName]];
        }
    }
    return [categories sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
}

- (void) filterButtonPressed:(UIBarButtonItem *)button {
    NSArray * categories = [@[@"All Categories"] arrayByAddingObjectsFromArray:[self allCategories]];
    SSUSelectionController * selectionController = [[SSUSelectionController alloc] initWithItems:categories];
    selectionController.delegate = self;
    if (self.predicate == nil) {
        selectionController.defaultIndex = [NSIndexPath indexPathForRow:0 inSection:0];
    }
    else {
        NSString * current = [self.events[0] category];
        NSInteger row = (NSInteger)[categories indexOfObject:current];
        selectionController.defaultIndex = [NSIndexPath indexPathForRow:row inSection:0];
    }
    [self.navigationController pushViewController:selectionController animated:YES];
}

#pragma mark - Segue

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:SSUEventDetailSegue])
    {
        SSUCalendarEventDetailController * detailController = segue.destinationViewController;
        detailController.event = self.selectedEvent;
    }
}

@end

