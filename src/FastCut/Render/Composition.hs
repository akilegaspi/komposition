{-# OPTIONS_GHC -fno-warn-unticked-promoted-constructors #-}
{-# LANGUAGE DataKinds          #-}
{-# LANGUAGE GADTs              #-}
{-# LANGUAGE LambdaCase         #-}
{-# LANGUAGE StandaloneDeriving #-}
-- | Flat compositions for rendering.

module FastCut.Render.Composition
  ( Composition(..)
  , StillFrameMode(..)
  , CompositionPart(..)
  , flattenTimeline
  ) where

import           FastCut.Prelude

import qualified FastCut.Composition as Core
import           FastCut.Duration
import           FastCut.Library
import           FastCut.MediaType

data Composition =
  Composition (NonEmpty (CompositionPart Video))
              (NonEmpty (CompositionPart Audio))
  deriving (Show, Eq)

data StillFrameMode = FirstFrame | LastFrame
  deriving (Show, Eq)

data CompositionPart mt where
  Clip :: Asset mt -> CompositionPart mt
  StillFrame
    :: StillFrameMode -> Asset Video -> Duration -> CompositionPart Video
  Silence :: Duration -> CompositionPart Audio

instance HasDuration (CompositionPart mt) where
  durationOf = \case
    Clip a -> durationOf a
    StillFrame _ _ d  -> d
    Silence d -> d

deriving instance Eq (CompositionPart t)
deriving instance Show (CompositionPart t)

instance HasDuration Composition where
  durationOf (Composition vs as) = max (foldMap durationOf vs) (foldMap durationOf as)

data Tracks = Tracks [CompositionPart Video] [CompositionPart Audio]
  deriving (Eq, Show)

instance Semigroup Tracks where
  Tracks v1 a1 <> Tracks v2 a2 = Tracks (v1 <> v2) (a1 <> a2)

instance Monoid Tracks where
  mempty = Tracks mempty mempty

instance HasDuration Tracks where
  durationOf (Tracks video audio) =
    max (foldMap durationOf video) (foldMap durationOf audio)

flattenTimeline :: Core.Composition a Core.TimelineType -> Maybe Composition
flattenTimeline (Core.Timeline _ seqs) = do
  Tracks vs as <- foldMap flattenSequence seqs
  Composition <$> nonEmpty vs <*> nonEmpty as

flattenSequence :: Core.Composition a Core.SequenceType -> Maybe Tracks
flattenSequence (Core.Sequence _ pars) = foldMap flattenParallel pars

flattenParallel :: Core.Composition a Core.ParallelType -> Maybe Tracks
flattenParallel (Core.Parallel _ vs as) =
  let (video, lastAsset, _) = foldl' foldVideo (mempty, Nothing, mempty) vs
      audio = foldMap toAudio as
  in matchTrackDurations video audio <$> lastAsset
  where
    foldVideo (tracks, lastAsset, precedingGaps) =
      \case
        Core.Clip _ asset ->
          ( tracks <>
            Tracks
              (map (StillFrame FirstFrame asset) precedingGaps <> [Clip asset])
              []
          , Just asset
          , [])
        Core.Gap _ d ->
          case lastAsset of
            Just asset ->
              ( tracks <> Tracks [StillFrame LastFrame asset d] []
              , lastAsset
              , precedingGaps)
            Nothing -> (tracks, lastAsset, precedingGaps <> [d])
    toAudio =
      \case
        Core.Clip _ asset -> Tracks [] [Clip asset]
        Core.Gap _ d -> Tracks [] [Silence d]
    matchTrackDurations video audio lastAsset =
      case (durationOf video, durationOf audio) of
        (vd, ad)
          | vd < ad ->
            video <> Tracks [StillFrame LastFrame lastAsset (ad - vd)] [] <>
            audio
          | vd > ad ->
            video <> audio <> Tracks [] [Silence (vd - ad)]
          | otherwise ->
            video <> audio