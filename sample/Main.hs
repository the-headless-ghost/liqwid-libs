module Main (main) where

import GHC.IO.Encoding (setLocaleEncoding, utf8)
import qualified MintingBuilder (specs)
import Plutarch.Context (
    Builder,
    buildMinting,
    buildSpending,
    buildTxInfo,
    buildTxOuts,
    input,
    mint,
    output,
    pubKey,
    script,
    withDatum,
    withMinting,
    withRefIndex,
    withSpendingUTXO,
    withTxId,
    withValue,
 )
import PlutusLedgerApi.V2 (
    ScriptContext (scriptContextTxInfo),
    TxInfo (txInfoOutputs),
    singleton,
 )
import qualified SpendingBuilder (specs)
import Test.Tasty (defaultMain, testGroup)
import Test.Tasty.HUnit (testCase, (@?=))

main :: IO ()
main = do
    setLocaleEncoding utf8
    defaultMain . testGroup "Sample Tests" $
        [ testCase "TxInfo matches with both Minting and Spending Script Purposes" $
            (scriptContextTxInfo <$> a) @?= (scriptContextTxInfo <$> b)
        , testCase "TxInfo from TxInfoBuilder should also match" $
            (scriptContextTxInfo <$> a) @?= c
        , testCase "TxOut list from TxInfoBuilder should match one from buildTxOut" $
            (txInfoOutputs . scriptContextTxInfo <$> a) @?= return d
        , SpendingBuilder.specs
        , MintingBuilder.specs
        ]
  where
    a = buildMinting (generalSample <> withMinting "aaaa")
    b =
        buildSpending
            ( generalSample
                <> withSpendingUTXO
                    (pubKey "aabb" <> withValue (singleton "cc" "hello" 123))
            )
    c = buildTxInfo generalSample
    d = buildTxOuts generalSample

generalSample :: (Monoid a, Builder a) => a
generalSample =
    mconcat
        [ input $
            pubKey "aabb"
                <> withValue (singleton "cc" "hello" 123)
                <> withRefIndex 5
        , input $
            pubKey "eeee"
                <> withValue (singleton "cc" "hello" 123)
                <> withDatum (123 :: Integer)
                <> withTxId "eeff"
        , output $
            script "cccc"
                <> withValue (singleton "dd" "world" 123)
        , mint $ singleton "aaaa" "hello" 333
        ]
