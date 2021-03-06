{-# LANGUAGE OverloadedStrings #-}

module Main
  ( main
  ) where

import           Network             (PortID (PortNumber))
import           Periodic.Client     (Client, newClient, submitJob)
import qualified Periodic.Client     as Client (close)

import           Control.Monad       (void)
import           Data.String.Utils   (split)

import           Data.Semigroup      ((<>))
import           Options.Applicative

data Options = Options { periodicHost :: String
                       , periodicPort :: Int
                       , funcNameList :: String
                       }

parser :: Parser Options
parser = Options <$> strOption (long "host"
                                <> short 'H'
                                <> metavar "HOST"
                                <> help "Periodic Host"
                                <> value "127.0.0.1")
                 <*> option auto (long "port"
                                <> short 'P'
                                <> metavar "PORT"
                                <> help "Periodic Port"
                                <> value 5000)
                 <*> strOption (long "func"
                                <> short 'f'
                                <> metavar "FUNC"
                                <> help "FuncName List"
                                <> value "")

main :: IO ()
main = execParser opts >>= program
  where
    opts = info (helper <*> parser)
      ( fullDesc
     <> progDesc "Submit Image"
     <> header "submit-image - Submit Image" )

program :: Options -> IO ()
program (Options { periodicPort = port
                 , periodicHost = host
                 , funcNameList = funcs
                 }) = do

  c <- newClient host (PortNumber $ fromIntegral port)
  name <- getLine
  mapM (doSubmit c name) $ split "," funcs
  submitJob c "remove" name 43200
  Client.close c
  putStrLn "OK"

doSubmit :: Client -> FilePath -> String -> IO ()
doSubmit c fileName funcName = void $ submitJob c funcName fileName 0
