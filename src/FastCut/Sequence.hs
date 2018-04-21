{-# OPTIONS_GHC -fno-warn-unticked-promoted-constructors #-}
{-# LANGUAGE DataKinds             #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE FlexibleInstances     #-}
{-# LANGUAGE GADTs                 #-}
{-# LANGUAGE KindSignatures        #-}
{-# LANGUAGE LambdaCase            #-}
{-# LANGUAGE OverloadedLabels      #-}
{-# LANGUAGE RankNTypes            #-}
{-# LANGUAGE StandaloneDeriving    #-}
{-# LANGUAGE TypeFamilies          #-}
module FastCut.Sequence where

import           Data.Foldable   (foldl')
import           Data.Semigroup
import           Data.Text       (Text)
import           Data.Time.Clock (NominalDiffTime)

type Duration = NominalDiffTime

data ClipMetadata = ClipMetadata
  { clipName :: Text
  , path     :: FilePath
  , duration :: Duration
  } deriving (Eq, Show)

data ClipType = Video | Audio
  deriving (Eq, Show)

type family InverseClipType (t :: ClipType) :: ClipType where
  InverseClipType Video = Audio
  InverseClipType Audio = Video

data Clip a (t :: ClipType) where
  VideoClip :: a -> ClipMetadata -> Clip a Video
  AudioClip :: a -> ClipMetadata -> Clip a Audio
  VideoGap :: a -> Duration -> Clip a Video
  AudioGap :: a -> Duration -> Clip a Audio

setClipAnnotation :: a -> Clip b t -> Clip a t
setClipAnnotation a = \case
  VideoClip _ m -> VideoClip a m
  AudioClip _ m -> AudioClip a m
  VideoGap  _ d -> VideoGap a d
  AudioGap  _ d -> AudioGap a d

deriving instance Eq a => Eq (Clip a t)
deriving instance Show a => Show (Clip a t)

class HasDuration t where
  durationOf :: t -> Duration

instance HasDuration (Clip a t) where
  durationOf = \case
    VideoClip _ m -> duration m
    AudioClip _ m -> duration m
    VideoGap _ d -> d
    AudioGap _ d -> d

instance HasDuration t => HasDuration [t] where
  durationOf = foldl' (\acc c -> acc + durationOf c) 0

data Sequence a
  = Sequence a [Sequence a]
  | Composition a [Clip a Video] [Clip a Audio]
  deriving (Eq, Show)

single :: Clip () t -> Sequence ()
single c = case c of
  VideoClip{} -> Composition () [c] []
  VideoGap{}  -> Composition () [c] []
  AudioClip{} -> Composition () [] [c]
  AudioGap{}  -> Composition () [] [c]

instance Semigroup (Sequence ()) where
  Sequence _ s1 <> Sequence _ s2 = Sequence () (s1 <> s2)
  Sequence _ s1 <> s2 = Sequence () (s1 <> [s2])
  s1 <> Sequence _ s2 = Sequence () (s1 : s2)
  s1 <> s2 = Sequence () [s1, s2]

instance Monoid (Sequence ()) where
  mempty = Sequence mempty []
  mappend = (<>)
