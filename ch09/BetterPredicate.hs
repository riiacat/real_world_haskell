{-# OPTIONS_GHC -cpp #-}
-- file: ch09/BetterPredicate.hs
module BetterPredicate () where

import Control.Monad (filterM)
import System.Directory ( Permissions(..), getModificationTime, getPermissions) 
import Data.Time ( UTCTime(..) )
import System.FilePath( takeExtension)
import Control.Exception (bracket, handle)
import System.IO (IOMode(..), hClose, hFileSize, openFile)
--以前書いた関数
import RecursiveContents (getRecursiveContents)
--Exception Tipe Signature用
import GHC.Exception

type Predicate = FilePath --ディレクトリエントリへのパス
                 -> Permissions
                 -> Maybe Integer --File size (not file -> Nothing)
                 -> UTCTime --ClockTime
                 -> Bool  --純粋なことに注意する

getFileSize :: FilePath -> IO ( Maybe Integer )
betterFind :: Predicate -> FilePath -> IO [FilePath]

betterFind p path = getRecursiveContents path >>= filterM check
  where check name = do
          perms <- getPermissions name
          size <- getFileSize name
          modified <- getModificationTime name
          return (p name perms size modified )
        
        
simpleFileSize :: FilePath -> IO Integer
simpleFileSize path = do
  h <- openFile path ReadMode
  size <- hFileSize h
  hClose h
  return size
  
saferFileSize :: FilePath -> IO (Maybe Integer)
saferFileSize path =  handle ( (\_ -> return Nothing ) :: SomeException-> IO ( (Maybe Integer)) )$ do  --例外の型が不明なこととNothingの型が不明なことから注釈が必要
  h <- openFile path ReadMode
  size <- hFileSize h
  hClose h
  return (Just size)
  
--獲得ー使用ー開放サイクル　（確実にファイルハンドラを閉じる方法）
getFileSize path = handle ( (\_ -> return Nothing ) :: SomeException-> IO ( (Maybe Integer)) )$   --例外の型が不明なこととNothingの型が不明なことから注釈が必要
                   bracket (openFile path ReadMode) hClose $ \h -> do
                     size <- hFileSize h
                     return (Just size)

--引数が多すぎるのに２つしか使わない。また、等式が２つ必要。DSLを作って改善する
myTest path _ (Just size) _ =                      
  takeExtension path == ".cpp" && size > 131072
myTest _ _ _ _ = False

--引数の１つを返す関数
type InfoP a = FilePath                 
               -> Permissions
               -> Maybe Integer
               -> UTCTime
               -> a               
pathP :: InfoP FilePath               
pathP path _ _ _ = path

sizeP :: InfoP Integer                   
sizeP _ _ (Just size) _  = size
sizeP _ _ Nothing _ = -1  -- nothingの時は-1にすることで表現

--InfoP Bool はPredicate                      
--返り値は Predicate、つまり述語を取る
equalP :: (Eq a) => InfoP a -> a -> InfoP Bool
equalP f k = \w x y z -> f w x y z == k

--equalP' （別実装例、ラムダ式を使わないバージョン
equalP' :: (Eq a) => InfoP a-> a -> InfoP Bool
equalP' f k w x y z = f w x y z == k