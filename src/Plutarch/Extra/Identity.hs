{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE UndecidableInstances #-}

module Plutarch.Extra.Identity (
    PIdentity (..),
) where

import Data.Kind (Type)
import GHC.Generics (Generic)
import Generics.SOP (Top)
import qualified Generics.SOP as SOP
import Plutarch.Extra.Applicative (PApplicative (ppure), PApply (pliftA2))
import Plutarch.Extra.Boring (PBoring (pboring))
import Plutarch.Extra.Comonad (
    PComonad (pextract),
    PExtend (pextend),
 )
import Plutarch.Extra.Functor (PFunctor (PSubcategory, pfmap))
import Plutarch.Extra.TermCont (pmatchC)
import Plutarch.Num (PNum)
import Plutarch.Prelude (
    DerivePlutusType (..),
    PEq,
    PIntegral,
    PIsData,
    POrd,
    PPartialOrd,
    PlutusType,
    PlutusTypeNewtype,
    S,
    Term,
    pcon,
    phoistAcyclic,
    plam,
    unTermCont,
    (#),
 )
import Plutarch.Show (PShow)

{- | Just a value of type @a@.

 @since 1.0.0
-}
newtype PIdentity (a :: S -> Type) (s :: S)
    = PIdentity (Term s a)
    deriving stock
        ( -- | @since 1.0.0
          Generic
        )
    deriving anyclass
        ( -- | @since 1.0.0
          SOP.Generic
        , -- | @since 1.0.0
          PlutusType
        )

-- | @since 1.4.0
instance DerivePlutusType (PIdentity a) where
    type DPTStrat _ = PlutusTypeNewtype

-- | @since 1.0.0
deriving anyclass instance (PIsData a) => (PIsData (PIdentity a))

-- | @since 1.0.0
deriving anyclass instance (PEq a) => PEq (PIdentity a)

-- | @since 1.4.0
deriving anyclass instance (POrd a) => PPartialOrd (PIdentity a)

-- | @since 1.0.0
deriving anyclass instance (POrd a) => POrd (PIdentity a)

-- | @since 1.0.0
deriving anyclass instance (PIntegral a) => PIntegral (PIdentity a)

-- | @since 1.4.0
deriving anyclass instance (PNum a) => PNum (PIdentity a)

-- | @since 1.0.0
deriving anyclass instance (PShow a) => PShow (PIdentity a)

-- | @since 1.0.0
instance PFunctor PIdentity where
    type PSubcategory PIdentity = Top
    pfmap = phoistAcyclic $
        plam $ \f t -> unTermCont $ do
            PIdentity t' <- pmatchC t
            pure . pcon . PIdentity $ f # t'

-- | @since 1.0.0
instance PExtend PIdentity where
    pextend = phoistAcyclic $ plam $ \f t -> pcon . PIdentity $ f # t

-- | @since 1.0.0
instance PComonad PIdentity where
    pextract = phoistAcyclic $
        plam $ \t -> unTermCont $ do
            PIdentity t' <- pmatchC t
            pure t'

-- | @since 1.0.0
instance PApply PIdentity where
    pliftA2 = phoistAcyclic $
        plam $ \f xs ys -> unTermCont $ do
            PIdentity tx <- pmatchC xs
            PIdentity ty <- pmatchC ys
            pure . pcon . PIdentity $ f # tx # ty

-- | @since 1.0.0
instance PApplicative PIdentity where
    ppure = phoistAcyclic $ plam $ pcon . PIdentity

-- | @since 1.2.0
instance (PBoring a) => PBoring (PIdentity a) where
    pboring = ppure # pboring
