{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RebindableSyntax #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE TypeFamilies #-}

{-# OPTIONS_GHC -fno-warn-missing-import-lists #-}

module Kontiki.Raft.Internal.Candidate (
      convertToCandidate
    , onRequestVoteRequest
    , onRequestVoteResponse

    , onElectionTimeout
    , onHeartbeatTimeout
    ) where

import Prelude hiding ((>>), (>>=), return)
import Data.String (fromString)

import qualified Data.Set as Set

import Control.Lens ((.~), (&), (.=), (<%=), view)

import Control.Monad.Reader.Class (MonadReader)
import Control.Monad.State.Class (MonadState)
import Control.Monad.Indexed.State (IxMonadState, iget, imodify, iput)

import Data.Default.Class (Default, def)

import Control.Monad.Logger (MonadLogger, logInfo)

import qualified Language.Haskell.Rebindable.Do as Use

import Kontiki.Raft.Classes.Config (Config, localNode)
import qualified Kontiki.Raft.Classes.Config as Config
import Kontiki.Raft.Classes.RPC (MonadRPC, broadcastRequestVoteRequest, term)
import qualified Kontiki.Raft.Classes.RPC as RPC
import Kontiki.Raft.Classes.RPC.RequestVoteRequest (RequestVoteRequest, candidateId, lastLogIndex, lastLogTerm)
import qualified Kontiki.Raft.Classes.RPC.RequestVoteRequest as RequestVoteRequest
import Kontiki.Raft.Classes.State.Persistent (MonadPersistentState, getCurrentTerm, setCurrentTerm, lastLogEntry)
import qualified Kontiki.Raft.Classes.State.Persistent as Persistent
import Kontiki.Raft.Classes.State.Volatile (Conversion(FollowerToCandidate), Role(Candidate, Follower, Leader), VolatileState, convert, dispatch, votesGranted)
import qualified Kontiki.Raft.Classes.State.Volatile as Volatile
import Kontiki.Raft.Classes.Timers (MonadTimers, cancelElectionTimer, startElectionTimer)
import Kontiki.Raft.Classes.Types (Index, Term, index0, succTerm, term0)

import Kontiki.Raft.Internal.Leader (convertToLeader)
import Kontiki.Raft.Internal.State (Some(Some), wrap)

convertToCandidate :: ( IxMonadState m
                      , VolatileState volatileState
                      , Config.Config config
                      , MonadReader config (m (volatileState 'Candidate) (volatileState 'Candidate))
                      , MonadTimers (m (volatileState 'Candidate) (volatileState 'Candidate))
                      , MonadPersistentState (m (volatileState 'Candidate) (volatileState 'Candidate))
                      , Term (Persistent.Term (m (volatileState 'Candidate) (volatileState 'Candidate)))
                      , RequestVoteRequest.Node (RPC.RequestVoteRequest (m (volatileState 'Candidate) (volatileState 'Candidate))) ~ Config.Node config
                      , RPC.Term (RPC.RequestVoteRequest (m (volatileState 'Candidate) (volatileState 'Candidate))) ~ Persistent.Term (m (volatileState 'Candidate) (volatileState 'Candidate))
                      , RequestVoteRequest.Index (RPC.RequestVoteRequest (m (volatileState 'Candidate) (volatileState 'Candidate))) ~ Persistent.Index (m (volatileState 'Candidate) (volatileState 'Candidate))
                      , Default (RPC.RequestVoteRequest (m (volatileState 'Candidate) (volatileState 'Candidate)))
                      , RequestVoteRequest (RPC.RequestVoteRequest (m (volatileState 'Candidate) (volatileState 'Candidate)))
                      , MonadRPC (m (volatileState 'Candidate) (volatileState 'Candidate))
                      , Index (Persistent.Index (m (volatileState 'Candidate) (volatileState 'Candidate)))
                      , Volatile.Node volatileState ~ Config.Node config
                      , Ord (Config.Node config)
                      , MonadState (volatileState 'Candidate) (m (volatileState 'Candidate) (volatileState 'Candidate))
                      , MonadTimers (m (volatileState 'Leader) (volatileState 'Leader))
                      )
                   => m (volatileState 'Follower) (Some volatileState) ()
convertToCandidate = let Use.IxMonad{..} = def in do
    imodify (convert FollowerToCandidate)
    startElection

startElection :: forall m config index node requestVoteRequest term volatileState mCC mLL.
                 ( mCC ~ m (volatileState 'Candidate) (volatileState 'Candidate)
                 , mLL ~ m (volatileState 'Leader) (volatileState 'Leader)

                 , IxMonadState m
                 , MonadPersistentState mCC
                 , MonadReader config mCC
                 , MonadTimers mCC
                 , MonadRPC mCC
                 , MonadState (volatileState 'Candidate) mCC
                 , MonadTimers mLL

                 , Config config
                 , Index index
                 , VolatileState volatileState
                 , RequestVoteRequest requestVoteRequest
                 , Default requestVoteRequest
                 , Ord node

                 , Config.Node config ~ node
                 , RequestVoteRequest.Node requestVoteRequest ~ node
                 , Volatile.Node volatileState ~ node

                 , Term term
                 , Persistent.Term mCC ~ term
                 , RPC.Term requestVoteRequest ~ term

                 , RPC.RequestVoteRequest mCC ~ requestVoteRequest

                 , Persistent.Index mCC ~ index
                 , RequestVoteRequest.Index requestVoteRequest ~ index
                 )
              => m (volatileState 'Candidate) (Some volatileState) ()
startElection = let Use.IxMonad{..} = def in do
    -- When starting a new election round, reset any prior votes
    votesGranted .= Set.empty :: mCC ()

    incrementCurrentTerm
    voteForSelf
    -- In theory, after vote, we could've been turned into Leader
    whenStillCandidate $ do
        resetElectionTimer
        sendRequestVoteToOtherServers
        wrap
  where
    incrementCurrentTerm = let Use.Monad{..} = def in do
        currentTerm <- getCurrentTerm
        setCurrentTerm $ succTerm currentTerm
    voteForSelf = let Use.IxMonad{..} = def in do
        self <- view localNode :: mCC node
        voteFor self
    resetElectionTimer = let Use.Monad{..} = def in do
        cancelElectionTimer
        startElectionTimer
    sendRequestVoteToOtherServers = let Use.Monad{..} = def in do
        me <- view localNode
        currentTerm <- getCurrentTerm :: mCC term
        (idx, term') <- maybe (index0, term0) (\(i, t, _) -> (i, t)) <$> lastLogEntry
        broadcastRequestVoteRequest $ def & term .~ currentTerm
                                          & candidateId .~ me
                                          & lastLogIndex .~ idx
                                          & lastLogTerm .~ term'

    whenStillCandidate act = let Use.IxMonad{..} = def in do
        let remain _ = return ()
            runAct s = iput s >> act
        iget >>= \case
            Some s -> dispatch remain runAct remain s

voteFor :: ( IxMonadState m
           , MonadState (volatileState 'Candidate) (m (volatileState 'Candidate) (volatileState 'Candidate))
           , MonadTimers (m (volatileState 'Leader) (volatileState 'Leader))
           , VolatileState volatileState
           , Volatile.Node volatileState ~ node
           , Ord node
           )
        => node
        -> m (volatileState 'Candidate) (Some volatileState) ()
voteFor node = let Use.IxMonad{..} = def in do
    votes <- votesGranted <%= Set.insert node
    if Set.size votes == 2 -- TODO
        then convertToLeader >> wrap
        else wrap

onRequestVoteRequest :: a
onRequestVoteRequest = undefined
onRequestVoteResponse :: a
onRequestVoteResponse = undefined

onElectionTimeout :: forall m config index node requestVoteRequest term volatileState mCC mLL.
                     ( mCC ~ m (volatileState 'Candidate) (volatileState 'Candidate)
                     , mLL ~ m (volatileState 'Leader) (volatileState 'Leader)

                     , IxMonadState m
                     , MonadPersistentState mCC
                     , MonadReader config mCC
                     , MonadTimers mCC
                     , MonadRPC mCC
                     , MonadState (volatileState 'Candidate) mCC
                     , MonadTimers mLL
                     , MonadLogger mCC

                     , Config config
                     , Index index
                     , VolatileState volatileState
                     , RequestVoteRequest requestVoteRequest
                     , Default requestVoteRequest
                     , Ord node

                     , Config.Node config ~ node
                     , RequestVoteRequest.Node requestVoteRequest ~ node
                     , Volatile.Node volatileState ~ node

                     , Term term
                     , Persistent.Term mCC ~ term
                     , RPC.Term requestVoteRequest ~ term

                     , RPC.RequestVoteRequest mCC ~ requestVoteRequest

                     , Persistent.Index mCC ~ index
                     , RequestVoteRequest.Index requestVoteRequest ~ index
                     )
                  => m (volatileState 'Candidate) (Some volatileState) ()
onElectionTimeout = let Use.IxMonad{..} = def in do
    $(logInfo) "Election timeout while in Candidate mode, starting new election"
    startElection

onHeartbeatTimeout :: a
onHeartbeatTimeout = undefined


ifThenElse :: Bool -> a -> a -> a
ifThenElse b t f = case b of
    True -> t
    False -> f
