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
#import "OLSwizzler.h"
#import <objc/runtime.h>

@implementation OLSwizzler

BOOL OLSwizzleInstanceMethods(Class class, SEL dstSel, SEL srcSel)
{
    Method dstMethod = class_getInstanceMethod(class, dstSel);
    Method srcMethod = class_getInstanceMethod(class, srcSel);
    if (!srcMethod)
    {
        @throw [NSException exceptionWithName:@"InvalidParameter"
                
                                       reason:[NSString stringWithFormat:@"Missing source method implementation for swizzling!  Class %@, Source: %@, Destination: %@", NSStringFromClass(class), NSStringFromSelector(srcSel), NSStringFromSelector(dstSel)]
                                     userInfo:nil];
    }
    IMP srcIMP = method_getImplementation(srcMethod);
    if (class_addMethod(class, dstSel, srcIMP, method_getTypeEncoding(srcMethod)))
    {
        class_replaceMethod(class, dstSel, method_getImplementation(dstMethod), method_getTypeEncoding(dstMethod));
    }
    else
    {
        method_exchangeImplementations(dstMethod, srcMethod);
    }
    return (method_getImplementation(srcMethod) == method_getImplementation(class_getInstanceMethod(class, dstSel)));
}

BOOL OLSwizzleClassMethods(Class class, SEL dstSel, SEL srcSel)
{
    Class metaClass = object_getClass(class);
    if (!metaClass || metaClass == class) // the metaClass being the same as class shows that class was already a MetaClass
    {
        @throw [NSException exceptionWithName:@"InvalidParameter"
                                       reason:[NSString stringWithFormat:@"%@ does not have a meta class to swizzle methods on!", NSStringFromClass(class)]
                                     userInfo:nil];
    }
    return OLSwizzleInstanceMethods(metaClass, dstSel, srcSel);
}

@end
