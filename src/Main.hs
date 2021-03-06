{-# LANGUAGE OverloadedStrings #-}

module Main where

import Prelude
import Data.Maybe (isNothing, catMaybes, fromMaybe)
import Text.Read (readMaybe)

import Haste.Ajax (ajaxRequest, Method(POST), noParams)
import FormEngine.JQuery (ready, errorIO)
import qualified Questionnaire
import FormEngine.FormData (FormData)
import FormEngine.FormElement.FormElement as Element
import Form (generateForm, renderSpinner)
import Overlay (initOverlay)
import qualified Actions

--import Debug.Trace
main :: IO ()
main = ready $ do
  Actions.doExports
  _ <- initOverlay
  renderSpinner
  ajaxRequest POST "api/plan/getData" noParams buildQuestionnaire
    where
    buildQuestionnaire :: Maybe String -> IO ()
    buildQuestionnaire maybeDataString = do
      let maybeFormData = readMaybe (fromMaybe "" maybeDataString) :: Maybe FormData
      --let tabMaybes = map (Element.makeChapter $ traceShow maybeFormData maybeFormData) Questionnaire.formItems
      let tabMaybes = map (Element.makeChapter maybeFormData) Questionnaire.formItems
      if any isNothing tabMaybes then do
        errorIO "Error generating tabs"
        return ()
      else do
        let tabs = catMaybes tabMaybes
        --generateForm (traceShow tabs tabs)
        generateForm tabs
