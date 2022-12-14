#import "SettingsViewController.h"
#import "BackgroundModeSettingsViewController.h"
#import "SponsorBlockSettingsViewController.h"

@interface SettingsViewController ()
@end

@implementation SettingsViewController

- (void)loadView {
	[super loadView];

	self.title = @"";
    self.view.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0];
	[self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}];
	self.navigationController.navigationBar.barStyle = UIBarStyleBlack;

	UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done)];
    self.navigationItem.leftBarButtonItem = doneButton;

    UIBarButtonItem *applyButton = [[UIBarButtonItem alloc] initWithTitle:@"Apply" style:UIBarButtonItemStylePlain target:self action:@selector(apply)];
    self.navigationItem.rightBarButtonItem = applyButton;

    if (@available(iOS 15.0, *)) {
    	[self.tableView setSectionHeaderTopPadding:0.0f];
	}
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 2;
    }
    if (section == 1) {
        return 2;
    }
    if (section == 2) {
        return 1;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"SettingsTableViewCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
        cell.textLabel.adjustsFontSizeToFitWidth = true;
        cell.textLabel.adjustsFontForContentSizeCategory = false;
        cell.backgroundColor = [UIColor colorWithRed:0.110 green:0.110 blue:0.118 alpha:1.0];
        cell.textLabel.textColor = [UIColor whiteColor];
        if (indexPath.section == 0) {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            if (indexPath.row == 0) {
                cell.textLabel.text = @"Background Mode";
                if (![[NSUserDefaults standardUserDefaults] integerForKey:@"kBackgroundMode"]) {
                    cell.detailTextLabel.text = @"None";
                } else {
                    int selectedTab = [[NSUserDefaults standardUserDefaults] integerForKey:@"kBackgroundMode"];
                    if (selectedTab == 0) {
                        cell.detailTextLabel.text = @"None";
                    }
                    if (selectedTab == 1) {
                        cell.detailTextLabel.text = @"Background Playback";
                    }
                    if (selectedTab == 2) {
                        cell.detailTextLabel.text = @"Picture In Picture";
                    }
                }
            }
            if (indexPath.row == 1) {
                cell.textLabel.text = @"SponsorBlock";
            }
        }
        if (indexPath.section == 1) {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            if (indexPath.row == 0) {
                cell.textLabel.text = @"Clear History";
            }
            if (indexPath.row == 1) {
                cell.textLabel.text = @"Clear Playlists";
            }
        }

        if (indexPath.section == 1) {
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            if (indexPath.row == 0) {
                cell.textLabel.text = @"Enable Developer Options";
                UISwitch *enableDeveloperOptions = [[UISwitch alloc] initWithFrame:CGRectZero];
                [enableDeveloperOptions addTarget:self action:@selector(toggleEnableDeveloperOptions:) forControlEvents:UIControlEventValueChanged];
                enableDeveloperOptions.on = [[NSUserDefaults standardUserDefaults] boolForKey:@"kEnableDeveloperOptions"];
                cell.accessoryView = enableDeveloperOptions;
            }
        }
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            BackgroundModeSettingsViewController *backgroundModeSettingsViewController = [[BackgroundModeSettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
            UINavigationController *backgroundModeSettingsViewControllerView = [[UINavigationController alloc] initWithRootViewController:backgroundModeSettingsViewController];
            backgroundModeSettingsViewControllerView.modalPresentationStyle = UIModalPresentationFullScreen;

            [self presentViewController:backgroundModeSettingsViewControllerView animated:YES completion:nil];
        }
        if (indexPath.row == 1) {
            SponsorBlockSettingsViewController *sponsorBlockSettingsViewController = [[SponsorBlockSettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
            UINavigationController *sponsorBlockSettingsViewControllerView = [[UINavigationController alloc] initWithRootViewController:sponsorBlockSettingsViewController];
            sponsorBlockSettingsViewControllerView.modalPresentationStyle = UIModalPresentationFullScreen;

            [self presentViewController:sponsorBlockSettingsViewControllerView animated:YES completion:nil];
        }
    }
    if (indexPath.section == 1) {
        if (indexPath.row == 0) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Notice" message:@"Are you sure you want to delete your history?" preferredStyle:UIAlertControllerStyleAlert];

            [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            }]];

            [alert addAction:[UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                NSFileManager *fm = [[NSFileManager alloc] init];
                NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                NSString *documentsDirectory = [paths objectAtIndex:0];
                [fm removeItemAtPath:[documentsDirectory stringByAppendingPathComponent:@"history.plist"] error:nil];
            }]];

            [self presentViewController:alert animated:YES completion:nil];
        }
        if (indexPath.row == 1) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Notice" message:@"Are you sure you want to delete your playlists?" preferredStyle:UIAlertControllerStyleAlert];

            [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            }]];

            [alert addAction:[UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                NSFileManager *fm = [[NSFileManager alloc] init];
                NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                NSString *documentsDirectory = [paths objectAtIndex:0];
                [fm removeItemAtPath:[documentsDirectory stringByAppendingPathComponent:@"playlists.plist"] error:nil];
            }]];

            [self presentViewController:alert animated:YES completion:nil];
        }
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [self.tableView reloadData];
}

@end

@implementation SettingsViewController (Privates)

- (void)done {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)apply {
    exit(0); 
}

- (void)toggleEnableDeveloperOptions:(UISwitch *)sender {
    if ([sender isOn]) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"kEnableDeveloperOptions"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    } else {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"kEnableDeveloperOptions"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

@end