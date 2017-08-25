{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE OverloadedStrings #-}
{-# OPTIONS_GHC -fno-warn-unused-imports #-}
{-# OPTIONS_GHC -fno-warn-name-shadowing #-}
{-# OPTIONS_GHC -fno-warn-missing-import-lists #-}
-- | Generated by Haskell protocol buffer compiler. DO NOT EDIT!
module Kontiki.Protocol.Server where
import qualified Prelude as Hs
import qualified Proto3.Suite.DotProto as HsProtobuf
import qualified Proto3.Suite.Types as HsProtobuf
import qualified Proto3.Suite.Class as HsProtobuf
import qualified Proto3.Wire as HsProtobuf
import Control.Applicative ((<*>), (<|>))
import qualified Data.Text.Lazy as Hs (Text)
import qualified Data.ByteString as Hs
import qualified Data.String as Hs (fromString)
import qualified Data.Vector as Hs (Vector)
import qualified Data.Int as Hs (Int16, Int32, Int64)
import qualified Data.Word as Hs (Word16, Word32, Word64)
import qualified GHC.Generics as Hs
import qualified GHC.Enum as Hs
import Network.GRPC.HighLevel.Generated as HsGRPC
import Network.GRPC.HighLevel.Client as HsGRPC
import Network.GRPC.HighLevel.Server as HsGRPC hiding (serverLoop)
import Network.GRPC.HighLevel.Server.Unregistered as HsGRPC
       (serverLoop)
import Network.GRPC.LowLevel.Call as HsGRPC
 
data Node request response = Node{nodeRequestVote ::
                                  request 'HsGRPC.Normal Kontiki.Protocol.Server.RequestVoteRequest
                                    Kontiki.Protocol.Server.RequestVoteResponse
                                    ->
                                    Hs.IO
                                      (response 'HsGRPC.Normal
                                         Kontiki.Protocol.Server.RequestVoteResponse)}
                           deriving Hs.Generic
 
nodeServer ::
             Node HsGRPC.ServerRequest HsGRPC.ServerResponse ->
               HsGRPC.ServiceOptions -> Hs.IO ()
nodeServer Node{nodeRequestVote = nodeRequestVote}
  (ServiceOptions serverHost serverPort useCompression
     userAgentPrefix userAgentSuffix initialMetadata sslConfig logger)
  = (HsGRPC.serverLoop
       HsGRPC.defaultOptions{HsGRPC.optNormalHandlers =
                               [(HsGRPC.UnaryHandler
                                   (HsGRPC.MethodName "/kontiki.Node/RequestVote")
                                   (HsGRPC.convertGeneratedServerHandler nodeRequestVote))],
                             HsGRPC.optClientStreamHandlers = [],
                             HsGRPC.optServerStreamHandlers = [],
                             HsGRPC.optBiDiStreamHandlers = [], optServerHost = serverHost,
                             optServerPort = serverPort, optUseCompression = useCompression,
                             optUserAgentPrefix = userAgentPrefix,
                             optUserAgentSuffix = userAgentSuffix,
                             optInitialMetadata = initialMetadata, optSSLConfig = sslConfig,
                             optLogger = logger})
 
nodeClient ::
             HsGRPC.Client ->
               Hs.IO (Node HsGRPC.ClientRequest HsGRPC.ClientResult)
nodeClient client
  = (Hs.pure Node) <*>
      ((Hs.pure (HsGRPC.clientRequest client)) <*>
         (HsGRPC.clientRegisterMethod client
            (HsGRPC.MethodName "/kontiki.Node/RequestVote")))
 
data RequestVoteRequest = RequestVoteRequest{requestVoteRequestTerm
                                             :: Hs.Word64,
                                             requestVoteRequestCandidateId :: Hs.Text,
                                             requestVoteRequestLastLogIndex :: Hs.Word64,
                                             requestVoteRequestLastLogTerm :: Hs.Word64}
                        deriving (Hs.Show, Hs.Eq, Hs.Ord, Hs.Generic)
 
instance HsProtobuf.Named RequestVoteRequest where
        nameOf _ = (Hs.fromString "RequestVoteRequest")
 
instance HsProtobuf.Message RequestVoteRequest where
        encodeMessage _
          RequestVoteRequest{requestVoteRequestTerm = requestVoteRequestTerm,
                             requestVoteRequestCandidateId = requestVoteRequestCandidateId,
                             requestVoteRequestLastLogIndex = requestVoteRequestLastLogIndex,
                             requestVoteRequestLastLogTerm = requestVoteRequestLastLogTerm}
          = (Hs.mconcat
               [(HsProtobuf.encodeMessageField (HsProtobuf.FieldNumber 1)
                   requestVoteRequestTerm),
                (HsProtobuf.encodeMessageField (HsProtobuf.FieldNumber 2)
                   requestVoteRequestCandidateId),
                (HsProtobuf.encodeMessageField (HsProtobuf.FieldNumber 3)
                   requestVoteRequestLastLogIndex),
                (HsProtobuf.encodeMessageField (HsProtobuf.FieldNumber 4)
                   requestVoteRequestLastLogTerm)])
        decodeMessage _
          = (Hs.pure RequestVoteRequest) <*>
              (HsProtobuf.at HsProtobuf.decodeMessageField
                 (HsProtobuf.FieldNumber 1))
              <*>
              (HsProtobuf.at HsProtobuf.decodeMessageField
                 (HsProtobuf.FieldNumber 2))
              <*>
              (HsProtobuf.at HsProtobuf.decodeMessageField
                 (HsProtobuf.FieldNumber 3))
              <*>
              (HsProtobuf.at HsProtobuf.decodeMessageField
                 (HsProtobuf.FieldNumber 4))
        dotProto _
          = [(HsProtobuf.DotProtoField (HsProtobuf.FieldNumber 1)
                (HsProtobuf.Prim HsProtobuf.UInt64)
                (HsProtobuf.Single "term")
                []
                Hs.Nothing),
             (HsProtobuf.DotProtoField (HsProtobuf.FieldNumber 2)
                (HsProtobuf.Prim HsProtobuf.String)
                (HsProtobuf.Single "candidateId")
                []
                Hs.Nothing),
             (HsProtobuf.DotProtoField (HsProtobuf.FieldNumber 3)
                (HsProtobuf.Prim HsProtobuf.UInt64)
                (HsProtobuf.Single "lastLogIndex")
                []
                Hs.Nothing),
             (HsProtobuf.DotProtoField (HsProtobuf.FieldNumber 4)
                (HsProtobuf.Prim HsProtobuf.UInt64)
                (HsProtobuf.Single "lastLogTerm")
                []
                Hs.Nothing)]
 
data RequestVoteResponse = RequestVoteResponse{requestVoteResponseTerm
                                               :: Hs.Word64,
                                               requestVoteResponseVoteGranted :: Hs.Bool}
                         deriving (Hs.Show, Hs.Eq, Hs.Ord, Hs.Generic)
 
instance HsProtobuf.Named RequestVoteResponse where
        nameOf _ = (Hs.fromString "RequestVoteResponse")
 
instance HsProtobuf.Message RequestVoteResponse where
        encodeMessage _
          RequestVoteResponse{requestVoteResponseTerm =
                                requestVoteResponseTerm,
                              requestVoteResponseVoteGranted = requestVoteResponseVoteGranted}
          = (Hs.mconcat
               [(HsProtobuf.encodeMessageField (HsProtobuf.FieldNumber 1)
                   requestVoteResponseTerm),
                (HsProtobuf.encodeMessageField (HsProtobuf.FieldNumber 2)
                   requestVoteResponseVoteGranted)])
        decodeMessage _
          = (Hs.pure RequestVoteResponse) <*>
              (HsProtobuf.at HsProtobuf.decodeMessageField
                 (HsProtobuf.FieldNumber 1))
              <*>
              (HsProtobuf.at HsProtobuf.decodeMessageField
                 (HsProtobuf.FieldNumber 2))
        dotProto _
          = [(HsProtobuf.DotProtoField (HsProtobuf.FieldNumber 1)
                (HsProtobuf.Prim HsProtobuf.UInt64)
                (HsProtobuf.Single "term")
                []
                Hs.Nothing),
             (HsProtobuf.DotProtoField (HsProtobuf.FieldNumber 2)
                (HsProtobuf.Prim HsProtobuf.Bool)
                (HsProtobuf.Single "voteGranted")
                []
                Hs.Nothing)]