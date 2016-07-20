-- file: ch06/JSONClass.hs
{-# LANGUAGE TypeSynonymInstances #-} --型パラメータを具体化したデータ型を型クラスのinstanceにするのを許す言語拡張
{-# LANGUAGE FlexibleInstances #-}

module JSONClass where

import SimpleJSON 
type JSONError = String

class JSON a where
  toJValue :: a -> JValue
  fromJValue :: JValue -> Either JSONError a
  
instance JSON JValue where
  toJValue = id
  fromJValue = Right
  
--値コンストラクタの種類に関わらない統一的なインターフェースを定義
instance JSON Bool where  
  toJValue = JBool
  fromJValue (JBool b) = Right b
  fromJValue _ = Left "not a JSON boolean"
  
instance JSON String where  
  toJValue = JString
  fromJValue(JString s) = Right s
  fromJValue _ = Left "not a JSON string"

--JNumber vから整数と実数への共通インターフェース  
doubleToJValue :: (Double ->a) -> JValue -> Either JSONError a
doubleToJValue f (JNumber v) = Right (f v)
doubleToJValue _ _ = Left "Not a JSON number"

instance JSON Int where
  toJValue = JNumber . realToFrac
  fromJValue = doubleToJValue round

instance JSON Integer where
  toJValue = JNumber . realToFrac
  fromJValue = doubleToJValue round

instance JSON Double where
  toJValue = JNumber
  fromJValue = doubleToJValue id
  
