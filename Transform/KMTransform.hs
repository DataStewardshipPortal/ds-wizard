{-# LANGUAGE OverloadedStrings #-}

module Transform.KMTransform (transformQuestionnaire) where

import FormEngine.FormItem
import Transform.KModel as Model

import Data.Maybe
import Data.Monoid
import Data.Text hiding (map)

concatt = Data.Text.concat

transformText :: Maybe Text -> Text
transformText = fromMaybe ""

makeHtmlLink :: Text -> Text -> Bool -> Text
makeHtmlLink link anchor newtab = concatt ["<a href=\"", link, "\" target=\"", target,"\">", anchor, "</a>"]
                                where target = if newtab then "_blank" else "_self"

transformExpert     :: Model.Expert -> Text
transformExpert e   = case expertEmail e of
                        Nothing      -> expertName e
                        Just address -> makeHtmlLink ("mailto:" <> address) (expertName e) True

transformReference   :: Model.Reference -> Text
transformReference r = case refType r of
                        "dmpbook" -> concatt ["DMP Book chapter ", transformText . dmpChapter $ r]
                        "xref"    -> "Reference to other question (not implemented yet)"
                        "url"     -> case urlrefText r of
                                        Nothing     -> makeHtmlLink url url True
                                        Just anchor -> makeHtmlLink url anchor True
                                     where url = transformText . urlrefLink $ r
                        _         -> "Unrecognized reference"

transformAnswer   :: Model.Answer -> Option
transformAnswer a = case answerFollow a of
                        Just follows -> DetailedOption NoNumbering (answerLabel a) [followGroup follows]
                        _ -> SimpleOption (answerLabel a)
                        where
                            followGroup fs = SimpleGroup
                              { sgDescriptor = FIDescriptor
                                { iLabel = Nothing
                                , iShortDescription = Nothing
                                , iTags = []
                                , iLongDescription =  Nothing
                                , iLink = Nothing
                                , iMandatory = True
                                , iNumbering = NoNumbering
                                , iIdent = Nothing
                                , iRules = []
                                }
                              , sgLevel = 0
                              , sgItems = map transformQuestion fs
                              }

-- TODO: references, experts, follows on question
transformQuestion   :: Model.Question -> FormItem
transformQuestion q = case questType q of
                        "option" -> transformOptionQuestion q
                        "list" -> transformListQuestion q
                        _ -> transformFieldQuestion q

transformOptionQuestion   :: Model.Question -> FormItem
transformOptionQuestion q = ChoiceFI
  { chfiDescriptor = FIDescriptor
    { iLabel = Just (questTitle q)
    , iTags = []
    , iShortDescription = Nothing
    , iLongDescription =  Nothing
    , iLink = Nothing
    , iMandatory = True
    , iNumbering = NoNumbering
    , iIdent = Nothing
    , iRules = []
    }
  , chfiAvailableOptions = map transformAnswer (fromMaybe [] . questAnswers $ q)
  }

transformListQuestion   :: Model.Question -> FormItem
transformListQuestion q = SimpleGroup
  { sgDescriptor = FIDescriptor
    { iLabel = Just (questTitle q)
    , iTags = []
    , iShortDescription = Nothing
    , iLongDescription = Nothing
    , iLink = Nothing
    , iMandatory = True
    , iNumbering = NoNumbering
    , iIdent = Nothing
    , iRules = []
    }
  , sgLevel = 0
  , sgItems = [ TextFI
                { tfiDescriptor = FIDescriptor
                  { iLabel = Just "Items"
                  , iTags = []
                  , iShortDescription = Just "Write each item on new line"
                  , iLongDescription = Nothing
                  , iLink = Nothing
                  , iMandatory = False
                  , iNumbering = NoNumbering
                  , iIdent = Nothing
                  , iRules = []
                  }
                }
              ]
  }

transformFieldQuestion   :: Model.Question -> FormItem
transformFieldQuestion q = case questType q of
                            "text" -> TextFI {tfiDescriptor = qFI}
                            "number" -> NumberFI {nfiDescriptor = qFI, nfiUnit = NoUnit}
                            "email" -> EmailFI {efiDescriptor = qFI}
                            _ -> StringFI {sfiDescriptor = qFI}
                            where qFI = FIDescriptor
                                        { iLabel = Just (questTitle q)
                                        , iTags = []
                                        , iShortDescription = Nothing
                                        , iLongDescription = questText q
                                        , iLink = Nothing
                                        , iMandatory = True
                                        , iNumbering = NoNumbering
                                        , iIdent = Nothing
                                        , iRules = []
                                        }

transformChapter    :: Model.Chapter -> FormItem
transformChapter ch = FormEngine.FormItem.Chapter
  { chDescriptor = FIDescriptor
    { iLabel = Just (chapTitle ch)
    , iTags = []
    , iShortDescription = Just "chapter"
    , iLongDescription = chapText ch
    , iLink = Nothing
    , iMandatory = False
    , iNumbering = NoNumbering
    , iIdent = Nothing
    , iRules = []
    }
  , chItems = map transformQuestion (chapQuests ch)
  }

transformQuestionnaire :: [Model.Chapter] -> [FormItem]
transformQuestionnaire = map transformChapter
