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

#import "OLAddressLookupViewController.h"
#import "OLAddress.h"
#import "OLCountry.h"
#import "OLCountryPickerController.h"
#import "OLAddressEditViewController.h"
#import "OLConstants.h"
#import "OLProgressHUD.h"
#import "OLKiteViewController.h"
#import "OLKiteUtils.h"
#import "OLKiteABTesting.h"
#import "OLUserSession.h"

//static const NSUInteger kMaxInFlightRequests = 5;

@interface OLAddressLookupViewController () <UITextFieldDelegate, OLCountryPickerControllerDelegate,
    UINavigationControllerDelegate, OLAddressSearchRequestDelegate, UISearchResultsUpdating, UIGestureRecognizerDelegate, UISearchBarDelegate>
@property (nonatomic, strong) OLCountry *country;
@property (nonatomic, strong) UILabel *labelCountry;
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) NSArray<OLAddress *> *searchResults;

@property (nonatomic, strong) UIAlertView *errorAlertView;

@property (nonatomic, assign) BOOL progressToEditViewControllerOnUniqueAddressResult;
@property (nonatomic, strong) UITableViewCell *countryPickerView;
@property (nonatomic, assign) BOOL showSectionHeader;
@property (nonatomic, strong) OLAddressSearchRequest *inProgressRequest;
@property (nonatomic, strong) NSString *queuedSearchQuery;
@property (nonatomic, strong) OLCountry *queuedSearchCountry;

@property (strong, nonatomic) UISearchController *searchController;

@end

@implementation OLAddressLookupViewController

- (id)init {
    if (self = [super initWithStyle:UITableViewStylePlain]) {
        self.title = NSLocalizedStringFromTableInBundle(@"Address Search", @"KitePrintSDK", [OLKiteUtils kiteBundle], @"");
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // create a new Search Bar and add it to the table view
    self.searchBar = [[UISearchBar alloc]initWithFrame:CGRectMake(0, 0, 320, 44)];
    self.searchBar.delegate = self;
    self.tableView.tableHeaderView = self.searchBar;
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.dimsBackgroundDuringPresentation = NO;
    [self.searchController.searchBar sizeToFit];
    
    self.searchController.searchBar.delegate = self;
    
    self.tableView.tableHeaderView = self.searchController.searchBar;
    self.definesPresentationContext = YES;

    
    // create the country picker
    // create the country picker button
    self.countryPickerView = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"CountryPickerView"];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(15, 0, 110, 44)];
    label.text = NSLocalizedStringFromTableInBundle(@"Country", @"KitePrintSDK", [OLKiteUtils kiteBundle], @"");
    
    self.labelCountry = [[UILabel alloc] initWithFrame:CGRectMake(110, 0, 320 - 110, 44)];
    self.labelCountry.adjustsFontSizeToFitWidth = YES;
    
    [self.countryPickerView addSubview:label];
    [self.countryPickerView addSubview:self.labelCountry];
    self.countryPickerView.userInteractionEnabled = YES;
    self.countryPickerView.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    self.countryPickerView.backgroundColor = [UIColor colorWithRed:230 / 255.0 green:230 / 255.0 blue:230 / 255.0 alpha:1];
    
    UIView *cellSeparator = [[UIView alloc] initWithFrame:CGRectMake(0, 43.5, 320, 0.5)];
    cellSeparator.backgroundColor = [UIColor colorWithRed:200 / 255.0 green:199 / 255.0 blue:204 / 255.0 alpha:1];
    [self.countryPickerView addSubview:cellSeparator];
    
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onButtonChangeCountryClicked)];
    tapRecognizer.delegate = self;
    [self.countryPickerView addGestureRecognizer:tapRecognizer];
    
    
    self.country = [OLCountry countryForCurrentLocale];
    self.showSectionHeader = YES;
    
    if ([self.tableView respondsToSelector:@selector(setCellLayoutMarginsFollowReadableWidth:)]){
        self.tableView.cellLayoutMarginsFollowReadableWidth = NO;
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [OLAnalytics trackSearchAddressScreenViewed];
}

- (void)setCountry:(OLCountry *)country {
    _country = country;
    self.labelCountry.text = country.name;
    if ([country.codeAlpha3 isEqualToString:@"USA"]) {
        self.searchBar.placeholder = NSLocalizedStringFromTableInBundle(@"Search by street, address or ZIP code", @"KitePrintSDK", [OLKiteUtils kiteBundle], @"");
    } else {
        self.searchBar.placeholder = NSLocalizedStringFromTableInBundle(@"Search by postcode, street or address", @"KitePrintSDK", [OLKiteUtils kiteBundle], @"");
    }
}

- (void)onButtonChangeCountryClicked {
    OLCountryPickerController *controller = [[OLCountryPickerController alloc] init];
    controller.delegate = self;
    controller.selected = @[self.country];
    controller.modalPresentationStyle = [OLUserSession currentSession].kiteVc.modalPresentationStyle;
    [self presentViewController:controller animated:YES completion:nil];
}

- (void)performQueuedAddressLookup {
    if (self.queuedSearchQuery == nil) {
        return;
    }
    
    if (self.inProgressRequest == nil) {
        self.inProgressRequest = [OLAddress searchForAddressWithCountry:self.queuedSearchCountry query:self.queuedSearchQuery delegate:self];
        self.queuedSearchQuery = nil;
        self.queuedSearchCountry = nil;
    }
}

#pragma mark - UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSUInteger c = self.searchResults.count;
    if (tableView == self.tableView) {
        c += 1; // account for special country selector cell
    }
    return c;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.tableView) {
        if (indexPath.row == 0) {
            return self.countryPickerView;
        } else {
            indexPath = [NSIndexPath indexPathForRow:indexPath.row - 1 inSection:indexPath.section];
        }
    }
    
    static NSString *const CellIdentifier = @"CellIdentifier";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.textLabel.minimumScaleFactor = 0.75;
        cell.textLabel.adjustsFontSizeToFitWidth = YES;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        

    }
    
    OLAddress *addr = self.searchResults[indexPath.row];
    cell.textLabel.text = [addr description];
    
    return cell;
}

#pragma mark - UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.tableView) {
        if (indexPath.row == 0) {
            return;
        } else {
            indexPath = [NSIndexPath indexPathForRow:indexPath.row - 1 inSection:indexPath.section];
        }
    }
    
    OLAddress *address = self.searchResults[indexPath.row];
    if (address.isSearchRequiredForFullDetails) {
        [OLProgressHUD setDefaultMaskType:OLProgressHUDMaskTypeBlack];
        [OLProgressHUD showWithStatus:@"Fetching Address Details"];
        [self.inProgressRequest  cancelSearch];
        self.progressToEditViewControllerOnUniqueAddressResult = YES;
        OLAddressSearchRequest *req = [OLAddress searchForAddress:address delegate:self];
        self.inProgressRequest = req;
    } else {
        [self.navigationController pushViewController:[[OLAddressEditViewController alloc] initWithAddress:address] animated:YES];
    }
}

#pragma mark - OLCountryControllerPicker methods

- (void)countryPicker:(OLCountryPickerController *)picker didSucceedWithCountries:(NSArray<OLCountry *> *)countries {
    [self dismissViewControllerAnimated:YES completion:nil];
    if (self.country != countries.lastObject) {
        self.searchResults = @[]; // country has changed, clear the results as they're no longer applicable
    }
    self.country = countries.lastObject;
    
    [self.tableView reloadData];
}

- (void)countryPickerDidCancelPicking:(OLCountryPickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - OLAddressSearchRequestDelegate methods

- (void)addressSearchRequest:(OLAddressSearchRequest *)req didSuceedWithMultipleOptions:(NSArray *)options {
    [OLProgressHUD dismiss];
    self.progressToEditViewControllerOnUniqueAddressResult = NO;
    self.inProgressRequest = nil;
    if (self.errorAlertView.isVisible) {
        return;
    }
    
    self.searchResults = options;
    [self.tableView reloadData];
    
    [self performQueuedAddressLookup];
}

- (void)addressSearchRequest:(OLAddressSearchRequest *)req didSuceedWithUniqueAddress:(OLAddress *)addr {
    [OLProgressHUD dismiss];
    self.inProgressRequest = nil;
    if (self.errorAlertView.isVisible) {
        return;
    }
    
    if (self.progressToEditViewControllerOnUniqueAddressResult) {
        self.progressToEditViewControllerOnUniqueAddressResult = NO;
        [self.navigationController pushViewController:[[OLAddressEditViewController alloc] initWithAddress:addr] animated:YES];
        return;
    }
    
    self.searchResults = @[addr];
    [self.tableView reloadData];
    
    [self performQueuedAddressLookup];
}

- (void)addressSearchRequest:(OLAddressSearchRequest *)req didFailWithError:(NSError *)error {
    [OLProgressHUD dismiss];
    self.progressToEditViewControllerOnUniqueAddressResult = NO;
    self.inProgressRequest = nil;
    if (self.errorAlertView.isVisible) {
        return;
    }
    
    self.errorAlertView = [[UIAlertView alloc] initWithTitle:@"Oops!" message:error.localizedDescription delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [self.errorAlertView show];
}

#pragma mark - UISearchBarDelegate methods

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    NSString *searchString = searchController.searchBar.text;
    
    if (searchString.length == 0) {
        self.searchResults = @[];
        [self.tableView reloadData];
        return;
    }
    self.queuedSearchQuery = searchString;
    self.queuedSearchCountry = self.country;
    [self performQueuedAddressLookup];
}

@end
