//
//  RNDDDropTargetView.h
//  gustash-react-native-drag-drop
//
//  Created by Gustavo Parreira on 26/04/2022.
//

#ifndef RNDDDropTargetView_h
#define RNDDDropTargetView_h

#import <UIKit/UIKit.h>
#import <React/RCTComponent.h>

@interface RNDDDropTargetView : UIView

@property (nonatomic, copy) RCTBubblingEventBlock onDrop;

@end

#endif /* RNDDDropTargetView_h */
