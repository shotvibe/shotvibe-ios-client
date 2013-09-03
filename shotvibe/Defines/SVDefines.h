//
//  SVDefines.h
//  shotvibe
//
//  Created by Fredrick Gabelmann on 2/12/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#ifndef shotvibe_SVDefines_h
#define shotvibe_SVDefines_h

#define IS_IOS6_OR_GREATER ([[UIDevice currentDevice].systemVersion floatValue] >= 6.0)
#define IS_IPHONE_5 ( fabs( ( double )[ [ UIScreen mainScreen ] bounds ].size.height - ( double )568 ) < DBL_EPSILON )

#define kMemberNickname     @"nickname"
#define kMemberPhone        @"phone"
#define kMemberFirstName    @"firstName"
#define kMemberLastName     @"lastname"
#define kMemberIcon			@"member_icon"

#endif
