//
//  GKTurnBasedHelper.m
//
//  Created by Guven Iscan on 10/02/14.
//
//

#import "GKTurnBasedHelper.h"

#define LOGGING_ENABLED 1 //Set to 0 if you want to disable logging in GKTurnBasedHelper

#if LOGGING_ENABLED
#define DLog(...) NSLog(@"%s %@", __PRETTY_FUNCTION__, [NSString stringWithFormat:__VA_ARGS__])
#endif
#if !LOGGING_ENABLED
#define DLog(...) do { } while (0) //No-op
#endif

#define ONE_WEEK_IN_SECONDS 172800
#define GAMECENTER_TURNBASEDMATCH_TIMEOUT ONE_WEEK_IN_SECONDS

@implementation GKTurnBasedHelper

//Get index or indices (in case player scores are tied) of winners in match
+(NSArray *) getWinnerIndicesInEndedMatch:(GKTurnBasedMatch *) match
{
    NSMutableArray *winners = [NSMutableArray array];
    
    //Iterate through participants list and check the outcomes
    for (NSInteger i = 0; i < [match.participants count]; i++)
    {
        GKTurnBasedParticipant *temp = match.participants[i];
        
        //Add participants with 'WON' outcome to the return value
        if (temp.matchOutcome == GKTurnBasedMatchOutcomeWon)
        {
            [winners addObject:[NSNumber numberWithInteger:i]];
        }
    }
    
    return winners;
}

//Checks if local player has the match outcome 'won'
+(BOOL) hasLocalPlayerWonTheMatch:(GKTurnBasedMatch *) match
{
    return [[GKTurnBasedHelper getWinnerIndicesInEndedMatch:match] containsObject:[NSNumber numberWithInteger:[GKTurnBasedHelper getLocalPlayersIndexInMatch:match]]];
}

//Returns the last activity date of a match looking at the previous participants last turn date
+(NSDate *) getLastActivityDateInMatch:(GKTurnBasedMatch *) match
{
    //Retrieve the previous participant and set his lastTurnDate as the last activity date in the game
    NSInteger prevParticipant = ([GKTurnBasedHelper getCurrentParticipantIndexInMatch:match] + [match.participants count] - 1) % [match.participants count];
    return [(GKTurnBasedParticipant *) match.participants[prevParticipant] lastTurnDate];
}

//Check if it is the local player's turn in the given match
+(BOOL) isLocalPlayersTurnInMatch:(GKTurnBasedMatch *) match
{
    return [match.currentParticipant.playerID isEqualToString:[[GKLocalPlayer localPlayer] playerID]];
}

//Convenience method to return previous participant's playerID wrapped in an array
+(NSArray *) makeArrayFromPreviousParticipantPlayerID:(GKTurnBasedMatch *) match
{
    NSMutableArray *prevParticipantId=[NSMutableArray array];
    [prevParticipantId addObject:[(GKTurnBasedParticipant *) match.participants[[GKTurnBasedHelper getPreviousParticipantIndexInMatch:match]] playerID]];
    
    return prevParticipantId;
}

//Returns local players index in the match checking the playerIDs of participant
+(NSInteger) getLocalPlayersIndexInMatch:(GKTurnBasedMatch *) match
{
    return [ [match.participants valueForKey:@"playerID"] indexOfObject:[[GKLocalPlayer localPlayer] playerID]];
}

//Returns index of current participant in the match checking the playerIDs
+(NSInteger) getCurrentParticipantIndexInMatch:(GKTurnBasedMatch *) match
{
    return [ [match.participants valueForKey:@"playerID"] indexOfObject:[match.currentParticipant playerID]];
}

//Returns validated previous participant index in match
+(NSInteger) getPreviousParticipantIndexInMatch:(GKTurnBasedMatch *) match
{
    NSInteger curParticipantIndex = [GKTurnBasedHelper getCurrentParticipantIndexInMatch:match];
    NSInteger prevParticipantIndex;
    //If first player is current, return the last player
    if (curParticipantIndex == 0) {
        prevParticipantIndex=[match.participants count]-1;
    }
    //If not, return the player with index - 1
    else{
        prevParticipantIndex=curParticipantIndex - 1;
    }
    
    return prevParticipantIndex;
}

//Returns validated next participant index in match
+(NSInteger) getNextParticipantIndexInMatch:(GKTurnBasedMatch *) match
{
    NSInteger nextParticipant = [GKTurnBasedHelper getCurrentParticipantIndexInMatch:match] + 1;
    nextParticipant = nextParticipant % ([match.participants count]);
    
    return nextParticipant;
}

//Convenience method to return next participant's playerID wrapped in an array
+(NSArray *) makeArrayFromNextParticipantPlayerID:(GKTurnBasedMatch *) match
{
    NSMutableArray *nextParticipantId=[NSMutableArray array];
    [nextParticipantId addObject:[(GKTurnBasedParticipant *) match.participants[[GKTurnBasedHelper getNextParticipantIndexInMatch:match]] playerID]];
    
    return nextParticipantId;
}

//Returns local player as the participant of the match if he isn't a part of the
//game returns nil
+(GKTurnBasedParticipant *) getLocalParticipantInMatch:(GKTurnBasedMatch *) match
{
    NSInteger index = [GKTurnBasedHelper getLocalPlayersIndexInMatch:match];
    
    if (index >= [match.participants count])
    {
        return nil;
    }
    
    return  match.participants[index];
}

//Calls load player for identifier for resigned player if there are any, and allows
//further handling after retrieval via complationBlock
+(void) retrieveResignedParticipantInMatch:(GKTurnBasedMatch *) match
                           completionBlock:(void (^)(NSArray *players, NSError *error)) completion
{
    for (NSInteger i = 0; i < [match.participants count]; i++)
    {
        GKTurnBasedParticipant *temp = match.participants[i];
        if (temp.matchOutcome == GKTurnBasedMatchOutcomeQuit)
        {
            [GKPlayer loadPlayersForIdentifiers:[NSArray arrayWithObject:temp.playerID]
                          withCompletionHandler:completion];
            break;
        }
    }
}

//Checks if there any participants with match outcome 'quit' in the match
+(BOOL) hasAnyParticipantResignedFromMatch:(GKTurnBasedMatch *) match
{
    //Iterate through all participants list
    for (NSInteger i = 0 ; i < [match.participants count]; i++)
    {
        GKTurnBasedParticipant *temp = match.participants[i];
        if (temp.matchOutcome == GKTurnBasedMatchOutcomeQuit)
        {
            return TRUE;
        }
    }
    
    return FALSE;
}

//Makes local user quit from an active match by either calling participant quit
//in turn or quit out of turn
-(void) quitFromActiveMatch:(GKTurnBasedMatch *) match
{
    //If it is user's turn we need call participant quit in turn with some extra settings
    if ([GKTurnBasedHelper isLocalPlayersTurnInMatch:match])
    {
        //Same match data sent while quitting in turn
        [match participantQuitInTurnWithOutcome:GKTurnBasedMatchOutcomeQuit
                               nextParticipants:[GKTurnBasedHelper makeArrayFromNextParticipantPlayerID:match]
                                    turnTimeout:GAMECENTER_TURNBASEDMATCH_TIMEOUT
                                      matchData:match.matchData
                              completionHandler:^(NSError *error) {
                                  if (error != nil) {
                                      DLog(@"Error quitting in turn from match %@",error);
                                  }
                                  else
                                  {
                                      DLog(@"Successfully quit in turn from the match");
                                  }
                              }];
    }
    //If it is not user's turn call participant quit of turn
    else
    {
        [match participantQuitOutOfTurnWithOutcome:GKTurnBasedMatchOutcomeQuit withCompletionHandler:^(NSError *error) {
            if (error != nil) {
                DLog(@"Error quitting out of turn from match %@",error);
            }
            else
            {
                DLog(@"Successfully quit out of turn from the match");
            }
        }];
        
    }
}

@end
