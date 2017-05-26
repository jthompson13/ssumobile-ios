//
//  SSUResourcesViewController.m
//  SSUMobile
//
//  Created by Eric Amorde on 10/5/14.
//  Copyright (c) 2014 Sonoma State University Department of Computer Science. All rights reserved.
//

@import CoreData;

#import "SSUResourcesViewController.h"
#import "SSUResourcesCell.h"
#import "SSUResourcesConstants.h"
#import "SSUResourcesEntry.h"
#import "SSUResourcesSection.h"
#import "SSUMobile-Swift.h"

@interface SSUResourcesViewController () <NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) NSArray * sectionInfo;
@property (nonatomic, strong) NSIndexPath * selectedIndexPath;
@property (nonatomic, strong) NSManagedObjectContext * context;

@end

@implementation SSUResourcesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.context = [[SSUResourcesModule sharedInstance] context];
    [self setupCoreData];
    
    self.tableView.separatorColor = SSU_BLUE_COLOR;
    self.tableView.estimatedRowHeight = 100;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.tableView reloadData];
}

- (void) refresh {    
    [[SSUResourcesModule sharedInstance] updateData:^{
        [self.refreshControl endRefreshing];
    }];
}

- (void) setupCoreData {
    NSArray * sortDescriptors = @[
                                  [NSSortDescriptor sortDescriptorWithKey:@"section.position" ascending:YES],
                                  [NSSortDescriptor sortDescriptorWithKey:@"id" ascending:YES],
                                  ];
    NSFetchRequest * fetchRequest = [NSFetchRequest fetchRequestWithEntityName:SSUResourcesEntityResource];
    fetchRequest.sortDescriptors = sortDescriptors;
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                        managedObjectContext:self.context
                                                                          sectionNameKeyPath:@"section.position"
                                                                                   cacheName:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [[self.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.fetchedResultsController.sections[section] numberOfObjects];
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    id<NSFetchedResultsSectionInfo> info = self.fetchedResultsController.sections[section];
    SSUResourcesEntry * firstResource = [[info objects] objectAtIndex:0];
    return [firstResource.section name];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SSUResourcesCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
    SSUResourcesEntry * resource = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.titleLabel.text = resource.name;
    
    
    cell.phoneLabel.textColor = SSU_BLUE_COLOR;
    cell.phoneLabel.text = resource.phone;
    cell.urlLabel.text = [[resource.url stringByReplacingOccurrencesOfString:@"http://" withString:@""]
                                        stringByReplacingOccurrencesOfString:@"www." withString:@""];
    
    
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    SSUResourcesEntry * resource = [self.fetchedResultsController objectAtIndexPath:indexPath];
    if (resource.phone == nil && resource.url == nil) {
        SSULogError(@"A resource was selected but has neither a phone number nor website URL: %@", resource);
        return;
    }
    self.selectedIndexPath = indexPath;
    UIAlertController * controller = [UIAlertController alertControllerWithTitle:resource.name
                                                                         message:nil
                                                                  preferredStyle:UIAlertControllerStyleActionSheet];
    [controller addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:NULL]];
    
    if (resource.phone != nil) {
        // Both phone and url
        NSString * phoneTitle = [NSString stringWithFormat:@"Call %@",resource.phone];
        [controller addAction:[UIAlertAction actionWithTitle:phoneTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self callPhoneNumberOfResource:resource];
        }]];
    }
    if (resource.url != nil) {
        NSString * urlTitle = @"Open in Safari";
        [controller addAction:[UIAlertAction actionWithTitle:urlTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self openURLOfResource:resource];
        }]];
    }
    [self presentViewController:controller animated:YES completion:NULL];
}

- (void) callPhoneNumberOfResource:(SSUResourcesEntry *)resource {
    NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"tel:%@",resource.phone]];
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        [[UIApplication sharedApplication] openURL:url];
    } else {
        SSULogError(@"Unable to call resource phone number: %@", resource.phone);
    }
}

- (void) openURLOfResource:(SSUResourcesEntry *)resource {
    NSURL * url = [NSURL URLWithString:resource.url];
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        [[UIApplication sharedApplication] openURL:url];
    } else {
        SSULogError(@"Unable to open resource URL: %@", resource.url);
    }
}


@end
