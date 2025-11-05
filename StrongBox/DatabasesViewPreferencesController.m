//
//  DatabasesViewPreferencesController.m
//  Strongbox-iOS
//
//  Created by Mark on 30/07/2019.
//  Copyright © 2014-2021 Mark McGuill. All rights reserved.
//

#import "DatabasesViewPreferencesController.h"
//#import "Settings.h"
#import "AppPreferences.h"
#import "SelectItemTableViewController.h"
#import "NSArray+Extensions.h"

@interface DatabasesViewPreferencesController ()
@property (weak, nonatomic) IBOutlet UISwitch *switchShowStorageIcon;
@property (weak, nonatomic) IBOutlet UISwitch *showStatusIndicator;
@property (weak, nonatomic) IBOutlet UISwitch *showHiddenDatabasesSwitch;
@property (weak, nonatomic) IBOutlet UILabel *showHiddenDatabasesLabel;
@property (weak, nonatomic) IBOutlet UILabel *labelTopRight;
@property (weak, nonatomic) IBOutlet UILabel *labelSubtitle1;
@property (weak, nonatomic) IBOutlet UILabel *labelSubtitle2;
@property (weak, nonatomic) IBOutlet UITableViewCell *cellTopRight;
@property (weak, nonatomic) IBOutlet UITableViewCell *cellSubtitle1;
@property (weak, nonatomic) IBOutlet UITableViewCell *cellSubtitle2;
@property (weak, nonatomic) IBOutlet UISwitch *showSeparator;
@property (weak, nonatomic) IBOutlet UIImageView *sortOptionDateImageView;
@property (weak, nonatomic) IBOutlet UIImageView *sortOptionNameImageView;
@property (weak, nonatomic) IBOutlet UIImageView *sortOptionSizeImageView;
@property (weak, nonatomic) IBOutlet UIImageView *sortOptionNoneImageView;

@end

@implementation DatabasesViewPreferencesController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self bindUi];
}

- (void)bindUi {
    self.switchShowStorageIcon.on = AppPreferences.sharedInstance.showDatabaseIcon;
    self.showStatusIndicator.on = AppPreferences.sharedInstance.showDatabaseStatusIcon;
    self.showSeparator.on = AppPreferences.sharedInstance.showDatabasesSeparator;
    self.showHiddenDatabasesSwitch.on = AppPreferences.sharedInstance.showHiddenDatabases;
    
    self.labelTopRight.text = [self getDatabaseSubtitleFieldName:AppPreferences.sharedInstance.databaseCellTopSubtitle];
    self.labelSubtitle1.text = [self getDatabaseSubtitleFieldName:AppPreferences.sharedInstance.databaseCellSubtitle1];
    self.labelSubtitle2.text = [self getDatabaseSubtitleFieldName:AppPreferences.sharedInstance.databaseCellSubtitle2];
    
    UIImage *selectedImage = [UIImage systemImageNamed:@"checkmark.circle.fill"];
    DatabaseSortOption selectedOption = AppPreferences.sharedInstance.databasesSortOption;
    self.sortOptionDateImageView.image = selectedOption == DatabaseSortOptionDate ? selectedImage : nil;
    self.sortOptionNameImageView.image = selectedOption == DatabaseSortOptionName ? selectedImage : nil;
    self.sortOptionSizeImageView.image = selectedOption == DatabaseSortOptionSize ? selectedImage : nil;
    self.sortOptionNoneImageView.image = selectedOption == DatabaseSortOptionNone ? selectedImage : nil;
}

- (IBAction)onSettingChanged:(id)sender {
    AppPreferences.sharedInstance.showDatabaseIcon = self.switchShowStorageIcon.on;
    AppPreferences.sharedInstance.showDatabaseStatusIcon = self.showStatusIndicator.on;
    AppPreferences.sharedInstance.showDatabasesSeparator = self.showSeparator.on;
    AppPreferences.sharedInstance.showHiddenDatabases = self.showHiddenDatabasesSwitch.on;
    
    if(self.onPreferencesChanged) {
        self.onPreferencesChanged();
    }
    
    [self bindUi];
}

- (IBAction)onDone:(id)sender {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:indexPath];

    if (indexPath.section == 0) {
        NSArray<NSNumber*>* opts = @[
            @(kDatabaseCellSubtitleFieldNone),
            @(kDatabaseCellSubtitleFieldFileName),
            @(kDatabaseCellSubtitleFieldStorage),
            @(kDatabaseCellSubtitleFieldLastModifiedDate),
            @(kDatabaseCellSubtitleFieldLastModifiedDatePrecise),
            @(kDatabaseCellSubtitleFieldFileSize),
            


        ];
        
        NSArray<NSString*>* options = [opts map:^id _Nonnull(NSNumber*  _Nonnull obj, NSUInteger idx) {
            return [self getDatabaseSubtitleFieldName:obj.integerValue];
        }];
        
        if (cell == self.cellTopRight) {
            [self promptForString:NSLocalizedString(@"databases_preferences_select_top_right_field", @"Select Top Right Field")
                          options:options
                     currentIndex:AppPreferences.sharedInstance.databaseCellTopSubtitle
                       completion:^(BOOL success, NSInteger selectedIdx) {
                if(success) {
                    AppPreferences.sharedInstance.databaseCellTopSubtitle = selectedIdx;
                    [self onSettingChanged:nil];
                }
            }];
        }
        else if (cell == self.cellSubtitle1) {
            [self promptForString:NSLocalizedString(@"databases_preferences_select_subtitle1_field", @"Select Subtitle 1 Field")
                          options:options
                     currentIndex:AppPreferences.sharedInstance.databaseCellSubtitle1
                       completion:^(BOOL success, NSInteger selectedIdx) {
                if(success) {
                    AppPreferences.sharedInstance.databaseCellSubtitle1 = selectedIdx;
                    [self onSettingChanged:nil];
                }
            }];
        }
        else if (cell == self.cellSubtitle2) {
            [self promptForString:NSLocalizedString(@"databases_preferences_select_subtitle2_field", @"Select Subtitle 2 Field")
                          options:options
                     currentIndex:AppPreferences.sharedInstance.databaseCellSubtitle2
                       completion:^(BOOL success, NSInteger selectedIdx) {
                if(success) {
                    AppPreferences.sharedInstance.databaseCellSubtitle2 = selectedIdx;
                    [self onSettingChanged:nil];
                }
            }];
        }
    } else if (indexPath.section == 1) {
        
        DatabaseSortOption option = DatabaseSortOptionNone;
        if (indexPath.row == 0) {
            option = DatabaseSortOptionDate;
        } else if (indexPath.row == 1) {
            option = DatabaseSortOptionName;
        } else if (indexPath.row == 2) {
            option = DatabaseSortOptionSize;
        } else if (indexPath.row == 3) {
            option = DatabaseSortOptionNone;
        }
        AppPreferences.sharedInstance.databasesSortOption = option;
        [self onSettingChanged:nil];
    }
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSString*)getDatabaseSubtitleFieldName:(DatabaseCellSubtitleField)field {
    switch (field) {
        case kDatabaseCellSubtitleFieldNone:
            return NSLocalizedString(@"databases_preferences_subtitle_field_name_none", @"None");
            break;
        case kDatabaseCellSubtitleFieldFileName:
            return NSLocalizedString(@"databases_preferences_subtitle_field_name_filename", @"Filename");
            break;
        case kDatabaseCellSubtitleFieldLastModifiedDate:
            return NSLocalizedString(@"databases_preferences_subtitle_field_name_last_cached_data", @"Last Modified");
            break;
        case kDatabaseCellSubtitleFieldLastModifiedDatePrecise:
            return NSLocalizedString(@"databases_preferences_subtitle_field_name_last_modified_date_precise", @"Last Modified (Precise)");
            break;
        case kDatabaseCellSubtitleFieldFileSize:
            return NSLocalizedString(@"databases_preferences_subtitle_field_name_file_size", @"File Size");
            break;
        case kDatabaseCellSubtitleFieldStorage:
            return NSLocalizedString(@"databases_preferences_subtitle_field_name_database_storage", @"Database Storage");
            break;
        case kDatabaseCellSubtitleFieldCreateDate:
            return NSLocalizedString(@"browse_prefs_item_subtitle_date_created", @"Date Created");
            break;
        case kDatabaseCellSubtitleFieldCreateDatePrecise:
            return NSLocalizedString(@"databases_preferences_subtitle_field_name_create_date_precise", @"Date Created (Precise)");
            break;
        default:
            return @"<Unknown Field>";
            break;
    }
}

- (void)promptForString:(NSString*)title
                options:(NSArray<NSString*>*)options
           currentIndex:(NSInteger)currentIndex
             completion:(void(^)(BOOL success, NSInteger selectedIdx))completion {
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"SelectItem" bundle:nil];
    UINavigationController* nav = (UINavigationController*)[storyboard instantiateInitialViewController];
    SelectItemTableViewController *vc = (SelectItemTableViewController*)nav.topViewController;
    
    vc.groupItems = @[options];
    vc.selectedIndexPaths = @[[NSIndexSet indexSetWithIndex:currentIndex]];
    vc.onSelectionChange = ^(NSArray<NSIndexSet *> * _Nonnull selectedIndices) {
        [self.navigationController popViewControllerAnimated:YES];
        
        NSIndexSet* set = selectedIndices.firstObject;
        completion(YES, set.firstIndex);
    };
    vc.title = title;
    
    [self.navigationController pushViewController:vc animated:YES];
}

@end
