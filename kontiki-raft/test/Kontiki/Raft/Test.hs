module Kontiki.Raft.Test (tests) where

import Control.Lens ((^.))

import Control.Monad.Logger (runNoLoggingT)

import Test.Tasty (TestTree)
import Test.Tasty.Hspec (describe, it, testSpec)

import Test.Hspec.Expectations (shouldBe)

import Kontiki.Raft.Classes.State.Volatile (commitIndex, lastApplied)
import Kontiki.Raft.Classes.Types (index0, term0)

import Kontiki.Raft (SomeState, Role(Follower), initialState, initializePersistentState, role)
import Kontiki.Raft.Internal.State (volatileState)

import qualified Kontiki.Raft.Types as T

tests :: IO TestTree
tests = testSpec "Kontiki.Raft" $ do
    describe "initialState" $ do
        let s = initialState :: SomeState T.VolatileState ()
            v = volatileState s

        it "is in Follower role" $
            role s `shouldBe` Follower
        it "sets commitIndex to index0" $
            v ^. commitIndex `shouldBe` index0
        it "sets lastApplied to index0" $
            v ^. lastApplied `shouldBe` index0

    describe "initializePersistentState" $ do
        let s0 = T.PersistentState (T.Term 123) (Just $ T.Node 1)

        it "sets currentTerm to term0" $ do
            ((), s) <- runNoLoggingT $ T.runPersistentStateT s0 initializePersistentState
            T.persistentStateCurrentTerm s `shouldBe` term0
        it "sets votedFor to Nothing" $ do
            ((), s) <- runNoLoggingT $ T.runPersistentStateT s0 initializePersistentState
            T.persistentStateVotedFor s `shouldBe` Nothing
