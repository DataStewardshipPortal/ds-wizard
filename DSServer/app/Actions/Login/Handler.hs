{-# LANGUAGE OverloadedStrings #-}

module Actions.Login.Handler (handler) where

import Data.Text (Text)
import qualified Data.Text as T
import qualified Data.Text.Lazy as TL
import Text.Blaze.Html5 (Html, (!))
import qualified Text.Blaze.Html5 as H
import qualified Text.Blaze.Html5.Attributes as A
import Text.Digestive ((.:))
import qualified Text.Digestive as D
import qualified Text.Digestive.Blaze.Html5 as DH
import Text.Digestive.Scotty (runForm)
import Web.Scotty (redirect)

import App (Action, PGPool, runQuery)
import Auth (doLoginAction)
import qualified Model.User as U
import qualified Persistence.User as U
import Actions.FormUtils (emailFormlet, passwordFormlet, addError, errorTr)
import Actions.Login.Url (url)
import qualified Actions.Main.Url as Actions.Main
import qualified Actions.ForgottenPassword.Url as Actions.ForgottenPassword
import qualified Page

{-# ANN module ("HLint: ignore Use camelCase" :: String) #-}
{-# ANN module ("HLint: ignore Redundant do" :: String) #-}

data LoginRequest = LoginRequest
  { lr_email :: Text
  , lr_password :: Text
  } deriving (Show)

loginForm :: Monad m => D.Form Html m LoginRequest
loginForm =
  LoginRequest <$> "email" .: emailFormlet Nothing
                  <*> "password" .: passwordFormlet Nothing

formView :: D.View Html -> Html
formView v = do
 -- errorList "mail" view
  H.h2 "User Login"
  DH.form v (T.pack url) $ do
    H.table ! A.class_ "form-table" $
      H.tbody $ do
        H.tr $ do
          H.td $ DH.label     "email" v "Email: "
          H.td $ DH.inputText "email" v
        errorTr "email" v
        H.tr $ do
          H.td $ DH.label         "password" v "Password: "
          H.td $ do
            DH.inputPassword "password" v
            H.button ! A.type_ "submit" ! A.formaction (H.textValue $ T.pack Actions.ForgottenPassword.url) $ "Forgotten password"
            --H.a ! A.href (H.textValue $ T.pack Actions.ForgottenPassword.url) $ "Forgotten password"
        errorTr "password" v
        H.tr $ do
          H.td mempty
          H.td $ H.button ! A.type_ "submit" $ "Login"

handler :: PGPool -> Action
handler pool = do
  f <- runForm "loginForm" loginForm
  case f of
    (v, Nothing) -> Page.render False (formView v) Nothing Page.NoMessage
    (v, Just loginReq) -> do
      mUser <- runQuery pool $ U.getUserByEmail (U.Email $ TL.fromStrict $ lr_email loginReq)
      case mUser of
        Nothing -> do
          let v2 = addError v "email" "Email not registered."
          Page.render False (formView v2) Nothing Page.NoMessage
        Just user -> do
          if not (U.u_registration_confirmed user) then do
            let v2 = addError v "email" "Email registration has not been confirmed."
            Page.render False (formView v2) Nothing Page.NoMessage
        -- todo
          else
            if not $ U.authUser (U.Password $ TL.fromStrict $ lr_password loginReq) user then do
              let v2 = addError v "password" "Incorrect password."
              Page.render False (formView v2) Nothing  Page.NoMessage
            else
              doLoginAction pool user $ redirect $ TL.pack Actions.Main.url

