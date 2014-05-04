//
//  GKTurnBasedHelper.h
//
//  Created by Guven Iscan on 10/02/14.
//
//

#import <Foundation/Foundation.h>
#import <GameKit/GameKit.h>

@interface GKTurnBasedHelper : NSObject

//Returns index or indices (in case player scores are tied) of winners in match
+(NSArray *) getWinnerIndicesInEndedMatch:(GKTurnBasedMatch *) match;

//Checks if local player has the match outcome 'won'
+(BOOL) hasLocalPlayerWonTheMatch:(GKTurnBasedMatch *) match;

//Returns the last activity date of a match looking at the previous participants last turn date
+(NSDate *) getLastActivityDateInMatch:(GKTurnBasedMatch *) match;

//Check if it is the local player's turn in the given match
+(BOOL) isLocalPlayersTurnInMatch:(GKTurnBasedMatch *) match;

//Convenience method to return previous participant's playerID wrapped in an array
+(NSArray *) makeArrayFromPreviousParticipantPlayerID:(GKTurnBasedMatch *) match;

//Returns local players index in the match checking the playerIDs of participant
+(NSInteger) getLocalPlayersIndexInMatch:(GKTurnBasedMatch *) match;

//Returns index of current participant in the match checking the playerIDs
+(NSInteger) getCurrentParticipantIndexInMatch:(GKTurnBasedMatch *) match;

//Returns validated previous participant index in match
+(NSInteger) getPreviousParticipantIndexInMatch:(GKTurnBasedMatch *) match;

//Returns validated next participant index in match
+(NSInteger) getNextParticipantIndexInMatch:(GKTurnBasedMatch *) match;

//Convenience method to return next participant's playerID wrapped in an array
+(NSArray *) makeArrayFromNextParticipantPlayerID:(GKTurnBasedMatch *) match;

//Returns local player as the participant of the match if he isn't a part of the
//game returns nil
+(GKTurnBasedParticipant *) getLocalParticipantInMatch:(GKTurnBasedMatch *) match;

//Calls load player for identifier for resigned player if there are any, and allows
//further handling after retrieval via complationBlock
+(void) retrieveResignedParticipantInMatch:(GKTurnBasedMatch *) match;

//Checks if there any participants with match outcome 'quit' in the match
+(BOOL) hasAnyParticipantResignedFromMatch:(GKTurnBasedMatch *) match;

//Makes local user quit from an active match by either calling participant quit
//in turn or quit out of turn
-(void) quitFromActiveMatch:(GKTurnBasedMatch *) match;

@end
