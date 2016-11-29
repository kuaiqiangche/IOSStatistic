//
//  KQCStatisticLogger.h
//  B2B_iOS
//
//  Created by 史衡 on 2016/11/22.
//  Copyright © 2016年 KQC. All rights reserved.
//

#ifndef KQCStatisticLogger_h
#define KQCStatisticLogger_h

#ifdef DEBUG
#define KQCStatisticLogger( s, ... ) NSLog( @"<%@:%d> %@", [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__,  [NSString stringWithFormat:(s), ##__VA_ARGS__] )
#else
#define KQCStatisticLogger( s, ...)
#endif
#endif /* KQCStatisticLogger_h */
