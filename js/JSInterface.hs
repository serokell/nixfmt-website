{- © 2019-2024 Serokell <hi@serokell.io>
 -
 - SPDX-License-Identifier: MPL-2.0
 -}

{-# LANGUAGE BlockArguments #-}

import GHC.JS.Foreign.Callback
import GHC.JS.Prim
import Data.Text as T

import Nixfmt
import Nixfmt.Predoc (layout)

foreign import javascript "((f) => { nixfmt_ = f })"
  setNixfmt :: Callback (JSVal -> JSVal -> IO JSVal) -> IO ()

main :: IO ()
main = setNixfmt =<< syncCallback2' \text_ obj -> do
  width <- fromJSInt <$> getProp obj "width"
  filename <- fromJSString <$> getProp obj "filename"
  let text = T.pack $ fromJSString text_
  pure $ toJSString case format (layout width False) filename text of
    Left err -> err
    Right out -> T.unpack out
