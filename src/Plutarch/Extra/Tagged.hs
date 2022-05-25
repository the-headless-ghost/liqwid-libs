{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE UndecidableInstances #-}
-- Needed for Tagged instances for PlutusTx stuff
{-# OPTIONS_GHC -Wno-orphans #-}

module Plutarch.Extra.Tagged (
    PTagged (..),
) where

import Data.Kind (Type)
import Data.Tagged (Tagged (Tagged))
import Generics.SOP (I (I), Top)
import Generics.SOP.TH (deriveGeneric)
import Plutarch (
    DerivePNewtype (DerivePNewtype),
    PlutusType,
    S,
    Term,
    pcon,
    phoistAcyclic,
    plam,
    unTermCont,
    (#),
 )
import Plutarch.Bool (PEq, POrd)
import Plutarch.Builtin (PIsData)
import Plutarch.Extra.Applicative (PApplicative (ppure), PApply (pliftA2))
import Plutarch.Extra.Comonad (PComonad (pextend, pextract))
import Plutarch.Extra.Functor (
    PBifunctor (PSubcategoryLeft, PSubcategoryRight, pbimap, psecond),
    PFunctor (PSubcategory, pfmap),
 )
import Plutarch.Extra.TermCont (pmatchC)
import Plutarch.Extra.Traversable (PTraversable (ptraverse))
import Plutarch.Integer (PIntegral)
import Plutarch.Lift (
    PConstantDecl (PConstantRepr, PConstanted, pconstantFromRepr, pconstantToRepr),
    PUnsafeLiftDecl (PLifted),
 )
import Plutarch.Show (PShow)
import qualified PlutusTx

{- | Plutarch-level 'Tagged'.

 @since 1.0.0
-}
newtype PTagged (tag :: S -> Type) (underlying :: S -> Type) (s :: S)
    = PTagged (Term s underlying)

deriveGeneric ''PTagged

-- | @since 1.0.0
deriving via
    (DerivePNewtype (PTagged tag underlying) underlying)
    instance
        (PlutusType (PTagged tag underlying))

-- | @since 1.0.0
deriving via
    (DerivePNewtype (PTagged tag underlying) underlying)
    instance
        (PIsData underlying) => (PIsData (PTagged tag underlying))

-- | @since 1.0.0
deriving via
    (DerivePNewtype (PTagged tag underlying) underlying)
    instance
        (PEq underlying) => PEq (PTagged tag underlying)

-- | @since 1.0.0
deriving via
    (DerivePNewtype (PTagged tag underlying) underlying)
    instance
        (POrd underlying) => POrd (PTagged tag underlying)

-- | @since 1.0.0
deriving via
    (DerivePNewtype (PTagged tag underlying) underlying)
    instance
        (PIntegral underlying) => PIntegral (PTagged tag underlying)

-- | @since 1.0.0
deriving via
    (Term s (DerivePNewtype (PTagged tag underlying) underlying))
    instance
        (Num (Term s underlying)) => Num (Term s (PTagged tag underlying))

-- | @since 1.0.0
deriving via
    (Term s (DerivePNewtype (PTagged tag underlying) underlying))
    instance
        (Semigroup (Term s underlying)) => Semigroup (Term s (PTagged tag underlying))

-- | @since 1.0.0
deriving via
    (Term s (DerivePNewtype (PTagged tag underlying) underlying))
    instance
        (Monoid (Term s underlying)) => Monoid (Term s (PTagged tag underlying))

-- | @since 1.0.0
deriving anyclass instance (PShow underlying) => PShow (PTagged tag underlying)

-- | @since 1.0.0
instance PFunctor (PTagged tag) where
    type PSubcategory (PTagged tag) = Top
    pfmap = psecond

-- | @since 1.0.0
instance PBifunctor PTagged where
    type PSubcategoryLeft PTagged = Top
    type PSubcategoryRight PTagged = Top
    pbimap = phoistAcyclic $
        plam $ \_ g t -> unTermCont $ do
            PTagged t' <- pmatchC t
            pure . pcon . PTagged $ g # t'

-- | @since 1.0.0
instance PComonad (PTagged tag) where
    pextract = phoistAcyclic $
        plam $ \t -> unTermCont $ do
            PTagged t' <- pmatchC t
            pure t'
    pextend = phoistAcyclic $ plam $ \f t -> pcon . PTagged $ f # t

-- | @since 1.0.0
instance PApply (PTagged tag) where
    pliftA2 = phoistAcyclic $
        plam $ \f xs ys -> unTermCont $ do
            PTagged x <- pmatchC xs
            PTagged y <- pmatchC ys
            pure . pcon . PTagged $ f # x # y

-- | @since 1.0.0
instance PApplicative (PTagged tag) where
    ppure = phoistAcyclic $ plam $ pcon . PTagged

-- | @since 1.0.0
instance PTraversable (PTagged tag) where
    ptraverse = phoistAcyclic $
        plam $ \f t -> unTermCont $ do
            PTagged t' <- pmatchC t
            pure $ pfmap # plam (pcon . PTagged) # (f # t')

-- | @since 1.0.0
instance
    (PUnsafeLiftDecl t, PUnsafeLiftDecl a) =>
    PUnsafeLiftDecl (PTagged t a)
    where
    type PLifted (PTagged t a) = Tagged (PLifted t) (PLifted a)

-- | @since 1.0.0
instance (PConstantDecl a, PConstantDecl t) => PConstantDecl (Tagged t a) where
    type PConstantRepr (Tagged t a) = PConstantRepr a
    type PConstanted (Tagged t a) = PTagged (PConstanted t) (PConstanted a)
    pconstantToRepr (Tagged x) = pconstantToRepr x
    pconstantFromRepr x = Tagged <$> pconstantFromRepr x

-- These are needed, because plutus-tx doesn't have them

-- | @since 1.0.0
deriving via
    underlying
    instance
        (PlutusTx.ToData underlying) =>
        PlutusTx.ToData (Tagged tag underlying)

-- | @since 1.0.0
deriving via
    underlying
    instance
        (PlutusTx.FromData underlying) =>
        PlutusTx.FromData (Tagged tag underlying)

-- | @since 1.0.0
deriving via
    underlying
    instance
        (PlutusTx.UnsafeFromData underlying) =>
        PlutusTx.UnsafeFromData (Tagged tag underlying)
