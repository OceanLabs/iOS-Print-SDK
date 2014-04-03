//
//  OLCountry.m
//  PS SDK
//
//  Created by Deon Botha on 19/12/2013.
//  Copyright (c) 2013 Deon Botha. All rights reserved.
//

#import "OLCountry.h"

@implementation OLCountry

- (id)initWithName:(NSString *)name code2:(NSString *)code2 code3:(NSString *)code3 currencyCode:(NSString *)currencyCode {
    if (self = [super init]) {
        _name = name;
        _codeAlpha2 = code2;
        _codeAlpha3 = code3;
        _currencyCode = currencyCode;
    }
    
    return self;
}

+ (OLCountry *)countryForCurrentLocale {
    NSString *countryCode = [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode];
    OLCountry *country = [OLCountry countryForCode:countryCode];
    
    if (country == nil) {
        // fallback to GB in the worst case as it's probably the system locale.
        return [OLCountry countryForCode:@"GBR"];
    }
    
    return country;
}

+ (OLCountry *)countryForCode:(NSString *)code {
    code = [code uppercaseString];
    NSArray *countries = [OLCountry countries];
    for (OLCountry *country in countries) {
        if ([country.codeAlpha2 isEqualToString:code] || [country.codeAlpha3 isEqualToString:code]) {
            return country;
        }
    }
    
    return nil;
}

+ (BOOL)isValidCurrencyCode:(NSString *)code {
    code = [code uppercaseString];
    NSArray *countries = [OLCountry countries];
    for (OLCountry *country in countries) {
        if ([country.currencyCode isEqualToString:code]) {
            return YES;
        }
    }
    
    return NO;
}

+ (NSArray *)countries {
    static NSMutableArray *countries = nil;
    
    if (countries != nil) {
        return countries;
    }
    
    countries = [[NSMutableArray alloc] init];
    [countries addObject:[[OLCountry alloc] initWithName:@"Åland Islands" code2:@"AX" code3:@"ALA" currencyCode:@"EUR"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Afghanistan" code2:@"AF" code3:@"AFG" currencyCode:@"AFN"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Albania" code2:@"AL" code3:@"ALB" currencyCode:@"ALL"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Algeria" code2:@"DZ" code3:@"DZA" currencyCode:@"DZD"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"American Samoa" code2:@"AS" code3:@"ASM" currencyCode:@"USD"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Andorra" code2:@"AD" code3:@"AND" currencyCode:@"EUR"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Angola" code2:@"AO" code3:@"AGO" currencyCode:@"AOA"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Anguilla" code2:@"AI" code3:@"AIA" currencyCode:@"XCD"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Antarctica" code2:@"AQ" code3:@"ATA" currencyCode:@""]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Antigua and Barbuda" code2:@"AG" code3:@"ATG" currencyCode:@"XCD"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Argentina" code2:@"AR" code3:@"ARG" currencyCode:@"ARS"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Armenia" code2:@"AM" code3:@"ARM" currencyCode:@"AMD"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Aruba" code2:@"AW" code3:@"ABW" currencyCode:@"AWG"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Australia" code2:@"AU" code3:@"AUS" currencyCode:@"AUD"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Austria" code2:@"AT" code3:@"AUT" currencyCode:@"EUR"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Azerbaijan" code2:@"AZ" code3:@"AZE" currencyCode:@"AZN"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Bahamas" code2:@"BS" code3:@"BHS" currencyCode:@"BSD"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Bahrain" code2:@"BH" code3:@"BHR" currencyCode:@"BHD"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Bangladesh" code2:@"BD" code3:@"BGD" currencyCode:@"BDT"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Barbados" code2:@"BB" code3:@"BRB" currencyCode:@"BBD"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Belarus" code2:@"BY" code3:@"BLR" currencyCode:@"BYR"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Belgium" code2:@"BE" code3:@"BEL" currencyCode:@"EUR"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Belize" code2:@"BZ" code3:@"BLZ" currencyCode:@"BZD"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Benin" code2:@"BJ" code3:@"BEN" currencyCode:@"XOF"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Bermuda" code2:@"BM" code3:@"BMU" currencyCode:@"BMD"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Bhutan" code2:@"BT" code3:@"BTN" currencyCode:@"INR"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Bolivia, Plurinational State of" code2:@"BO" code3:@"BOL" currencyCode:@"BOB"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Bonaire, Sint Eustatius and Saba" code2:@"BQ" code3:@"BES" currencyCode:@"USD"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Bosnia and Herzegovina" code2:@"BA" code3:@"BIH" currencyCode:@"BAM"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Botswana" code2:@"BW" code3:@"BWA" currencyCode:@"BWP"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Bouvet Island" code2:@"BV" code3:@"BVT" currencyCode:@"NOK"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Brazil" code2:@"BR" code3:@"BRA" currencyCode:@"BRL"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"British Indian Ocean Territory" code2:@"IO" code3:@"IOT" currencyCode:@"USD"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Brunei Darussalam" code2:@"BN" code3:@"BRN" currencyCode:@"BND"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Bulgaria" code2:@"BG" code3:@"BGR" currencyCode:@"BGN"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Burkina Faso" code2:@"BF" code3:@"BFA" currencyCode:@"XOF"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Burundi" code2:@"BI" code3:@"BDI" currencyCode:@"BIF"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Cambodia" code2:@"KH" code3:@"KHM" currencyCode:@"KHR"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Cameroon" code2:@"CM" code3:@"CMR" currencyCode:@"XAF"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Canada" code2:@"CA" code3:@"CAN" currencyCode:@"CAD"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Cape Verde" code2:@"CV" code3:@"CPV" currencyCode:@"CVE"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Cayman Islands" code2:@"KY" code3:@"CYM" currencyCode:@"KYD"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Central African Republic" code2:@"CF" code3:@"CAF" currencyCode:@"XAF"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Chad" code2:@"TD" code3:@"TCD" currencyCode:@"XAF"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Chile" code2:@"CL" code3:@"CHL" currencyCode:@"CLP"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"China" code2:@"CN" code3:@"CHN" currencyCode:@"CNY"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Christmas Island" code2:@"CX" code3:@"CXR" currencyCode:@"AUD"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Cocos (Keeling) Islands" code2:@"CC" code3:@"CCK" currencyCode:@"AUD"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Colombia" code2:@"CO" code3:@"COL" currencyCode:@"COP"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Comoros" code2:@"KM" code3:@"COM" currencyCode:@"KMF"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Congo" code2:@"CG" code3:@"COG" currencyCode:@"XAF"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Congo, the Democratic Republic of the" code2:@"CD" code3:@"COD" currencyCode:@"CDF"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Cook Islands" code2:@"CK" code3:@"COK" currencyCode:@"NZD"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Costa Rica" code2:@"CR" code3:@"CRI" currencyCode:@"CRC"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Croatia" code2:@"HR" code3:@"HRV" currencyCode:@"HRK"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Cuba" code2:@"CU" code3:@"CUB" currencyCode:@"CUP"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Curaçao" code2:@"CW" code3:@"CUW" currencyCode:@"ANG"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Cyprus" code2:@"CY" code3:@"CYP" currencyCode:@"EUR"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Czech Republic" code2:@"CZ" code3:@"CZE" currencyCode:@"CZK"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Côte d'Ivoire" code2:@"CI" code3:@"CIV" currencyCode:@"XOF"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Denmark" code2:@"DK" code3:@"DNK" currencyCode:@"DKK"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Djibouti" code2:@"DJ" code3:@"DJI" currencyCode:@"DJF"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Dominica" code2:@"DM" code3:@"DMA" currencyCode:@"XCD"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Dominican Republic" code2:@"DO" code3:@"DOM" currencyCode:@"DOP"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Ecuador" code2:@"EC" code3:@"ECU" currencyCode:@"USD"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Egypt" code2:@"EG" code3:@"EGY" currencyCode:@"EGP"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"El Salvador" code2:@"SV" code3:@"SLV" currencyCode:@"USD"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Equatorial Guinea" code2:@"GQ" code3:@"GNQ" currencyCode:@"XAF"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Eritrea" code2:@"ER" code3:@"ERI" currencyCode:@"ERN"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Estonia" code2:@"EE" code3:@"EST" currencyCode:@"EUR"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Ethiopia" code2:@"ET" code3:@"ETH" currencyCode:@"ETB"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Falkland Islands (Malvinas)" code2:@"FK" code3:@"FLK" currencyCode:@"FKP"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Faroe Islands" code2:@"FO" code3:@"FRO" currencyCode:@"DKK"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Fiji" code2:@"FJ" code3:@"FJI" currencyCode:@"FJD"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Finland" code2:@"FI" code3:@"FIN" currencyCode:@"EUR"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"France" code2:@"FR" code3:@"FRA" currencyCode:@"EUR"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"French Guiana" code2:@"GF" code3:@"GUF" currencyCode:@"EUR"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"French Polynesia" code2:@"PF" code3:@"PYF" currencyCode:@"XPF"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"French Southern Territories" code2:@"TF" code3:@"ATF" currencyCode:@"EUR"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Gabon" code2:@"GA" code3:@"GAB" currencyCode:@"XAF"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Gambia" code2:@"GM" code3:@"GMB" currencyCode:@"GMD"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Georgia" code2:@"GE" code3:@"GEO" currencyCode:@"GEL"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Germany" code2:@"DE" code3:@"DEU" currencyCode:@"EUR"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Ghana" code2:@"GH" code3:@"GHA" currencyCode:@"GHS"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Gibraltar" code2:@"GI" code3:@"GIB" currencyCode:@"GIP"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Greece" code2:@"GR" code3:@"GRC" currencyCode:@"EUR"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Greenland" code2:@"GL" code3:@"GRL" currencyCode:@"DKK"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Grenada" code2:@"GD" code3:@"GRD" currencyCode:@"XCD"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Guadeloupe" code2:@"GP" code3:@"GLP" currencyCode:@"EUR"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Guam" code2:@"GU" code3:@"GUM" currencyCode:@"USD"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Guatemala" code2:@"GT" code3:@"GTM" currencyCode:@"GTQ"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Guernsey" code2:@"GG" code3:@"GGY" currencyCode:@"GBP"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Guinea" code2:@"GN" code3:@"GIN" currencyCode:@"GNF"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Guinea-Bissau" code2:@"GW" code3:@"GNB" currencyCode:@"XOF"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Guyana" code2:@"GY" code3:@"GUY" currencyCode:@"GYD"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Haiti" code2:@"HT" code3:@"HTI" currencyCode:@"USD"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Heard Island and McDonald Mcdonald Islands" code2:@"HM" code3:@"HMD" currencyCode:@"AUD"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Holy See (Vatican City State)" code2:@"VA" code3:@"VAT" currencyCode:@"EUR"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Honduras" code2:@"HN" code3:@"HND" currencyCode:@"HNL"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Hong Kong" code2:@"HK" code3:@"HKG" currencyCode:@"HKD"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Hungary" code2:@"HU" code3:@"HUN" currencyCode:@"HUF"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Iceland" code2:@"IS" code3:@"ISL" currencyCode:@"ISK"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"India" code2:@"IN" code3:@"IND" currencyCode:@"INR"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Indonesia" code2:@"ID" code3:@"IDN" currencyCode:@"IDR"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Iran, Islamic Republic of" code2:@"IR" code3:@"IRN" currencyCode:@"IRR"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Iraq" code2:@"IQ" code3:@"IRQ" currencyCode:@"IQD"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Ireland" code2:@"IE" code3:@"IRL" currencyCode:@"EUR"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Isle of Man" code2:@"IM" code3:@"IMN" currencyCode:@"GBP"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Israel" code2:@"IL" code3:@"ISR" currencyCode:@"ILS"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Italy" code2:@"IT" code3:@"ITA" currencyCode:@"EUR"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Jamaica" code2:@"JM" code3:@"JAM" currencyCode:@"JMD"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Japan" code2:@"JP" code3:@"JPN" currencyCode:@"JPY"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Jersey" code2:@"JE" code3:@"JEY" currencyCode:@"GBP"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Jordan" code2:@"JO" code3:@"JOR" currencyCode:@"JOD"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Kazakhstan" code2:@"KZ" code3:@"KAZ" currencyCode:@"KZT"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Kenya" code2:@"KE" code3:@"KEN" currencyCode:@"KES"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Kiribati" code2:@"KI" code3:@"KIR" currencyCode:@"AUD"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Korea, Democratic People's Republic of" code2:@"KP" code3:@"PRK" currencyCode:@"KPW"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Korea, Republic of" code2:@"KR" code3:@"KOR" currencyCode:@"KRW"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Kuwait" code2:@"KW" code3:@"KWT" currencyCode:@"KWD"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Kyrgyzstan" code2:@"KG" code3:@"KGZ" currencyCode:@"KGS"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Lao People's Democratic Republic" code2:@"LA" code3:@"LAO" currencyCode:@"LAK"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Latvia" code2:@"LV" code3:@"LVA" currencyCode:@"LVL"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Lebanon" code2:@"LB" code3:@"LBN" currencyCode:@"LBP"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Lesotho" code2:@"LS" code3:@"LSO" currencyCode:@"ZAR"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Liberia" code2:@"LR" code3:@"LBR" currencyCode:@"LRD"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Libya" code2:@"LY" code3:@"LBY" currencyCode:@"LYD"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Liechtenstein" code2:@"LI" code3:@"LIE" currencyCode:@"CHF"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Lithuania" code2:@"LT" code3:@"LTU" currencyCode:@"LTL"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Luxembourg" code2:@"LU" code3:@"LUX" currencyCode:@"EUR"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Macao" code2:@"MO" code3:@"MAC" currencyCode:@"MOP"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Macedonia, the Former Yugoslav Republic of" code2:@"MK" code3:@"MKD" currencyCode:@"MKD"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Madagascar" code2:@"MG" code3:@"MDG" currencyCode:@"MGA"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Malawi" code2:@"MW" code3:@"MWI" currencyCode:@"MWK"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Malaysia" code2:@"MY" code3:@"MYS" currencyCode:@"MYR"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Maldives" code2:@"MV" code3:@"MDV" currencyCode:@"MVR"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Mali" code2:@"ML" code3:@"MLI" currencyCode:@"XOF"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Malta" code2:@"MT" code3:@"MLT" currencyCode:@"EUR"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Marshall Islands" code2:@"MH" code3:@"MHL" currencyCode:@"USD"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Martinique" code2:@"MQ" code3:@"MTQ" currencyCode:@"EUR"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Mauritania" code2:@"MR" code3:@"MRT" currencyCode:@"MRO"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Mauritius" code2:@"MU" code3:@"MUS" currencyCode:@"MUR"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Mayotte" code2:@"YT" code3:@"MYT" currencyCode:@"EUR"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Mexico" code2:@"MX" code3:@"MEX" currencyCode:@"MXN"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Micronesia, Federated States of" code2:@"FM" code3:@"FSM" currencyCode:@"USD"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Moldova, Republic of" code2:@"MD" code3:@"MDA" currencyCode:@"MDL"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Monaco" code2:@"MC" code3:@"MCO" currencyCode:@"EUR"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Mongolia" code2:@"MN" code3:@"MNG" currencyCode:@"MNT"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Montenegro" code2:@"ME" code3:@"MNE" currencyCode:@"EUR"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Montserrat" code2:@"MS" code3:@"MSR" currencyCode:@"XCD"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Morocco" code2:@"MA" code3:@"MAR" currencyCode:@"MAD"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Mozambique" code2:@"MZ" code3:@"MOZ" currencyCode:@"MZN"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Myanmar" code2:@"MM" code3:@"MMR" currencyCode:@"MMK"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Namibia" code2:@"NA" code3:@"NAM" currencyCode:@"ZAR"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Nauru" code2:@"NR" code3:@"NRU" currencyCode:@"AUD"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Nepal" code2:@"NP" code3:@"NPL" currencyCode:@"NPR"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Netherlands" code2:@"NL" code3:@"NLD" currencyCode:@"EUR"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"New Caledonia" code2:@"NC" code3:@"NCL" currencyCode:@"XPF"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"New Zealand" code2:@"NZ" code3:@"NZL" currencyCode:@"NZD"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Nicaragua" code2:@"NI" code3:@"NIC" currencyCode:@"NIO"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Niger" code2:@"NE" code3:@"NER" currencyCode:@"XOF"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Nigeria" code2:@"NG" code3:@"NGA" currencyCode:@"NGN"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Niue" code2:@"NU" code3:@"NIU" currencyCode:@"NZD"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Norfolk Island" code2:@"NF" code3:@"NFK" currencyCode:@"AUD"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Northern Mariana Islands" code2:@"MP" code3:@"MNP" currencyCode:@"USD"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Norway" code2:@"NO" code3:@"NOR" currencyCode:@"NOK"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Oman" code2:@"OM" code3:@"OMN" currencyCode:@"OMR"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Pakistan" code2:@"PK" code3:@"PAK" currencyCode:@"PKR"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Palau" code2:@"PW" code3:@"PLW" currencyCode:@"USD"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Palestine, State of" code2:@"PS" code3:@"PSE" currencyCode:@""]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Panama" code2:@"PA" code3:@"PAN" currencyCode:@"USD"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Papua New Guinea" code2:@"PG" code3:@"PNG" currencyCode:@"PGK"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Paraguay" code2:@"PY" code3:@"PRY" currencyCode:@"PYG"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Peru" code2:@"PE" code3:@"PER" currencyCode:@"PEN"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Philippines" code2:@"PH" code3:@"PHL" currencyCode:@"PHP"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Pitcairn" code2:@"PN" code3:@"PCN" currencyCode:@"NZD"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Poland" code2:@"PL" code3:@"POL" currencyCode:@"PLN"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Portugal" code2:@"PT" code3:@"PRT" currencyCode:@"EUR"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Puerto Rico" code2:@"PR" code3:@"PRI" currencyCode:@"USD"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Qatar" code2:@"QA" code3:@"QAT" currencyCode:@"QAR"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Romania" code2:@"RO" code3:@"ROU" currencyCode:@"RON"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Russian Federation" code2:@"RU" code3:@"RUS" currencyCode:@"RUB"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Rwanda" code2:@"RW" code3:@"RWA" currencyCode:@"RWF"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Réunion" code2:@"RE" code3:@"REU" currencyCode:@"EUR"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Saint Barthélemy" code2:@"BL" code3:@"BLM" currencyCode:@"EUR"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Saint Helena, Ascension and Tristan da Cunha" code2:@"SH" code3:@"SHN" currencyCode:@"SHP"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Saint Kitts and Nevis" code2:@"KN" code3:@"KNA" currencyCode:@"XCD"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Saint Lucia" code2:@"LC" code3:@"LCA" currencyCode:@"XCD"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Saint Martin (French part)" code2:@"MF" code3:@"MAF" currencyCode:@"EUR"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Saint Pierre and Miquelon" code2:@"PM" code3:@"SPM" currencyCode:@"EUR"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Saint Vincent and the Grenadines" code2:@"VC" code3:@"VCT" currencyCode:@"XCD"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Samoa" code2:@"WS" code3:@"WSM" currencyCode:@"WST"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"San Marino" code2:@"SM" code3:@"SMR" currencyCode:@"EUR"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Sao Tome and Principe" code2:@"ST" code3:@"STP" currencyCode:@"STD"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Saudi Arabia" code2:@"SA" code3:@"SAU" currencyCode:@"SAR"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Senegal" code2:@"SN" code3:@"SEN" currencyCode:@"XOF"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Serbia" code2:@"RS" code3:@"SRB" currencyCode:@"RSD"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Seychelles" code2:@"SC" code3:@"SYC" currencyCode:@"SCR"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Sierra Leone" code2:@"SL" code3:@"SLE" currencyCode:@"SLL"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Singapore" code2:@"SG" code3:@"SGP" currencyCode:@"SGD"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Sint Maarten (Dutch part)" code2:@"SX" code3:@"SXM" currencyCode:@"ANG"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Slovakia" code2:@"SK" code3:@"SVK" currencyCode:@"EUR"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Slovenia" code2:@"SI" code3:@"SVN" currencyCode:@"EUR"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Solomon Islands" code2:@"SB" code3:@"SLB" currencyCode:@"SBD"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Somalia" code2:@"SO" code3:@"SOM" currencyCode:@"SOS"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"South Africa" code2:@"ZA" code3:@"ZAF" currencyCode:@"ZAR"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"South Georgia and the South Sandwich Islands" code2:@"GS" code3:@"SGS" currencyCode:@""]];
    [countries addObject:[[OLCountry alloc] initWithName:@"South Sudan" code2:@"SS" code3:@"SSD" currencyCode:@"SSP"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Spain" code2:@"ES" code3:@"ESP" currencyCode:@"EUR"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Sri Lanka" code2:@"LK" code3:@"LKA" currencyCode:@"LKR"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Sudan" code2:@"SD" code3:@"SDN" currencyCode:@"SDG"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Suriname" code2:@"SR" code3:@"SUR" currencyCode:@"SRD"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Svalbard and Jan Mayen" code2:@"SJ" code3:@"SJM" currencyCode:@"NOK"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Swaziland" code2:@"SZ" code3:@"SWZ" currencyCode:@"SZL"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Sweden" code2:@"SE" code3:@"SWE" currencyCode:@"SEK"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Switzerland" code2:@"CH" code3:@"CHE" currencyCode:@"CHF"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Syrian Arab Republic" code2:@"SY" code3:@"SYR" currencyCode:@"SYP"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Taiwan, Province of China" code2:@"TW" code3:@"TWN" currencyCode:@"TWD"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Tajikistan" code2:@"TJ" code3:@"TJK" currencyCode:@"TJS"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Tanzania, United Republic of" code2:@"TZ" code3:@"TZA" currencyCode:@"TZS"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Thailand" code2:@"TH" code3:@"THA" currencyCode:@"THB"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Timor-Leste" code2:@"TL" code3:@"TLS" currencyCode:@"USD"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Togo" code2:@"TG" code3:@"TGO" currencyCode:@"XOF"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Tokelau" code2:@"TK" code3:@"TKL" currencyCode:@"NZD"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Tonga" code2:@"TO" code3:@"TON" currencyCode:@"TOP"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Trinidad and Tobago" code2:@"TT" code3:@"TTO" currencyCode:@"TTD"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Tunisia" code2:@"TN" code3:@"TUN" currencyCode:@"TND"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Turkey" code2:@"TR" code3:@"TUR" currencyCode:@"TRY"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Turkmenistan" code2:@"TM" code3:@"TKM" currencyCode:@"TMT"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Turks and Caicos Islands" code2:@"TC" code3:@"TCA" currencyCode:@"USD"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Tuvalu" code2:@"TV" code3:@"TUV" currencyCode:@"AUD"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Uganda" code2:@"UG" code3:@"UGA" currencyCode:@"UGX"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Ukraine" code2:@"UA" code3:@"UKR" currencyCode:@"UAH"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"United Arab Emirates" code2:@"AE" code3:@"ARE" currencyCode:@"AED"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"United Kingdom" code2:@"GB" code3:@"GBR" currencyCode:@"GBP"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"United States" code2:@"US" code3:@"USA" currencyCode:@"USD"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"United States Minor Outlying Islands" code2:@"UM" code3:@"UMI" currencyCode:@"USD"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Uruguay" code2:@"UY" code3:@"URY" currencyCode:@"UYU"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Uzbekistan" code2:@"UZ" code3:@"UZB" currencyCode:@"UZS"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Vanuatu" code2:@"VU" code3:@"VUT" currencyCode:@"VUV"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Venezuela, Bolivarian Republic of" code2:@"VE" code3:@"VEN" currencyCode:@"VEF"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Viet Nam" code2:@"VN" code3:@"VNM" currencyCode:@"VND"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Virgin Islands, British" code2:@"VG" code3:@"VGB" currencyCode:@"USD"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Virgin Islands, U.S." code2:@"VI" code3:@"VIR" currencyCode:@"USD"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Wallis and Futuna" code2:@"WF" code3:@"WLF" currencyCode:@"XPF"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Western Sahara" code2:@"EH" code3:@"ESH" currencyCode:@"MAD"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Yemen" code2:@"YE" code3:@"YEM" currencyCode:@"YER"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Zambia" code2:@"ZM" code3:@"ZMB" currencyCode:@"ZMW"]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Zimbabwe" code2:@"ZW" code3:@"ZWE" currencyCode:@"ZWL"]];
    
    // Quick sanity check to only add countries that have all the details we want
    for (NSInteger i = countries.count - 1; i >= 0; --i) {
        OLCountry *c = countries[i];
        if (c.codeAlpha2.length != 2 || c.codeAlpha3.length != 3
            || [c.currencyCode stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].length == 0) {
            [countries removeObjectAtIndex:i];
        }
    }
    
    
    return countries;
}

@end
