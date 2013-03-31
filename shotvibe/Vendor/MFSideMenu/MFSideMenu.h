//
/* Copyright (c) 2012, Michael Frederick
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of Michael Frederick nor the
 *       names of its contributors may be used to endorse or promote products
 *       derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY Michael Frederick ''AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL Michael Frederick BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

//  MFSideMenu.h
//
//  Created by Michael Frederick on 3/17/12.
//

#import "UINavigationController+MFSideMenu.h"

static const CGFloat kMFSideMenuSidebarWidth = 260.0f; // size of the side menu(s)
static const CGFloat kMFSideMenuShadowRadius = 10.0f; // radius of the shadow
static const CGFloat kMFSideMenuAnimationDuration = 0.3f; // default duration for the open/close animation
static const CGFloat kMFSideMenuAnimationMaxDuration = 0.4f; // maximum duration for the open/close animation

typedef enum {
    MFSideMenuPanModeNavigationBar = 1 << 0, // enable panning on the navigation bar
    MFSideMenuPanModeNavigationController = 1 << 1 // enable panning on the body of the navigation controller
} MFSideMenuPanMode;

typedef enum {
    MFSideMenuStateClosed, // the menu is closed
    MFSideMenuStateLeftMenuOpen, // the left-hand menu is open
    MFSideMenuStateRightMenuOpen // the right-hand menu is open
} MFSideMenuState;

typedef enum {
    MFSideMenuStateEventMenuWillOpen, // the menu is going to open
    MFSideMenuStateEventMenuDidOpen, // the menu finished opening
    MFSideMenuStateEventMenuWillClose, // the menu is going to close
    MFSideMenuStateEventMenuDidClose // the menu finished closing
} MFSideMenuStateEvent;

typedef void (^MFSideMenuStateEventBlock)(MFSideMenuStateEvent);

@interface MFSideMenu : NSObject<UIGestureRecognizerDelegate>

@property (nonatomic, readonly) UINavigationController *navigationController;

@property (nonatomic, assign) MFSideMenuState menuState;
@property (nonatomic, assign) MFSideMenuPanMode panMode;
@property (nonatomic, assign) BOOL shadowEnabled;

// this can be used to observe all MFSideMenuStateEvents
@property (copy) MFSideMenuStateEventBlock menuStateEventBlock;

+ (MFSideMenu *)menuWithNavigationController:(UINavigationController *)controller
                      leftSideMenuController:(id)leftMenuController
                     rightSideMenuController:(id)rightMenuController;

+ (MFSideMenu *)menuWithNavigationController:(UINavigationController *)controller
                       leftSideMenuController:(id)leftMenuController
                      rightSideMenuController:(id)rightMenuController
                                      panMode:(MFSideMenuPanMode)panMode;

// I'm taking this.
@property (nonatomic, strong) UIViewController *rightSideMenuViewController;
@property (nonatomic, strong) UIViewController *leftSideMenuViewController;
@property (nonatomic, strong) UIView *menuContainerView;

- (void)toggleLeftSideMenu;
- (void)toggleRightSideMenu;

@end
