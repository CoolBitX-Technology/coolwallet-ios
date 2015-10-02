//
//  CwHost.m
//  CwTest
//
//  Created by CP Hsiao on 2014/12/14.
//  Copyright (c) 2014年 CP Hsiao. All rights reserved.
//

#import "CwHost.h"

@interface CwHost ()

@end

@implementation CwHost

- (void) encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeInteger:self.hostBindStatus forKey:@"hostBindStatus"];
    [encoder encodeObject:self.hostDescription forKey:@"hostDescription"];}

- (id)initWithCoder:(NSCoder *)decoder {
    self.hostBindStatus = [decoder decodeIntegerForKey:@"hostBindStatus"];
    self.hostDescription = [decoder decodeObjectForKey:@"hostDescription"];
    return self;
}

@end
