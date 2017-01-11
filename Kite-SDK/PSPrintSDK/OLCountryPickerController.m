//
//  Modified MIT License
//
//  Copyright (c) 2010-2017 Kite Tech Ltd. https://www.kite.ly
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The software MAY ONLY be used with the Kite Tech Ltd platform and MAY NOT be modified
//  to be used with any competitor platforms. This means the software MAY NOT be modified
//  to place orders with any competitors to Kite Tech Ltd, all orders MUST go through the
//  Kite Tech Ltd platform servers.
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//
#import "OLCountryPickerController.h"
#import "OLCountry.h"
#import "OLConstants.h"
#import "OLKiteABTesting.h"
#import "OLKiteUtils.h"
#import "OLImageDownloader.h"

@interface OLCountryListController : UITableViewController
@property (strong, nonatomic) NSMutableArray *selected;
@property (strong, nonatomic) NSMutableArray<NSArray<OLCountry *> *> *sections;
@end

@interface OLCountryPickerController ()
@property (nonatomic, strong) OLCountryListController *countryListVC;
@end

@implementation OLCountryListController

- (id)initWithStyle:(UITableViewStyle)style {
    if (self = [super initWithStyle:style]) {
        self.selected = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = NSLocalizedStringFromTableInBundle(@"Choose Country", @"KitePrintSDK", [OLKiteUtils kiteBundle], @"");
    
    if (self.tableView.allowsMultipleSelection) {
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"Done", @"KitePrintSDK", [OLKiteUtils kiteBundle], @"") style:UIBarButtonItemStyleDone target:self action:@selector(onButtonDoneClicked)];
        self.navigationItem.rightBarButtonItem = doneButton;
        
        UIColor *color1 = [OLKiteABTesting sharedInstance].lightThemeColor1;
        if (color1){
            self.navigationItem.rightBarButtonItem.tintColor = color1;
        }
        UIFont *font = [[OLKiteABTesting sharedInstance] lightThemeFont1WithSize:17];
        if (font){
            [self.navigationItem.rightBarButtonItem setTitleTextAttributes:@{NSFontAttributeName : font} forState:UIControlStateNormal];
        }
    } else {
        NSURL *cancelUrl = [NSURL URLWithString:[OLKiteABTesting sharedInstance].cancelButtonIconURL];
        if (cancelUrl && ![[OLImageDownloader sharedInstance] cachedDataExistForURL:cancelUrl]){
            [[OLImageDownloader sharedInstance] downloadImageAtURL:cancelUrl withCompletionHandler:^(UIImage *image, NSError *error){
                if (error) return;
                self.navigationItem.rightBarButtonItem= [[UIBarButtonItem alloc] initWithImage:[UIImage imageWithCGImage:image.CGImage scale:2.0 orientation:UIImageOrientationUp] style:UIBarButtonItemStyleDone target:self action:@selector(onButtonCancelClicked)];
            }];
        }
        else{
            UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"Cancel", @"KitePrintSDK", [OLKiteUtils kiteBundle], @"") style:UIBarButtonItemStylePlain target:self action:@selector(onButtonCancelClicked)];
            self.navigationItem.rightBarButtonItem = cancelButton;
        }
    }
    
    [self prepareSections];
}

- (void)setSelected:(NSMutableArray *)selected {
    _selected = [NSMutableArray arrayWithArray:selected];
    [self.tableView reloadData];
}

- (void)onButtonDoneClicked {
    OLCountryPickerController *parent = (OLCountryPickerController *) self.parentViewController;
    if (self.selected.count == 0) {
        [parent.delegate countryPickerDidCancelPicking:parent];
    } else {
        [parent.delegate countryPicker:parent didSucceedWithCountries:self.selected];
    }
}

- (void)onButtonCancelClicked {
    OLCountryPickerController *parent = (OLCountryPickerController *) self.parentViewController;
    [parent.delegate countryPickerDidCancelPicking:parent];
}

- (void)prepareSections {
    self.sections = [[NSMutableArray alloc] init];
    NSArray *countries = [OLCountry countries];
    NSString *lastSectionIndexChar = nil;
    NSMutableArray *countriesInSection = nil;
    for (OLCountry *country in countries) {
        NSString *indexChar = [country.name substringToIndex:1];
        if (![indexChar isEqualToString:lastSectionIndexChar]) {
            lastSectionIndexChar = indexChar;
            countriesInSection = [[NSMutableArray alloc] init];
            [self.sections addObject:countriesInSection];
        }
        
        [countriesInSection addObject:country];
    }
}

#pragma mark - UITableViewDataSource methods

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    NSMutableArray *titles = [[NSMutableArray alloc] init];
    for (NSArray *counties in self.sections) {
        [titles addObject:[((OLCountry *) counties[0]).name substringToIndex:1]];
    }
    return titles;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSArray *countriesForSection = self.sections[section];
    return [[(OLCountry *)countriesForSection.lastObject name] substringToIndex:1];
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    return index;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.sections[section] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *const kCellIdentifier = @"CellIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCellIdentifier];
    }
    
    OLCountry *country = self.sections[indexPath.section][indexPath.row];
    cell.textLabel.text = country.name;
    cell.accessoryType = [self.selected containsObject:country] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    return cell;
}

#pragma mark - UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    OLCountry *selected = self.sections[indexPath.section][indexPath.row];
    BOOL alreadySelected = [self.selected containsObject:selected];
    
    if (!self.tableView.allowsMultipleSelection) {
        if (self.selected.count > 0) {
            // deselect previously selected cell
            OLCountry *oldSelectedCountry = self.selected.lastObject;
            for (NSUInteger section = 0; section < self.sections.count; ++section) {
                NSArray *countriesInSection = self.sections[section];
                NSUInteger row = [countriesInSection indexOfObject:oldSelectedCountry];
                if (row != NSNotFound) {
                    NSIndexPath *oldSelectedPath = [NSIndexPath indexPathForRow:row inSection:section];
                    UITableViewCell *cell = [tableView cellForRowAtIndexPath:oldSelectedPath];
                    cell.accessoryType = UITableViewCellAccessoryNone;
                    break;
                }
            }
            
            [self.selected removeAllObjects];
        }
        
        [self.selected addObject:selected];
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        OLCountryPickerController *parent = (OLCountryPickerController *) self.parentViewController;
        [parent.delegate countryPicker:parent didSucceedWithCountries:self.selected];
    } else {
        // Toggle checkmark selection
        if (alreadySelected) {
            [self.selected removeObject:selected];
            UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
            cell.accessoryType = UITableViewCellAccessoryNone;
        } else {
            [self.selected addObject:selected];
            UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
    }
}

@end

@implementation OLCountryPickerController

@dynamic delegate;

- (id)init {
    OLCountryListController *vc = [[OLCountryListController alloc] initWithStyle:UITableViewStylePlain];
    if (self = [super initWithRootViewController:vc]) {
        self.countryListVC = vc;
    }
    
    return self;
}

- (void)setAllowsMultipleSelection:(BOOL)allowsMultipleSelection {
    self.countryListVC.tableView.allowsMultipleSelection = allowsMultipleSelection;
}

- (BOOL)allowsMultipleSelection {
    return self.countryListVC.tableView.allowsMultipleSelection;
}

- (void)setSelected:(NSArray *)selected {
    self.countryListVC.selected = [NSMutableArray arrayWithArray:selected];
}

- (NSArray *)selected {
    return self.countryListVC.selected;
}

@end
