{-# LANGUAGE OverloadedStrings, CPP #-}

module Model.Plan where

import qualified Data.Time.Clock as DTC
import Database.PostgreSQL.Simple.FromRow

#ifdef __HASTE__
type Text = String
#else
import Data.Text (Text)
#endif

{-# ANN module ("HLint: ignore Use camelCase" :: String) #-}

data Plan = Plan
  { p_id :: Int
  , p_user_id :: Int
  , p_name :: Text
  , p_description :: Maybe Text
  , p_created :: DTC.UTCTime
  , p_modified :: DTC.UTCTime
  } deriving (Show, Read)

instance FromRow Plan where
  fromRow = Plan <$> field <*> field <*> field <*> field <*> field <*> field

