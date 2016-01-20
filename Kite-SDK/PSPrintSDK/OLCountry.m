//
//  Modified MIT License
//
//  Copyright (c) 2010-2016 Kite Tech Ltd. https://www.kite.ly
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

#import "OLCountry.h"

@interface OLCountry () {
BOOL _inEurope;
}

@end

@implementation OLCountry

- (id)initWithName:(NSString *)name code2:(NSString *)code2 code3:(NSString *)code3 currencyCode:(NSString *)currencyCode inEurope:(BOOL)inEurope {
    if (self = [super init]) {
        _name = name;
        _codeAlpha2 = code2;
        _codeAlpha3 = code3;
        _currencyCode = currencyCode;
        _inEurope = inEurope;
    }
    
    return self;
}

- (BOOL)isInEurope {
    return _inEurope;
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

+ (OLCountry *)countryForName:(NSString *)name {
    NSArray *countries = [OLCountry countries];
    for (OLCountry *country in countries) {
        if ([[country.name uppercaseString] isEqualToString:[name uppercaseString]]) {
            return country;
        }
    }
    
    return nil;
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
    [countries addObject:[[OLCountry alloc] initWithName:@"Åland Islands" code2:@"AX" code3:@"ALA" currencyCode:@"EUR" inEurope:YES]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Afghanistan" code2:@"AF" code3:@"AFG" currencyCode:@"AFN" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Albania" code2:@"AL" code3:@"ALB" currencyCode:@"ALL" inEurope:YES]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Algeria" code2:@"DZ" code3:@"DZA" currencyCode:@"DZD" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"American Samoa" code2:@"AS" code3:@"ASM" currencyCode:@"USD" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Andorra" code2:@"AD" code3:@"AND" currencyCode:@"EUR" inEurope:YES]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Angola" code2:@"AO" code3:@"AGO" currencyCode:@"AOA" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Anguilla" code2:@"AI" code3:@"AIA" currencyCode:@"XCD" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Antarctica" code2:@"AQ" code3:@"ATA" currencyCode:@"" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Antigua and Barbuda" code2:@"AG" code3:@"ATG" currencyCode:@"XCD" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Argentina" code2:@"AR" code3:@"ARG" currencyCode:@"ARS" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Armenia" code2:@"AM" code3:@"ARM" currencyCode:@"AMD" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Aruba" code2:@"AW" code3:@"ABW" currencyCode:@"AWG" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Australia" code2:@"AU" code3:@"AUS" currencyCode:@"AUD" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Austria" code2:@"AT" code3:@"AUT" currencyCode:@"EUR" inEurope:YES]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Azerbaijan" code2:@"AZ" code3:@"AZE" currencyCode:@"AZN" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Bahamas" code2:@"BS" code3:@"BHS" currencyCode:@"BSD" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Bahrain" code2:@"BH" code3:@"BHR" currencyCode:@"BHD" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Bangladesh" code2:@"BD" code3:@"BGD" currencyCode:@"BDT" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Barbados" code2:@"BB" code3:@"BRB" currencyCode:@"BBD" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Belarus" code2:@"BY" code3:@"BLR" currencyCode:@"BYR" inEurope:YES]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Belgium" code2:@"BE" code3:@"BEL" currencyCode:@"EUR" inEurope:YES]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Belize" code2:@"BZ" code3:@"BLZ" currencyCode:@"BZD" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Benin" code2:@"BJ" code3:@"BEN" currencyCode:@"XOF" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Bermuda" code2:@"BM" code3:@"BMU" currencyCode:@"BMD" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Bhutan" code2:@"BT" code3:@"BTN" currencyCode:@"INR" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Bolivia, Plurinational State of" code2:@"BO" code3:@"BOL" currencyCode:@"BOB" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Bonaire, Sint Eustatius and Saba" code2:@"BQ" code3:@"BES" currencyCode:@"USD" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Bosnia and Herzegovina" code2:@"BA" code3:@"BIH" currencyCode:@"BAM" inEurope:YES]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Botswana" code2:@"BW" code3:@"BWA" currencyCode:@"BWP" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Bouvet Island" code2:@"BV" code3:@"BVT" currencyCode:@"NOK" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Brazil" code2:@"BR" code3:@"BRA" currencyCode:@"BRL" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"British Indian Ocean Territory" code2:@"IO" code3:@"IOT" currencyCode:@"USD" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Brunei Darussalam" code2:@"BN" code3:@"BRN" currencyCode:@"BND" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Bulgaria" code2:@"BG" code3:@"BGR" currencyCode:@"BGN" inEurope:YES]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Burkina Faso" code2:@"BF" code3:@"BFA" currencyCode:@"XOF" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Burundi" code2:@"BI" code3:@"BDI" currencyCode:@"BIF" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Cambodia" code2:@"KH" code3:@"KHM" currencyCode:@"KHR" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Cameroon" code2:@"CM" code3:@"CMR" currencyCode:@"XAF" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Canada" code2:@"CA" code3:@"CAN" currencyCode:@"CAD" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Cape Verde" code2:@"CV" code3:@"CPV" currencyCode:@"CVE" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Cayman Islands" code2:@"KY" code3:@"CYM" currencyCode:@"KYD" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Central African Republic" code2:@"CF" code3:@"CAF" currencyCode:@"XAF" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Chad" code2:@"TD" code3:@"TCD" currencyCode:@"XAF" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Chile" code2:@"CL" code3:@"CHL" currencyCode:@"CLP" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"China" code2:@"CN" code3:@"CHN" currencyCode:@"CNY" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Christmas Island" code2:@"CX" code3:@"CXR" currencyCode:@"AUD" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Cocos (Keeling) Islands" code2:@"CC" code3:@"CCK" currencyCode:@"AUD" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Colombia" code2:@"CO" code3:@"COL" currencyCode:@"COP" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Comoros" code2:@"KM" code3:@"COM" currencyCode:@"KMF" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Congo" code2:@"CG" code3:@"COG" currencyCode:@"XAF" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Congo, the Democratic Republic of the" code2:@"CD" code3:@"COD" currencyCode:@"CDF" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Cook Islands" code2:@"CK" code3:@"COK" currencyCode:@"NZD" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Costa Rica" code2:@"CR" code3:@"CRI" currencyCode:@"CRC" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Croatia" code2:@"HR" code3:@"HRV" currencyCode:@"HRK" inEurope:YES]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Cuba" code2:@"CU" code3:@"CUB" currencyCode:@"CUP" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Curaçao" code2:@"CW" code3:@"CUW" currencyCode:@"ANG" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Cyprus" code2:@"CY" code3:@"CYP" currencyCode:@"EUR" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Czech Republic" code2:@"CZ" code3:@"CZE" currencyCode:@"CZK" inEurope:YES]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Côte d'Ivoire" code2:@"CI" code3:@"CIV" currencyCode:@"XOF" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Denmark" code2:@"DK" code3:@"DNK" currencyCode:@"DKK" inEurope:YES]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Djibouti" code2:@"DJ" code3:@"DJI" currencyCode:@"DJF" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Dominica" code2:@"DM" code3:@"DMA" currencyCode:@"XCD" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Dominican Republic" code2:@"DO" code3:@"DOM" currencyCode:@"DOP" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Ecuador" code2:@"EC" code3:@"ECU" currencyCode:@"USD" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Egypt" code2:@"EG" code3:@"EGY" currencyCode:@"EGP" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"El Salvador" code2:@"SV" code3:@"SLV" currencyCode:@"USD" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Equatorial Guinea" code2:@"GQ" code3:@"GNQ" currencyCode:@"XAF" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Eritrea" code2:@"ER" code3:@"ERI" currencyCode:@"ERN" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Estonia" code2:@"EE" code3:@"EST" currencyCode:@"EUR" inEurope:YES]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Ethiopia" code2:@"ET" code3:@"ETH" currencyCode:@"ETB" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Falkland Islands (Malvinas)" code2:@"FK" code3:@"FLK" currencyCode:@"FKP" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Faroe Islands" code2:@"FO" code3:@"FRO" currencyCode:@"DKK" inEurope:YES]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Fiji" code2:@"FJ" code3:@"FJI" currencyCode:@"FJD" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Finland" code2:@"FI" code3:@"FIN" currencyCode:@"EUR" inEurope:YES]];
    [countries addObject:[[OLCountry alloc] initWithName:@"France" code2:@"FR" code3:@"FRA" currencyCode:@"EUR" inEurope:YES]];
    [countries addObject:[[OLCountry alloc] initWithName:@"French Guiana" code2:@"GF" code3:@"GUF" currencyCode:@"EUR" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"French Polynesia" code2:@"PF" code3:@"PYF" currencyCode:@"XPF" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"French Southern Territories" code2:@"TF" code3:@"ATF" currencyCode:@"EUR" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Gabon" code2:@"GA" code3:@"GAB" currencyCode:@"XAF" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Gambia" code2:@"GM" code3:@"GMB" currencyCode:@"GMD" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Georgia" code2:@"GE" code3:@"GEO" currencyCode:@"GEL" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Germany" code2:@"DE" code3:@"DEU" currencyCode:@"EUR" inEurope:YES]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Ghana" code2:@"GH" code3:@"GHA" currencyCode:@"GHS" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Gibraltar" code2:@"GI" code3:@"GIB" currencyCode:@"GIP" inEurope:YES]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Greece" code2:@"GR" code3:@"GRC" currencyCode:@"EUR" inEurope:YES]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Greenland" code2:@"GL" code3:@"GRL" currencyCode:@"DKK" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Grenada" code2:@"GD" code3:@"GRD" currencyCode:@"XCD" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Guadeloupe" code2:@"GP" code3:@"GLP" currencyCode:@"EUR" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Guam" code2:@"GU" code3:@"GUM" currencyCode:@"USD" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Guatemala" code2:@"GT" code3:@"GTM" currencyCode:@"GTQ" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Guernsey" code2:@"GG" code3:@"GGY" currencyCode:@"GBP" inEurope:YES]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Guinea" code2:@"GN" code3:@"GIN" currencyCode:@"GNF" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Guinea-Bissau" code2:@"GW" code3:@"GNB" currencyCode:@"XOF" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Guyana" code2:@"GY" code3:@"GUY" currencyCode:@"GYD" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Haiti" code2:@"HT" code3:@"HTI" currencyCode:@"USD" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Heard Island and McDonald Mcdonald Islands" code2:@"HM" code3:@"HMD" currencyCode:@"AUD" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Holy See (Vatican City State)" code2:@"VA" code3:@"VAT" currencyCode:@"EUR" inEurope:YES]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Honduras" code2:@"HN" code3:@"HND" currencyCode:@"HNL" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Hong Kong" code2:@"HK" code3:@"HKG" currencyCode:@"HKD" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Hungary" code2:@"HU" code3:@"HUN" currencyCode:@"HUF" inEurope:YES]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Iceland" code2:@"IS" code3:@"ISL" currencyCode:@"ISK" inEurope:YES]];
    [countries addObject:[[OLCountry alloc] initWithName:@"India" code2:@"IN" code3:@"IND" currencyCode:@"INR" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Indonesia" code2:@"ID" code3:@"IDN" currencyCode:@"IDR" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Iran, Islamic Republic of" code2:@"IR" code3:@"IRN" currencyCode:@"IRR" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Iraq" code2:@"IQ" code3:@"IRQ" currencyCode:@"IQD" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Ireland" code2:@"IE" code3:@"IRL" currencyCode:@"EUR" inEurope:YES]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Isle of Man" code2:@"IM" code3:@"IMN" currencyCode:@"GBP" inEurope:YES]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Israel" code2:@"IL" code3:@"ISR" currencyCode:@"ILS" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Italy" code2:@"IT" code3:@"ITA" currencyCode:@"EUR" inEurope:YES]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Jamaica" code2:@"JM" code3:@"JAM" currencyCode:@"JMD" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Japan" code2:@"JP" code3:@"JPN" currencyCode:@"JPY" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Jersey" code2:@"JE" code3:@"JEY" currencyCode:@"GBP" inEurope:YES]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Jordan" code2:@"JO" code3:@"JOR" currencyCode:@"JOD" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Kazakhstan" code2:@"KZ" code3:@"KAZ" currencyCode:@"KZT" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Kenya" code2:@"KE" code3:@"KEN" currencyCode:@"KES" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Kiribati" code2:@"KI" code3:@"KIR" currencyCode:@"AUD" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Korea, Democratic People's Republic of" code2:@"KP" code3:@"PRK" currencyCode:@"KPW" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Korea, Republic of" code2:@"KR" code3:@"KOR" currencyCode:@"KRW" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Kuwait" code2:@"KW" code3:@"KWT" currencyCode:@"KWD" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Kyrgyzstan" code2:@"KG" code3:@"KGZ" currencyCode:@"KGS" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Lao People's Democratic Republic" code2:@"LA" code3:@"LAO" currencyCode:@"LAK" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Latvia" code2:@"LV" code3:@"LVA" currencyCode:@"LVL" inEurope:YES]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Lebanon" code2:@"LB" code3:@"LBN" currencyCode:@"LBP" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Lesotho" code2:@"LS" code3:@"LSO" currencyCode:@"ZAR" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Liberia" code2:@"LR" code3:@"LBR" currencyCode:@"LRD" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Libya" code2:@"LY" code3:@"LBY" currencyCode:@"LYD" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Liechtenstein" code2:@"LI" code3:@"LIE" currencyCode:@"CHF" inEurope:YES]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Lithuania" code2:@"LT" code3:@"LTU" currencyCode:@"LTL" inEurope:YES]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Luxembourg" code2:@"LU" code3:@"LUX" currencyCode:@"EUR" inEurope:YES]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Macao" code2:@"MO" code3:@"MAC" currencyCode:@"MOP" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Macedonia, the Former Yugoslav Republic of" code2:@"MK" code3:@"MKD" currencyCode:@"MKD" inEurope:YES]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Madagascar" code2:@"MG" code3:@"MDG" currencyCode:@"MGA" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Malawi" code2:@"MW" code3:@"MWI" currencyCode:@"MWK" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Malaysia" code2:@"MY" code3:@"MYS" currencyCode:@"MYR" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Maldives" code2:@"MV" code3:@"MDV" currencyCode:@"MVR" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Mali" code2:@"ML" code3:@"MLI" currencyCode:@"XOF" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Malta" code2:@"MT" code3:@"MLT" currencyCode:@"EUR" inEurope:YES]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Marshall Islands" code2:@"MH" code3:@"MHL" currencyCode:@"USD" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Martinique" code2:@"MQ" code3:@"MTQ" currencyCode:@"EUR" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Mauritania" code2:@"MR" code3:@"MRT" currencyCode:@"MRO" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Mauritius" code2:@"MU" code3:@"MUS" currencyCode:@"MUR" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Mayotte" code2:@"YT" code3:@"MYT" currencyCode:@"EUR" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Mexico" code2:@"MX" code3:@"MEX" currencyCode:@"MXN" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Micronesia, Federated States of" code2:@"FM" code3:@"FSM" currencyCode:@"USD" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Moldova, Republic of" code2:@"MD" code3:@"MDA" currencyCode:@"MDL" inEurope:YES]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Monaco" code2:@"MC" code3:@"MCO" currencyCode:@"EUR" inEurope:YES]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Mongolia" code2:@"MN" code3:@"MNG" currencyCode:@"MNT" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Montenegro" code2:@"ME" code3:@"MNE" currencyCode:@"EUR" inEurope:YES]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Montserrat" code2:@"MS" code3:@"MSR" currencyCode:@"XCD" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Morocco" code2:@"MA" code3:@"MAR" currencyCode:@"MAD" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Mozambique" code2:@"MZ" code3:@"MOZ" currencyCode:@"MZN" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Myanmar" code2:@"MM" code3:@"MMR" currencyCode:@"MMK" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Namibia" code2:@"NA" code3:@"NAM" currencyCode:@"ZAR" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Nauru" code2:@"NR" code3:@"NRU" currencyCode:@"AUD" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Nepal" code2:@"NP" code3:@"NPL" currencyCode:@"NPR" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Netherlands" code2:@"NL" code3:@"NLD" currencyCode:@"EUR" inEurope:YES]];
    [countries addObject:[[OLCountry alloc] initWithName:@"New Caledonia" code2:@"NC" code3:@"NCL" currencyCode:@"XPF" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"New Zealand" code2:@"NZ" code3:@"NZL" currencyCode:@"NZD" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Nicaragua" code2:@"NI" code3:@"NIC" currencyCode:@"NIO" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Niger" code2:@"NE" code3:@"NER" currencyCode:@"XOF" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Nigeria" code2:@"NG" code3:@"NGA" currencyCode:@"NGN" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Niue" code2:@"NU" code3:@"NIU" currencyCode:@"NZD" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Norfolk Island" code2:@"NF" code3:@"NFK" currencyCode:@"AUD" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Northern Mariana Islands" code2:@"MP" code3:@"MNP" currencyCode:@"USD" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Norway" code2:@"NO" code3:@"NOR" currencyCode:@"NOK" inEurope:YES]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Oman" code2:@"OM" code3:@"OMN" currencyCode:@"OMR" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Pakistan" code2:@"PK" code3:@"PAK" currencyCode:@"PKR" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Palau" code2:@"PW" code3:@"PLW" currencyCode:@"USD" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Palestine, State of" code2:@"PS" code3:@"PSE" currencyCode:@"" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Panama" code2:@"PA" code3:@"PAN" currencyCode:@"USD" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Papua New Guinea" code2:@"PG" code3:@"PNG" currencyCode:@"PGK" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Paraguay" code2:@"PY" code3:@"PRY" currencyCode:@"PYG" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Peru" code2:@"PE" code3:@"PER" currencyCode:@"PEN" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Philippines" code2:@"PH" code3:@"PHL" currencyCode:@"PHP" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Pitcairn" code2:@"PN" code3:@"PCN" currencyCode:@"NZD" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Poland" code2:@"PL" code3:@"POL" currencyCode:@"PLN" inEurope:YES]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Portugal" code2:@"PT" code3:@"PRT" currencyCode:@"EUR" inEurope:YES]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Puerto Rico" code2:@"PR" code3:@"PRI" currencyCode:@"USD" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Qatar" code2:@"QA" code3:@"QAT" currencyCode:@"QAR" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Romania" code2:@"RO" code3:@"ROU" currencyCode:@"RON" inEurope:YES]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Russian Federation" code2:@"RU" code3:@"RUS" currencyCode:@"RUB" inEurope:YES]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Rwanda" code2:@"RW" code3:@"RWA" currencyCode:@"RWF" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Réunion" code2:@"RE" code3:@"REU" currencyCode:@"EUR" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Saint Barthélemy" code2:@"BL" code3:@"BLM" currencyCode:@"EUR" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Saint Helena, Ascension and Tristan da Cunha" code2:@"SH" code3:@"SHN" currencyCode:@"SHP" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Saint Kitts and Nevis" code2:@"KN" code3:@"KNA" currencyCode:@"XCD" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Saint Lucia" code2:@"LC" code3:@"LCA" currencyCode:@"XCD" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Saint Martin (French part)" code2:@"MF" code3:@"MAF" currencyCode:@"EUR" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Saint Pierre and Miquelon" code2:@"PM" code3:@"SPM" currencyCode:@"EUR" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Saint Vincent and the Grenadines" code2:@"VC" code3:@"VCT" currencyCode:@"XCD" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Samoa" code2:@"WS" code3:@"WSM" currencyCode:@"WST" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"San Marino" code2:@"SM" code3:@"SMR" currencyCode:@"EUR" inEurope:YES]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Sao Tome and Principe" code2:@"ST" code3:@"STP" currencyCode:@"STD" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Saudi Arabia" code2:@"SA" code3:@"SAU" currencyCode:@"SAR" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Senegal" code2:@"SN" code3:@"SEN" currencyCode:@"XOF" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Serbia" code2:@"RS" code3:@"SRB" currencyCode:@"RSD" inEurope:YES]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Seychelles" code2:@"SC" code3:@"SYC" currencyCode:@"SCR" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Sierra Leone" code2:@"SL" code3:@"SLE" currencyCode:@"SLL" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Singapore" code2:@"SG" code3:@"SGP" currencyCode:@"SGD" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Sint Maarten (Dutch part)" code2:@"SX" code3:@"SXM" currencyCode:@"ANG" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Slovakia" code2:@"SK" code3:@"SVK" currencyCode:@"EUR" inEurope:YES]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Slovenia" code2:@"SI" code3:@"SVN" currencyCode:@"EUR" inEurope:YES]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Solomon Islands" code2:@"SB" code3:@"SLB" currencyCode:@"SBD" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Somalia" code2:@"SO" code3:@"SOM" currencyCode:@"SOS" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"South Africa" code2:@"ZA" code3:@"ZAF" currencyCode:@"ZAR" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"South Georgia and the South Sandwich Islands" code2:@"GS" code3:@"SGS" currencyCode:@"" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"South Sudan" code2:@"SS" code3:@"SSD" currencyCode:@"SSP" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Spain" code2:@"ES" code3:@"ESP" currencyCode:@"EUR" inEurope:YES]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Sri Lanka" code2:@"LK" code3:@"LKA" currencyCode:@"LKR" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Sudan" code2:@"SD" code3:@"SDN" currencyCode:@"SDG" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Suriname" code2:@"SR" code3:@"SUR" currencyCode:@"SRD" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Svalbard and Jan Mayen" code2:@"SJ" code3:@"SJM" currencyCode:@"NOK" inEurope:YES]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Swaziland" code2:@"SZ" code3:@"SWZ" currencyCode:@"SZL" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Sweden" code2:@"SE" code3:@"SWE" currencyCode:@"SEK" inEurope:YES]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Switzerland" code2:@"CH" code3:@"CHE" currencyCode:@"CHF" inEurope:YES]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Syrian Arab Republic" code2:@"SY" code3:@"SYR" currencyCode:@"SYP" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Taiwan" code2:@"TW" code3:@"TWN" currencyCode:@"TWD" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Tajikistan" code2:@"TJ" code3:@"TJK" currencyCode:@"TJS" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Tanzania, United Republic of" code2:@"TZ" code3:@"TZA" currencyCode:@"TZS" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Thailand" code2:@"TH" code3:@"THA" currencyCode:@"THB" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Timor-Leste" code2:@"TL" code3:@"TLS" currencyCode:@"USD" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Togo" code2:@"TG" code3:@"TGO" currencyCode:@"XOF" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Tokelau" code2:@"TK" code3:@"TKL" currencyCode:@"NZD" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Tonga" code2:@"TO" code3:@"TON" currencyCode:@"TOP" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Trinidad and Tobago" code2:@"TT" code3:@"TTO" currencyCode:@"TTD" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Tunisia" code2:@"TN" code3:@"TUN" currencyCode:@"TND" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Turkey" code2:@"TR" code3:@"TUR" currencyCode:@"TRY" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Turkmenistan" code2:@"TM" code3:@"TKM" currencyCode:@"TMT" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Turks and Caicos Islands" code2:@"TC" code3:@"TCA" currencyCode:@"USD" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Tuvalu" code2:@"TV" code3:@"TUV" currencyCode:@"AUD" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Uganda" code2:@"UG" code3:@"UGA" currencyCode:@"UGX" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Ukraine" code2:@"UA" code3:@"UKR" currencyCode:@"UAH" inEurope:YES]];
    [countries addObject:[[OLCountry alloc] initWithName:@"United Arab Emirates" code2:@"AE" code3:@"ARE" currencyCode:@"AED" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"United Kingdom" code2:@"GB" code3:@"GBR" currencyCode:@"GBP" inEurope:YES]];
    [countries addObject:[[OLCountry alloc] initWithName:@"United States" code2:@"US" code3:@"USA" currencyCode:@"USD" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"United States Minor Outlying Islands" code2:@"UM" code3:@"UMI" currencyCode:@"USD" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Uruguay" code2:@"UY" code3:@"URY" currencyCode:@"UYU" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Uzbekistan" code2:@"UZ" code3:@"UZB" currencyCode:@"UZS" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Vanuatu" code2:@"VU" code3:@"VUT" currencyCode:@"VUV" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Venezuela, Bolivarian Republic of" code2:@"VE" code3:@"VEN" currencyCode:@"VEF" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Viet Nam" code2:@"VN" code3:@"VNM" currencyCode:@"VND" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Virgin Islands, British" code2:@"VG" code3:@"VGB" currencyCode:@"USD" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Virgin Islands, U.S." code2:@"VI" code3:@"VIR" currencyCode:@"USD" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Wallis and Futuna" code2:@"WF" code3:@"WLF" currencyCode:@"XPF" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Western Sahara" code2:@"EH" code3:@"ESH" currencyCode:@"MAD" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Yemen" code2:@"YE" code3:@"YEM" currencyCode:@"YER" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Zambia" code2:@"ZM" code3:@"ZMB" currencyCode:@"ZMW" inEurope:NO]];
    [countries addObject:[[OLCountry alloc] initWithName:@"Zimbabwe" code2:@"ZW" code3:@"ZWE" currencyCode:@"ZWL" inEurope:NO]];
    
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
