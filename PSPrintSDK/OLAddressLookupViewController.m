//
//  OLAddressLookupViewController.m
//  Kite SDK
//
//  Created by Deon Botha on 06/01/2014.
//  Copyright (c) 2014 Deon Botha. All rights reserved.
//

#import "OLAddressLookupViewController.h"
#import "OLAddress.h"
#import "OLCountry.h"
#import "OLCountryPickerController.h"
#import "OLAddressEditViewController.h"
#import <SVProgressHUD.h>

//static const NSUInteger kMaxInFlightRequests = 5;

@interface OLAddressLookupViewController () <UITextFieldDelegate, OLCountryPickerControllerDelegate,
    UINavigationControllerDelegate, OLAddressSearchRequestDelegate, UISearchDisplayDelegate, UIGestureRecognizerDelegate, UISearchBarDelegate>
@property (nonatomic, strong) OLCountry *country;
@property (nonatomic, strong) UILabel *labelCountry;
@property (nonatomic, strong) UISearchDisplayController *searchController;
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) NSArray/*<OLAddress>*/ *searchResults;

@property (nonatomic, strong) UIAlertView *errorAlertView;

@property (nonatomic, assign) BOOL progressToEditViewControllerOnUniqueAddressResult;
@property (nonatomic, strong) UITableViewCell *countryPickerView;
@property (nonatomic, assign) BOOL showSectionHeader;
@property (nonatomic, strong) OLAddressSearchRequest *inProgressRequest;
@property (nonatomic, strong) NSString *queuedSearchQuery;
@property (nonatomic, strong) OLCountry *queuedSearchCountry;

@end

@implementation OLAddressLookupViewController

- (id)init {
    if (self = [super initWithStyle:UITableViewStylePlain]) {
        self.title = NSLocalizedString(@"Address Search", @"");
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // create a new Search Bar and add it to the table view
    self.searchBar = [[UISearchBar alloc]initWithFrame:CGRectMake(0, 0, 320, 44)];
    self.searchBar.delegate = self;
    self.tableView.tableHeaderView = self.searchBar;
    self.searchController = [[UISearchDisplayController alloc] initWithSearchBar:self.searchBar contentsController:self];
    self.searchController.searchResultsDataSource = self;
    self.searchController.searchResultsDelegate = self;
    self.searchController.delegate = self;
    
    // create the country picker
    // create the country picker button
    self.countryPickerView = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"CountryPickerView"];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(15, 0, 110, 44)];
    label.text = @"Country";
    
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
}

- (void)setCountry:(OLCountry *)country {
    _country = country;
    self.labelCountry.text = country.name;
    self.searchBar.placeholder = NSLocalizedString(([NSString stringWithFormat:@"Search %@", country.name]), @"");
}

- (void)onButtonChangeCountryClicked {
        OLCountryPickerController *controller = [[OLCountryPickerController alloc] init];
        controller.delegate = self;
        controller.selected = @[self.country];
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
        [SVProgressHUD showWithStatus:@"Fetching Address Details" maskType:SVProgressHUDMaskTypeBlack];
        [self.inProgressRequest  cancelSearch];
        self.progressToEditViewControllerOnUniqueAddressResult = YES;
        OLAddressSearchRequest *req = [OLAddress searchForAddress:address delegate:self];
        self.inProgressRequest = req;
    } else {
        [self.navigationController pushViewController:[[OLAddressEditViewController alloc] initWithAddress:address] animated:YES];
    }
}

#pragma mark - OLCountryControllerPicker methods

- (void)countryPicker:(OLCountryPickerController *)picker didSucceedWithCountries:(NSArray/*<OLCountry>*/ *)countries {
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
    [SVProgressHUD dismiss];
    self.progressToEditViewControllerOnUniqueAddressResult = NO;
    self.inProgressRequest = nil;
    if (self.errorAlertView.isVisible) {
        return;
    }
    
    self.searchResults = options;
    [self.tableView reloadData];
    [self.searchController.searchResultsTableView reloadData];
    
    [self performQueuedAddressLookup];
}

- (void)addressSearchRequest:(OLAddressSearchRequest *)req didSuceedWithUniqueAddress:(OLAddress *)addr {
    [SVProgressHUD dismiss];
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
    [self.searchController.searchResultsTableView reloadData];
    
    [self performQueuedAddressLookup];
}

- (void)addressSearchRequest:(OLAddressSearchRequest *)req didFailWithError:(NSError *)error {
    [SVProgressHUD dismiss];
    self.progressToEditViewControllerOnUniqueAddressResult = NO;
    self.inProgressRequest = nil;
    if (self.errorAlertView.isVisible) {
        return;
    }
    
    self.errorAlertView = [[UIAlertView alloc] initWithTitle:@"Oops!" message:error.localizedDescription delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [self.errorAlertView show];
}

#pragma mark - UISearchBarDelegate methods

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if (self.errorAlertView.isVisible) {
        return;
    }
    
    if (searchText.length == 0) {
        self.searchResults = @[];
        [self.tableView reloadData];
        [self.searchController.searchResultsTableView reloadData];
        return;
    }
    
    self.queuedSearchQuery = searchText;
    self.queuedSearchCountry = self.country;
    [self performQueuedAddressLookup];
}

#pragma mark - UISearchDisplayControllerDelegate methods

- (void)searchDisplayController:(UISearchDisplayController *)controller willShowSearchResultsTableView:(UITableView *)tableView {
    self.showSectionHeader = NO;
}

- (void)searchDisplayController:(UISearchDisplayController *)controller willHideSearchResultsTableView:(UITableView *)tableView {
    self.showSectionHeader = YES;
    [self.tableView reloadData]; // ensure section header is reloaded appropriately
}

@end
